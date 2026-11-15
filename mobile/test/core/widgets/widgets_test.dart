import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OmeoButton', () {
    testWidgets('déclenche onPressed et expose un bouton accessible', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpOmeo(
        OmeoButton(label: 'Continuer', onPressed: () => taps++),
      );
      await tester.tap(find.text('Continuer'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(OmeoButton)),
        matchesSemantics(
          label: 'Continuer',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('désactivé : aucun appui pris en compte', (tester) async {
      await tester.pumpOmeo(
        const OmeoButton(label: 'Envoyer', onPressed: null),
      );
      final ink = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(OmeoButton),
          matching: find.byType(InkWell),
        ),
      );
      expect(ink.onTap, isNull);
    });

    testWidgets('cible tactile d’au moins 48 dp', (tester) async {
      await tester.pumpOmeo(
        OmeoButton(
          label: 'Petit',
          size: OmeoButtonSize.small,
          expand: false,
          onPressed: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(42),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('OmeoIconButton', () {
    testWidgets('libellé lu et compteur plafonné à 99+', (tester) async {
      await tester.pumpOmeo(
        OmeoIconButton(
          icon: OmeoIcons.bell,
          semanticLabel: 'Notifications, 120 non lues',
          badgeCount: 120,
          onPressed: () {},
        ),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Notifications, 120 non lues'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('pas de pastille sans non lues', (tester) async {
      await tester.pumpOmeo(
        OmeoIconButton(
          icon: OmeoIcons.bell,
          semanticLabel: 'Notifications',
          badgeCount: 0,
          onPressed: () {},
        ),
      );
      expect(find.text('0'), findsNothing);
    });
  });

  group('OmeoIcon', () {
    testWidgets('retournée en arabe seulement si directionnelle', (
      tester,
    ) async {
      await tester.pumpOmeo(
        const Row(
          children: [
            OmeoIcon(OmeoIcons.chevR, mirrorInRtl: true),
            OmeoIcon(OmeoIcons.home),
          ],
        ),
        variant: DisplayVariant.arabic,
      );
      Finder flipIn(Finder icon) =>
          find.descendant(of: icon, matching: find.byType(Transform));
      expect(flipIn(find.byType(OmeoIcon).first), findsOneWidget);
      expect(flipIn(find.byType(OmeoIcon).last), findsNothing);
    });
  });

  group('OmeoRing', () {
    testWidgets('lit la valeur en texte et borne la progression', (
      tester,
    ) async {
      await tester.pumpOmeo(
        const OmeoRing(progress: 1.4, semanticLabel: '180 kcal en plus'),
      );
      expect(find.bySemanticsLabel('180 kcal en plus'), findsOneWidget);
    });
  });

  group('OmeoTabBar', () {
    const tabs = <OmeoTab>[
      (icon: OmeoIcons.home, label: 'Accueil', enabled: true),
      (icon: OmeoIcons.chart, label: 'Progression', enabled: true),
      (icon: OmeoIcons.calendar, label: 'Journal', enabled: true),
      (icon: OmeoIcons.user, label: 'Profil', enabled: true),
    ];

    testWidgets('sélection et action centrale', (tester) async {
      int? selected;
      var fab = 0;
      await tester.pumpOmeo(
        Align(
          alignment: Alignment.bottomCenter,
          child: OmeoTabBar(
            tabs: tabs,
            currentIndex: 0,
            onSelect: (i) => selected = i,
            fabLabel: 'Ajouter un repas',
            onFab: () => fab++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Journal'));
      await tester.tap(find.bySemanticsLabel('Ajouter un repas'));
      expect(selected, 2);
      expect(fab, 1);
    });

    testWidgets('texte à 200 % sans débordement sur 320 dp', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpOmeo(
        Align(
          alignment: Alignment.bottomCenter,
          child: OmeoTabBar(
            tabs: tabs,
            currentIndex: 1,
            onSelect: (_) {},
            fabLabel: 'Ajouter un repas',
            onFab: () {},
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DayStrip', () {
    testWidgets('les jours futurs ne sont pas sélectionnables', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpOmeo(
        DayStrip(
          selectedIndex: 0,
          onSelect: taps.add,
          days: [
            for (var i = 0; i < 7; i++)
              (
                shortName: 'J$i',
                number: '${9 + i}',
                semanticLabel: 'Jour $i',
                hasEntries: i == 0,
                isFuture: i > 1,
              ),
          ],
        ),
      );
      await tester.tap(find.bySemanticsLabel('Jour 1'));
      await tester.tap(find.bySemanticsLabel('Jour 4'), warnIfMissed: false);
      expect(taps, [1]);
    });
  });

  group('Skeleton', () {
    testWidgets('immobile si les mouvements sont réduits', (tester) async {
      await tester.pumpOmeo(
        const Skeleton(width: 120),
        reduceMotion: true,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('OmeoSegmented', () {
    testWidgets('change de segment', (tester) async {
      String? value;
      await tester.pumpOmeo(
        OmeoSegmented<String>(
          segments: const [
            (value: 'w', label: 'Semaine'),
            (value: 'm', label: 'Mois'),
          ],
          selected: 'w',
          onChanged: (v) => value = v,
        ),
      );
      await tester.tap(find.text('Mois'));
      expect(value, 'm');
    });
  });
}
