import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Authentification, session et documents légaux à (ré)accepter.
abstract interface class AuthRepository {
  Future<AuthResult> login({required String email, required String password});

  /// Inscription par email à la fin de l'onboarding (étape 9).
  Future<AuthResult> register(RegisterRequest request);

  /// Connexion ou inscription Google / Apple.
  Future<AuthResult> socialAuth(SocialAuthRequest request);

  /// Révoque la session courante (ou toutes).
  Future<void> logout({required bool allDevices});

  /// Répond toujours, que l'email existe ou non (pas d'énumération).
  Future<void> forgotPassword(String email);

  /// Révoque toutes les sessions existantes.
  Future<void> resetPassword({required String token, required String password});

  Future<void> resendVerificationEmail();

  Future<Me> getMe();

  Future<LegalDocument> getLegalDocument(LegalKind kind);

  /// Accepte les versions publiées des documents indiqués.
  Future<void> acceptDocuments(List<LegalDocumentRef> documents);
}

/// Implémentation sur l'API réelle.
final class AuthApiRepository implements AuthRepository {
  const AuthApiRepository(this._auth, this._account, this._content);

  final AuthApi _auth;
  final AccountApi _account;
  final ContentApi _content;

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      guardApi(
        () => _auth.login(
          loginRequest: LoginRequest(email: email, password: password),
        ),
      );

  @override
  Future<AuthResult> register(RegisterRequest request) =>
      guardApi(() => _auth.register(registerRequest: request));

  @override
  Future<AuthResult> socialAuth(SocialAuthRequest request) =>
      guardApi(() => _auth.socialAuth(socialAuthRequest: request));

  @override
  Future<void> logout({required bool allDevices}) => guardApi(
    () => _auth.logout(logoutRequest: LogoutRequest(allDevices: allDevices)),
  );

  @override
  Future<void> forgotPassword(String email) => guardApi(
    () => _auth.forgotPassword(
      forgotPasswordRequest: ForgotPasswordRequest(email: email),
    ),
  );

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => guardApi(
    () => _auth.resetPassword(
      resetPasswordRequest: ResetPasswordRequest(
        token: token,
        password: password,
      ),
    ),
  );

  @override
  Future<void> resendVerificationEmail() =>
      guardApi(_auth.resendVerificationEmail);

  @override
  Future<Me> getMe() => guardApi(_account.getMe);

  @override
  Future<LegalDocument> getLegalDocument(LegalKind kind) =>
      guardApi(() => _content.getLegalDocument(kind: kind));

  @override
  Future<void> acceptDocuments(List<LegalDocumentRef> documents) => guardApi(
    () => _account.updateConsents(
      updateConsentsRequest: UpdateConsentsRequest(
        consents: [
          for (final d in documents)
            if (_consentKinds[d.kind] case final kind?)
              ConsentInput(kind: kind, granted: true, version: d.version),
        ],
      ),
    ),
  );
}

/// Documents légaux qui s'acceptent par un consentement (les mentions
/// légales et la politique cookies ne s'acceptent pas dans l'app).
const Map<LegalKind, ConsentKind> _consentKinds = {
  LegalKind.terms: ConsentKind.terms,
  LegalKind.privacy: ConsentKind.privacy,
};

/// Dépôt d'authentification. Le flavor mock le remplace.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(omeoApiProvider);
  return AuthApiRepository(
    api.getAuthApi(),
    api.getAccountApi(),
    api.getContentApi(),
  );
});
