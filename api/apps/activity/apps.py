from django.apps import AppConfig


class ActivityConfig(AppConfig):
    name = "apps.activity"

    def ready(self) -> None:
        from apps.activity import services
        from apps.nutrition import projection

        projection.register_contributor("activity", services.day_contribution)
