from django.apps import AppConfig


class BillingConfig(AppConfig):
    name = "apps.billing"

    def ready(self) -> None:
        from apps.billing.services import connect_events, entitlement_for
        from apps.core import access

        connect_events()
        access.register_entitlements(allows_feature=lambda user, feature: entitlement_for(user).allows(feature))
