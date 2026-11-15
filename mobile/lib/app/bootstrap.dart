import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/config/app_config.dart';
import 'package:omeo/core/l10n/number_symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configuration fournie à toute l'app. Surchargée au démarrage.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider doit être surchargé.'),
);

/// Démarre l'app avec ses surcharges de dépendances (une par flavor).
Future<void> bootstrap({
  required Widget Function() builder,
  required DataSource dataSource,
  List<Override> overrides = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  useRenderableGroupSeparators();
  final config = AppConfig.fromEnvironment()..validate();
  // Chaque point d'entrée ne sait servir qu'une source de données : les
  // dépôts simulés n'existent que dans main_mock.dart.
  if (config.dataSource != dataSource) {
    throw StateError(
      'DATA_SOURCE=${config.dataSource.name} incompatible avec ce point '
      "d'entrée (${dataSource.name}).",
    );
  }
  final device = await _readDevice();

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
      // Pas de nouvel essai automatique : l'écran montre l'erreur selon son
      // code et propose « Réessayer » (les écritures passent par la file
      // d'attente hors connexion).
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        deviceTimezoneProvider.overrideWithValue(device.timezone),
        clientIdProvider.overrideWithValue(device.clientId),
        ...overrides,
      ],
      child: builder(),
    ),
  );
}

/// Fuseau IANA et identifiant client (`mobile/1.4.0 (android 15)`).
Future<({String timezone, String clientId})> _readDevice() async {
  final timezone = await FlutterTimezone.getLocalTimezone();
  final package = await PackageInfo.fromPlatform();
  final info = DeviceInfoPlugin();
  final os = switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'android ${(await info.androidInfo).version.release}',
    TargetPlatform.iOS => 'ios ${(await info.iosInfo).systemVersion}',
    final other => other.name,
  };
  return (
    timezone: timezone.identifier,
    clientId: 'mobile/${package.version} ($os)',
  );
}
