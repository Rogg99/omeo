import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/quotas_controller.dart';
import 'package:omeo_api/omeo_api.dart';

/// Destinations du menu « + », fournies par le routeur. Une destination
/// absente rend l'option non interactive.
typedef AddMealActions = ({
  VoidCallback? takePhoto,
  VoidCallback? pickFromGallery,
  VoidCallback? describe,
  VoidCallback? searchCatalog,
});

/// Ouvre le menu « + » (MEA-01) au-dessus de l'écran courant.
Future<void> showAddMealSheet(
  BuildContext context, {
  required AddMealActions actions,
}) {
  final l = AppLocalizations.of(context);
  return showOmeoSheet<void>(
    context: context,
    title: l.appMealAddTitle,
    closeLabel: l.commonActionClose,
    builder: (sheetContext) {
      // Chaque choix ferme la feuille avant d'ouvrir sa destination.
      VoidCallback? close(VoidCallback? action) => action == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              action();
            };
      return AddMealSheet(
        actions: (
          takePhoto: close(actions.takePhoto),
          pickFromGallery: close(actions.pickFromGallery),
          describe: close(actions.describe),
          searchCatalog: close(actions.searchCatalog),
        ),
      );
    },
  );
}

/// Menu « + » : la photo est l'option principale, le quota est visible avant
/// d'agir (MEA-01).
class AddMealSheet extends ConsumerWidget {
  const AddMealSheet({required this.actions, super.key});

  final AddMealActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final quotas = ref.watch(quotasProvider).value;
    final photo = quotas == null
        ? null
        : quotaFor(quotas, QuotaFeatureEnum.photoAnalysis);
    final text = quotas == null
        ? null
        : quotaFor(quotas, QuotaFeatureEnum.textAnalysis);
    // Saisie vocale et texte : réservées à Plus quand l'API n'en accorde pas.
    final describeLocked = text != null && text.limit == 0;

    final photoSubtitle = switch (photo) {
      null => l.appMealAddQuotaLoading,
      Quota(remaining: null) => l.appMealAddUnlimited,
      Quota(:final remaining?) => l.appMealAnalysesLeft(remaining),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PhotoAction(
          title: l.appMealAddPhoto,
          subtitle: photoSubtitle,
          onTap: actions.takePhoto,
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoList(
          children: [
            OmeoListTile(
              icon: OmeoIcons.image,
              title: l.appMealAddGallery,
              subtitle: l.appMealAddGalleryHint,
              onTap: actions.pickFromGallery,
            ),
            OmeoListTile(
              icon: OmeoIcons.mic,
              title: l.appMealAddVoice,
              subtitle: l.appMealAddVoiceHint,
              trailing: describeLocked ? OmeoTag.plus(l.appHomePlusTag) : null,
              onTap: actions.describe,
            ),
            OmeoListTile(
              icon: OmeoIcons.search,
              title: l.appMealAddCatalog,
              subtitle: l.appMealAddCatalogHint,
              onTap: actions.searchCatalog,
            ),
          ],
        ),
      ],
    );
  }
}

/// Option principale, en carte noire.
class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: OmeoCard(
        variant: OmeoCardVariant.black,
        onTap: onTap,
        child: Row(
          children: [
            const BadgeIcon(
              OmeoIcons.camera,
              tone: OmeoTone.glass,
              size: BadgeSize.large,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(color: t.onContrast),
                  ),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: t.onContrast.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            OmeoIcon(OmeoIcons.chevR, color: t.onContrast, mirrorInRtl: true),
          ],
        ),
      ),
    );
  }
}
