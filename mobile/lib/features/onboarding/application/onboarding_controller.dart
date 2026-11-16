import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/data/auth_repository.dart';
import 'package:omeo/features/onboarding/data/onboarding_draft.dart';
import 'package:omeo/features/onboarding/data/onboarding_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Brouillon du questionnaire, relu au démarrage et enregistré à chaque
/// réponse : l'utilisateur reprend là où il s'était arrêté.
class OnboardingController extends AsyncNotifier<OnboardingDraft> {
  @override
  Future<OnboardingDraft> build() =>
      ref.watch(onboardingDraftStoreProvider).read();

  /// Applique une réponse et l'enregistre sur le téléphone.
  Future<void> answer(OnboardingDraft Function(OnboardingDraft) change) async {
    final current = state.value ?? await future;
    final next = change(current);
    if (next == current) return;
    state = AsyncData(next);
    await ref.read(onboardingDraftStoreProvider).write(next);
  }

  /// Retient l'étape atteinte, pour reprendre au bon endroit.
  Future<void> reach(int step) =>
      update((d) => step > d.step ? d.copyWith(step: step) : d);

  /// Ajoute ou retire un objectif ; un objectif incompatible déjà choisi
  /// empêche l'ajout (l'écran explique pourquoi).
  Future<void> toggleGoal(Goal goal) => answer((d) {
    if (d.goals.contains(goal)) {
      return d.copyWith(goals: {...d.goals}..remove(goal));
    }
    final blocker = incompatibleGoals[goal];
    if (blocker != null && d.goals.contains(blocker)) return d;
    return d.copyWith(goals: {...d.goals, goal});
  });

  Future<void> clear() async {
    await ref.read(onboardingDraftStoreProvider).clear();
    state = const AsyncData(OnboardingDraft());
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

/// Configuration publique de l'app (versions légales, essai).
final publicConfigProvider = FutureProvider<AppConfig>(
  (ref) => ref.watch(onboardingRepositoryProvider).getAppConfig(),
);

/// Suggestions de villes pour une saisie ; vide : villes populaires.
final FutureProviderFamily<List<City>, String> citySearchProvider =
    FutureProvider.autoDispose.family<List<City>, String>(
      (ref, query) =>
          ref.watch(onboardingRepositoryProvider).searchCities(query: query),
    );

/// Vérification d'un code d'invitation avant l'inscription.
final FutureProviderFamily<CheckInviteCode200Response, String>
inviteCheckProvider = FutureProvider.autoDispose
    .family<CheckInviteCode200Response, String>(
      (ref, code) =>
          ref.watch(onboardingRepositoryProvider).checkInviteCode(code),
    );

/// Choix faits à l'étape 9, en plus des réponses du brouillon.
typedef AccountChoices = ({
  String email,
  String password,
  String? inviteCode,
  bool marketing,
  String locale,
});

/// Création du compte (étape 9) : profil, consentements et code
/// d'invitation, puis ouverture de la session.
class RegistrationController extends AsyncNotifier<AuthResult?> {
  @override
  AuthResult? build() => null;

  Future<void> register(AccountChoices choices) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final draft = await ref.read(onboardingProvider.future);
      final config = await ref.read(publicConfigProvider.future);
      final result = await ref
          .read(authRepositoryProvider)
          .register(
            RegisterRequest(
              email: choices.email.trim(),
              password: choices.password,
              inviteCode: choices.inviteCode,
              profile: draft.toProfile(
                locale: choices.locale,
                timezone: ref.read(deviceTimezoneProvider),
              ),
              consents: registrationConsents(
                legalVersions: config.legalVersions,
                marketing: choices.marketing,
              ),
            ),
          );
      await ref.read(sessionProvider.notifier).signIn(result);
      unawaited(ref.read(onboardingProvider.notifier).clear());
      return result;
    });
  }
}

final registrationProvider =
    AsyncNotifierProvider<RegistrationController, AuthResult?>(
      RegistrationController.new,
    );

/// Consentements de l'inscription : CGU, confidentialité et données de santé
/// (obligatoires, cochés par l'utilisateur), marketing (facultatif).
List<ConsentInput> registrationConsents({
  required Map<String, int> legalVersions,
  required bool marketing,
}) => [
  ConsentInput(
    kind: ConsentKind.terms,
    granted: true,
    version: legalVersions[ConsentKind.terms.value],
  ),
  ConsentInput(
    kind: ConsentKind.privacy,
    granted: true,
    version: legalVersions[ConsentKind.privacy.value],
  ),
  ConsentInput(kind: ConsentKind.healthData, granted: true),
  ConsentInput(kind: ConsentKind.marketing, granted: marketing),
];
