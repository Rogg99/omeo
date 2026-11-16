import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Délai pendant lequel une suppression peut être annulée (SYS-07).
const undoDelay = Duration(seconds: 5);

/// Repas affiché dans son détail (GET /me/meals/{id}).
// Le type d'une famille de providers n'est pas exporté par Riverpod 3.
// ignore: specify_nonobvious_property_types
final mealProvider = FutureProvider.autoDispose.family<Meal, String>(
  (ref, id) => ref.watch(mealsRepositoryProvider).getMeal(id),
);

/// Repas dont la suppression attend la fin du délai d'annulation. Le journal
/// les masque sans attendre l'API.
class PendingMealDeletions extends Notifier<Set<String>> {
  final _timers = <String, Timer>{};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return const {};
  }

  /// Programme la suppression ; [onDeleted] reçoit le jour recalculé.
  void schedule(String mealId, {void Function(DaySummary day)? onDeleted}) {
    state = {...state, mealId};
    _timers[mealId] = Timer(undoDelay, () async {
      _timers.remove(mealId);
      try {
        final day = await ref.read(mealsRepositoryProvider).deleteMeal(mealId);
        onDeleted?.call(day);
      } on ApiFailure catch (e) {
        ref.read(globalErrorBusProvider).report(e);
      } finally {
        state = {...state}..remove(mealId);
      }
    });
  }

  /// Annule une suppression encore en attente.
  void undo(String mealId) {
    _timers.remove(mealId)?.cancel();
    state = {...state}..remove(mealId);
  }
}

final NotifierProvider<PendingMealDeletions, Set<String>>
pendingMealDeletionsProvider = NotifierProvider(PendingMealDeletions.new);

/// Gestion d'un repas du journal.
class MealActions {
  MealActions(this._repo);

  final MealsRepository _repo;
  static const _uuid = Uuid();

  Future<MealWriteResult> move(
    String id, {
    required MealType mealType,
    required DateTime date,
  }) => _repo.updateMeal(id, MealUpdate(mealType: mealType, date: date));

  Future<MealWriteResult> duplicate(
    String id, {
    required MealType mealType,
    required DateTime date,
  }) => _repo.duplicateMeal(
    id,
    target: DuplicateMealRequest(date: date, mealType: mealType),
    idempotencyKey: _uuid.v4(),
  );

  Future<void> deletePhoto(String id) => _repo.deleteMealPhoto(id);
}

final Provider<MealActions> mealActionsProvider = Provider(
  (ref) => MealActions(ref.watch(mealsRepositoryProvider)),
);
