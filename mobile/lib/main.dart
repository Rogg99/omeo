import 'package:omeo/app/app.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/core/config/app_config.dart';

/// Point d'entrée des flavors dev, staging et prod (API réelle).
/// `fvm flutter run --dart-define-from-file=config/dev.json`
Future<void> main() => bootstrap(
  builder: () => const OmeoApp(),
  dataSource: DataSource.api,
);
