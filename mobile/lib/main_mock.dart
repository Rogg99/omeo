import 'package:omeo/app/app.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/core/config/app_config.dart';
import 'package:omeo/mock/mock_overrides.dart';

/// Point d'entrée du flavor mock : seul fichier autorisé à importer lib/mock/.
/// `fvm flutter run -t lib/main_mock.dart --dart-define-from-file=config/mock.json`
Future<void> main() => bootstrap(
  builder: () => const OmeoApp(),
  dataSource: DataSource.mock,
  overrides: mockOverrides(),
);
