import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/auth_paths.dart';
import 'package:omeo/features/auth/auth_routes.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';
import 'package:omeo/features/auth/presentation/consent_screens.dart';
import 'package:omeo/features/onboarding/onboarding_paths.dart';
import 'package:omeo/features/profile/application/app_settings.dart';
import 'package:omeo/features/support/support_paths.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';

const _loaded = AppSettings(languageCode: 'fr', loaded: true);

String? _redirect(
  String location, {
  SessionStatus session = SessionStatus.signedIn,
  AppSettings settings = _loaded,
}) => sessionRedirect(
  session: session,
  settings: settings,
  uri: Uri.parse(location),
);

void main() {
  group('garde de session', () {
    test(
      'démarrage tant que la session est inconnue, avec le lien demandé',
      () {
        final target = _redirect('/journal', session: SessionStatus.unknown);
        expect(Uri.parse(target!).path, AuthPaths.start);
        expect(Uri.parse(target).queryParameters['from'], '/journal');
        expect(
          _redirect('/', settings: const AppSettings()),
          startsWith(AuthPaths.start),
        );
      },
    );

    test('sans session : choix de la langue au premier lancement', () {
      expect(
        _redirect(
          AuthPaths.start,
          session: SessionStatus.signedOut,
          settings: const AppSettings(loaded: true),
        ),
        AuthPaths.language,
      );
      expect(
        _redirect(TrackingPaths.home, session: SessionStatus.signedOut),
        AuthPaths.welcome,
      );
    });

    test('sans session : écrans publics et onboarding accessibles', () {
      for (final path in [
        AuthPaths.login,
        AuthPaths.forgotPassword,
        OnboardingPaths.stepOf(3),
        AuthPaths.legalOf('terms'),
      ]) {
        expect(_redirect(path, session: SessionStatus.signedOut), isNull);
      }
    });

    test('sans session : un lien de réinitialisation est conservé', () {
      const link = '${AuthPaths.resetPassword}?token=abc';
      expect(
        _redirect(
          '${AuthPaths.start}?from=${Uri.encodeQueryComponent(link)}',
          session: SessionStatus.signedOut,
        ),
        link,
      );
    });

    test('connecté : écrans publics renvoyés vers l’accueil', () {
      expect(_redirect(AuthPaths.login), TrackingPaths.home);
      expect(_redirect(OnboardingPaths.stepOf(2)), TrackingPaths.home);
      expect(_redirect(AuthPaths.start), TrackingPaths.home);
    });

    test('connecté : fin de l’inscription et lien profond conservés', () {
      expect(_redirect(OnboardingPaths.computing), isNull);
      expect(_redirect(OnboardingPaths.ready), isNull);
      expect(_redirect('${AuthPaths.start}?from=%2Fjournal'), '/journal');
    });

    test('écrans bloquants toujours accessibles', () {
      for (final s in SessionStatus.values) {
        expect(_redirect(SupportPaths.upgrade, session: s), isNull);
        expect(_redirect(SupportPaths.suspended, session: s), isNull);
      }
    });
  });

  group('règles du mot de passe', () {
    test('chaque règle séparément', () {
      expect(PasswordRules.longEnough('abcdefghij'), isTrue);
      expect(PasswordRules.longEnough('abcdefghi'), isFalse);
      expect(PasswordRules.mixedCase('abcD'), isTrue);
      expect(PasswordRules.mixedCase('abcd'), isFalse);
      expect(PasswordRules.hasDigit('a1'), isTrue);
      expect(PasswordRules.hasSpecial('abc!'), isTrue);
      expect(PasswordRules.hasSpecial('abc1'), isFalse);
    });

    test('toutes réunies', () {
      expect(PasswordRules.allMet('Omeo2026!x'), isTrue);
      expect(PasswordRules.allMet('omeo2026!x'), isFalse);
    });
  });

  test('document légal découpé en titres et paragraphes', () {
    final blocks = markdownBlocks('# Titre\n\nTexte **gras**.\n\n- a\n- b');
    expect(blocks, hasLength(3));
    expect(blocks[0], (heading: true, text: 'Titre'));
    expect(blocks[1].text, 'Texte gras.');
    expect(blocks[2].text, '• a\n• b');
  });
}
