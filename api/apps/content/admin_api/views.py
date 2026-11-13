"""Back-office éditorial : contenus des 15 types, workflow, versions, traduction proposée, couverture, médias."""

from __future__ import annotations

from typing import Any, ClassVar, Final

from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.content import admin_catalog, admin_services
from apps.content.models import ContentRevision
from apps.content.translation import translate_fields
from apps.core import storage
from apps.core.errors import NotFound, ValidationFailed
from apps.core.i18n import LOCALES, resolve
from apps.core.models import ApprovalRequest
from apps.core.pagination import apply_ordering, page_body, page_paginate
from apps.core.presenters import approval_out
from apps.core.views import AdminAPIView, validated
from apps.meals.models import Upload, UploadKind

MEDIA_TYPES: Final[dict[str, dict[str, str]]] = {
    "image": {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"},
    "video": {"video/mp4": "mp4", "application/vnd.apple.mpegurl": "m3u8", "video/mp2t": "ts"},
    "subtitles": {"text/vtt": "vtt"},
}
MAX_MEDIA_BYTES: Final = 500 * 1024 * 1024


def _kind(type_name: str) -> admin_catalog.ContentType:
    try:
        return admin_catalog.get(type_name)
    except KeyError:
        raise NotFound() from None


def _title(kind: admin_catalog.ContentType, obj: Any) -> str:
    value = getattr(obj, kind.title_field)
    return resolve(value) if isinstance(value, dict) else str(value)


def row_out(kind: admin_catalog.ContentType, obj: Any) -> dict[str, Any]:
    author = admin_services.last_author(kind.name, obj.pk)
    return {
        "id": obj.pk,
        "type": kind.name,
        "title": _title(kind, obj),
        "status": kind.status_of(obj),
        "missing_locales": kind.missing_locales(obj),
        "thumbnail": None,
        "updated_at": obj.updated_at,
        "updated_by": author.email if author else None,
    }


def item_out(kind: admin_catalog.ContentType, obj: Any) -> dict[str, Any]:
    return {
        **row_out(kind, obj),
        "version": admin_services.version_of(kind.name, obj.pk),
        "data": kind.to_data(obj),
        "computed": kind.computed(obj),
    }


class PayloadSerializer(serializers.Serializer[Any]):
    version = serializers.IntegerField(min_value=0, required=False)
    data = serializers.DictField()


class ContentListView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "content.view", "POST": "content.edit"}

    @extend_schema(operation_id="adminListContent")
    def get(self, request: Request, type: str) -> Response:  # noqa: A002 - nom imposé par le contrat
        kind = _kind(type)
        queryset = kind.model.objects.all()
        params = request.query_params
        if params.get("status") and kind.has_status:
            queryset = queryset.filter(status=params["status"])
        if params.get("q") and kind.title_field != "action":
            queryset = queryset.filter(**{f"{kind.title_field}__fr__icontains": params["q"]})
        if params.get("missing_locale") in LOCALES and kind.i18n_fields:
            locale = params["missing_locale"]
            queryset = queryset.exclude(**{f"{kind.title_field}__has_key": locale})
        queryset = apply_ordering(request, queryset, allowed=["updated_at", "created_at"], default="-updated_at")
        rows, meta = page_paginate(request, queryset)
        return Response(page_body([row_out(kind, obj) for obj in rows], meta))

    @extend_schema(operation_id="adminCreateContent", request=PayloadSerializer)
    def post(self, request: Request, type: str) -> Response:  # noqa: A002
        kind = _kind(type)
        payload = validated(PayloadSerializer, request.data)
        data = validated(kind.serializer, payload["data"])
        obj = admin_services.save_content(kind=kind, obj=kind.model(), data=data, actor=request.user, request=request)
        return Response(item_out(kind, obj), status=status.HTTP_201_CREATED)


class ContentDetailView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {
        "GET": "content.view",
        "PATCH": "content.edit",
        "DELETE": "content.edit",
    }

    @extend_schema(operation_id="adminGetContent")
    def get(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        kind = _kind(type)
        return Response(item_out(kind, admin_services.get_object(kind, id)))

    @extend_schema(operation_id="adminUpdateContent", request=PayloadSerializer)
    def patch(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        kind = _kind(type)
        payload = validated(PayloadSerializer, request.data)
        data = validated(kind.serializer, payload["data"], partial=True)
        obj = admin_services.update_content(
            kind=kind, object_id=id, data=data, version=payload.get("version"), actor=request.user, request=request
        )
        return Response(item_out(kind, obj))

    @extend_schema(operation_id="adminDeleteContent")
    def delete(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        admin_services.archive_content(kind=_kind(type), object_id=id, actor=request.user, request=request)
        return Response(status=status.HTTP_204_NO_CONTENT)


class TransitionSerializer(serializers.Serializer[Any]):
    to = serializers.ChoiceField(choices=["draft", "review", "published", "archived"])
    comment = serializers.CharField(max_length=500, required=False, allow_blank=True, default="")


class ContentTransitionView(AdminAPIView):
    required_permission = "content.edit"

    @extend_schema(operation_id="adminTransitionContent", request=TransitionSerializer)
    def post(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        kind = _kind(type)
        data = validated(TransitionSerializer, request.data)
        result = admin_services.transition(
            kind=kind, object_id=id, to=data["to"], comment=data["comment"], actor=request.user, request=request
        )
        if isinstance(result, ApprovalRequest):
            return Response(approval_out(result), status=status.HTTP_202_ACCEPTED)
        return Response(item_out(kind, result))


class ContentRevisionsView(AdminAPIView):
    required_permission = "content.view"

    @extend_schema(operation_id="adminListRevisions")
    def get(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        kind = _kind(type)
        revisions = (
            ContentRevision.objects.filter(content_type=kind.name, object_id=id)
            .select_related("author")
            .order_by("-created_at")
        )
        return Response(
            [
                {
                    "id": r.id,
                    "author": r.author.email if r.author else "system",
                    "created_at": r.created_at,
                    "snapshot": r.snapshot,
                }
                for r in revisions
            ]
        )


class TranslateSerializer(serializers.Serializer[Any]):
    locales = serializers.ListField(child=serializers.ChoiceField(choices=list(LOCALES)), min_length=1)


class ContentTranslateView(AdminAPIView):
    required_permission = "content.translate"

    @extend_schema(operation_id="adminMachineTranslate", request=TranslateSerializer)
    def post(self, request: Request, type: str, id: Any) -> Response:  # noqa: A002
        kind = _kind(type)
        data = validated(TranslateSerializer, request.data)
        obj = admin_services.get_object(kind, id)
        fields = {name: getattr(obj, name) for name in kind.i18n_fields if isinstance(getattr(obj, name), dict)}
        return Response(translate_fields(fields, data["locales"]))


class TranslationCoverageView(AdminAPIView):
    required_permission = "content.view"

    @extend_schema(operation_id="adminTranslationCoverage")
    def get(self, request: Request) -> Response:
        coverage = []
        for kind in admin_catalog.REGISTRY.values():
            if not kind.i18n_fields:
                continue
            queryset = kind.model.objects.all()
            total = queryset.count()
            for locale in LOCALES:
                present = queryset.filter(**{f"{kind.title_field}__has_key": locale}).count()
                missing = total - present
                coverage.append(
                    {
                        "type": kind.name,
                        "locale": locale,
                        "total": total,
                        "missing": missing,
                        "percent": round(present / total * 100, 1) if total else 100.0,
                    }
                )
        return Response(coverage)


class MediaSerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=list(MEDIA_TYPES))
    content_type = serializers.CharField(max_length=60)
    size = serializers.IntegerField(min_value=1, max_value=MAX_MEDIA_BYTES)


class MediaUploadView(AdminAPIView):
    required_permission = "content.edit"

    @extend_schema(operation_id="adminCreateMediaUpload", request=MediaSerializer)
    def post(self, request: Request) -> Response:
        data = validated(MediaSerializer, request.data)
        extension = MEDIA_TYPES[data["kind"]].get(data["content_type"])
        if extension is None:
            raise ValidationFailed(
                errors={"content_type": [{"code": "invalid_choice", "message": data["content_type"]}]}
            )
        key = storage.build_key(prefix=f"media/{data['kind']}", owner_id=None, extension=extension)
        ticket = storage.presign_upload(key=key, content_type=data["content_type"], size=data["size"], bucket="public")
        upload = Upload.objects.create(
            user=request.user,
            kind=UploadKind.MEDIA,
            storage_key=key,
            content_type=data["content_type"],
            size=data["size"],
            expires_at=ticket.expires_at,
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
