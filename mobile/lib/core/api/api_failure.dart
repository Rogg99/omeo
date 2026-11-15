import 'package:dio/dio.dart';
import 'package:omeo_api/omeo_api.dart';

/// Erreur renvoyée par un dépôt. Le comportement de l'app dépend uniquement
/// de [code] (problem+json), jamais du texte (règle 2).
sealed class ApiFailure implements Exception {
  const ApiFailure();

  /// Code stable : celui de l'API, ou un code local (`network`, `timeout`…).
  String get code;
}

/// Erreur problem+json renvoyée par l'API.
final class ProblemFailure extends ApiFailure {
  const ProblemFailure({
    required this.status,
    required this.code,
    this.detail,
    this.fieldErrors = const {},
    this.meta = const {},
    this.retryAfter,
  });

  factory ProblemFailure.fromProblem(Problem p, {Duration? retryAfter}) =>
      ProblemFailure(
        status: p.status,
        code: p.code,
        detail: p.detail,
        fieldErrors: {
          for (final e in (p.errors ?? const {}).entries)
            e.key: [for (final v in e.value) v.code],
        },
        meta: p.meta ?? const {},
        retryAfter: retryAfter,
      );

  final int status;
  @override
  final String code;

  /// Message traduit par l'API, affichable tel quel.
  final String? detail;

  /// Codes d'erreur par champ (`validation_error`).
  final Map<String, List<String>> fieldErrors;
  final Map<String, Object> meta;
  final Duration? retryAfter;

  @override
  String toString() => 'ProblemFailure($status, $code)';
}

/// Pas de réseau ou serveur injoignable.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure();
  @override
  String get code => 'network';
}

/// Délai dépassé.
final class TimeoutFailure extends ApiFailure {
  const TimeoutFailure();
  @override
  String get code => 'timeout';
}

/// Réponse inattendue (corps illisible, certificat refusé…).
final class UnexpectedFailure extends ApiFailure {
  const UnexpectedFailure();
  @override
  String get code => 'server_error';
}

/// Codes problem+json gérés globalement par l'app.
abstract final class ProblemCodes {
  static const tokenExpired = 'token_expired';
  static const notAuthenticated = 'not_authenticated';
  static const upgradeRequired = 'upgrade_required';
  static const planRequired = 'plan_required';
  static const quotaExceeded = 'quota_exceeded';
  static const consentRequired = 'consent_required';
  static const accountSuspended = 'account_suspended';
  static const rateLimited = 'rate_limited';
  static const validationError = 'validation_error';
}

/// Convertit une erreur Dio en [ApiFailure].
ApiFailure failureFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return e.error is ApiFailure
          ? e.error! as ApiFailure
          : const NetworkFailure();
    case DioExceptionType.badResponse:
      final response = e.response!;
      final body = response.data;
      final retry = int.tryParse(response.headers.value('retry-after') ?? '');
      if (body is Map<String, dynamic> && body['code'] is String) {
        try {
          return ProblemFailure.fromProblem(
            Problem.fromJson(body),
            retryAfter: retry == null ? null : Duration(seconds: retry),
          );
        } on Object {
          return const UnexpectedFailure();
        }
      }
      return const UnexpectedFailure();
  }
}

/// Exécute un appel du client généré et traduit ses erreurs.
Future<T> guardApi<T>(Future<Response<T>> Function() call) async {
  try {
    final response = await call();
    return response.data as T;
  } on DioException catch (e) {
    throw failureFromDio(e);
  }
}
