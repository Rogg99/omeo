from django.apps import AppConfig


class NutritionConfig(AppConfig):
    name = "apps.nutrition"

    def ready(self) -> None:
        from apps.core import exports
        from apps.nutrition.selectors import export_water

        exports.register_section("water", export_water)
