import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';

/// Ouvre la feuille de quota épuisé : en Free (PLS-02), alternatives
/// gratuites et Plus en option ; en Plus (PLS-03), date de remise à zéro,
/// sans proposition d'achat.
Future<void> showQuotaExhaustedSheet(
  BuildContext context, {
  required bool canUpgrade,
  required VoidCallback? onDiscoverPlus,
  required VoidCallback? onSearchCatalog,
  DateTime? resetsAt,
}) {
  final l = AppLocalizations.of(context);
  return showOmeoSheet<void>(
    context: context,
    title: canUpgrade ? l.appPlusQuotaFreeTitle : l.appPlusQuotaPlusTitle,
    closeLabel: l.commonActionClose,
    builder: (sheetContext) {
      VoidCallback? close(VoidCallback? action) => action == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              action();
            };
      return QuotaExhaustedSheet(
        canUpgrade: canUpgrade,
        resetsAt: resetsAt,
        onDiscoverPlus: close(onDiscoverPlus),
        onSearchCatalog: close(onSearchCatalog),
        onDismiss: () => Navigator.of(sheetContext).pop(),
      );
    },
  );
}

/// Contenu de la feuille de quota épuisé.
class QuotaExhaustedSheet extends StatelessWidget {
  const QuotaExhaustedSheet({
    required this.canUpgrade,
    required this.onDismiss,
    super.key,
    this.resetsAt,
    this.onDiscoverPlus,
    this.onSearchCatalog,
  });

  /// Free : l'API indique qu'il faut proposer Plus.
  final bool canUpgrade;
  final DateTime? resetsAt;
  final VoidCallback? onDiscoverPlus;
  final VoidCallback? onSearchCatalog;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final reset = resetsAt?.toLocal();

    final String body;
    if (canUpgrade) {
      body = reset == null
          ? l.appPlusQuotaFreeBodyNoDate
          : l.appPlusQuotaFreeBody(
              material.formatTimeOfDay(TimeOfDay.fromDateTime(reset)),
            );
    } else {
      body = reset == null
          ? l.appPlusQuotaPlusBodyNoDate
          : l.appPlusQuotaPlusBody(material.formatFullDate(reset));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canUpgrade) ...[
          const Center(
            child: BadgeIcon(
              OmeoIcons.hourglass,
              tone: OmeoTone.neutral,
              size: BadgeSize.large,
              round: true,
            ),
          ),
          const SizedBox(height: OmeoTokens.space3),
        ],
        Text(
          body,
          textAlign: canUpgrade ? TextAlign.start : TextAlign.center,
          style: text.bodyMedium?.copyWith(color: t.text2),
        ),
        if (canUpgrade && onDiscoverPlus != null) ...[
          const SizedBox(height: OmeoTokens.space4),
          OmeoCard(
            variant: OmeoCardVariant.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BadgeIcon(OmeoIcons.crown, tone: OmeoTone.glass),
                    const SizedBox(width: OmeoTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.appPlusQuotaPlusCard,
                            style: text.titleSmall?.copyWith(
                              color: t.onContrast,
                            ),
                          ),
                          Text(
                            l.appPlusQuotaPlusCardBody,
                            style: text.labelSmall?.copyWith(
                              color: t.onContrast.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OmeoTokens.space3),
                OmeoButton(
                  label: l.appPlusQuotaTryPlus,
                  variant: OmeoButtonVariant.white,
                  size: OmeoButtonSize.medium,
                  onPressed: onDiscoverPlus,
                ),
              ],
            ),
          ),
        ],
        if (onSearchCatalog != null) ...[
          const SizedBox(height: 20),
          Eyebrow(l.appPlusQuotaMeanwhile),
          const SizedBox(height: OmeoTokens.space2),
          OmeoList(
            children: [
              OmeoListTile(
                icon: OmeoIcons.search,
                title: l.appPlusQuotaCatalog,
                subtitle: l.appPlusQuotaCatalogHint,
                onTap: onSearchCatalog,
              ),
            ],
          ),
        ],
        if (!canUpgrade) ...[
          const SizedBox(height: OmeoTokens.space4),
          OmeoButton(label: l.appPlusQuotaOk, onPressed: onDismiss),
        ],
      ],
    );
  }
}
