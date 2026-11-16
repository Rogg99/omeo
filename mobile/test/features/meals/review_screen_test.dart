import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/application/review_controller.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/review_screen.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

Analysis _analysis({bool low = false}) => analysisFixture(
  id: 'a1',
  status: 'succeeded',
  createdAt: DateTime(2026, 11, 9, 12, 40),
  lowConfidence: low,
);

final _events = <String>[];

Future<MealsMockRepository> _pump(
  WidgetTester tester,
  Analysis analysis, {
  String? pickedDish,
}) async {
  final backend = MockBackend(latency: Duration.zero);
  final repo = MealsMockRepository(backend);
  // L'analyse doit exister côté mock pour « Pas satisfait ? ».
  await repo.createPhotoAnalysis(uploadId: 'u', idempotencyKey: 'k');
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        mealsRepositoryProvider.overrideWithValue(repo),
        offlineStoreProvider.overrideWithValue(MemoryOfflineStore()),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: ReviewScreen(
          analysis: analysis,
          navigation: (
            onClose: () => _events.add('close'),
            onSaved: (r, c) => _events.add('saved:$c'),
            onQueued: () => _events.add('queued'),
            pickDish: () async => pickedDish,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(_events.clear);

  testWidgets(
    'confiance élevée : apports de l’API, « Pas satisfait ? » replié',
    (
      tester,
    ) async {
      await _pump(tester, _analysis());
      expect(find.text('Thiéboudienne'), findsOneWidget);
      expect(find.text('Confiance élevée'), findsOneWidget);
      expect(find.text('640'), findsOneWidget);
      expect(find.text('Enregistrer · 640 kcal'), findsOneWidget);
      expect(find.text('On a aussi pensé à 3 autres plats.'), findsOneWidget);
      expect(find.text('Yassa poisson'), findsNothing);
    },
  );

  testWidgets(
    'confiance faible : bannière, à vérifier, alternatives dépliées',
    (
      tester,
    ) async {
      await _pump(tester, _analysis(low: true));
      expect(find.text('Confiance moyenne'), findsOneWidget);
      expect(find.textContaining("On n'est pas sûrs de tout"), findsOneWidget);
      expect(find.text('À vérifier'), findsNWidgets(2));
      expect(find.text('Yassa poisson'), findsOneWidget);
      expect(find.text('22 %'), findsOneWidget);
    },
  );

  testWidgets('une correction met les totaux en cours de calcul', (
    tester,
  ) async {
    await _pump(tester, _analysis());
    await tester.tap(find.bySemanticsLabel('Plus de Riz brisé'));
    await tester.pump();
    expect(find.text('190 g'), findsOneWidget);
    expect(find.text('En cours de calcul'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(_events, ['saved:1']);
  });

  testWidgets('choisir une alternative remplace le plat', (tester) async {
    await _pump(tester, _analysis(low: true));
    await tester.tap(find.text('Yassa poisson'));
    await tester.pumpAndSettle();
    expect(find.text("C'est noté, merci ! 💛"), findsOneWidget);
  });

  test('le contrôleur envoie les quantités corrigées', () async {
    final backend = MockBackend(latency: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        mealsRepositoryProvider.overrideWithValue(
          MealsMockRepository(backend),
        ),
        offlineStoreProvider.overrideWithValue(MemoryOfflineStore()),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    addTearDown(container.dispose);
    final provider = reviewControllerProvider(_analysis());
    final sub = container.listen(provider, (_, _) {});
    container.read(provider.notifier)
      ..toggle(5)
      ..step(0, up: false);
    expect(sub.read().corrections, 2);
    expect(sub.read().items[0].grams, 170);
    expect(sub.read().totalsPending, isTrue);
  });
}
