import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/presentation/consent_screens.dart';
import 'package:omeo/features/auth/presentation/entry_screens.dart';
import 'package:omeo/features/auth/presentation/login_screens.dart';
import 'package:omeo/mock/fixtures/auth_fixtures.dart';

import 'auth_test_app.dart';

void main() {
  group('connexion (ACC-01, ACC-02)', () {
    testWidgets('identifiants refusés : message générique, champs gardés', (
      tester,
    ) async {
      await pumpWithMocks(
        tester,
        LoginScreen(onForgotPassword: (_) {}, onStart: () {}),
      );
      await tester.enterText(find.byType(TextField).at(0), 'awa@exemple.com');
      await tester.enterText(find.byType(TextField).at(1), 'mauvais');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email ou mot de passe incorrect'), findsOne);
      expect(find.text('awa@exemple.com'), findsOne);
    });

    testWidgets('identifiants valides : session ouverte', (tester) async {
      final container = await pumpWithMocks(
        tester,
        LoginScreen(onForgotPassword: (_) {}, onStart: () {}),
      );
      await tester.enterText(find.byType(TextField).at(0), demoEmail);
      await tester.enterText(find.byType(TextField).at(1), demoPassword);
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider), SessionStatus.signedIn);
      expect(container.read(meProvider).value?.email, demoEmail);
    });

    testWidgets('mot de passe oublié reçoit l’email saisi', (tester) async {
      String? forwarded;
      await pumpWithMocks(
        tester,
        LoginScreen(onForgotPassword: (e) => forwarded = e, onStart: () {}),
      );
      await tester.enterText(find.byType(TextField).first, ' awa@exemple.com ');
      await tester.tap(find.text('Mot de passe oublié ?'));
      expect(forwarded, 'awa@exemple.com');
    });

    testWidgets('boutons Google et Apple avec une connexion sociale', (
      tester,
    ) async {
      await pumpWithMocks(
        tester,
        LoginScreen(onForgotPassword: (_) {}, onStart: () {}),
      );
      expect(find.text('Continuer avec Google'), findsOne);
      expect(find.text('Continuer avec Apple'), findsOne);
    });
  });

  testWidgets('mot de passe oublié (ACC-03) : bouton actif avec un email', (
    tester,
  ) async {
    String? sent;
    await pumpWithMocks(tester, ForgotPasswordScreen(onSent: (e) => sent = e));
    final button = find.widgetWithText(InkWell, 'Envoyer le lien');
    expect(button, findsNothing);
    await tester.enterText(find.byType(TextField), 'awa@exemple.com');
    await tester.pump();
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();
    expect(sent, 'awa@exemple.com');
  });

  testWidgets('lien envoyé (ACC-04) : renvoi après le délai', (tester) async {
    await pumpWithMocks(
      tester,
      ResetLinkSentScreen(
        email: 'awa@exemple.com',
        onOpenMail: () {},
        resendDelay: const Duration(seconds: 2),
      ),
    );
    expect(find.text('Renvoyer dans 0:02'), findsOne);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Renvoyer le lien'), findsOne);
  });

  testWidgets('nouveau mot de passe (ACC-05) : règles et confirmation', (
    tester,
  ) async {
    var done = false;
    await pumpWithMocks(
      tester,
      ResetPasswordScreen(token: 'abc', onDone: () => done = true),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Omeo2026!x');
    await tester.enterText(find.byType(TextField).at(1), 'Omeo2026!y');
    await tester.pump();
    expect(find.textContaining('ne correspondent pas'), findsOne);
    await tester.enterText(find.byType(TextField).at(1), 'Omeo2026!x');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
  });

  testWidgets('lien expiré (ACC-05) : message dédié', (tester) async {
    await pumpWithMocks(
      tester,
      ResetPasswordScreen(token: 'expired', onDone: () {}),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Omeo2026!x');
    await tester.enterText(find.byType(TextField).at(1), 'Omeo2026!x');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ce lien a expiré'), findsOne);
  });

  testWidgets('langue (ONB-02) : arabe signalé de droite à gauche', (
    tester,
  ) async {
    String? picked;
    await pumpWithMocks(
      tester,
      Scaffold(
        body: LanguageList(selected: 'fr', onSelect: (c) => picked = c),
      ),
    );
    expect(find.text('De droite à gauche'), findsOne);
    await tester.tap(find.text('العربية'));
    expect(picked, 'ar');
  });

  testWidgets('nouvelles CGU (SYS-05) : document et acceptation', (
    tester,
  ) async {
    String? read;
    await pumpWithMocks(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ConsentSheet(
            documentKinds: const ['privacy'],
            onRead: (k) => read = k,
          ),
        ),
      ),
    );
    expect(find.text('Nos conditions évoluent'), findsOne);
    expect(find.textContaining('Politique de confidentialité'), findsWidgets);
    await tester.tap(find.textContaining('Lire'));
    expect(read, 'privacy');
    expect(find.text("J'accepte"), findsOne);
  });
}
