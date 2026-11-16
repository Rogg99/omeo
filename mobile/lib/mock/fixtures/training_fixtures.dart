// Fixtures des exercices et séances, reprises des maquettes
// (previews/mobile/screens/05-sport.js). Les vidéos pointent vers une
// adresse simulée : sans réseau, le lecteur affiche l'affiche de l'exercice.
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo_api/omeo_api.dart';

const squatId = 'ae1f2a3b-0011-4000-8000-000000000001';
const pompesId = 'ae1f2a3b-0011-4000-8000-000000000002';
const fentesId = 'ae1f2a3b-0011-4000-8000-000000000003';
const gainageId = 'ae1f2a3b-0011-4000-8000-000000000004';
const burpeesId = 'ae1f2a3b-0011-4000-8000-000000000005';
const etirementId = 'ae1f2a3b-0011-4000-8000-000000000006';
const jumpingJacksId = 'ae1f2a3b-0011-4000-8000-000000000007';
const genouxId = 'ae1f2a3b-0011-4000-8000-000000000008';

typedef _Exercise = ({
  String id,
  String name,
  List<String> muscles,
  String level,
  List<String> equipment,
  bool plus,
  String instructions,
});

const List<_Exercise> _exercises = [
  (
    id: squatId,
    name: 'Squat',
    muscles: ['Jambes', 'Fessiers'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        "Pieds écartés largeur d'épaules, pointes légèrement ouvertes.\n"
        'Descends en poussant les fesses en arrière, dos droit.\n'
        "Genoux dans l'axe des pieds, sans dépasser les orteils.\n"
        'Remonte en poussant dans les talons. Expire à la montée.',
  ),
  (
    id: pompesId,
    name: 'Pompes inclinées',
    muscles: ['Pectoraux', 'Bras'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        'Mains sur un banc ou une table, un peu plus larges que les épaules.\n'
        'Corps gainé, de la tête aux talons.\n'
        'Descends la poitrine vers le support, coudes à 45°.\n'
        'Pousse pour remonter, sans creuser le dos.',
  ),
  (
    id: fentesId,
    name: 'Fentes alternées',
    muscles: ['Jambes'],
    level: 'intermediate',
    equipment: [],
    plus: true,
    instructions:
        'Fais un grand pas en avant.\n'
        'Descends jusqu’à ce que le genou arrière frôle le sol.\n'
        'Remonte et change de jambe.',
  ),
  (
    id: gainageId,
    name: 'Gainage',
    muscles: ['Abdominaux'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        'Avant-bras au sol, coudes sous les épaules.\n'
        'Corps aligné, fessiers serrés.\n'
        'Respire calmement et tiens la position.',
  ),
  (
    id: burpeesId,
    name: 'Burpees',
    muscles: ['Corps entier'],
    level: 'advanced',
    equipment: [],
    plus: true,
    instructions:
        'Accroupis-toi, mains au sol.\n'
        'Saute pieds en arrière en planche.\n'
        'Reviens accroupi, puis saute bras en l’air.',
  ),
  (
    id: etirementId,
    name: 'Étirement hanches',
    muscles: ['Mobilité'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        'Un genou au sol, l’autre pied devant.\n'
        'Avance doucement le bassin.\n'
        'Tiens 30 secondes de chaque côté.',
  ),
  (
    id: jumpingJacksId,
    name: 'Jumping jacks',
    muscles: ['Corps entier'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        'Saute en écartant bras et jambes.\n'
        'Reviens pieds joints, bras le long du corps.\n'
        'Garde un rythme régulier.',
  ),
  (
    id: genouxId,
    name: 'Montées de genoux',
    muscles: ['Cardio'],
    level: 'beginner',
    equipment: [],
    plus: false,
    instructions:
        'Cours sur place en montant les genoux à hauteur de hanches.\n'
        'Bras actifs, buste droit.',
  ),
];

Map<String, Object?> _summaryJson(_Exercise e, {required bool plusUser}) => {
  'id': e.id,
  'name': e.name,
  'muscles': e.muscles,
  'level': e.level,
  'equipment': e.equipment,
  'locked': e.plus && !plusUser,
};

Map<String, Object?> _detailJson(_Exercise e, {required bool plusUser}) => {
  ..._summaryJson(e, plusUser: plusUser),
  'instructions': e.instructions,
  'video': {
    'hls_url': 'https://media.mock.omeo/exercises/${e.id}/index.m3u8',
    'duration_s': 40,
    'subtitles': [
      {
        'locale': 'fr',
        'url': 'https://media.mock.omeo/exercises/${e.id}/fr.vtt',
      },
    ],
  },
};

/// Bibliothèque d'exercices (GET /exercises), six premiers des maquettes.
List<ExerciseSummary> exercisesFixture({required bool plus}) => [
  for (final e in _exercises.take(6))
    ExerciseSummary.fromJson(_summaryJson(e, plusUser: plus)),
];

/// Fiche d'un exercice (GET /exercises/{id}).
ExerciseDetail? exerciseFixture(String id, {required bool plus}) {
  for (final e in _exercises) {
    if (e.id == id) {
      return ExerciseDetail.fromJson(_detailJson(e, plusUser: plus));
    }
  }
  return null;
}

/// Séances (GET /workouts).
List<WorkoutSummary> workoutsFixture({required bool plus}) => [
  for (final w in workoutSummariesJson(plus: plus)) WorkoutSummary.fromJson(w),
];

_Exercise _ex(String id) => _exercises.firstWhere((e) => e.id == id);

/// Détail d'une séance (GET /workouts/{id}) : enchaînement en deux tours.
WorkoutDetail? workoutFixture(String id, {required bool plus}) {
  final summary = workoutSummariesJson(
    plus: plus,
  ).where((w) => w['id'] == id).firstOrNull;
  if (summary == null) return null;
  final sequence = switch (id) {
    reveilMobiliteId => [
      (etirementId, 'time', 40, null, 15),
      (gainageId, 'time', 30, null, 15),
      (squatId, 'reps', null, 10, 20),
    ],
    _ => [
      (jumpingJacksId, 'time', 40, null, 20),
      (squatId, 'reps', null, 15, 20),
      (genouxId, 'time', 40, null, 20),
      (pompesId, 'reps', null, 10, 20),
    ],
  };
  final steps = [
    for (var round = 0; round < 2; round++)
      for (final (i, (ex, mode, seconds, reps, rest)) in sequence.indexed)
        {
          'order': round * sequence.length + i + 1,
          'exercise': _detailJson(_ex(ex), plusUser: plus),
          'mode': mode,
          'duration_s': ?seconds,
          'reps': ?reps,
          'rest_s': rest,
        },
  ];
  return WorkoutDetail.fromJson({
    ...summary,
    'description': 'Un enchaînement simple, sans matériel, à faire chez toi.',
    'downloadable': plus,
    'steps': steps,
  });
}

/// Fin de séance (POST /me/workout-sessions) : réponse « après ».
CompleteWorkoutSession201Response sessionFixture({
  required String id,
  required CompleteWorkoutSessionRequest request,
  required DaySummary day,
}) => CompleteWorkoutSession201Response.fromJson({
  'id': id,
  'kcal': 196,
  'duration_s': request.endedAt.difference(request.startedAt).inSeconds,
  'completed': true,
  'day': day.toJson(),
  'rewards': {'points': 30, 'total_points': 680},
});
