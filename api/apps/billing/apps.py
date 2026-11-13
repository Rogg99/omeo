from django.apps import AppConfig


class BillingConfig(AppConfig):
    name = "apps.billing"

    def ready(self) -> None:
        from apps.billing.services import connect_events, entitlement_for
        from apps.core import access

        connect_events()
        from apps.billing.admin_services import apply_plan_update, apply_quota_update, apply_refund
        from apps.core.approvals import register_executor
        from apps.core.models import ApprovalKind

        register_executor(ApprovalKind.PLAN_UPDATE, apply_plan_update)
        register_executor(ApprovalKind.QUOTA_UPDATE, apply_quota_update)
        register_executor(ApprovalKind.REFUND, apply_refund)
        access.register_entitlements(allows_feature=lambda user, feature: entitlement_for(user).allows(feature))
