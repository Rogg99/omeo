"""
Back-office des campagnes. Programmer une campagne passe par quatre yeux : programmée par son auteur, elle crée une
demande de validation (202) ; une autre personne ayant `campaigns.schedule` la programme directement.
"""

from __future__ import annotations

from typing import Any, ClassVar, Final

from django.db import transaction
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core import audit
from apps.core.approvals import ApprovalService, is_enabled
from apps.core.errors import Conflict, NotFound
from apps.core.i18n import validate_i18n_text
from apps.core.models import ApprovalKind, ApprovalRequest
from apps.core.pagination import page_body, page_paginate
from apps.core.presenters import approval_out
from apps.core.views import AdminAPIView, validated
from apps.notifications import selectors, services
from apps.notifications.models import Campaign, CampaignStatus

ACTION_PERMISSIONS: Final[dict[str, str]] = {
    "schedule": "campaigns.schedule",
    "cancel": "campaigns.schedule",
    "send_test": "campaigns.edit",
}


class SegmentSerializer(serializers.Serializer[Any]):
    locales = serializers.ListField(child=serializers.CharField(max_length=2), required=False, default=list)
    countries = serializers.ListField(child=serializers.CharField(max_length=2), required=False, default=list)
    tiers = serializers.ListField(
        child=serializers.ChoiceField(choices=["trial", "free", "plus"]), required=False, default=list
    )
    goals = serializers.ListField(child=serializers.CharField(max_length=24), required=False, default=list)
    inactive_days_min = serializers.IntegerField(min_value=1, required=False, allow_null=True)


class CampaignSerializer(serializers.Serializer[Any]):
    title = serializers.JSONField(validators=[validate_i18n_text])
    body = serializers.JSONField(validators=[validate_i18n_text])
    deeplink = serializers.CharField(max_length=200, required=False, allow_null=True, allow_blank=True)
    image_upload_id = serializers.UUIDField(required=False, allow_null=True)
    segment = SegmentSerializer()
    scheduled_at = serializers.DateTimeField(required=False, allow_null=True)


def _segment(data: dict[str, Any]) -> dict[str, Any]:
    segment = {k: v for k, v in data.items() if v}
    if "inactive_days_min" in segment:
        segment["inactive_days"] = segment.pop("inactive_days_min")
    return segment


def _audience_count(segment: dict[str, Any]) -> int:
    return len(selectors.filter_by_tier(selectors.campaign_audience(segment), segment.get("tiers")))


def campaign_out(campaign: Campaign, *, with_audience: bool = False) -> dict[str, Any]:
    segment = dict(campaign.segment)
    if "inactive_days" in segment:
        segment["inactive_days_min"] = segment.pop("inactive_days")
    body: dict[str, Any] = {
        "id": campaign.id,
        "title": campaign.title,
        "body": campaign.body,
        "deeplink": campaign.deeplink or None,
        "segment": segment,
        "scheduled_at": campaign.scheduled_at,
        "status": campaign.status,
        "sent_count": campaign.sent_count,
        "opened_count": campaign.opened_count,
        "open_rate": round(campaign.opened_count / campaign.sent_count, 3) if campaign.sent_count else None,
        "created_by": campaign.created_by.email,
        "created_at": campaign.created_at,
    }
    if with_audience:
        body["audience_count"] = _audience_count(campaign.segment)
    return body


def _campaign(campaign_id: Any) -> Campaign:
    campaign = Campaign.objects.select_related("created_by").filter(pk=campaign_id).first()
    if campaign is None:
        raise NotFound()
    return campaign


class CampaignsView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "campaigns.view", "POST": "campaigns.edit"}

    @extend_schema(operation_id="adminListCampaigns")
    def get(self, request: Request) -> Response:
        rows, meta = page_paginate(request, Campaign.objects.select_related("created_by").order_by("-created_at"))
        return Response(page_body([campaign_out(c) for c in rows], meta))

    @extend_schema(operation_id="adminCreateCampaign", request=CampaignSerializer)
    def post(self, request: Request) -> Response:
        data = validated(CampaignSerializer, request.data)
        campaign = Campaign.objects.create(
            title=data["title"],
            body=data["body"],
            deeplink=data.get("deeplink") or "",
            segment=_segment(dict(data["segment"])),
            scheduled_at=data.get("scheduled_at"),
            created_by=request.user,
        )
        return Response(campaign_out(campaign, with_audience=True), status=status.HTTP_201_CREATED)


class AudienceView(AdminAPIView):
    required_permission = "campaigns.edit"

    @extend_schema(operation_id="adminEstimateAudience", request=SegmentSerializer)
    def post(self, request: Request) -> Response:
        data = validated(SegmentSerializer, request.data)
        return Response({"count": _audience_count(_segment(dict(data)))})


class CampaignDetailView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "campaigns.view", "PATCH": "campaigns.edit"}

    @extend_schema(operation_id="adminGetCampaign")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        return Response(campaign_out(_campaign(id), with_audience=True))

    @extend_schema(operation_id="adminUpdateCampaign", request=CampaignSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        campaign = _campaign(id)
        if campaign.status != CampaignStatus.DRAFT:
            raise Conflict(detail="only drafts are editable")
        data = validated(CampaignSerializer, request.data, partial=True)
        for field in ("title", "body", "scheduled_at"):
            if field in data:
                setattr(campaign, field, data[field])
        if "deeplink" in data:
            campaign.deeplink = data["deeplink"] or ""
        if "segment" in data:
            campaign.segment = _segment(dict(data["segment"]))
        campaign.save()
        return Response(campaign_out(campaign, with_audience=True))


class CampaignActionView(AdminAPIView):
    """Permission dynamique « campaigns.<action> » ; programmer/annuler exige un step-up."""

    dynamic_step_up = True

    def resolve_permission(self, request: Request) -> str | None:
        return ACTION_PERMISSIONS.get(str(self.kwargs.get("action")))

    @extend_schema(operation_id="adminCampaignAction", request=None)
    def post(self, request: Request, id: Any, action: str) -> Response:  # noqa: A002
        campaign = _campaign(id)
        if action == "send_test":
            services.notify(user=request.user, category="campaign", title=campaign.title, body=campaign.body, push=True)
            return Response(campaign_out(campaign))
        if action == "cancel":
            if campaign.status not in (CampaignStatus.DRAFT, CampaignStatus.SCHEDULED):
                raise Conflict(detail="campaign already sent")
            campaign.status = CampaignStatus.CANCELED
            campaign.save(update_fields=["status", "updated_at"])
            audit.record(
                actor=request.user,
                action="campaign.cancel",
                target_type="campaign",
                target_id=campaign.pk,
                request=request,
            )
            return Response(campaign_out(campaign))
        if campaign.status != CampaignStatus.DRAFT or campaign.scheduled_at is None:
            raise Conflict(detail="a draft with a send date is required")
        if campaign.created_by_id == request.user.pk and is_enabled("content"):
            approval = ApprovalService.create(
                kind=ApprovalKind.CAMPAIGN_SCHEDULE,
                payload={"campaign_id": str(campaign.pk)},
                diff={
                    "before": {"status": "draft"},
                    "after": {"status": "scheduled", "scheduled_at": str(campaign.scheduled_at)},
                },
                target_type="campaign",
                target_id=str(campaign.pk),
                reason="Programmation de campagne",
                requested_by=request.user,
                request=request,
            )
            return Response(approval_out(approval), status=status.HTTP_202_ACCEPTED)
        schedule_campaign({"campaign_id": str(campaign.pk)}, actor=request.user)
        return Response(campaign_out(_campaign(id)))


@transaction.atomic
def schedule_campaign(payload: dict[str, Any], *, actor: Any) -> dict[str, Any]:
    campaign = Campaign.objects.select_for_update().get(pk=payload["campaign_id"])
    if campaign.status != CampaignStatus.DRAFT:
        raise Conflict(detail="campaign is not a draft")
    campaign.status = CampaignStatus.SCHEDULED
    campaign.save(update_fields=["status", "updated_at"])
    audit.record(actor=actor, action="campaign.schedule", target_type="campaign", target_id=campaign.pk)
    return {"status": "scheduled"}


def apply_campaign_schedule(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    return schedule_campaign(approval.payload, actor=decider)
