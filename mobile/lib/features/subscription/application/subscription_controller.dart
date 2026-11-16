import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// État de l'abonnement, tel que calculé par l'API.
final FutureProvider<SubscriptionState> subscriptionProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(subscriptionRepositoryProvider).getSubscription(),
    );

/// Offres, avec le prix affiché par le store quand il est connu.
typedef PlanOffer = ({PlanCatalogPlansInner plan, String? storePrice});

/// Identifiant du produit store d'une offre, selon la plateforme.
String? storeProductId(PlanCatalogPlansInner plan) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? plan.storeProductIds?.apple
    : plan.storeProductIds?.google;

final FutureProvider<List<PlanOffer>> planOffersProvider =
    FutureProvider.autoDispose((ref) async {
      final catalog = await ref
          .watch(subscriptionRepositoryProvider)
          .listPlans();
      final ids = {
        for (final p in catalog.plans) ?storeProductId(p),
      };
      // Sans store (émulateur, store indisponible), le prix de l'API reste.
      List<StoreProduct> products;
      try {
        products = await ref.watch(storeBillingProvider).products(ids);
      } on StoreBillingException {
        products = const [];
      }
      return [
        for (final p in catalog.plans)
          (
            plan: p,
            storePrice: products
                .where((s) => s.id == storeProductId(p))
                .map((s) => s.price)
                .firstOrNull,
          ),
      ];
    });

/// Issue d'un achat ou d'une restauration.
enum PurchaseOutcome { plus, cancelled, nothingToRestore }

/// Achat et restauration : le store encaisse, l'API vérifie, et l'achat
/// n'est terminé auprès du store qu'après la réponse de l'API.
class PurchaseActions {
  PurchaseActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  StoreBilling get _billing => _ref.read(storeBillingProvider);
  SubscriptionRepository get _repo => _ref.read(subscriptionRepositoryProvider);

  Future<PurchaseOutcome> buy(PlanCatalogPlansInner plan) async {
    final productId = storeProductId(plan);
    if (productId == null) {
      throw const StoreBillingException('unknown_product');
    }
    final purchase = await _billing.buy(productId);
    if (purchase == null) return PurchaseOutcome.cancelled;
    await _verifyThenComplete(purchase);
    return PurchaseOutcome.plus;
  }

  Future<PurchaseOutcome> restore() async {
    final purchases = await _billing.restore();
    if (purchases.isEmpty) return PurchaseOutcome.nothingToRestore;
    final state = await _guard(
      () => _repo.restorePurchases([for (final p in purchases) p.receipt]),
    );
    for (final p in purchases) {
      await _billing.complete(p);
    }
    _ref.invalidate(subscriptionProvider);
    return state.entitlements.tier == PlanTier.plus
        ? PurchaseOutcome.plus
        : PurchaseOutcome.nothingToRestore;
  }

  Future<void> _verifyThenComplete(StorePurchase purchase) async {
    await _guard(
      () => _repo.verifyPurchase(
        purchase.receipt,
        idempotencyKey: _uuid.v4(),
      ),
    );
    await _billing.complete(purchase);
    _ref.invalidate(subscriptionProvider);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiFailure catch (e) {
      _ref.read(globalErrorBusProvider).report(e);
      rethrow;
    }
  }
}

final Provider<PurchaseActions> purchaseActionsProvider = Provider(
  PurchaseActions.new,
);

/// Parrainage (GET /me/referral).
final FutureProvider<ReferralOverview> referralProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(subscriptionRepositoryProvider).getReferral(),
    );

/// Historique des paiements, tous canaux confondus.
final FutureProvider<List<Payment>>
paymentsProvider = FutureProvider.autoDispose(
  (ref) async =>
      (await ref.watch(subscriptionRepositoryProvider).listPayments()).results,
);
