import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/mock/mock_backend.dart';

/// Faux serveur partagé par tous les dépôts simulés de la session.
final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend();
  ref.onDispose(backend.dispose);
  return backend;
});
