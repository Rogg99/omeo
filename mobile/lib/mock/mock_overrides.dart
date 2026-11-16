import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/api/token_store.dart';
import 'package:omeo/mock/auth_mock.dart';
import 'package:omeo/mock/meals_mock.dart';
import 'package:omeo/mock/offline_mock.dart';
import 'package:omeo/mock/subscription_mock.dart';
import 'package:omeo/mock/tracking_mock.dart';

export 'package:omeo/mock/mock_backend_provider.dart';

/// Surcharges du flavor mock : une ligne par module (`mock/<module>_mock.dart`).
List<Override> mockOverrides() => [
  tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
  ...authMockOverrides(),
  ...trackingMockOverrides(),
  ...mealsMockOverrides(),
  ...offlineMockOverrides(),
  ...subscriptionMockOverrides(),
];
