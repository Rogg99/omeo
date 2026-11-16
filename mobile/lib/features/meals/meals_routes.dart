import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/meals_paths.dart';
import 'package:omeo/features/meals/presentation/add_meal_sheet.dart';
import 'package:omeo/features/meals/presentation/analysis_screen.dart';
import 'package:omeo/features/meals/presentation/camera_screen.dart';
import 'package:omeo/features/meals/presentation/catalog_screen.dart';
import 'package:omeo/features/meals/presentation/describe_meal_screen.dart';
import 'package:omeo/features/meals/presentation/dish_screen.dart';
import 'package:omeo/features/meals/presentation/meal_detail_screen.dart';
import 'package:omeo/features/meals/presentation/meal_saved_screen.dart';
import 'package:omeo/features/meals/presentation/offline_banner.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';
import 'package:omeo_api/omeo_api.dart' show MealWriteResult;

/// Ouvre l'analyse d'une photo à la place de l'écran courant.
void _analyze(BuildContext context, AnalysisRequest request) =>
    context.pushReplacement(MealsPaths.analysis, extra: request);

Future<void> _pickFromGallery(BuildContext context) async {
  final bytes = await pickMealPhotoFromGallery();
  if (bytes != null && context.mounted) {
    unawaited(context.push(MealsPaths.analysis, extra: PhotoRequest(bytes)));
  }
}

/// Repas mis en attente du réseau : retour à l'accueil avec un message.
void _queued(BuildContext context) {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  context.go(TrackingPaths.home);
  messenger.showSnackBar(SnackBar(content: Text(l.appMealOfflineQueued)));
}

/// Routes du module des repas et action centrale « + » de la barre.
FeatureRoutes mealsRoutes(Ref ref) {
  // Le rejeu des repas en attente doit être prêt dès le démarrage.
  ref.read(mealWriterProvider);
  return FeatureRoutes(
    shellBanner: const OfflineBanner(),
    routes: [
      GoRoute(
        path: MealsPaths.camera,
        builder: (context, state) => CameraScreen(
          navigation: (
            onPhoto: (bytes) => _analyze(context, PhotoRequest(bytes)),
            onClose: context.pop,
            onVoice: () => context.pushReplacement(MealsPaths.describe),
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
            onSearchCatalog: () => context.pushReplacement(MealsPaths.catalog),
          ),
        ),
      ),
      GoRoute(
        path: MealsPaths.catalog,
        builder: (context, state) => CatalogScreen(
          onClose: context.pop,
          onDish: (dish) => unawaited(context.push(MealsPaths.dishOf(dish.id))),
        ),
      ),
      GoRoute(
        path: MealsPaths.dish,
        builder: (context, state) => DishScreen(
          dishId: state.pathParameters['id']!,
          navigation: (
            onClose: context.pop,
            onSaved: (result) =>
                context.pushReplacement(MealsPaths.saved, extra: result),
            onQueued: () => _queued(context),
            openRecipe: null,
          ),
        ),
      ),
      GoRoute(
        path: MealsPaths.describe,
        builder: (context, state) => DescribeMealScreen(
          onClose: context.pop,
          onAnalyze: (text) => _analyze(context, TextRequest(text)),
        ),
      ),
      GoRoute(
        path: MealsPaths.saved,
        redirect: (context, state) =>
            state.extra is MealWriteResult ? null : TrackingPaths.home,
        builder: (context, state) => MealSavedScreen(
          result: state.extra! as MealWriteResult,
          onDone: () => context.go(TrackingPaths.home),
        ),
      ),
      GoRoute(
        path: MealsPaths.meal,
        builder: (context, state) => MealDetailScreen(
          mealId: state.pathParameters['id']!,
          onBack: context.pop,
        ),
      ),
    ],
    onAddMeal: (context) => unawaited(
      showAddMealSheet(
        context,
        actions: (
          takePhoto: () => unawaited(context.push(MealsPaths.camera)),
          pickFromGallery: () => unawaited(_pickFromGallery(context)),
          describe: () => unawaited(context.push(MealsPaths.describe)),
          searchCatalog: () => unawaited(context.push(MealsPaths.catalog)),
        ),
      ),
    ),
  );
}
