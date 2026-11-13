from django.apps import AppConfig


class ProgramsConfig(AppConfig):
    name = "apps.programs"

    def ready(self) -> None:
        from apps.programs.services import connect_events

        connect_events()
