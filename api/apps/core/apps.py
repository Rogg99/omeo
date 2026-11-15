from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.core"
    verbose_name = "Socle commun"

    def ready(self) -> None:
        from apps.core.admin_api.views import apply_settings_nutrition
        from apps.core.approvals import register_executor
        from apps.core.models import ApprovalKind

        register_executor(ApprovalKind.SETTINGS_NUTRITION, apply_settings_nutrition)

        from apps.core import web_cache

        web_cache.connect()
