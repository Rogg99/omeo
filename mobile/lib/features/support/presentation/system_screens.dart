import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';

/// Écran bloquant à une seule action (mise à jour, compte suspendu).
class _BlockingScreen extends StatelessWidget {
  const _BlockingScreen({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.icon,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final OmeoIcons? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (icon == null)
                            const OmeoLogo(size: 56, withText: false)
                          else
                            Container(
                              width: 88,
                              height: 88,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.dangerSoft,
                                shape: BoxShape.circle,
                              ),
                              child: OmeoIcon(icon!, size: 36, color: t.danger),
                            ),
                          const SizedBox(height: OmeoTokens.space6),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: text.headlineMedium?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: OmeoTokens.space2),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge?.copyWith(color: t.text2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                OmeoButton(label: actionLabel, onPressed: onAction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mise à jour exigée (426, SYS-04) : écran bloquant vers le store.
class UpgradeRequiredScreen extends StatelessWidget {
  const UpgradeRequiredScreen({required this.onUpdate, super.key});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _BlockingScreen(
      title: l.appSystemUpgradeTitle,
      body: l.appSystemUpgradeBody,
      actionLabel: l.appSystemUpgradeAction,
      onAction: onUpdate,
    );
  }
}

/// Compte suspendu (403 account_suspended) : écran dédié vers le support.
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({required this.onContact, super.key});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _BlockingScreen(
      icon: OmeoIcons.ban,
      title: l.appSystemSuspendedTitle,
      body: l.appSystemSuspendedBody,
      actionLabel: l.appSystemContactSupport,
      onAction: onContact,
    );
  }
}

/// Feuille de quota (429 quota_exceeded) : Plus en Free, date de remise à
/// zéro sinon. Le choix vient de l'API (`meta.upgrade`).
class QuotaSheet extends StatelessWidget {
  const QuotaSheet({
    required this.canUpgrade,
    this.onDiscoverPlus,
    this.resetsAt,
    super.key,
  });

  final bool canUpgrade;
  final DateTime? resetsAt;

  /// Ouvre la présentation de Plus ; le bouton est masqué sans elle.
  final VoidCallback? onDiscoverPlus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final reset = resetsAt;
    final showPlus = canUpgrade && onDiscoverPlus != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canUpgrade) Text(l.appSystemQuotaFreeBody, style: text.bodyLarge),
        if (reset != null) ...[
          if (canUpgrade) const SizedBox(height: OmeoTokens.space2),
          Text(
            l.appSystemQuotaReset(context.longDate(reset.toLocal())),
            style: text.bodyMedium?.copyWith(color: t.text2),
          ),
        ],
        const SizedBox(height: OmeoTokens.space6),
        if (showPlus) ...[
          OmeoButton(
            label: l.commonPlusDiscover,
            icon: OmeoIcons.sparkles,
            onPressed: onDiscoverPlus,
          ),
          const SizedBox(height: OmeoTokens.space2),
        ],
        OmeoButton(
          label: l.appSystemOk,
          variant: showPlus ? OmeoButtonVariant.ghost : OmeoButtonVariant.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
