import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/mock/fixtures/subscription_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';

/// Achats simulés (flavor mock) : prix des maquettes, achat accepté après la
/// latence simulée, restauration selon les achats de la session.
final class FakeStoreBilling implements StoreBilling {
  FakeStoreBilling(this._backend);

  final MockBackend _backend;
  final _bought = <String>{};

  static const Map<String, String> _prices = {
    annualProductGoogle: r'46,99 $',
    annualProductApple: r'46,99 $',
    monthlyProductGoogle: r'4,49 $',
    monthlyProductApple: r'4,49 $',
  };

  StorePurchase _purchase(String productId) => StorePurchase(
    receipt: GooglePlayReceipt(
      productId: productId,
      purchaseToken: 'mock-token-$productId',
    ),
    handle: null,
  );

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    await Future<void>.delayed(_backend.latency);
    return [
      for (final id in ids)
        if (_prices[id] != null) (id: id, price: _prices[id]!),
    ];
  }

  @override
  Future<StorePurchase?> buy(String productId) async {
    await Future<void>.delayed(_backend.latency * 2);
    _bought.add(productId);
    return _purchase(productId);
  }

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<List<StorePurchase>> restore() async {
    await Future<void>.delayed(_backend.latency);
    return [for (final id in _bought) _purchase(id)];
  }
}
