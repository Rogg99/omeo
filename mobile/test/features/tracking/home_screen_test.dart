import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo/features/tracking/presentation/home_screen.dart';
import 'package:omeo/mock/fixtures/home_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/home_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

import '../../helpers/pump_app.dart';

class _StubRepository implements HomeRepository {
  _StubRepository(this.answer);

  final Future<Home> Function(DateTime? date) answer;
  final requested = <DateTime?>[];

  @override
  Future<Home> getHome({DateTime? date}) {
    requested.add(date);
    return answer(date);
  }
}

final _taps = <String>[];

final HomeNavigation _navigation = (
  openHelp: () => _taps.add('help'),
  openNotifications: () => _taps.add('notifications'),
  quickAction: (a) => _taps.add('quick:${a.kind.value}'),
  openJournal: (d) => _taps.add('journal'),
  openShortcut: (s) => _taps.add('shortcut:${s.value}'),
  openProgram: () => _taps.add('program'),
  openChallenge: (c) => _taps.add('challenge'),
  openRewards: () => _taps.add('rewards'),
);

Widget _app(
  HomeRepository repository, {
  DisplayVariant variant = DisplayVariant.light,
}) {
  final arabic = variant == DisplayVariant.arabic;
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(arabic ? 'ar' : 'fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: variant == DisplayVariant.dark
          ? OmeoTheme.dark()
          : OmeoTheme.light(arabic: arabic),
      home: MediaQuery(
        // Les tests figent les animations infinies (squelettes).
        data: const MediaQueryData(
          size: Size(390, 2400),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: HomeScreen(navigation: _navigation, unreadNotifications: 3),
        ),
      ),
    ),
  );
}

/// Nombre signé tel que l'affiche l'app (isolé en gauche à droite).
String _signed(String sign, String digits) =>
    '${String.fromCharCode(0x2066)}$sign$digits${String.fromCharCode(0x2069)}';

/// Écran de téléphone assez haut pour afficher tout l'accueil.
void _tallView(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(_taps.clear);

  testWidgets('journée en cours : valeurs de l’API affichées telles quelles', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(
      _app(_StubRepository((_) async => homeFixture(HomeVariant.current))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Awa'), findsOneWidget);
    expect(find.text('890'), findsOneWidget);
    expect(find.text('84/128 g'), findsOneWidget);
    expect(find.text(_signed('−', '1 160')), findsOneWidget);
    expect(find.text('Mincir sans frustration'), findsOneWidget);
    expect(find.bySemanticsLabel('890 kcal restantes'), findsOneWidget);
    expect(find.text('2 analyses restantes'), findsOneWidget);
    expect(find.text('1 450 kcal'), findsOneWidget);
  });

  testWidgets('actions rapides et en-tête renvoient vers la navigation', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(
      _app(_StubRepository((_) async => homeFixture(HomeVariant.current))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Photo du plat'));
    await tester.tap(find.bySemanticsLabel('Notifications, 3 non lues'));
    await tester.tap(find.bySemanticsLabel('Recettes'));
    expect(_taps, ['quick:photo', 'notifications', 'shortcut:recipes']);
  });

  testWidgets('chargement : squelette, puis contenu', (tester) async {
    _tallView(tester);
    _tallView(tester);
    final completer = Completer<Home>();
    await tester.pumpWidget(_app(_StubRepository((_) => completer.future)));
    await tester.pump();
    expect(find.text('Bonjour, Awa'), findsNothing);
    completer.complete(homeFixture(HomeVariant.current));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour, Awa'), findsOneWidget);
  });

  testWidgets('erreur : message selon le code et nouvel essai', (
    tester,
  ) async {
    _tallView(tester);
    var calls = 0;
    await tester.pumpWidget(
      _app(
        _StubRepository((_) async {
          calls++;
          if (calls == 1) throw const NetworkFailure();
          return homeFixture(HomeVariant.current);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Impossible de charger ta journée.'), findsOneWidget);
    expect(
      find.text(
        'Pas de connexion. Tes données seront envoyées au retour du réseau.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour, Awa'), findsOneWidget);
  });

  testWidgets('premier jour : invitation à la première photo', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      _app(_StubRepository((_) async => homeFixture(HomeVariant.firstDay))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Photographie ton prochain repas'), findsOneWidget);
    await tester.tap(find.text('Prendre une photo'));
    expect(_taps, ['quick:photo']);
  });

  testWidgets('dépassement : kcal consommées et message bienveillant', (
    tester,
  ) async {
    _tallView(tester);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(
      _app(
        _StubRepository(
          (_) async => homeFixture(HomeVariant.over, date: yesterday),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('kcal consommées'), findsOneWidget);
    expect(find.textContaining('Ça arrive !'), findsOneWidget);
  });

  testWidgets(
    'jour passé : sélection dans le bandeau et lien vers le journal',
    (
      tester,
    ) async {
      // Mercredi 11 novembre 2026 : lundi et mardi sont passés.
      final today = DateTime(2026, 11, 11);
      final repo = _StubRepository(
        (date) async => homeFixture(
          date == null ? HomeVariant.current : HomeVariant.past,
          date: date,
          today: today,
        ),
      );
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(repo.requested.last, DateTime(2026, 11, 9));
      expect(find.text('Photo du plat'), findsNothing);
      await tester.tap(find.text('Voir le journal de ce jour'));
      expect(_taps, ['journal']);
    },
  );

  test('mock : variante selon le scénario et le jour', () async {
    final backend = MockBackend(latency: Duration.zero);
    final repo = HomeMockRepository(backend);
    expect((await repo.getHome()).day.mealsCount, 3);

    backend.setScenario(MockScenario.firstLaunch);
    expect((await repo.getHome()).day.mealsCount, 0);

    backend.setScenario(MockScenario.error500);
    await expectLater(
      repo.getHome(),
      throwsA(
        isA<ProblemFailure>().having((f) => f.code, 'code', 'server_error'),
      ),
    );

    backend
      ..setScenario(MockScenario.trial)
      ..setNetworkDown(down: true);
    await expectLater(repo.getHome(), throwsA(isA<NetworkFailure>()));
  });

  for (final variant in DisplayVariant.values) {
    // goldenTest enregistre le test ; son Future n'a pas à être attendu.
    // ignore: discarded_futures
    goldenTest(
      'accueil HOM-01 (${variant.name})',
      fileName: 'home_${variant.name}',
      constraints: const BoxConstraints.tightFor(width: 390, height: 2400),
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pumpAndSettle();
      },
      builder: () => _app(
        _StubRepository(
          (_) async => homeFixture(
            HomeVariant.current,
            today: DateTime(2026, 11, 9),
          ),
        ),
        variant: variant,
      ),
    );
  }
}
