import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/mock/fixtures/subscription_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo_api/omeo_api.dart';

/// Abonnement simulé : l'état suit le scénario, puis passe en Plus après un
/// achat vérifié ou une restauration.
final class SubscriptionMockRepository implements SubscriptionRepository {
  const SubscriptionMockRepository(this._backend);

  final MockBackend _backend;

  static const _purchasedKey = 'subscription.purchased';

  SubscriptionVariant get _variant {
    if (_backend.state[_purchasedKey] == true) {
      return SubscriptionVariant.plusStore;
    }
    return switch (_backend.scenario) {
      MockScenario.free ||
      MockScenario.quotaExhausted => SubscriptionVariant.free,
      MockScenario.plus => SubscriptionVariant.plusStore,
      MockScenario.plusGrace => SubscriptionVariant.grace,
      _ => SubscriptionVariant.trial,
    };
  }

  @override
  Future<PlanCatalog> listPlans() => _backend.call(planCatalogFixture);

  @override
  Future<SubscriptionState> getSubscription() =>
      _backend.call(() => subscriptionFixture(_variant));

  @override
  Future<SubscriptionState> verifyPurchase(
    StoreReceipt receipt, {
    required String idempotencyKey,
  }) => _backend.call(() {
    final valid = switch (receipt) {
      GooglePlayReceipt(:final purchaseToken) => purchaseToken.isNotEmpty,
      AppStoreReceipt(:final signedTransaction) => signedTransaction.isNotEmpty,
    };
    if (!valid) {
      throw const ProblemFailure(status: 422, code: 'invalid_receipt');
    }
    _backend.state[_purchasedKey] = true;
    return subscriptionFixture(SubscriptionVariant.plusStore);
  });

  @override
  Future<SubscriptionState> restorePurchases(List<StoreReceipt> receipts) =>
      _backend.call(() {
        if (receipts.isNotEmpty) _backend.state[_purchasedKey] = true;
        return subscriptionFixture(_variant);
      });

  @override
  Future<ListPayments200Response> listPayments({String? cursor}) =>
      _backend.call(paymentsFixture);

  @override
  Future<String> billingPortalUrl({required String returnUrl}) =>
      _backend.call(() => 'https://my-omeo.app/compte/abonnement');

  @override
  Future<ReferralOverview> getReferral() => _backend.call(referralFixture);
}
