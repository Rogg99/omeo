import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/features/subscription/presentation/payments_screen.dart';
import 'package:omeo/features/subscription/presentation/subscription_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';
import 'package:omeo/mock/services/fake_store_billing.dart';

final _taps = <String>[];

Widget _app(MockScenario scenario, Widget home) {
  final backend = MockBackend(latency: Duration.zero, scenario: scenario);
  return ProviderScope(
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
      home: home,
    ),
  );
}

final SubscriptionScreen _screen = SubscriptionScreen(
  navigation: (
    onBack: () => _taps.add('back'),
    onPayments: () => _taps.add('payments'),
    onDiscoverPlus: () => _taps.add('plus'),
    onReferral: () => _taps.add('referral'),
    onManageStore: () => _taps.add('store'),
    onManageWeb: () => _taps.add('web'),
  ),
);

void main() {
  setUp(_taps.clear);

  testWidgets('Plus actif : offre, quotas et gestion dans le store', (
    tester,
  ) async {
    await tester.pumpWidget(_app(MockScenario.plus, _screen));
    await tester.pumpAndSettle();
    expect(find.text('Plus annuel'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);
    expect(find.textContaining('Renouvellement le'), findsOneWidget);
    expect(find.text('98 / 140'), findsOneWidget);
    expect(find.text('14 jours de parrainage en attente'), findsOneWidget);
    await tester.tap(find.text('Gérer dans Google Play'));
    await tester.tap(find.text('Historique des paiements'));
    expect(_taps, ['store', 'payments']);
  });

  testWidgets('paiement en échec : bannière et correction sur le site', (
    tester,
  ) async {
    await tester.pumpWidget(_app(MockScenario.plusGrace, _screen));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("Ton paiement n'est pas passé."),
      findsOneWidget,
    );
    expect(find.text('Période de grâce'), findsOneWidget);
    await tester.tap(find.text('Mettre à jour sur my-omeo.app'));
    expect(_taps, ['web']);
    expect(find.textContaining('Abonnement pris sur le site'), findsOneWidget);
  });

  testWidgets('sans abonnement : invitation à découvrir Plus', (tester) async {
    await tester.pumpWidget(_app(MockScenario.free, _screen));
    await tester.pumpAndSettle();
    expect(find.text("Tu n'as pas d'abonnement"), findsOneWidget);
    await tester.tap(find.text('Découvrir Omeo Plus'));
    expect(_taps, ['plus']);
  });

  testWidgets('paiements : tous canaux, remboursement signalé', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MockScenario.plus,
        PaymentsScreen(onBack: () {}, onReceipt: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plus annuel · Google Play'), findsOneWidget);
    expect(find.text('Plus mensuel · Site web'), findsOneWidget);
    expect(find.text('Remboursé'), findsOneWidget);
    expect(find.text(r'46,99 $'), findsOneWidget);
  });
}
