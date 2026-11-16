import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/analysis_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' show Analysis;

final _events = <String>[];

Widget _app(MockBackend backend, AnalysisRequest request) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    mealsRepositoryProvider.overrideWithValue(MealsMockRepository(backend)),
  ],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OmeoTheme.light(),
    home: AnalysisScreen(
      request: request,
      navigation: (
        onSucceeded: (Analysis a) => _events.add('ok:${a.dish?.name}'),
        onClose: () => _events.add('close'),
        onRetake: () => _events.add('retake'),
        onSearchCatalog: () => _events.add('catalog'),
      ),
    ),
  ),
);

MockBackend _plus() => MockBackend(
  latency: const Duration(milliseconds: 10),
  scenario: MockScenario.plus,
)..analysisLatency = const Duration(milliseconds: 40);

void main() {
  setUp(_events.clear);

  testWidgets("affiche les étapes puis transmet l'analyse réussie", (
    tester,
  ) async {
    await tester.pumpWidget(_app(_plus(), const TextRequest('thiéboudienne')));
    await tester.pump();
    expect(find.text('On regarde ton assiette…'), findsOneWidget);
    expect(find.text('Calcul des apports'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(_events, ['ok:Thiéboudienne']);
  });

  testWidgets('photo inexploitable : conseils et reprise', (tester) async {
    await tester.pumpWidget(_app(_plus(), const TextRequest('flou')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text("On n'a pas reconnu de plat"), findsOneWidget);
    await tester.tap(find.text('Reprendre la photo'));
    await tester.tap(find.text('Chercher dans le catalogue'));
    expect(_events, ['retake', 'catalog']);
  });

  testWidgets("fermer annule l'analyse", (tester) async {
    await tester.pumpWidget(_app(_plus(), const TextRequest('ndolé')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Fermer'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(_events, ['close']);
  });

  testWidgets('Free : erreur selon le code, avec Réessayer', (tester) async {
    final backend = MockBackend(
      latency: Duration.zero,
      scenario: MockScenario.free,
    );
    await tester.pumpWidget(_app(backend, const TextRequest('ndolé')));
    await tester.pumpAndSettle();
    expect(find.text("L'analyse n'a pas abouti"), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
