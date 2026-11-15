import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/api/interceptors.dart';
import 'package:omeo/core/api/token_store.dart';
import 'package:omeo_api/omeo_api.dart';

/// Paramètres de construction du client HTTP.
typedef ApiClientOptions = ({
  String baseUrl,
  String clientId,
  String Function() languageTag,
  String Function() timezone,

  /// Empreintes SHA-256 (hex) des certificats acceptés. Vide : pas
  /// d'épinglage (mock, dev).
  List<String> pinnedCertificates,
});

/// Construit le client généré avec les intercepteurs de l'app.
OmeoApi buildApiClient({
  required ApiClientOptions options,
  required TokenStore tokens,
  required GlobalErrorBus errors,
}) {
  BaseOptions base() => BaseOptions(
    baseUrl: options.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
  );

  final headers = ClientHeadersInterceptor(
    languageTag: options.languageTag,
    timezone: options.timezone,
    clientId: options.clientId,
  );

  // Client séparé pour le renouvellement : il ne passe pas par
  // l'intercepteur d'authentification (pas d'attente circulaire).
  final refreshDio = Dio(base())..interceptors.add(headers);
  final dio = Dio(base());
  _pin(refreshDio, options.pinnedCertificates);
  _pin(dio, options.pinnedCertificates);

  final refreshApi = AuthApi(refreshDio);
  dio.interceptors.addAll([
    headers,
    AuthInterceptor(
      dio: dio,
      tokens: tokens,
      errors: errors,
      refresh: (refreshToken) async {
        final response = await refreshApi.refreshToken(
          refreshTokenRequest: RefreshTokenRequest(refresh: refreshToken),
        );
        final t = response.data!;
        return (access: t.access, refresh: t.refresh);
      },
    ),
    GlobalErrorInterceptor(errors),
  ]);
  return OmeoApi(dio: dio);
}

/// Épinglage TLS : le certificat présenté doit faire partie de la liste.
/// La validation système (chaîne, nom d'hôte) s'applique en plus.
void _pin(Dio dio, List<String> fingerprints) {
  if (fingerprints.isEmpty) return;
  final allowed = fingerprints.map((f) => f.toLowerCase()).toSet();
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () =>
        HttpClient()..findProxy = HttpClient.findProxyFromEnvironment,
    validateCertificate: (certificate, host, port) {
      if (certificate == null) return false;
      return allowed.contains(sha256.convert(certificate.der).toString());
    },
  );
}
