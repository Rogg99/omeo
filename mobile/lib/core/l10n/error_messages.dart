import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';

/// Message à afficher pour une erreur, choisi selon son code (règle 2).
/// Le `detail` traduit par l'API est préféré quand il existe.
String failureMessage(AppLocalizations l, Object error) {
  if (error is! ApiFailure) return l.errorsServerError;
  if (error is ProblemFailure && error.detail != null) return error.detail!;
  return switch (error.code) {
    'network' || 'timeout' => l.commonStateOffline,
    ProblemCodes.validationError => l.errorsValidationError,
    ProblemCodes.tokenExpired => l.errorsTokenExpired,
    ProblemCodes.notAuthenticated => l.errorsNotAuthenticated,
    ProblemCodes.planRequired => l.errorsPlanRequired,
    ProblemCodes.accountSuspended => l.errorsAccountSuspended,
    ProblemCodes.upgradeRequired => l.errorsUpgradeRequired,
    ProblemCodes.rateLimited => l.errorsRateLimited,
    'analysis_rejected' => l.errorsAnalysisRejected,
    'email_not_verified' => l.errorsEmailNotVerified,
    'invalid_credentials' => l.errorsInvalidCredentials,
    _ => l.errorsServerError,
  };
}
