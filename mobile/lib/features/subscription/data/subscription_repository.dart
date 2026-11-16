import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Preuve d'achat renvoyée par le store, vérifiée par l'API.
sealed class StoreReceipt {
  const StoreReceipt();
}

/// Google Play : identifiant du produit et jeton d'achat.
final class GooglePlayReceipt extends StoreReceipt {
  const GooglePlayReceipt({
    required this.productId,
    required this.purchaseToken,
  });
  final String productId;
  final String purchaseToken;
}

/// App Store (StoreKit 2) : transaction signée.
final class AppStoreReceipt extends StoreReceipt {
  const AppStoreReceipt(this.signedTransaction);
  final String signedTransaction;
}

/// Abonnement Omeo Plus et parrainage. L'état de l'abonnement est toujours
/// celui calculé par l'API.
abstract interface class SubscriptionRepository {
  Future<PlanCatalog> listPlans();

  Future<SubscriptionState> getSubscription();

  /// POST /me/subscription/verify, avant de terminer l'achat côté store.
  Future<SubscriptionState> verifyPurchase(
    StoreReceipt receipt, {
    required String idempotencyKey,
  });

  Future<SubscriptionState> restorePurchases(List<StoreReceipt> receipts);

  Future<ListPayments200Response> listPayments({String? cursor});

  /// Portail de gestion d'un abonnement pris sur le site.
  Future<String> billingPortalUrl({required String returnUrl});

  Future<ReferralOverview> getReferral();
}

/// Implémentation sur l'API réelle.
final class SubscriptionApiRepository implements SubscriptionRepository {
  const SubscriptionApiRepository(this._api);

  final OmeoApi _api;

  BillingApi get _billing => _api.getBillingApi();

  @override
  Future<PlanCatalog> listPlans() => guardApi(_billing.listPlans);

  @override
  Future<SubscriptionState> getSubscription() =>
      guardApi(_billing.getSubscription);

  // Le client généré fusionne mal le oneOf du corps : chaque variante est
  // envoyée avec son propre modèle, sur le client configuré.
  @override
  Future<SubscriptionState> verifyPurchase(
    StoreReceipt receipt, {
    required String idempotencyKey,
  }) async {
    final body = switch (receipt) {
      GooglePlayReceipt(:final productId, :final purchaseToken) =>
        GooglePlayPurchaseInput(
          channel: GooglePlayPurchaseInputChannelEnum.googlePlay,
          productId: productId,
          purchaseToken: purchaseToken,
        ).toJson(),
      AppStoreReceipt(:final signedTransaction) => AppStorePurchaseInput(
        channel: AppStorePurchaseInputChannelEnum.appStore,
        signedTransaction: signedTransaction,
      ).toJson(),
    };
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/me/subscription/verify',
        data: body,
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
          extra: {
            'secure': [
              {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
            ],
          },
        ),
      );
      return SubscriptionState.fromJson(response.data!);
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  @override
  Future<SubscriptionState> restorePurchases(List<StoreReceipt> receipts) {
    final apple = receipts.whereType<AppStoreReceipt>().toList();
    return guardApi(
      () => _billing.restorePurchases(
        restorePurchasesRequest: RestorePurchasesRequest(
          channel: apple.isEmpty
              ? RestorePurchasesRequestChannelEnum.googlePlay
              : RestorePurchasesRequestChannelEnum.appStore,
          receipts: [
            for (final r in receipts)
              switch (r) {
                GooglePlayReceipt(:final purchaseToken) => purchaseToken,
                AppStoreReceipt(:final signedTransaction) => signedTransaction,
              },
          ],
        ),
      ),
    );
  }

  @override
  Future<ListPayments200Response> listPayments({String? cursor}) =>
      guardApi(() => _billing.listPayments(cursor: cursor));

  @override
  Future<String> billingPortalUrl({required String returnUrl}) async =>
      (await guardApi(
        () => _billing.createBillingPortal(
          createBillingPortalRequest: CreateBillingPortalRequest(
            returnUrl: returnUrl,
          ),
        ),
      )).url;

  @override
  Future<ReferralOverview> getReferral() => guardApi(_billing.getReferral);
}

/// Dépôt de l'abonnement. Le flavor mock le remplace par sa version simulée.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionApiRepository(ref.watch(omeoApiProvider)),
);
