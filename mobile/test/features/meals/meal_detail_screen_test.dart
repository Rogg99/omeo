import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/application/meal_controller.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/meal_detail_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

const String _id = MealsMockRepository.demoMealId;

Future<ProviderContainer> _pump(
  WidgetTester tester,
  MealsMockRepository repo, {
  VoidCallback? onBack,
}) async {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [mealsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: MealDetailScreen(mealId: _id, onBack: onBack ?? () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('apports, ingrédients et actions', (tester) async {
    await _pump(
      tester,
      MealsMockRepository(MockBackend(latency: Duration.zero)),
    );
    expect(find.text('Alloco & poisson braisé'), findsOneWidget);
    expect(find.text('810'), findsOneWidget);
    expect(find.text('Banane plantain frite'), findsOneWidget);
    expect(find.text('Déplacer'), findsOneWidget);
    // Sans écran de correction fourni, « Modifier » est masqué.
    expect(find.text('Modifier'), findsNothing);
  });

  testWidgets('déplacer vers le dîner', (tester) async {
    final repo = MealsMockRepository(MockBackend(latency: Duration.zero));
    await _pump(tester, repo);
    await tester.tap(find.text('Déplacer'));
    await tester.pumpAndSettle();
    expect(find.text('Déplacer le repas'), findsOneWidget);
    await tester.tap(find.text('Dîner'));
    await tester.pump();
    await tester.tap(find.textContaining('Déplacer vers dîner'));
    await tester.pumpAndSettle();
    expect(find.text('Repas déplacé'), findsOneWidget);
    expect((await repo.getMeal(_id)).mealType, MealType.dinner);
  });

  testWidgets('supprimer puis annuler : le repas reste', (tester) async {
    var back = 0;
    final repo = MealsMockRepository(MockBackend(latency: Duration.zero));
    final container = await _pump(tester, repo, onBack: () => back++);
    await tester.tap(find.text('Supprimer').first);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce repas ?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Supprimer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(back, 1);
    expect(container.read(pendingMealDeletionsProvider), {_id});
    await tester.tap(find.text('Annuler'));
    await tester.pump(undoDelay + const Duration(seconds: 1));
    expect(container.read(pendingMealDeletionsProvider), isEmpty);
    expect((await repo.getMeal(_id)).id, _id);
  });

  testWidgets('sans annulation, la suppression part après le délai', (
    tester,
  ) async {
    final repo = MealsMockRepository(MockBackend(latency: Duration.zero));
    final container = await _pump(tester, repo);
    container
        .read(pendingMealDeletionsProvider.notifier)
        .schedule(
          'inconnu',
        );
    expect(container.read(pendingMealDeletionsProvider), {'inconnu'});
    await tester.pump(undoDelay);
    await tester.pump();
    expect(container.read(pendingMealDeletionsProvider), isEmpty);
  });
}
