import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/meals/meals_paths.dart';
import 'package:omeo/features/meals/presentation/add_meal_sheet.dart';
import 'package:omeo/features/meals/presentation/analysis_screen.dart';
import 'package:omeo/features/meals/presentation/camera_screen.dart';

/// Ouvre l'analyse d'une photo à la place de l'écran courant.
void _analyze(BuildContext context, AnalysisRequest request) =>
    context.pushReplacement(MealsPaths.analysis, extra: request);

Future<void> _pickFromGallery(BuildContext context) async {
  final bytes = await pickMealPhotoFromGallery();
  if (bytes != null && context.mounted) {
    unawaited(context.push(MealsPaths.analysis, extra: PhotoRequest(bytes)));
  }
}

/// Routes du module des repas et action centrale « + » de la barre.
FeatureRoutes mealsRoutes(Ref ref) => FeatureRoutes(
  routes: [
    GoRoute(
      path: MealsPaths.camera,
      builder: (context, state) => CameraScreen(
        navigation: (
          onPhoto: (bytes) => _analyze(context, PhotoRequest(bytes)),
          onClose: context.pop,
          onVoice: null,
        ),
      ),
    ),
    GoRoute(
      path: MealsPaths.analysis,
      redirect: (context, state) =>
          state.extra is AnalysisRequest ? null : MealsPaths.camera,
      builder: (context, state) => AnalysisScreen(
        request: state.extra! as AnalysisRequest,
        navigation: (
          onSucceeded: (_) => context.pop(),
          onClose: context.pop,
          onRetake: () => context.pushReplacement(MealsPaths.camera),
          onSearchCatalog: null,
        ),
      ),
    ),
  ],
  onAddMeal: (context) => unawaited(
    showAddMealSheet(
      context,
      actions: (
        takePhoto: () => unawaited(context.push(MealsPaths.camera)),
        pickFromGallery: () => unawaited(_pickFromGallery(context)),
        describe: null,
        searchCatalog: null,
      ),
    ),
  ),
);
