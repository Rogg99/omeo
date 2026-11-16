import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/data/auth_repository.dart';
import 'package:omeo/features/auth/data/social_sign_in.dart';
import 'package:omeo_api/omeo_api.dart';

/// Connexion par email (ACC-01). L'erreur reste affichée et les champs
/// conservés (ACC-02).
class LoginController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      await ref.read(sessionProvider.notifier).signIn(result);
    });
  }
}

final loginProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

/// Envoi du lien de réinitialisation (ACC-03).
class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> submit(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).forgotPassword(email.trim()),
    );
    return !state.hasError;
  }
}

final forgotPasswordProvider =
    AsyncNotifierProvider<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );

/// Nouveau mot de passe depuis le lien reçu (ACC-05). L'API révoque toutes
/// les sessions : l'utilisateur se reconnecte ensuite.
class ResetPasswordController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> submit({required String token, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, password: password),
    );
    return !state.hasError;
  }
}

final resetPasswordProvider =
    AsyncNotifierProvider<ResetPasswordController, void>(
      ResetPasswordController.new,
    );

/// Renvoi de l'email de vérification (ACC-06).
class ResendVerificationController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> resend() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).resendVerificationEmail(),
    );
    return !state.hasError;
  }
}

final resendVerificationProvider =
    AsyncNotifierProvider<ResendVerificationController, void>(
      ResendVerificationController.new,
    );

/// Documents à réaccepter (SYS-05), lus depuis l'API pour le titre, la
/// version et le texte complet. Clé : codes séparés par des virgules
/// (`terms,privacy`), pour une égalité par valeur.
final FutureProviderFamily<List<LegalDocument>, String>
pendingLegalDocumentsProvider = FutureProvider.autoDispose
    .family<List<LegalDocument>, String>((ref, kinds) async {
      final repository = ref.watch(authRepositoryProvider);
      return Future.wait([
        for (final code in kinds.split(','))
          for (final kind in LegalKind.values)
            if (kind.value == code) repository.getLegalDocument(kind),
      ]);
    });

/// Lecture d'un document légal.
final FutureProviderFamily<LegalDocument, LegalKind> legalDocumentProvider =
    FutureProvider.autoDispose.family<LegalDocument, LegalKind>(
      (ref, kind) => ref.watch(authRepositoryProvider).getLegalDocument(kind),
    );

/// Acceptation des nouvelles versions (SYS-05), puis relecture de /me.
class ConsentController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> accept(List<LegalDocumentRef> documents) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).acceptDocuments(documents);
      ref.invalidate(meProvider);
    });
    return !state.hasError;
  }
}

final consentProvider = AsyncNotifierProvider<ConsentController, void>(
  ConsentController.new,
);

/// Inscription jointe à une connexion sociale : profil de l'onboarding,
/// consentements et code d'invitation.
typedef SocialSignUp = ({
  OnboardingProfile profile,
  List<ConsentInput> consents,
  String? inviteCode,
});

/// Connexion ou inscription Google / Apple (ACC-01, ONB-13). Sans inscription,
/// un compte inexistant renvoie `validation_error` : l'écran propose alors
/// de commencer l'onboarding.
class SocialAuthController extends AsyncNotifier<AuthResult?> {
  @override
  AuthResult? build() => null;

  Future<void> submit(
    SocialAuthRequestProviderEnum provider, {
    SocialSignUp? signUp,
  }) async {
    final social = ref.read(socialSignInProvider);
    if (social == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await social.signIn(provider);
      if (credential == null) return null;
      final result = await ref
          .read(authRepositoryProvider)
          .socialAuth(
            SocialAuthRequest(
              provider: provider,
              idToken: credential.idToken,
              nonce: credential.nonce,
              profile: signUp?.profile,
              consents: signUp?.consents,
              inviteCode: signUp?.inviteCode,
            ),
          );
      await ref.read(sessionProvider.notifier).signIn(result);
      return result;
    });
  }
}

final socialAuthProvider =
    AsyncNotifierProvider<SocialAuthController, AuthResult?>(
      SocialAuthController.new,
    );
