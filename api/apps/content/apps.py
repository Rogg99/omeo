from django.apps import AppConfig


class ContentConfig(AppConfig):
    name = "apps.content"

    def ready(self) -> None:
        from apps.content.services import recipe_composition
        from apps.meals.providers import register_recipe_resolver

        register_recipe_resolver(recipe_composition)
