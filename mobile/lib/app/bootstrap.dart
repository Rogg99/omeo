import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/config/app_config.dart';

/// Configuration fournie à toute l'app. Surchargée au démarrage.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider doit être surchargé.'),
);

/// Démarre l'app avec ses surcharges de dépendances (une par flavor).
Future<void> bootstrap({
  required Widget Function() builder,
  List<Override> overrides = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // Les erreurs non gérées ne sortent jamais avec des données utilisateur :
  // seul le type et la pile sont journalisés, et uniquement hors production.
  FlutterError.onError = (details) {
    if (config.flavor != Flavor.prod) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('Erreur non gérée : ${error.runtimeType}');
    return true;
  };

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config), ...overrides],
      child: builder(),
    ),
  );
}
