import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo_api/omeo_api.dart';

/// Jeton d'identité renvoyé par Google ou Apple, vérifié par l'API.
typedef SocialCredential = ({String idToken, String? nonce});

/// Connexion native Google / Apple, derrière une interface : le flavor mock
/// en fournit une fausse.
abstract interface class SocialSignIn {
  /// Fournisseurs utilisables sur cet appareil (Apple : iOS uniquement).
  Set<SocialAuthRequestProviderEnum> get available;

  /// `null` si l'utilisateur annule.
  Future<SocialCredential?> signIn(SocialAuthRequestProviderEnum provider);
}

/// Connexion sociale de l'appareil. `null` tant qu'aucune implémentation
/// native n'est configurée (identifiants OAuth par flavor) : les boutons
/// Google et Apple sont alors masqués.
final socialSignInProvider = Provider<SocialSignIn?>((ref) => null);
