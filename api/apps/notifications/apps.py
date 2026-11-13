from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    name = "apps.notifications"

    def ready(self) -> None:
        from apps.core.approvals import register_executor
        from apps.core.models import ApprovalKind
        from apps.notifications.admin_api.views import apply_campaign_schedule

        register_executor(ApprovalKind.CAMPAIGN_SCHEDULE, apply_campaign_schedule)
