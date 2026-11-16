import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/presentation/meal_saved_screen.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

/// Seul l'envoi d'avis est appelé par cet écran.
class _Spy implements MealsRepository {
  final sent = <FeedbackInput>[];

  @override
  Future<void> sendFeedback({
    required String analysisId,
    required FeedbackInput feedback,
  }) async => sent.add(feedback);

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

MealWriteResult _result({String? analysisId}) => mealWriteFixture(
  mealId: 'm1',
  title: 'Thiéboudienne',
  now: DateTime(2026, 11, 9, 12, 40),
  input: MealInput(
    source_: analysisId == null
        ? MealInputSource_Enum.dish
        : MealInputSource_Enum.photo,
    mealType: MealType.lunch,
    analysisId: analysisId,
  ),
);

Widget _app(_Spy spy, MealWriteResult result, VoidCallback onDone) =>
    ProviderScope(
      overrides: [mealsRepositoryProvider.overrideWithValue(spy)],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: MealSavedScreen(result: result, onDone: onDone, corrections: 2),
      ),
    );

void main() {
  testWidgets('reste du jour, points et Terminé', (tester) async {
    var done = 0;
    await tester.pumpWidget(_app(_Spy(), _result(), () => done++));
    expect(find.text('Déjeuner enregistré'), findsOneWidget);
    expect(find.textContaining('890'), findsOneWidget);
    expect(find.text('+10 points'), findsOneWidget);
    // Sans analyse, pas de demande d'avis.
    expect(find.text("L'analyse était-elle juste ?"), findsNothing);
    await tester.tap(find.text('Terminé'));
    expect(done, 1);
  });

  testWidgets('avis positif en un geste', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(_app(spy, _result(analysisId: 'a1'), () {}));
    await tester.tap(find.text('Oui'));
    await tester.pumpAndSettle();
    expect(spy.sent.single.rating, FeedbackInputRatingEnum.up);
    expect(find.text("L'analyse était-elle juste ?"), findsNothing);
  });

  testWidgets('avis négatif : motif obligatoire, corrections jointes', (
    tester,
  ) async {
    final spy = _Spy();
    await tester.pumpWidget(_app(spy, _result(analysisId: 'a1'), () {}));
    await tester.tap(find.text('Non'));
    await tester.pumpAndSettle();
    expect(find.text("Qu'est-ce qui n'allait pas ?"), findsOneWidget);
    expect(
      find.text("Tes 2 corrections seront jointes à l'avis."),
      findsOneWidget,
    );
    await tester.tap(find.text('Quantités fausses'));
    await tester.enterText(
      find.byType(TextField),
      'Portion de riz plus petite',
    );
    await tester.pump();
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    final sent = spy.sent.single;
    expect(sent.rating, FeedbackInputRatingEnum.down);
    expect(sent.reason, FeedbackReason.wrongQuantities);
    expect(sent.comment, 'Portion de riz plus petite');
  });
}
