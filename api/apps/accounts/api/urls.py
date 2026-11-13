"""Routes de l'authentification et du compte (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.accounts.api import views

urlpatterns = [
    path("app/config", views.AppConfigView.as_view()),
    path("app/cities", views.CitySearchView.as_view()),
    path("auth/register", views.RegisterView.as_view()),
    path("auth/login", views.LoginView.as_view()),
    path("auth/social", views.SocialAuthView.as_view()),
    path("auth/mfa/verify", views.MfaVerifyView.as_view()),
    path("auth/mfa/step-up", views.MfaStepUpView.as_view()),
    path("auth/refresh", views.RefreshView.as_view()),
    path("auth/logout", views.LogoutView.as_view()),
    path("auth/password/forgot", views.ForgotPasswordView.as_view()),
    path("auth/password/reset", views.ResetPasswordView.as_view()),
    path("auth/email/verify", views.VerifyEmailView.as_view()),
    path("auth/email/resend", views.ResendVerificationView.as_view()),
    path("referral/check", views.CheckInviteCodeView.as_view()),
    path("me", views.MeView.as_view()),
    path("me/profile", views.ProfileView.as_view()),
    path("me/avatar", views.AvatarView.as_view()),
    path("me/email", views.ChangeEmailView.as_view()),
    path("me/password", views.ChangePasswordView.as_view()),
    path("me/social-accounts", views.SocialAccountsView.as_view()),
    path("me/sessions", views.SessionsView.as_view()),
    path("me/sessions/<uuid:id>", views.SessionDetailView.as_view()),
    path("me/consents", views.ConsentsView.as_view()),
    path("me/uploads", views.UploadsView.as_view()),
    path("account-deletion", views.DeletionByEmailView.as_view()),
    path("account-deletion/confirm", views.ConfirmDeletionByEmailView.as_view()),
]
