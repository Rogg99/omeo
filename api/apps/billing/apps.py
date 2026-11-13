from django.apps import AppConfig


class BillingConfig(AppConfig):
    name = "apps.billing"

    def ready(self) -> None:
        from apps.billing.services import connect_events

        connect_events()
