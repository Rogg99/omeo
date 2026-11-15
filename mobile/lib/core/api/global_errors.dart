import 'dart:async';

import 'package:omeo/core/api/api_failure.dart';

/// Événement d'erreur traité au niveau de l'app (écran ou feuille dédiés),
/// quel que soit l'écran qui a fait l'appel.
sealed class GlobalErrorEvent {
  const GlobalErrorEvent();

  /// Associe un code problem+json à son événement global, s'il en a un.
  static GlobalErrorEvent? fromFailure(ApiFailure failure) {
    if (failure is! ProblemFailure) return null;
    return switch (failure.code) {
      ProblemCodes.upgradeRequired => const UpgradeRequired(),
      ProblemCodes.planRequired => PlanRequired(
        feature: failure.meta['feature'] as String?,
      ),
      ProblemCodes.quotaExceeded => QuotaExceeded(
        resetsAt: DateTime.tryParse('${failure.meta['resets_at']}'),
        canUpgrade: failure.meta['upgrade'] == true,
        feature: failure.meta['feature'] as String?,
      ),
      ProblemCodes.consentRequired => ConsentRequired(
        documents: [
          for (final d in (failure.meta['documents'] as List<Object?>? ?? []))
            '$d',
        ],
      ),
      ProblemCodes.accountSuspended => AccountSuspended(
        supportUrl: failure.meta['support_url'] as String?,
      ),
      ProblemCodes.notAuthenticated => const SignedOut(),
      _ => null,
    };
  }
}

/// 426 : écran de mise à jour forcée.
final class UpgradeRequired extends GlobalErrorEvent {
  const UpgradeRequired();
}

/// 403 plan_required : présentation d'Omeo Plus.
final class PlanRequired extends GlobalErrorEvent {
  const PlanRequired({this.feature});
  final String? feature;
}

/// 429 quota_exceeded : feuille de quota.
final class QuotaExceeded extends GlobalErrorEvent {
  const QuotaExceeded({
    required this.canUpgrade,
    this.resetsAt,
    this.feature,
  });

  /// En Free, l'API indique qu'il faut proposer Plus.
  final bool canUpgrade;
  final DateTime? resetsAt;
  final String? feature;
}

/// 403 consent_required : réacceptation des documents légaux.
final class ConsentRequired extends GlobalErrorEvent {
  const ConsentRequired({required this.documents});
  final List<String> documents;
}

/// 403 account_suspended : écran dédié.
final class AccountSuspended extends GlobalErrorEvent {
  const AccountSuspended({this.supportUrl});
  final String? supportUrl;
}

/// Session terminée (401 not_authenticated ou refresh refusé).
final class SignedOut extends GlobalErrorEvent {
  const SignedOut();
}

/// Bus des erreurs globales, écouté par la racine de l'app.
class GlobalErrorBus {
  final _controller = StreamController<GlobalErrorEvent>.broadcast();

  Stream<GlobalErrorEvent> get events => _controller.stream;

  /// Publie l'événement correspondant à [failure], s'il en a un.
  void report(ApiFailure failure) {
    final event = GlobalErrorEvent.fromFailure(failure);
    if (event != null) _controller.add(event);
  }

  void emit(GlobalErrorEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
