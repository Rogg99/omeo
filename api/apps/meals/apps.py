from django.apps import AppConfig


class MealsConfig(AppConfig):
    name = "apps.meals"

    def ready(self) -> None:
        from apps.meals import services
        from apps.nutrition import projection

        projection.register_contributor("meals", services.day_contribution)
        projection.register_recent_dishes(services.recent_dish_ids)
