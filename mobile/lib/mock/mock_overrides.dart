import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/api/token_store.dart';
import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/home_mock_repository.dart';

/// Faux serveur partagé par tous les dépôts simulés de la session.
final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend();
  ref.onDispose(backend.dispose);
  return backend;
});

/// Surcharges du flavor mock : chaque dépôt devient sa version simulée.
List<Override> mockOverrides() => [
  tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
  homeRepositoryProvider.overrideWith(
    (ref) => HomeMockRepository(ref.watch(mockBackendProvider)),
  ),
];
