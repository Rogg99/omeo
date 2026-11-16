import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/onboarding/presentation/account_step.dart';
import 'package:omeo/features/onboarding/presentation/plan_screens.dart';
import 'package:omeo/features/onboarding/presentation/question_steps.dart';
import 'package:omeo/mock/fixtures/auth_fixtures.dart';
import 'package:omeo_api/omeo_api.dart';

import '../auth/auth_test_app.dart';

void main() {
  testWidgets('étape 1 : bouton désactivé tant que le nom manque', (
    tester,
  ) async {
    var next = 0;
    final container = await pumpWithMocks(
      tester,
      QuestionStepScreen(step: 1, onNext: () => next++, onBack: () {}),
    );
    await tester.tap(find.text('Continuer'));
    expect(next, 0);
    await tester.enterText(find.byType(TextField).at(0), 'Awa');
    await tester.enterText(find.byType(TextField).at(1), 'Diallo');
    await tester.pumpAndSettle();
    expect(find.text('3/40'), findsOne);
    await tester.tap(find.text('Continuer'));
    expect(next, 1);
    expect(container.read(onboardingProvider).value!.step, 2);
  });

  testWidgets('étape 7 : cible au-dessus du poids actuel (ONB-11)', (
    tester,
  ) async {
    final container = await pumpWithMocks(
      tester,
      QuestionStepScreen(step: 7, onNext: () {}, onBack: () {}),
    );
    await container
        .read(onboardingProvider.notifier)
        .answer((d) => d.copyWith(weightKg: 80.5));
    await tester.enterText(find.byType(TextField), '90');
    await tester.pumpAndSettle();
    expect(find.textContaining('vérifie ce chiffre'), findsOne);
    await tester.enterText(find.byType(TextField), '74');
    await tester.pumpAndSettle();
    expect(find.textContaining('vérifie ce chiffre'), findsNothing);
    expect(find.textContaining("par rapport à aujourd'hui"), findsOne);
  });

  testWidgets('étape 8 : objectif incompatible expliqué (ONB-12)', (
    tester,
  ) async {
    final container = await pumpWithMocks(
      tester,
      QuestionStepScreen(step: 8, onNext: () {}, onBack: () {}),
    );
    await tester.tap(find.text('Perdre du poids'));
    await tester.pumpAndSettle();
    expect(find.text('Incompatible avec « Perdre du poids »'), findsOne);
    expect(find.text('Continuer · 1 choisi'), findsOne);
    expect(container.read(onboardingProvider).value!.goals, {Goal.loseWeight});
  });

  group('création du compte (ONB-13, ONB-14)', () {
    Widget account() => AccountStepScreen(
      onBack: () {},
      onSubmitted: () {},
      onOpenLegal: (_) {},
    );

    testWidgets('code valide : jours offerts', (tester) async {
      await pumpWithMocks(tester, account());
      await tester.enterText(find.byType(TextField).first, demoInviteCode);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('7 jours offerts'), findsOne);
    });

    testWidgets('code inconnu : non bloquant, essai par défaut', (
      tester,
    ) async {
      await pumpWithMocks(tester, account());
      await tester.enterText(find.byType(TextField).first, 'AWA20');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.textContaining('ton essai sera de 3 jours'), findsOne);
    });

    testWidgets('bouton actif avec email, mot de passe et consentements', (
      tester,
    ) async {
      await pumpWithMocks(tester, account());
      Finder create() => find.text('Créer mon compte');
      await tester.enterText(find.byType(TextField).at(1), 'fatou@exemple.com');
      await tester.enterText(find.byType(TextField).at(2), 'Omeo2026!x');
      await tester.pump();
      // Consentements pas encore cochés : rien ne se passe.
      await tester.tap(create());
      await tester.pump();
      expect(find.text('Obligatoire'), findsNWidgets(2));
      await tester.tap(find.text('Obligatoire').first);
      await tester.tap(find.text('Obligatoire').last);
      await tester.pump();
      expect(find.text('Facultatif'), findsOne);
    });
  });

  testWidgets('plan prêt (ONB-16) : objectifs de l’API', (tester) async {
    final container = await pumpWithMocks(
      tester,
      PlanReadyScreen(onStart: () {}),
    );
    await container
        .read(sessionProvider.notifier)
        .signIn(authResult(meFixture()));
    await tester.pumpAndSettle();
    expect(find.text('Awa, voici ton plan quotidien'), findsOne);
    expect(find.textContaining('2'), findsWidgets);
    expect(find.text('260 cl'), findsOne);
    expect(find.text('74 kg'), findsOne);
  });
}
