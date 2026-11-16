import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/activity/data/activity_repository.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/activity_mock_repository.dart';

/// Dépôts simulés du module activité.
List<Override> activityMockOverrides() => [
  activityRepositoryProvider.overrideWith(
    (ref) => ActivityMockRepository(ref.watch(mockBackendProvider)),
  ),
];
