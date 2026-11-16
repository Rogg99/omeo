import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';

/// Dépôts simulés du module des repas.
List<Override> mealsMockOverrides() => [
  mealsRepositoryProvider.overrideWith(
    (ref) => MealsMockRepository(ref.watch(mockBackendProvider)),
  ),
];
