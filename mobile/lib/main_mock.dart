import 'package:flutter/widgets.dart';
import 'package:omeo/app/app.dart';
import 'package:omeo/app/bootstrap.dart';

/// Point d'entrée du flavor mock : seul fichier autorisé à importer lib/mock/.
/// `fvm flutter run -t lib/main_mock.dart --dart-define-from-file=config/mock.json`
Future<void> main() => bootstrap(
  builder: () => const OmeoApp(home: SizedBox.shrink()),
);
