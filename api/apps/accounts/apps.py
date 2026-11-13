from django.apps import AppConfig


class AccountsConfig(AppConfig):
    name = "apps.accounts"

    def ready(self) -> None:
        from apps.accounts.permissions import can_decide_domain, permissions_for_user
        from apps.accounts.services import connect_events
        from apps.core import access

        access.register_permissions(permissions_for_user=permissions_for_user, can_decide_domain=can_decide_domain)
        connect_events()
