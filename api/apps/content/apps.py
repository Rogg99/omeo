from django.apps import AppConfig


class ContentConfig(AppConfig):
    name = "apps.content"

    def ready(self) -> None:
        from apps.content.services import recipe_composition
        from apps.meals.providers import register_recipe_resolver

        register_recipe_resolver(recipe_composition)
        from apps.content.admin_services import apply_content_publish
        from apps.core.approvals import register_executor
        from apps.core.models import ApprovalKind

        register_executor(ApprovalKind.CONTENT_PUBLISH, apply_content_publish)
