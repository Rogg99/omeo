import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/training_mock_repository.dart';

/// Dépôts simulés du module séances.
List<Override> trainingMockOverrides() => [
  trainingRepositoryProvider.overrideWith(
    (ref) => TrainingMockRepository(ref.watch(mockBackendProvider)),
  ),
];
