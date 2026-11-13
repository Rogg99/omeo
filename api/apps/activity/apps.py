from django.apps import AppConfig


class ActivityConfig(AppConfig):
    name = "apps.activity"

    def ready(self) -> None:
        from apps.activity import services
        from apps.nutrition import projection

        projection.register_contributor("activity", services.day_contribution)
        from apps.activity.selectors import export_activities, export_weights
        from apps.core import exports

        exports.register_section("weights", export_weights)
        exports.register_section("activities", export_activities)
