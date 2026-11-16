import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/catalog_screen.dart';
import 'package:omeo/features/meals/presentation/dish_screen.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' show MealWriteResult;

Widget _app(Widget home, MockBackend backend) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    mealsRepositoryProvider.overrideWithValue(MealsMockRepository(backend)),
  ],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OmeoTheme.light(),
    home: home,
  ),
);

void main() {
  test('drapeau du code pays', () {
    expect(countryFlag('SN'), '🇸🇳');
  });

  testWidgets('catalogue : récents, favoris, recherche et filtre', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        CatalogScreen(onClose: () {}, onDish: (d) => opened.add(d.name)),
        MockBackend(latency: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Récents'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Ndolé'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'yassa');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Résultats'), findsOneWidget);
    expect(find.text('Poulet yassa'), findsOneWidget);
    await tester.tap(find.text('Yassa poisson'));
    expect(opened, ['Yassa poisson']);

    await tester.tap(find.textContaining('Togo'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun plat trouvé'), findsOneWidget);
  });

  testWidgets('fiche du plat : portion, type de repas et ajout', (
    tester,
  ) async {
    final saved = <MealWriteResult>[];
    await tester.pumpWidget(
      _app(
        DishScreen(
          dishId: ndoleId,
          navigation: (
            onClose: () {},
            onSaved: saved.add,
            openRecipe: null,
          ),
        ),
        MockBackend(latency: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ndolé'), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
    expect(find.text('1 assiette ≈ 350 g'), findsOneWidget);

    await tester.tap(find.text('Dîner'));
    await tester.pump();
    expect(find.text('Ajouter au dîner'), findsOneWidget);
    await tester.tap(find.text('Ajouter au dîner'));
    await tester.pumpAndSettle();
    expect(saved.single.meal.title, 'Ndolé');
  });
}
