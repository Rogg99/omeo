"""Vues minces de l'authentification et du compte : validation, appel du service, sérialisation."""

from __future__ import annotations

from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import BaseThrottle

from apps.accounts import selectors, services
from apps.accounts import serializers as s
from apps.accounts.models import Session
from apps.core.captcha import verify_turnstile
from apps.accounts.tokens import rotate
from apps.core.idempotency import idempotent
from apps.core.permissions import AUTHENTICATED_STAFF, HasPermission, RequiresVerifiedEmail
from apps.core.throttles import (
    AuthAccountThrottle,
    AuthIpThrottle,
    PublicFormThrottle,
    PublicReadThrottle,
    RegisterThrottle,
)
from apps.core.views import AppAPIView, PublicAPIView, request_meta, validated
from apps.meals.services import create_upload


def _auth_result(outcome: services.AuthOutcome) -> dict[str, Any]:
    body: dict[str, Any] = {
        "tokens": s.tokens_out(outcome.tokens),
        "me": s.me_out(**selectors.me_context(outcome.user.pk)),
        "created": outcome.created,
    }
    if outcome.invite_code_status is not None:
        body["invite_code_status"] = outcome.invite_code_status
    return body


def _me_body(user_id: Any) -> dict[str, Any]:
    return s.me_out(**selectors.me_context(user_id))


def _session(request: Request) -> Session:
    return request.auth_session  # type: ignore[attr-defined, no-any-return]


# ───────────────────────── App ─────────────────────────


class AppConfigView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicReadThrottle]

    @extend_schema(operation_id="getAppConfig")
    def get(self, request: Request) -> Response:
        return Response(selectors.app_config())


class CitySearchView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicReadThrottle]

    @extend_schema(operation_id="searchCities")
    def get(self, request: Request) -> Response:
        params = validated(s.CitySearchSerializer, request.query_params)
        cities = selectors.search_cities(q=params.get("q"), country=params.get("country"))
        return Response({"results": [s.city_out(c) for c in cities]})


# ───────────────────────── Authentification ─────────────────────────


class RegisterView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [RegisterThrottle]

    @extend_schema(operation_id="register", request=s.RegisterSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.RegisterSerializer, request.data)
        outcome = services.register(
            email=data["email"],
            password=data["password"],
            profile=dict(data["profile"]),
            consents=[dict(c) for c in data["consents"]],
            invite_code=data.get("invite_code"),
            device=data.get("device"),
            meta=request_meta(request),
        )
        return Response(_auth_result(outcome), status=status.HTTP_201_CREATED)


class LoginView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle, AuthAccountThrottle]

    @extend_schema(operation_id="login", request=s.LoginSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.LoginSerializer, request.data)
        outcome = services.login(
            email=data["email"], password=data["password"], device=data.get("device"), meta=request_meta(request)
        )
        return Response(_auth_result(outcome))


class SocialAuthView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle]

    @extend_schema(operation_id="socialAuth", request=s.SocialAuthSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.SocialAuthSerializer, request.data)
        outcome = services.social_auth(
            provider=data["provider"],
            id_token=data["id_token"],
            nonce=data.get("nonce"),
            invite_code=data.get("invite_code"),
            profile=dict(data["profile"]) if data.get("profile") else None,
            consents=[dict(c) for c in data.get("consents") or []] or None,
            device=data.get("device"),
            meta=request_meta(request),
        )
        return Response(_auth_result(outcome))


class MfaVerifyView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle, AuthAccountThrottle]

    @extend_schema(operation_id="verifyMfa", request=s.MfaVerifySerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.MfaVerifySerializer, request.data)
        outcome = services.verify_mfa(
            mfa_token=data["mfa_token"], code=data["code"], device=data.get("device"), meta=request_meta(request)
        )
        return Response(_auth_result(outcome))


class MfaStepUpView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission]
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle]
    required_permission = AUTHENTICATED_STAFF

    @extend_schema(operation_id="stepUpMfa", request=s.MfaCodeSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.MfaCodeSerializer, request.data)
        verified_until = services.step_up(session=_session(request), code=data["code"])
        return Response({"mfa_verified_until": verified_until})


class RefreshView(PublicAPIView):
    @extend_schema(operation_id="refreshToken", request=s.RefreshSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.RefreshSerializer, request.data)
        return Response(s.tokens_out(rotate(data["refresh"])))


class LogoutView(AppAPIView):
    @extend_schema(operation_id="logout", request=s.LogoutSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.LogoutSerializer, request.data or {})
        services.logout(session=_session(request), all_devices=data["all_devices"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ForgotPasswordView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle, AuthAccountThrottle]

    @extend_schema(operation_id="forgotPassword", request=s.EmailSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.EmailSerializer, request.data)
        services.forgot_password(email=data["email"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ResetPasswordView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle]

    @extend_schema(operation_id="resetPassword", request=s.ResetPasswordSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.ResetPasswordSerializer, request.data)
        services.reset_password(token=data["token"], password=data["password"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class VerifyEmailView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle]

    @extend_schema(operation_id="verifyEmail", request=s.TokenSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.TokenSerializer, request.data)
        services.verify_email(token=data["token"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ResendVerificationView(AppAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicFormThrottle]

    @extend_schema(operation_id="resendVerificationEmail", request=None)
    def post(self, request: Request) -> Response:
        services.send_verification_email(user=request.user)  # type: ignore[arg-type]
        return Response(status=status.HTTP_204_NO_CONTENT)


class CheckInviteCodeView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [AuthIpThrottle]

    @extend_schema(operation_id="checkInviteCode", request=s.InviteCodeSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.InviteCodeSerializer, request.data)
        return Response(services.check_invite_code(code=data["code"]))


# ───────────────────────── Compte ─────────────────────────


class MeView(AppAPIView):
    @extend_schema(operation_id="getMe")
    def get(self, request: Request) -> Response:
        return Response(_me_body(request.user.pk))

    @extend_schema(operation_id="requestAccountDeletion", request=s.AccountDeletionSerializer)
    def delete(self, request: Request) -> Response:
        data = validated(s.AccountDeletionSerializer, request.data)
        result = services.request_account_deletion(user=request.user, password=data.get("password"))  # type: ignore[arg-type]
        body: dict[str, Any] = {
            "scheduled_for": result.scheduled_for,
            "store_subscription_active": result.store_channel is not None,
        }
        if result.store_channel:
            body["store_channel"] = result.store_channel
        return Response(body)


class ProfileView(AppAPIView):
    @extend_schema(operation_id="updateProfile", request=s.ProfileUpdateSerializer)
    def patch(self, request: Request) -> Response:
        data = validated(s.ProfileUpdateSerializer, request.data)
        services.update_profile(user=request.user, data=data)  # type: ignore[arg-type]
        return Response(_me_body(request.user.pk))


class AvatarView(AppAPIView):
    @extend_schema(operation_id="setAvatar", request=s.UploadRefSerializer)
    def put(self, request: Request) -> Response:
        data = validated(s.UploadRefSerializer, request.data)
        profile = services.set_avatar(user=request.user, upload_id=data["upload_id"])  # type: ignore[arg-type]
        return Response(s.image_out(profile.avatar))

    @extend_schema(operation_id="deleteAvatar")
    def delete(self, request: Request) -> Response:
        services.delete_avatar(user=request.user)  # type: ignore[arg-type]
        return Response(status=status.HTTP_204_NO_CONTENT)


class ChangeEmailView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresVerifiedEmail]

    @extend_schema(operation_id="changeEmail", request=s.ChangeEmailSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.ChangeEmailSerializer, request.data)
        services.request_email_change(user=request.user, new_email=data["email"], password=data.get("password"))  # type: ignore[arg-type]
        return Response(status=status.HTTP_202_ACCEPTED)


class ChangePasswordView(AppAPIView):
    @extend_schema(operation_id="changePassword", request=s.ChangePasswordSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.ChangePasswordSerializer, request.data)
        services.change_password(
            user=request.user,  # type: ignore[arg-type]
            current_password=data.get("current_password"),
            new_password=data["new_password"],
            session=_session(request),
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class SocialAccountsView(AppAPIView):
    @extend_schema(operation_id="listSocialAccounts")
    def get(self, request: Request) -> Response:
        accounts = request.user.social_accounts.order_by("provider")  # type: ignore[union-attr]
        return Response([{"provider": a.provider, "email": a.email or None} for a in accounts])


class SessionsView(AppAPIView):
    @extend_schema(operation_id="listSessions")
    def get(self, request: Request) -> Response:
        current = _session(request).pk
        sessions = selectors.active_sessions(request.user)  # type: ignore[arg-type]
        return Response([s.session_out(row, current_id=current) for row in sessions])


class SessionDetailView(AppAPIView):
    @extend_schema(operation_id="revokeSession")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        services.revoke_session(user=request.user, session_id=id)  # type: ignore[arg-type]
        return Response(status=status.HTTP_204_NO_CONTENT)


class ConsentsView(AppAPIView):
    @extend_schema(operation_id="listConsents")
    def get(self, request: Request) -> Response:
        user = request.user
        return Response(
            {
                "consents": selectors.consent_states(user),  # type: ignore[arg-type]
                "pending_documents": [s.legal_ref_out(d) for d in selectors.pending_documents(user)],  # type: ignore[arg-type]
            }
        )

    @extend_schema(operation_id="updateConsents", request=s.ConsentUpdateSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.ConsentUpdateSerializer, request.data)
        services.update_consents(
            user=request.user,  # type: ignore[arg-type]
            consents=[dict(c) for c in data["consents"]],
            meta=request_meta(request),
        )
        return Response(selectors.consent_states(request.user))  # type: ignore[arg-type]


class UploadsView(AppAPIView):
    @extend_schema(operation_id="createUpload", request=s.UploadRequestSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.UploadRequestSerializer, request.data)
        upload, ticket = create_upload(
            user=request.user, kind=data["kind"], content_type=data["content_type"], size=data["size"]
        )
        return Response(
            {
                "id": upload.id,
                "upload_url": ticket.url,
                "method": ticket.method,
                "headers": ticket.headers,
                "expires_at": ticket.expires_at,
            },
            status=status.HTTP_201_CREATED,
        )


class DeletionByEmailView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicFormThrottle]

    @extend_schema(operation_id="requestDeletionByEmail", request=s.DeletionByEmailSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.DeletionByEmailSerializer, request.data)
        verify_turnstile(data["captcha"], remote_ip=request_meta(request).ip)
        services.request_deletion_by_email(email=data["email"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ConfirmDeletionByEmailView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicFormThrottle]

    @extend_schema(operation_id="confirmDeletionByEmail", request=s.TokenSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.TokenSerializer, request.data)
        services.confirm_deletion_by_email(token=data["token"])
        return Response(status=status.HTTP_204_NO_CONTENT)

