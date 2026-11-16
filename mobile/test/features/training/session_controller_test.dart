import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/features/training/application/session_controller.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/fixtures/training_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/training_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Signaux de test : compte les changements d'étape.
class _Cues implements SessionCues {
  int count = 0;
  bool? lastSound;

  @override
  Future<void> phaseChanged({required bool sound}) async {
    count++;
    lastSound = sound;
  }
}

WorkoutDetail get _workout => workoutFixture(cardioSansMaterielId, plus: true)!;

void main() {
  test('enchaînement : exercices et repos, sans repos final', () {
    final phases = buildPhases(_workout.steps);
    expect(phases.where((p) => p.kind == PhaseKind.exercise), hasLength(8));
    expect(phases.where((p) => p.kind == PhaseKind.rest), hasLength(7));
    expect(phases.last.kind, PhaseKind.exercise);
    // Exercice en répétitions : pas de minuteur.
    expect(phases[2].durationS, isNull);
  });

  test('minuteur, passage au repos, +10 s, pause et fin', () {
    fakeAsync((async) {
      final cues = _Cues();
      final c = ProviderContainer(
        overrides: [
          sessionCuesProvider.overrideWithValue(cues),
          trainingRepositoryProvider.overrideWithValue(
            TrainingMockRepository(MockBackend(latency: Duration.zero)),
          ),
        ],
      );
      final provider = sessionControllerProvider(_workout);
      final sub = c.listen(provider, (_, _) {});
      expect(sub.read().remaining, 40);

      async.elapse(const Duration(seconds: 40));
      expect(sub.read().phase.kind, PhaseKind.rest);
      expect(sub.read().remaining, 20);
      expect(cues.count, 1);

      c.read(provider.notifier).extendRest();
      expect(sub.read().remaining, 30);

      c.read(provider.notifier).togglePause();
      async.elapse(const Duration(seconds: 5));
      expect(sub.read().remaining, 30);
      c.read(provider.notifier).togglePause();

      async.elapse(const Duration(seconds: 30));
      // Squat en répétitions : le minuteur attend l'utilisateur.
      expect(sub.read().phase.step.exercise.id, squatId);
      expect(sub.read().remaining, isNull);
      async.elapse(const Duration(minutes: 5));
      expect(sub.read().phase.step.exercise.id, squatId);

      c.read(provider.notifier).previous();
      expect(sub.read().index, 0);

      final notifier = c.read(provider.notifier);
      while (!sub.read().finished) {
        notifier.next();
      }
      expect(sub.read().completedExercises, 8);
      c.dispose();
    });
  });

  test('le son peut être coupé, la vibration reste', () {
    fakeAsync((async) {
      final cues = _Cues();
      final c = ProviderContainer(
        overrides: [sessionCuesProvider.overrideWithValue(cues)],
      );
      final provider = sessionControllerProvider(_workout);
      c.listen(provider, (_, _) {});
      c.read(provider.notifier)
        ..toggleSound()
        ..next();
      expect(cues.lastSound, isFalse);
      c.dispose();
    });
  });

  test('fin de séance envoyée à l’API', () async {
    final c = ProviderContainer(
      overrides: [
        sessionCuesProvider.overrideWithValue(_Cues()),
        trainingRepositoryProvider.overrideWithValue(
          TrainingMockRepository(MockBackend(latency: Duration.zero)),
        ),
      ],
    );
    addTearDown(c.dispose);
    final provider = sessionControllerProvider(_workout);
    c.listen(provider, (_, _) {});
    final result = await c.read(provider.notifier).complete();
    expect(result.rewards.points, 30);
  });
}
