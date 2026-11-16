import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Type d'écriture des repas dans la file d'attente hors connexion.
const mealCreateKind = 'meal.create';

/// Issue de l'enregistrement d'un repas : calculé par l'API, ou mis en
/// attente du réseau (les totaux ne changent qu'à la réponse de l'API).
sealed class MealSaveOutcome {
  const MealSaveOutcome();
}

final class MealSaved extends MealSaveOutcome {
  const MealSaved(this.result);
  final MealWriteResult result;
}

final class MealQueued extends MealSaveOutcome {
  const MealQueued(this.pending);
  final PendingWrite pending;
}

/// Enregistre les repas : envoi direct, ou file d'attente sans réseau, avec
/// la même clé d'idempotence dans les deux cas.
class MealWriter {
  MealWriter(this._repo, this._queue);

  final MealsRepository _repo;
  final OfflineQueue _queue;
  static const _uuid = Uuid();

  /// Rejoue un repas en attente.
  Future<void> replay(PendingWrite write) => _repo.createMeal(
    input: MealInput.fromJson(write.payload.cast<String, dynamic>()),
    idempotencyKey: write.idempotencyKey,
  );

  Future<MealSaveOutcome> save(MealInput input) async {
    final key = _uuid.v4();
    try {
      return MealSaved(
        await _repo.createMeal(input: input, idempotencyKey: key),
      );
    } on NetworkFailure {
      return MealQueued(await _enqueue(input, key));
    } on TimeoutFailure {
      return MealQueued(await _enqueue(input, key));
    }
  }

  Future<PendingWrite> _enqueue(MealInput input, String key) => _queue.enqueue(
    kind: mealCreateKind,
    payload: input.toJson(),
    idempotencyKey: key,
  );
}

final Provider<MealWriter> mealWriterProvider = Provider((ref) {
  final writer = MealWriter(
    ref.watch(mealsRepositoryProvider),
    ref.watch(offlineQueueProvider),
  );
  ref.watch(offlineQueueProvider).register(mealCreateKind, writer.replay);
  return writer;
});

/// Repas en attente d'envoi (bannière SYS-02, « en cours de calcul »).
final Provider<int> pendingMealsCountProvider = Provider(
  (ref) =>
      ref
          .watch(pendingWritesProvider)
          .value
          ?.where((w) => w.kind == mealCreateKind)
          .length ??
      0,
);
