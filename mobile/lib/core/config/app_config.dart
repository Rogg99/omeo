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
    this.pinnedCertificates = const [],
  });

  /// Lit les valeurs passées par --dart-define ou --dart-define-from-file.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'mock');
    const dataSourceName = String.fromEnvironment(
      'DATA_SOURCE',
      defaultValue: 'mock',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const pins = String.fromEnvironment('API_PINS');
    return AppConfig(
      flavor: Flavor.values.byName(flavorName),
      dataSource: DataSource.values.byName(dataSourceName),
      apiBaseUrl: apiBaseUrl,
      pinnedCertificates: [
        for (final p in pins.split(','))
          if (p.trim().isNotEmpty) p.trim(),
      ],
    );
  }

  final Flavor flavor;
  final DataSource dataSource;
  final String apiBaseUrl;

  /// Empreintes SHA-256 des certificats de l'API (épinglage TLS), dont une
  /// de secours. Obligatoires en staging et en production.
  final List<String> pinnedCertificates;

  /// Refuse de démarrer une configuration dangereuse : en staging et en
  /// production, l'API est en HTTPS et au moins deux empreintes (dont une de
  /// secours) sont fournies.
  void validate() {
    if (flavor == Flavor.mock) return;
    if (apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL manquant pour le flavor ${flavor.name}.');
    }
    if (flavor == Flavor.dev) return;
    final sha256 = RegExp(r'^[0-9a-fA-F]{64}$');
    if (!apiBaseUrl.startsWith('https://') ||
        pinnedCertificates.length < 2 ||
        !pinnedCertificates.every(sha256.hasMatch)) {
      throw StateError(
        'Flavor ${flavor.name} : HTTPS et deux empreintes SHA-256 '
        '(API_PINS) sont obligatoires.',
      );
    }
  }

  /// Le panneau de développement n'existe qu'en mock et en dev.
  bool get devToolsEnabled => flavor == Flavor.mock || flavor == Flavor.dev;
}
