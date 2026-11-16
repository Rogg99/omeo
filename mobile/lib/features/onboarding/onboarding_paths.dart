/// Chemins du questionnaire d'onboarding.
abstract final class OnboardingPaths {
  static const root = '/onboarding';

  /// Étapes 1 à 8 : `/onboarding/step/3`.
  static const step = '/onboarding/step/:n';
  static String stepOf(int n) => '/onboarding/step/$n';

  /// Étape 9 : création du compte.
  static const account = '/onboarding/account';

  /// Après l'inscription : calcul du plan, puis plan prêt.
  static const computing = '/onboarding/plan';
  static const ready = '/onboarding/ready';
}
