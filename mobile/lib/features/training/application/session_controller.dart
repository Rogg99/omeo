import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Secondes ajoutées par « +10 s » pendant un repos.
const restExtension = 10;

/// Étape du lecteur : un exercice ou un repos.
enum PhaseKind { exercise, rest }

@immutable
final class SessionPhase {
  const SessionPhase({
    required this.kind,
    required this.step,
    required this.stepIndex,
    this.durationS,
  });

  final PhaseKind kind;

  /// Exercice en cours, ou exercice qui suit pendant un repos.
  final WorkoutDetailAllOfSteps step;
  final int stepIndex;

  /// Durée minutée ; `null` pour un exercice en répétitions (l'utilisateur
  /// passe à la suite quand il a fini).
  final int? durationS;
}

/// Construit l'enchaînement : chaque exercice, suivi de son repos (sauf le
/// dernier).
List<SessionPhase> buildPhases(List<WorkoutDetailAllOfSteps> steps) {
  final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final (i, step) in sorted.indexed) ...[
      SessionPhase(
        kind: PhaseKind.exercise,
        step: step,
        stepIndex: i,
        durationS: step.mode == WorkoutDetailAllOfStepsModeEnum.time
            ? step.durationS
            : null,
      ),
      if (step.restS > 0 && i < sorted.length - 1)
        SessionPhase(
          kind: PhaseKind.rest,
          step: sorted[i + 1],
          stepIndex: i + 1,
          durationS: step.restS,
        ),
    ],
  ];
}

/// Signal sonore et vibration à chaque changement d'étape.
abstract interface class SessionCues {
  Future<void> phaseChanged({required bool sound});
}

final class DeviceSessionCues implements SessionCues {
  const DeviceSessionCues();

  @override
  Future<void> phaseChanged({required bool sound}) async {
    await HapticFeedback.heavyImpact();
    if (sound) await SystemSound.play(SystemSoundType.alert);
  }
}

final sessionCuesProvider = Provider<SessionCues>(
  (ref) => const DeviceSessionCues(),
);

@immutable
final class SessionState {
  const SessionState({
    required this.phases,
    required this.index,
    required this.remaining,
    required this.paused,
    required this.sound,
    required this.startedAt,
    this.finished = false,
  });

  final List<SessionPhase> phases;
  final int index;

  /// Secondes restantes de l'étape minutée (null en répétitions).
  final int? remaining;
  final bool paused;
  final bool sound;
  final DateTime startedAt;
  final bool finished;

  SessionPhase get phase => phases[index];

  /// Exercice suivant, pour « Ensuite : … ».
  SessionPhase? get nextExercise {
    for (var i = index + 1; i < phases.length; i++) {
      if (phases[i].kind == PhaseKind.exercise) return phases[i];
    }
    return null;
  }

  int get exercisesCount =>
      phases.where((p) => p.kind == PhaseKind.exercise).length;

  /// Exercices terminés (envoyés à l'API en fin de séance).
  int get completedExercises => finished
      ? exercisesCount
      : phases.take(index).where((p) => p.kind == PhaseKind.exercise).length;

  SessionState copyWith({
    int? index,
    int? remaining,
    bool clearRemaining = false,
    bool? paused,
    bool? sound,
    bool? finished,
  }) => SessionState(
    phases: phases,
    index: index ?? this.index,
    remaining: clearRemaining ? null : (remaining ?? this.remaining),
    paused: paused ?? this.paused,
    sound: sound ?? this.sound,
    startedAt: startedAt,
    finished: finished ?? this.finished,
  );
}

/// Lecteur de séance : minuteur, repos, pause, précédent et suivant.
class SessionController extends Notifier<SessionState> {
  SessionController(this._workout);

  final WorkoutDetail _workout;
  Timer? _timer;
  static const _uuid = Uuid();

  @override
  SessionState build() {
    ref.onDispose(() => _timer?.cancel());
    final phases = buildPhases(_workout.steps);
    _startTimer();
    return SessionState(
      phases: phases,
      index: 0,
      remaining: phases.isEmpty ? null : phases.first.durationS,
      paused: false,
      sound: true,
      startedAt: DateTime.now(),
      finished: phases.isEmpty,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final s = state;
    if (s.paused || s.finished) return;
    final remaining = s.remaining;
    if (remaining == null) return;
    if (remaining > 1) {
      state = s.copyWith(remaining: remaining - 1);
    } else {
      next();
    }
  }

  void _goTo(int index) {
    final s = state;
    if (index >= s.phases.length) {
      _timer?.cancel();
      state = s.copyWith(finished: true, clearRemaining: true);
      unawaited(ref.read(sessionCuesProvider).phaseChanged(sound: s.sound));
      return;
    }
    final target = index < 0 ? 0 : index;
    final duration = s.phases[target].durationS;
    state = s.copyWith(
      index: target,
      remaining: duration,
      clearRemaining: duration == null,
    );
    unawaited(ref.read(sessionCuesProvider).phaseChanged(sound: s.sound));
  }

  void next() => _goTo(state.index + 1);

  /// Revient à l'exercice précédent (en sautant les repos).
  void previous() {
    var i = state.index - 1;
    while (i > 0 && state.phases[i].kind == PhaseKind.rest) {
      i--;
    }
    _goTo(i);
  }

  void togglePause() => state = state.copyWith(paused: !state.paused);

  void toggleSound() => state = state.copyWith(sound: !state.sound);

  /// « +10 s » pendant un repos.
  void extendRest() {
    final s = state;
    if (s.phase.kind != PhaseKind.rest || s.remaining == null) return;
    state = s.copyWith(remaining: s.remaining! + restExtension);
  }

  /// Envoie la séance à l'API, qui calcule durée, calories et points.
  Future<CompleteWorkoutSession201Response> complete() async {
    final s = state;
    try {
      return await ref
          .read(trainingRepositoryProvider)
          .completeSession(
            CompleteWorkoutSessionRequest(
              workoutId: _workout.id,
              startedAt: s.startedAt.toUtc(),
              endedAt: DateTime.now().toUtc(),
              completedSteps: s.completedExercises,
            ),
            idempotencyKey: _uuid.v4(),
          );
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      rethrow;
    }
  }
}

// Le type d'une famille de providers n'est pas exporté par Riverpod 3.
// ignore: specify_nonobvious_property_types
final sessionControllerProvider = NotifierProvider.autoDispose
    .family<SessionController, SessionState, WorkoutDetail>(
      SessionController.new,
    );
