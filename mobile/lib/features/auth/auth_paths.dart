/// Chemins du module d'authentification (liens profonds compris).
abstract final class AuthPaths {
  /// Écran de démarrage, le temps de relire la session (ONB-01).
  static const start = '/start';
  static const language = '/language';
  static const welcome = '/welcome';
  static const login = '/login';
  static const forgotPassword = '/password/forgot';
  static const resetLinkSent = '/password/sent';

  /// Ouvert depuis le lien reçu par email : `/password/reset?token=…`.
  static const resetPassword = '/password/reset';

  /// Lecture d'un document légal : `/legal/terms`.
  static const legal = '/legal/:kind';
  static String legalOf(String kind) => '/legal/$kind';

  /// Chemins accessibles sans session.
  static const Set<String> public = {
    start,
    language,
    welcome,
    login,
    forgotPassword,
    resetLinkSent,
    resetPassword,
  };
}
