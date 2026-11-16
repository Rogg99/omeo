/// Chemins du module de suivi (liens profonds compris).
abstract final class TrackingPaths {
  static const home = '/';

  /// Journal du jour ; `?date=2026-11-09` pour un autre jour.
  static const journal = '/journal';
  static const progress = '/progress';
  static const weight = '/progress/weight';

  /// Autorisation Health Connect / Apple Health (PRO-05).
  static const healthPermission = '/health/permission';
}
