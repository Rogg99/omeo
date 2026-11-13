from django.apps import AppConfig


class AccountsConfig(AppConfig):
    name = "apps.accounts"

    def ready(self) -> None:
        from apps.accounts.permissions import STEP_UP_PERMISSIONS, can_decide_domain, permissions_for_user
        from apps.accounts.services import connect_events
        from apps.core import access

        access.register_permissions(
            permissions_for_user=permissions_for_user,
            can_decide_domain=can_decide_domain,
            step_up_permissions=frozenset(STEP_UP_PERMISSIONS),
        )
        connect_events()
        from apps.accounts.selectors import export_account, export_consents
        from apps.core import exports

        exports.register_section("account", export_account)
        exports.register_section("consents", export_consents)
