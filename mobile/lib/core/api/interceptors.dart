import 'dart:async';

import 'package:dio/dio.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/api/token_store.dart';

/// En-têtes communs (conventions-api.md) : langue, fuseau et client.
class ClientHeadersInterceptor extends Interceptor {
  ClientHeadersInterceptor({
    required this.languageTag,
    required this.timezone,
    required this.clientId,
  });

  /// Lus à chaque requête : la langue et le fuseau peuvent changer.
  final String Function() languageTag;
  final String Function() timezone;

  /// Ex. `mobile/1.4.0 (android 15)`.
  final String clientId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Accept-Language': languageTag(),
      'X-Timezone': timezone(),
      'X-Client': clientId,
    });
    handler.next(options);
  }
}

/// Renouvelle le jeton d'accès.
typedef RefreshCall = Future<SessionTokens> Function(String refreshToken);

/// Authentification : ajoute le jeton, et sur 401 token_expired renouvelle
/// la session une seule fois pour toutes les requêtes en attente, puis les
/// rejoue. Sur 401 not_authenticated ou refresh refusé : déconnexion.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokens,
    required this.refresh,
    required this.errors,
  });

  final Dio dio;
  final TokenStore tokens;
  final RefreshCall refresh;
  final GlobalErrorBus errors;

  /// Renouvellement en cours, partagé par les requêtes concurrentes.
  Future<SessionTokens?>? _refreshing;

  static const _retriedKey = 'omeo.retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final current = await tokens.read();
    if (current != null) {
      options.headers['Authorization'] = 'Bearer ${current.access}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final code = _problemCode(err);
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (err.response?.statusCode == 401 &&
        code == ProblemCodes.tokenExpired &&
        !alreadyRetried) {
      // Si une autre requête a déjà renouvelé la session pendant que
      // celle-ci attendait, on rejoue directement avec le nouveau jeton.
      final sent = err.requestOptions.headers['Authorization'];
      final current = await tokens.read();
      final renewed = current != null && sent != 'Bearer ${current.access}'
          ? current
          : await _refreshOnce();
      if (renewed == null) {
        handler.reject(err);
        return;
      }
      try {
        final options = err.requestOptions
          ..extra[_retriedKey] = true
          ..headers['Authorization'] = 'Bearer ${renewed.access}';
        handler.resolve(await dio.fetch<Object?>(options));
      } on DioException catch (retryError) {
        handler.reject(retryError);
      }
      return;
    }

    if (err.response?.statusCode == 401 &&
        code == ProblemCodes.notAuthenticated) {
      await tokens.clear();
      errors.emit(const SignedOut());
    }
    handler.next(err);
  }

  Future<SessionTokens?> _refreshOnce() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<SessionTokens?> _doRefresh() async {
    final current = await tokens.read();
    if (current == null) return null;
    try {
      final renewed = await refresh(current.refresh);
      await tokens.write(renewed);
      return renewed;
    } on Object {
      // Refresh rejoué ou révoqué : la session est perdue.
      await tokens.clear();
      errors.emit(const SignedOut());
      return null;
    }
  }

  static String? _problemCode(DioException err) {
    final data = err.response?.data;
    return data is Map<String, dynamic> ? data['code'] as String? : null;
  }
}

/// Publie les erreurs globales (426, 403 plan_required, 429…) sur le bus.
class GlobalErrorInterceptor extends Interceptor {
  GlobalErrorInterceptor(this.errors);

  final GlobalErrorBus errors;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = failureFromDio(err);
    // La déconnexion est gérée par AuthInterceptor.
    if (failure.code != ProblemCodes.notAuthenticated) errors.report(failure);
    handler.next(err);
  }
}
