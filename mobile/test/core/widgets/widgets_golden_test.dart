import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

/// Galerie des composants (reprend les états des maquettes) en clair, en
/// sombre et en arabe.
void main() {
  for (final variant in DisplayVariant.values) {
    // goldenTest enregistre le test ; son Future n'a pas à être attendu.
    // ignore: discarded_futures
    goldenTest(
      'composants (${variant.name})',
      fileName: 'widgets_${variant.name}',
      constraints: const BoxConstraints(maxWidth: 390),
      builder: () => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: const BoxConstraints(maxWidth: 390),
        children: [
          GoldenTestScenario(
            name: 'nutrition',
            child: themedForGolden(const _NutritionCard(), variant: variant),
          ),
          GoldenTestScenario(
            name: 'navigation',
            child: themedForGolden(const _Navigation(), variant: variant),
          ),
          GoldenTestScenario(
            name: 'listes et boutons',
            child: themedForGolden(const _ListsAndButtons(), variant: variant),
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OmeoCard(
        child: Row(
          children: [
            OmeoRing(
              progress: 0.62,
              semanticLabel: '890 kcal restantes',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '890',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontSize: 32),
                  ),
                  Text(
                    'kcal restantes',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  MacroRow(
                    label: 'Protéines',
                    valueText: '84/128 g',
                    progress: 0.66,
                    color: t.dataProtein,
                  ),
                  const SizedBox(height: 14),
                  MacroRow(
                    label: 'Glucides',
                    valueText: '180/270 g',
                    progress: 0.67,
                    color: t.dataCarbs,
                  ),
                  const SizedBox(height: 14),
                  MacroRow(
                    label: 'Lipides',
                    valueText: '42/72 g',
                    progress: 0.58,
                    color: t.dataFat,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OmeoAppBar(
          helpLabel: 'Aide et contact',
          notificationsLabel: 'Notifications, 3 non lues',
          unreadCount: 3,
          onHelp: () {},
          onNotifications: () {},
        ),
        const OmeoTopBar(
          title: 'Mon assiette',
          eyebrow: 'Déjeuner',
          backLabel: 'Retour',
        ),
        DayStrip(
          selectedIndex: 0,
          onSelect: (_) {},
          days: [
            for (final (i, n) in [
              'Lun',
              'Mar',
              'Mer',
              'Jeu',
              'Ven',
              'Sam',
              'Dim',
            ].indexed)
              (
                shortName: n,
                number: '${9 + i}',
                semanticLabel: n,
                hasEntries: i == 0,
                isFuture: i > 0,
              ),
          ],
        ),
        const SizedBox(height: 40),
        OmeoTabBar(
          tabs: const [
            (icon: OmeoIcons.home, label: 'Accueil', enabled: true),
            (icon: OmeoIcons.chart, label: 'Progression', enabled: true),
            (icon: OmeoIcons.calendar, label: 'Journal', enabled: true),
            (icon: OmeoIcons.user, label: 'Profil', enabled: true),
          ],
          currentIndex: 0,
          onSelect: (_) {},
          fabLabel: 'Ajouter un repas',
          onFab: () {},
        ),
      ],
    );
  }
}

class _ListsAndButtons extends StatelessWidget {
  const _ListsAndButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OmeoTag('Aujourd’hui'),
              OmeoTag(
                '+180 kcal',
                tone: OmeoTone.accent,
                icon: OmeoIcons.flame,
              ),
              OmeoTag.plus('Plus'),
              BadgeIcon(
                OmeoIcons.drop,
                tone: OmeoTone.info,
                size: BadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: OmeoTokens.space4),
          const OmeoBanner(
            icon: OmeoIcons.wifiOff,
            child: Text(
              'Hors connexion. Tes repas seront envoyés au retour du réseau.',
            ),
          ),
          const SizedBox(height: OmeoTokens.space4),
          OmeoList(
            children: [
              OmeoListTile(
                title: 'Notifications',
                subtitle: 'Rappels de repas et d’eau',
                icon: OmeoIcons.bell,
                onTap: () {},
              ),
              OmeoListTile(
                title: 'Supprimer mon compte',
                icon: OmeoIcons.trash,
                danger: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: OmeoTokens.space4),
          OmeoButton(
            label: 'Prendre une photo',
            icon: OmeoIcons.camera,
            onPressed: () {},
          ),
          const SizedBox(height: OmeoTokens.space3),
          OmeoButton(
            label: 'Voir le journal',
            variant: OmeoButtonVariant.outline,
            trailingIcon: OmeoIcons.arrowR,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
