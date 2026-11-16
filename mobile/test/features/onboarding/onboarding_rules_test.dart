import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/units/units.dart';
import 'package:omeo/features/auth/data/local_store.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/onboarding/application/target_weight.dart';
import 'package:omeo/features/onboarding/data/onboarding_draft.dart';
import 'package:omeo_api/omeo_api.dart';

final _complete = OnboardingDraft(
  firstName: 'Awa',
  lastName: 'Diallo',
  birthDate: DateTime(1996, 4, 14),
  sex: Sex.female,
  cityLabel: 'Yaoundé',
  heightCm: 168,
  weightKg: 80.5,
  targetWeightKg: 74,
  goals: const {Goal.loseWeight},
);

void main() {
  group('avertissement poids cible (D22)', () {
    test('rien sans les deux valeurs', () {
      expect(targetWeightAdvice(current: null, target: 70), isNull);
      expect(targetWeightAdvice(current: 70, target: null), isNull);
    });

    test('cible plus basse : écart négatif, pas d’alerte', () {
      final a = targetWeightAdvice(current: 80.5, target: 74)!;
      expect(a.difference, -6.5);
      expect(a.aboveCurrent, isFalse);
    });

    test('cible plus haute : alerte non bloquante', () {
      final a = targetWeightAdvice(current: 80.5, target: 90)!;
      expect(a.difference, 9.5);
      expect(a.aboveCurrent, isTrue);
    });

    test('arrondi au dixième', () {
      expect(targetWeightAdvice(current: 80.04, target: 80)!.difference, 0);
    });
  });

  group('brouillon', () {
    test('chaque étape exige sa réponse', () {
      const empty = OnboardingDraft();
      for (var n = 1; n <= onboardingQuestionSteps; n++) {
        expect(empty.isStepComplete(n), isFalse, reason: 'étape $n');
        expect(_complete.isStepComplete(n), isTrue, reason: 'étape $n');
      }
      expect(_complete.isComplete, isTrue);
    });

    test('nom : prénom et nom non vides', () {
      expect(
        const OnboardingDraft(
          firstName: 'Awa',
          lastName: ' ',
        ).isStepComplete(1),
        isFalse,
      );
    });

    test('bornes de taille et de poids', () {
      expect(_complete.copyWith(heightCm: 99).isStepComplete(5), isFalse);
      expect(_complete.copyWith(heightCm: 250).isStepComplete(5), isTrue);
      expect(_complete.copyWith(weightKg: 29.9).isStepComplete(6), isFalse);
      expect(
        _complete.copyWith(targetWeightKg: 301).isStepComplete(7),
        isFalse,
      );
    });

    test('JSON aller-retour, unités comprises', () {
      final draft = _complete.copyWith(
        weightUnit: UnitSystem.imperial,
        step: 7,
        city: (id: 'c1', label: 'Yaoundé', country: 'CM'),
      );
      expect(OnboardingDraft.fromJson(draft.toJson()), draft);
    });

    test('JSON illisible ou incomplet : brouillon vide sans erreur', () {
      expect(
        OnboardingDraft.fromJson(const {'sex': 'unknown', 'step': 99}).step,
        onboardingQuestionSteps + 1,
      );
      expect(OnboardingDraft.fromJson(const {}).isStepComplete(1), isFalse);
    });

    test('poids vidé', () {
      expect(_complete.withWeight(null, target: true).targetWeightKg, isNull);
      expect(_complete.withWeight(70, target: false).weightKg, 70);
    });

    test('profil envoyé à l’API', () {
      final p = _complete.toProfile(locale: 'fr', timezone: 'Africa/Douala');
      expect(p.firstName, 'Awa');
      expect(p.locale, Locale.fr);
      expect(p.goals, {Goal.loseWeight});
    });
  });

  group('contrôleur', () {
    late ProviderContainer container;
    late MemoryLocalStore store;

    setUp(() {
      store = MemoryLocalStore();
      container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
    });
    tearDown(() => container.dispose());

    test('chaque réponse est enregistrée sur le téléphone', () async {
      final c = container.read(onboardingProvider.notifier);
      await container.read(onboardingProvider.future);
      await c.answer((d) => d.copyWith(firstName: 'Awa'));
      await c.reach(3);
      final reread = await OnboardingDraftStore(store).read();
      expect(reread.firstName, 'Awa');
      expect(reread.step, 3);
    });

    test('objectifs incompatibles : perdre empêche prendre', () async {
      final c = container.read(onboardingProvider.notifier);
      await container.read(onboardingProvider.future);
      await c.toggleGoal(Goal.loseWeight);
      await c.toggleGoal(Goal.gainMuscle);
      expect(container.read(onboardingProvider).value!.goals, {
        Goal.loseWeight,
      });
      await c.toggleGoal(Goal.loseWeight);
      await c.toggleGoal(Goal.gainMuscle);
      expect(container.read(onboardingProvider).value!.goals, {
        Goal.gainMuscle,
      });
    });

    test('effacé après la création du compte', () async {
      final c = container.read(onboardingProvider.notifier);
      await container.read(onboardingProvider.future);
      await c.answer((d) => d.copyWith(firstName: 'Awa'));
      await c.clear();
      expect((await OnboardingDraftStore(store).read()).firstName, isEmpty);
    });
  });

  test('consentements de l’inscription', () {
    final consents = registrationConsents(
      legalVersions: {'terms': 3, 'privacy': 4},
      marketing: false,
    );
    expect(
      [for (final c in consents) c.kind],
      [
        ConsentKind.terms,
        ConsentKind.privacy,
        ConsentKind.healthData,
        ConsentKind.marketing,
      ],
    );
    expect(consents[1].version, 4);
    expect(consents.last.granted, isFalse);
  });
}
