import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/core/platform/external_links.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/auth_paths.dart';
import 'package:omeo/features/auth/presentation/consent_screens.dart';
import 'package:omeo/features/auth/presentation/entry_screens.dart';
import 'package:omeo/features/auth/presentation/login_screens.dart';
import 'package:omeo/features/onboarding/onboarding_paths.dart';
import 'package:omeo/features/onboarding/onboarding_routes.dart';
import 'package:omeo/features/profile/application/app_settings.dart';
import 'package:omeo/features/support/support_paths.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';
import 'package:omeo_api/omeo_api.dart';

/// Prévient le routeur quand la session ou les réglages changent.
class _Refresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Écrans d'onboarding encore accessibles une fois connecté : la fin de
/// l'inscription se joue après l'ouverture de la session.
const Set<String> _afterSignUp = {
  OnboardingPaths.account,
  OnboardingPaths.computing,
  OnboardingPaths.ready,
};

/// Destination d'un utilisateur sans session.
String signedOutHome({required bool languageChosen}) =>
    languageChosen ? AuthPaths.welcome : AuthPaths.language;

/// Garde de session : démarrage le temps de relire les jetons, écrans
/// publics sans session, app une fois connecté. Le chemin demandé est
/// conservé (`from`) pour les liens profonds.
@visibleForTesting
String? sessionRedirect({
  required SessionStatus session,
  required AppSettings settings,
  required Uri uri,
}) {
  final path = uri.path;
  // Écrans bloquants (mise à jour exigée, compte suspendu) : toujours.
  if (path == SupportPaths.upgrade || path == SupportPaths.suspended) {
    return null;
  }
  final isLegal = path.startsWith('/legal/');
  final isOnboarding = path.startsWith(OnboardingPaths.root);

  if (session == SessionStatus.unknown || !settings.loaded) {
    if (path == AuthPaths.start) return null;
    return Uri(
      path: AuthPaths.start,
      queryParameters: {'from': uri.toString()},
    ).toString();
  }

  final from = path == AuthPaths.start ? uri.queryParameters['from'] : null;

  if (session == SessionStatus.signedOut) {
    final publicTarget = from != null && _isPublic(Uri.parse(from).path);
    if (publicTarget) return from;
    if (path != AuthPaths.start &&
        (AuthPaths.public.contains(path) || isOnboarding || isLegal)) {
      return null;
    }
    return signedOutHome(languageChosen: settings.languageChosen);
  }

  // Connecté.
  if (path == AuthPaths.start) {
    final target = from == null ? null : Uri.parse(from).path;
    return target == null || _isPublic(target) && !_afterSignUp.contains(target)
        ? TrackingPaths.home
        : from;
  }
  if (path == AuthPaths.resetPassword || isLegal) return null;
  if (AuthPaths.public.contains(path)) return TrackingPaths.home;
  if (isOnboarding && !_afterSignUp.contains(path)) return TrackingPaths.home;
  return null;
}

bool _isPublic(String path) =>
    AuthPaths.public.contains(path) ||
    path.startsWith(OnboardingPaths.root) ||
    path.startsWith('/legal/');

/// Routes du module d'authentification et garde de session.
FeatureRoutes authRoutes(Ref ref) {
  final refresh = _Refresh();
  ref
    ..listen(sessionProvider, (_, _) => refresh.ping())
    ..listen(appSettingsProvider, (previous, next) {
      if (previous?.loaded != next.loaded ||
          previous?.languageChosen != next.languageChosen) {
        refresh.ping();
      }
    })
    ..onDispose(refresh.dispose);

  return FeatureRoutes(
    refresh: refresh,
    redirect: (context, state) => sessionRedirect(
      session: ref.read(sessionProvider),
      settings: ref.read(appSettingsProvider),
      uri: state.uri,
    ),
    routes: [
      GoRoute(
        path: AuthPaths.start,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: AuthPaths.language,
        builder: (context, state) =>
            LanguageScreen(onContinue: () => context.go(AuthPaths.welcome)),
      ),
      GoRoute(
        path: AuthPaths.welcome,
        builder: (context, state) => WelcomeScreen(
          onStart: () => unawaited(resumeOnboarding(ref, context)),
          onLogin: () => context.push(AuthPaths.login),
        ),
      ),
      GoRoute(
        path: AuthPaths.login,
        builder: (context, state) => LoginScreen(
          onForgotPassword: (email) => context.push(
            Uri(
              path: AuthPaths.forgotPassword,
              queryParameters: {if (email.isNotEmpty) 'email': email},
            ).toString(),
          ),
          onStart: () => unawaited(resumeOnboarding(ref, context)),
        ),
      ),
      GoRoute(
        path: AuthPaths.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
          onSent: (email) => context.pushReplacement(
            Uri(
              path: AuthPaths.resetLinkSent,
              queryParameters: {'email': email},
            ).toString(),
          ),
        ),
      ),
      GoRoute(
        path: AuthPaths.resetLinkSent,
        builder: (context, state) => ResetLinkSentScreen(
          email: state.uri.queryParameters['email'] ?? '',
          onOpenMail: () => unawaited(openExternal(Uri(scheme: 'mailto'))),
        ),
      ),
      GoRoute(
        path: AuthPaths.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
          onDone: () => context.go(AuthPaths.login),
        ),
      ),
      GoRoute(
        path: AuthPaths.legal,
        builder: (context, state) {
          final code = state.pathParameters['kind'];
          final kind = LegalKind.values.firstWhere(
            (k) => k.value == code,
            orElse: () => LegalKind.terms,
          );
          return LegalDocumentScreen(kind: kind);
        },
      ),
    ],
  );
}
