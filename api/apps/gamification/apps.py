from django.apps import AppConfig


class GamificationConfig(AppConfig):
    name = "apps.gamification"

    def ready(self) -> None:
        from apps.gamification.services import connect_events

        connect_events()
