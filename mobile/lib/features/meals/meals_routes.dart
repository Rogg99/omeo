import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/meals/presentation/add_meal_sheet.dart';

/// Routes du module des repas et action centrale « + » de la barre.
FeatureRoutes mealsRoutes(Ref ref) => FeatureRoutes(
  onAddMeal: (context) => unawaited(
    showAddMealSheet(
      context,
      actions: (
        takePhoto: null,
        pickFromGallery: null,
        describe: null,
        searchCatalog: null,
      ),
    ),
  ),
);
