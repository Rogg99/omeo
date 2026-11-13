/// Environnement d'exécution, fixé à la compilation (--dart-define-from-file).
enum Flavor { mock, dev, staging, prod }

/// Source des données des dépôts : simulée en mémoire ou API réelle.
enum DataSource { mock, api }

/// Configuration immuable de l'app, lue une seule fois au démarrage.
final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.dataSource,
    required this.apiBaseUrl,
  });

  /// Lit les valeurs passées par --dart-define ou --dart-define-from-file.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'mock');
    const dataSourceName = String.fromEnvironment(
      'DATA_SOURCE',
      defaultValue: 'mock',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      flavor: Flavor.values.byName(flavorName),
      dataSource: DataSource.values.byName(dataSourceName),
      apiBaseUrl: apiBaseUrl,
    );
  }

  final Flavor flavor;
  final DataSource dataSource;
  final String apiBaseUrl;

  /// Le panneau de développement n'existe qu'en mock et en dev.
  bool get devToolsEnabled => flavor == Flavor.mock || flavor == Flavor.dev;
}
