import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/subscription/application/subscription_controller.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

final _log = <String>[];

/// Store de test : journalise l'ordre des appels.
class _SpyBilling implements StoreBilling {
  _SpyBilling({this.cancel = false, this.token = 'token'});

  final bool cancel;
  final String token;

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => [
    for (final id in ids) (id: id, price: '50 000 FCFA'),
  ];

  @override
  Future<StorePurchase?> buy(String productId) async {
    _log.add('buy');
    return cancel
        ? null
        : StorePurchase(
            receipt: GooglePlayReceipt(
              productId: productId,
              purchaseToken: token,
            ),
            handle: null,
          );
  }

  @override
  Future<void> complete(StorePurchase purchase) async => _log.add('complete');

  @override
  Future<List<StorePurchase>> restore() async => const [];
}

/// Dépôt simulé qui journalise la vérification.
final class _SpyRepo implements SubscriptionRepository {
  _SpyRepo(this._inner);
  final SubscriptionMockRepository _inner;

  @override
  Future<SubscriptionState> verifyPurchase(
    StoreReceipt receipt, {
    required String idempotencyKey,
  }) {
    _log.add('verify');
    return _inner.verifyPurchase(receipt, idempotencyKey: idempotencyKey);
  }

  @override
  Future<PlanCatalog> listPlans() => _inner.listPlans();

  @override
  Future<SubscriptionState> getSubscription() => _inner.getSubscription();

  @override
  Future<SubscriptionState> restorePurchases(List<StoreReceipt> receipts) =>
      _inner.restorePurchases(receipts);

  @override
  Future<ListPayments200Response> listPayments({String? cursor}) =>
      _inner.listPayments();

  @override
  Future<String> billingPortalUrl({required String returnUrl}) =>
      _inner.billingPortalUrl(returnUrl: returnUrl);

  @override
  Future<ReferralOverview> getReferral() => _inner.getReferral();
}

ProviderContainer _container(StoreBilling billing) {
  final repo = _SpyRepo(
    SubscriptionMockRepository(
      MockBackend(latency: Duration.zero, scenario: MockScenario.free),
    ),
  );
  final c = ProviderContainer(
    overrides: [
      storeBillingProvider.overrideWithValue(billing),
      subscriptionRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(_log.clear);

  test("l'achat n'est terminé qu'après la vérification par l'API", () async {
    final c = _container(_SpyBilling());
    final annual = (await c.read(planOffersProvider.future)).first.plan;
    final outcome = await c.read(purchaseActionsProvider).buy(annual);
    expect(outcome, PurchaseOutcome.plus);
    expect(_log, ['buy', 'verify', 'complete']);
  });

  test('renoncement : rien n’est vérifié ni terminé', () async {
    final c = _container(_SpyBilling(cancel: true));
    final annual = (await c.read(planOffersProvider.future)).first.plan;
    expect(
      await c.read(purchaseActionsProvider).buy(annual),
      PurchaseOutcome.cancelled,
    );
    expect(_log, ['buy']);
  });

  test("refus de l'API : l'achat n'est pas terminé", () async {
    final c = _container(_SpyBilling(token: ''));
    final annual = (await c.read(planOffersProvider.future)).first.plan;
    await expectLater(
      c.read(purchaseActionsProvider).buy(annual),
      throwsA(isA<ProblemFailure>()),
    );
    expect(_log, ['buy', 'verify']);
  });

  test('le prix du store remplace celui de l’API', () async {
    final c = _container(_SpyBilling());
    final offers = await c.read(planOffersProvider.future);
    expect(offers.first.storePrice, '50 000 FCFA');
  });

  test('restauration sans achat', () async {
    final c = _container(_SpyBilling());
    expect(
      await c.read(purchaseActionsProvider).restore(),
      PurchaseOutcome.nothingToRestore,
    );
  });
}
