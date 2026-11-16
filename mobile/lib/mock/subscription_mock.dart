import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';
import 'package:omeo/mock/services/fake_store_billing.dart';

/// Dépôts simulés du module abonnement et parrainage.
List<Override> subscriptionMockOverrides() => [
  subscriptionRepositoryProvider.overrideWith(
    (ref) => SubscriptionMockRepository(ref.watch(mockBackendProvider)),
  ),
  storeBillingProvider.overrideWith(
    (ref) => FakeStoreBilling(ref.watch(mockBackendProvider)),
  ),
];
