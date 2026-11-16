import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Données publiques de l'onboarding : configuration, villes et code
/// d'invitation.
abstract interface class OnboardingRepository {
  /// Versions des documents légaux, durées d'essai, âge minimum.
  Future<AppConfig> getAppConfig();

  /// Villes correspondant à [query] ; sans requête, les villes populaires.
  Future<List<City>> searchCities({String? query});

  Future<CheckInviteCode200Response> checkInviteCode(String code);
}

final class OnboardingApiRepository implements OnboardingRepository {
  const OnboardingApiRepository(this._app, this._billing);

  final AppApi _app;
  final BillingApi _billing;

  @override
  Future<AppConfig> getAppConfig() => guardApi(_app.getAppConfig);

  @override
  Future<List<City>> searchCities({String? query}) async {
    final response = await guardApi(
      () => _app.searchCities(q: (query ?? '').isEmpty ? null : query),
    );
    return response.results;
  }

  @override
  Future<CheckInviteCode200Response> checkInviteCode(String code) => guardApi(
    () => _billing.checkInviteCode(
      checkInviteCodeRequest: CheckInviteCodeRequest(code: code),
    ),
  );
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final api = ref.watch(omeoApiProvider);
  return OnboardingApiRepository(api.getAppApi(), api.getBillingApi());
});
