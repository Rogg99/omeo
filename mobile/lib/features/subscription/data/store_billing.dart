import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';

/// Produit vendu par le store, avec son prix dans la monnaie de l'appareil.
typedef StoreProduct = ({String id, String price});

/// Achat rendu par le store, à vérifier par l'API puis à terminer.
final class StorePurchase {
  const StorePurchase({required this.receipt, required this.handle});

  final StoreReceipt receipt;

  /// Objet natif de l'achat (null pour un achat simulé).
  final Object? handle;
}

/// Achat impossible côté store (store indisponible, paiement refusé…).
final class StoreBillingException implements Exception {
  const StoreBillingException(this.reason);
  final String reason;
}

/// Achats sur les stores (StoreKit 2 et Play Billing), derrière une
/// interface : implémentation réelle, ou simulée dans le flavor mock.
abstract interface class StoreBilling {
  /// Produits disponibles parmi [ids] (ceux inconnus du store sont ignorés).
  Future<List<StoreProduct>> products(Set<String> ids);

  /// Lance l'achat. `null` si l'utilisateur renonce.
  Future<StorePurchase?> buy(String productId);

  /// Termine l'achat auprès du store. N'est appelé qu'après la réponse de
  /// l'API (POST /me/subscription/verify).
  Future<void> complete(StorePurchase purchase);

  /// Achats déjà faits avec ce compte store.
  Future<List<StorePurchase>> restore();
}

/// Implémentation réelle (in_app_purchase).
final class DeviceStoreBilling implements StoreBilling {
  DeviceStoreBilling() {
    _subscription = _iap.purchaseStream.listen(_onUpdates);
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final _waiting = <String, Completer<StorePurchase?>>{};
  List<StorePurchase>? _restored;
  Timer? _restoreIdle;
  Completer<List<StorePurchase>>? _restoreDone;

  /// Délai sans nouvel achat restauré avant de clore la restauration.
  static const _restoreQuiet = Duration(seconds: 2);

  final _details = <String, ProductDetails>{};

  static StoreReceipt _receipt(PurchaseDetails p) =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? AppStoreReceipt(p.verificationData.serverVerificationData)
      : GooglePlayReceipt(
          productId: p.productID,
          purchaseToken: p.verificationData.serverVerificationData,
        );

  void _onUpdates(List<PurchaseDetails> updates) {
    for (final p in updates) {
      final purchase = StorePurchase(receipt: _receipt(p), handle: p);
      switch (p.status) {
        case PurchaseStatus.purchased:
          _waiting.remove(p.productID)?.complete(purchase);
        case PurchaseStatus.restored:
          final restored = _restored;
          if (restored != null) {
            restored.add(purchase);
            _restoreIdle?.cancel();
            _restoreIdle = Timer(_restoreQuiet, _finishRestore);
          } else {
            _waiting.remove(p.productID)?.complete(purchase);
          }
        case PurchaseStatus.canceled:
          _waiting.remove(p.productID)?.complete(null);
        case PurchaseStatus.error:
          _waiting
              .remove(p.productID)
              ?.completeError(
                StoreBillingException(p.error?.code ?? 'purchase_error'),
              );
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  void _finishRestore() {
    _restoreDone?.complete(_restored ?? const []);
    _restored = null;
    _restoreDone = null;
  }

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    if (!await _iap.isAvailable()) {
      throw const StoreBillingException('store_unavailable');
    }
    final response = await _iap.queryProductDetails(ids);
    for (final d in response.productDetails) {
      _details[d.id] = d;
    }
    return [
      for (final d in response.productDetails) (id: d.id, price: d.price),
    ];
  }

  @override
  Future<StorePurchase?> buy(String productId) async {
    final details = _details[productId];
    if (details == null) {
      throw const StoreBillingException('unknown_product');
    }
    final completer = _waiting[productId] = Completer<StorePurchase?>();
    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
    if (!started) _waiting.remove(productId)?.complete(null);
    return completer.future;
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final handle = purchase.handle;
    if (handle is PurchaseDetails && handle.pendingCompletePurchase) {
      await _iap.completePurchase(handle);
    }
  }

  @override
  Future<List<StorePurchase>> restore() {
    _restored = [];
    final done = _restoreDone = Completer<List<StorePurchase>>();
    _restoreIdle = Timer(_restoreQuiet, _finishRestore);
    unawaited(_iap.restorePurchases());
    return done.future;
  }

  Future<void> dispose() => _subscription.cancel();
}

/// Achats sur le store. Le flavor mock les simule.
final storeBillingProvider = Provider<StoreBilling>((ref) {
  final billing = DeviceStoreBilling();
  ref.onDispose(billing.dispose);
  return billing;
});
