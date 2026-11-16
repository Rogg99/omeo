import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/features/subscription/presentation/paywall_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';
import 'package:omeo/mock/services/fake_store_billing.dart';

Widget _app(
  MockBackend backend, {
  required VoidCallback onClose,
  required VoidCallback onSubscribed,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    subscriptionRepositoryProvider.overrideWithValue(
      SubscriptionMockRepository(backend),
    ),
    storeBillingProvider.overrideWithValue(FakeStoreBilling(backend)),
  ],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OmeoTheme.light(),
    home: PaywallScreen(onClose: onClose, onSubscribed: onSubscribed),
  ),
);

void main() {
  testWidgets('essai : jours restants, annuel mis en avant, bénéfices', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MockBackend(latency: Duration.zero),
        onClose: () {},
        onSubscribed: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Essai gratuit'), findsOneWidget);
    expect(find.text('2 jours restants'), findsOneWidget);
    expect(find.text('Meilleure offre'), findsOneWidget);
    expect(find.textContaining('économise 13 %'), findsOneWidget);
    expect(find.text(r'Continuer · 46,99 $ / an'), findsOneWidget);
    expect(find.text('Toutes les recettes'), findsOneWidget);
  });

  testWidgets('choisir le mensuel puis acheter', (tester) async {
    var subscribed = 0;
    await tester.pumpWidget(
      _app(
        MockBackend(latency: Duration.zero, scenario: MockScenario.free),
        onClose: () {},
        onSubscribed: () => subscribed++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu es en Free'), findsOneWidget);
    await tester.tap(find.text('Mensuel'));
    await tester.pump();
    await tester.tap(find.text(r'Continuer · 4,49 $ / mois'));
    await tester.pumpAndSettle();
    expect(subscribed, 1);
    expect(find.text('Bienvenue dans Omeo Plus !'), findsOneWidget);
  });

  testWidgets('restaurer sans achat, puis rester en Free', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      _app(
        MockBackend(latency: Duration.zero),
        onClose: () => closed++,
        onSubscribed: () {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Restaurer mes achats'));
    await tester.tap(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucun achat à restaurer avec ce compte.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Rester en Free'));
    expect(closed, 1);
  });
}
