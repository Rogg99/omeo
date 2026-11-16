import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/add_meal_sheet.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';

Widget _app(MockBackend backend, AddMealActions actions) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    mealsRepositoryProvider.overrideWithValue(MealsMockRepository(backend)),
  ],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OmeoTheme.light(),
    home: Scaffold(body: AddMealSheet(actions: actions)),
  ),
);

void main() {
  testWidgets('affiche le quota photo et ouvre chaque destination', (
    tester,
  ) async {
    final taps = <String>[];
    final backend = MockBackend(latency: Duration.zero);
    await tester.pumpWidget(
      _app(backend, (
        takePhoto: () => taps.add('photo'),
        pickFromGallery: () => taps.add('gallery'),
        describe: () => taps.add('describe'),
        searchCatalog: () => taps.add('catalog'),
      )),
    );
    expect(find.text('Analyses restantes…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('2 analyses restantes'), findsOneWidget);

    await tester.tap(find.text('Prendre en photo'));
    await tester.tap(find.text('Choisir dans la galerie'));
    await tester.tap(find.text('Dicter ou écrire'));
    await tester.tap(find.text('Chercher un plat'));
    expect(taps, ['photo', 'gallery', 'describe', 'catalog']);
  });

  testWidgets('en Free, la saisie vocale porte la mention Plus', (
    tester,
  ) async {
    final backend = MockBackend(
      latency: Duration.zero,
      scenario: MockScenario.free,
    );
    await tester.pumpWidget(
      _app(backend, (
        takePhoto: null,
        pickFromGallery: null,
        describe: null,
        searchCatalog: null,
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plus'), findsOneWidget);
  });

  testWidgets('quota épuisé : plus aucune analyse aujourd’hui', (
    tester,
  ) async {
    final backend = MockBackend(
      latency: Duration.zero,
      scenario: MockScenario.quotaExhausted,
    );
    await tester.pumpWidget(
      _app(backend, (
        takePhoto: null,
        pickFromGallery: null,
        describe: null,
        searchCatalog: null,
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text("Plus d'analyse aujourd'hui"), findsOneWidget);
  });
}
