import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/auth/data/auth_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// État de la session sur cet appareil.
enum SessionStatus {
  /// Jetons en cours de relecture (écran de démarrage).
  unknown,
  signedOut,
  signedIn,
}

/// Session : jetons stockés, connexion et déconnexion.
class SessionController extends Notifier<SessionStatus> {
  /// Utilisateur renvoyé par la connexion : évite un GET /me de plus.
  Me? _seed;

  /// Rend l'utilisateur de la connexion, une seule fois.
  Me? takeSeed() {
    final me = _seed;
    _seed = null;
    return me;
  }

  @override
  SessionStatus build() {
    unawaited(_restore());
    return SessionStatus.unknown;
  }

  Future<void> _restore() async {
    final tokens = await ref.read(tokenStoreProvider).read();
    state = tokens == null ? SessionStatus.signedOut : SessionStatus.signedIn;
  }

  /// Ouvre la session avec le résultat d'une connexion ou d'une inscription.
  Future<void> signIn(AuthResult result) async {
    await ref.read(tokenStoreProvider).write((
      access: result.tokens.access,
      refresh: result.tokens.refresh,
    ));
    _seed = result.me;
    ref.invalidate(meProvider);
    state = SessionStatus.signedIn;
  }

  /// Déconnexion volontaire (PRF-10). La session locale est fermée même si
  /// l'API est injoignable : les jetons sont effacés de l'appareil.
  Future<void> signOut({bool allDevices = false}) async {
    try {
      await ref.read(authRepositoryProvider).logout(allDevices: allDevices);
    } on Object {
      // Le serveur révoquera le jeton à son expiration.
    } finally {
      await expire();
    }
  }

  /// Session perdue (401 not_authenticated, refresh refusé, compte supprimé).
  Future<void> expire() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidate(meProvider);
    state = SessionStatus.signedOut;
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionStatus>(
  SessionController.new,
);

/// Utilisateur connecté (GET /me) : profil, objectifs, droits, préférences.
class MeController extends AsyncNotifier<Me> {
  @override
  Future<Me> build() async {
    final seed = ref.read(sessionProvider.notifier).takeSeed();
    return seed ?? ref.watch(authRepositoryProvider).getMe();
  }

  /// Remplace l'utilisateur par la réponse d'une écriture (profil,
  /// préférences).
  void set(Me me) => state = AsyncData(me);
}

final meProvider = AsyncNotifierProvider<MeController, Me>(MeController.new);
