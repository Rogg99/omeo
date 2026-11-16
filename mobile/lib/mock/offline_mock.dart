import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/mock/mock_backend_provider.dart';

/// File d'attente du flavor mock : la base locale reste réelle, mais l'état
/// du réseau suit la coupure simulée (scénario « hors connexion »).
List<Override> offlineMockOverrides() => [
  connectivityProvider.overrideWith((ref) async* {
    final backend = ref.watch(mockBackendProvider);
    yield !backend.isOffline;
    yield* backend.changes.map((_) => !backend.isOffline).distinct();
  }),
];
