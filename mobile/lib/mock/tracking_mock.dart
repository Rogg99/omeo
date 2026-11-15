import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/home_mock_repository.dart';

/// Dépôts simulés du module de suivi.
List<Override> trackingMockOverrides() => [
  homeRepositoryProvider.overrideWith(
    (ref) => HomeMockRepository(ref.watch(mockBackendProvider)),
  ),
];
