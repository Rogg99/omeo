import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/auth/data/auth_repository.dart';
import 'package:omeo/features/auth/data/local_store.dart';
import 'package:omeo/features/auth/data/social_sign_in.dart';
import 'package:omeo/features/onboarding/data/onboarding_repository.dart';
import 'package:omeo/mock/fixtures/auth_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo_api/omeo_api.dart';

/// Clé de l'utilisateur courant dans l'état du faux serveur.
const meStateKey = 'auth.me';

/// Utilisateur de la session simulée (connecté ou inscrit pendant la session).
Me currentMockMe(MockBackend backend) {
  final stored = backend.state[meStateKey];
  if (stored is Me) return stored;
  final me = meFixture(
    tier: switch (backend.scenario) {
      MockScenario.free || MockScenario.quotaExhausted => 'free',
      MockScenario.plus => 'plus',
      _ => 'trial',
    },
  );
  backend.state[meStateKey] = me;
  return me;
}

/// Authentification simulée. Compte de démonstration : [demoEmail] /
/// [demoPassword] ; tout autre couple renvoie `invalid_credentials`.
final class AuthMockRepository implements AuthRepository {
  AuthMockRepository(this._backend);

  final MockBackend _backend;

  /// Documents à réaccepter une fois (démontre SYS-05 après la connexion).
  bool _consentAsked = false;

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _backend.call(() {
        if (email.toLowerCase() != demoEmail || password != demoPassword) {
          throw const ProblemFailure(
            status: 401,
            code: 'invalid_credentials',
          );
        }
        return authResult(currentMockMe(_backend));
      });

  @override
  Future<AuthResult> register(RegisterRequest request) => _backend.call(
    () {
      if (request.email.toLowerCase() == demoEmail) {
        throw const ProblemFailure(status: 409, code: 'conflict');
      }
      final me = meFromOnboarding(request.profile, request.email);
      _backend.state[meStateKey] = me;
      return authResult(
        me,
        created: true,
        inviteStatus: request.inviteCode == null
            ? 'none'
            : request.inviteCode == demoInviteCode
            ? 'valid'
            : 'invalid',
      );
    },
    // Le calcul du plan prend un peu plus de temps (ONB-15).
    delay: const Duration(milliseconds: 2600),
  );

  @override
  Future<AuthResult> socialAuth(SocialAuthRequest request) => _backend.call(() {
    final profile = request.profile;
    if (profile == null) return authResult(currentMockMe(_backend));
    final me = meFromOnboarding(profile, 'awa.social@exemple.com');
    _backend.state[meStateKey] = me;
    return authResult(me, created: true);
  });

  @override
  Future<void> logout({required bool allDevices}) => _backend.call(() {});

  @override
  Future<void> forgotPassword(String email) => _backend.call(() {});

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => _backend.call(() {
    if (token.isEmpty || token == 'expired') {
      throw const ProblemFailure(
        status: 400,
        code: ProblemCodes.validationError,
        fieldErrors: {
          'token': ['invalid'],
        },
      );
    }
  });

  @override
  Future<void> resendVerificationEmail() => _backend.call(() {});

  @override
  Future<Me> getMe() => _backend.call(() {
    final me = currentMockMe(_backend);
    if (_consentAsked || _backend.scenario != MockScenario.trial) return me;
    _consentAsked = true;
    // Première lecture : une nouvelle version de la confidentialité.
    return Me.fromJson({
      ...me.toJson(),
      'pending_documents': [
        {
          'kind': 'privacy',
          'version': 4,
          'title': 'Politique de confidentialité',
        },
      ],
    });
  });

  @override
  Future<LegalDocument> getLegalDocument(LegalKind kind) =>
      _backend.call(() => legalFixture(kind));

  @override
  Future<void> acceptDocuments(List<LegalDocumentRef> documents) =>
      _backend.call(() {});
}

/// Configuration, villes et codes d'invitation simulés.
final class OnboardingMockRepository implements OnboardingRepository {
  const OnboardingMockRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<AppConfig> getAppConfig() => _backend.call(appConfigFixture);

  @override
  Future<List<City>> searchCities({String? query}) =>
      _backend.call(() => citiesFixture(query));

  @override
  Future<CheckInviteCode200Response> checkInviteCode(String code) =>
      _backend.call(() {
        final valid = code.toUpperCase() == demoInviteCode;
        return CheckInviteCode200Response(
          valid: valid,
          referrerFirstName: valid ? 'Awa' : null,
          trialDays: valid ? 7 : 3,
        );
      });
}

/// Fausse connexion Google / Apple : un jeton d'exemple, sans compte réel.
final class FakeSocialSignIn implements SocialSignIn {
  const FakeSocialSignIn();

  @override
  Set<SocialAuthRequestProviderEnum> get available =>
      SocialAuthRequestProviderEnum.values.toSet();

  @override
  Future<SocialCredential?> signIn(
    SocialAuthRequestProviderEnum provider,
  ) async => (idToken: 'mock-id-token-${provider.value}', nonce: null);
}

/// Dépôts simulés de l'authentification et de l'onboarding.
List<Override> authMockOverrides() => [
  localStoreProvider.overrideWithValue(MemoryLocalStore()),
  authRepositoryProvider.overrideWith(
    (ref) => AuthMockRepository(ref.watch(mockBackendProvider)),
  ),
  onboardingRepositoryProvider.overrideWith(
    (ref) => OnboardingMockRepository(ref.watch(mockBackendProvider)),
  ),
  socialSignInProvider.overrideWithValue(const FakeSocialSignIn()),
];
