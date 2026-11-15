import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/core/api/api_client.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/api/token_store.dart';
import 'package:omeo_api/omeo_api.dart';

/// Bus des erreurs globales, unique pour toute l'app.
final globalErrorBusProvider = Provider<GlobalErrorBus>((ref) {
  final bus = GlobalErrorBus();
  ref.onDispose(bus.dispose);
  return bus;
});

/// Stockage des jetons (sécurisé, remplacé en mémoire dans le flavor mock).
final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// Fuseau IANA de l'appareil, lu au démarrage (flutter_timezone).
final deviceTimezoneProvider = Provider<String>((ref) => 'UTC');

/// Identifiant client envoyé dans X-Client, ex. `mobile/1.4.0 (android 15)`.
final clientIdProvider = Provider<String>(
  (ref) => 'mobile/0.0.0 (${Platform.operatingSystem})',
);

/// Client HTTP généré, configuré avec les intercepteurs de l'app.
final omeoApiProvider = Provider<OmeoApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final timezone = ref.watch(deviceTimezoneProvider);
  return buildApiClient(
    options: (
      baseUrl: config.apiBaseUrl,
      clientId: ref.watch(clientIdProvider),
      languageTag: () =>
          WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      timezone: () => timezone,
      pinnedCertificates: config.pinnedCertificates,
    ),
    tokens: ref.watch(tokenStoreProvider),
    errors: ref.watch(globalErrorBusProvider),
  );
});
