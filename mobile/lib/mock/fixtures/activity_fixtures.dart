// Fixtures de l'activité, reprises des maquettes (previews/mobile/screens/
// 05-sport.js). Les valeurs calculées sont précalculées, comme le ferait
// l'API. Seules les dates suivent le jour courant (calcul toléré dans
// lib/mock/).
import 'package:omeo_api/omeo_api.dart';

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const runningId = '8c9d0e1f-0008-4000-8000-000000000001';
const footballId = '8c9d0e1f-0008-4000-8000-000000000002';
const importedFootballId = '8c9d0e1f-0008-4000-8000-000000000003';

const reveilMobiliteId = '9d0e1f2a-0009-4000-8000-000000000001';
const cardioSansMaterielId = '9d0e1f2a-0009-4000-8000-000000000002';
const renfoDuSoirId = '9d0e1f2a-0009-4000-8000-000000000003';
const hiit30Id = '9d0e1f2a-0009-4000-8000-000000000004';

/// Séances recommandées et catalogue (Free : les séances Plus sont
/// verrouillées).
List<Map<String, Object?>> workoutSummariesJson({required bool plus}) => [
  for (final (id, name, goal, level, minutes, count, kcal, locked) in [
    (
      reveilMobiliteId,
      'Réveil mobilité',
      'mobility',
      'beginner',
      10,
      6,
      45,
      false,
    ),
    (
      cardioSansMaterielId,
      'Cardio sans matériel',
      'cardio',
      'intermediate',
      20,
      8,
      190,
      true,
    ),
    (renfoDuSoirId, 'Renfo du soir', 'strength', 'beginner', 15, 5, 110, false),
    (hiit30Id, 'HIIT 30', 'cardio', 'advanced', 30, 10, 330, true),
  ])
    {
      'id': id,
      'name': name,
      'goal': goal,
      'level': level,
      'duration_s': minutes * 60,
      'exercises_count': count,
      'estimated_kcal': kcal,
      'locked': locked && !plus,
    },
];

Map<String, Object?> _activity(
  String id,
  DateTime day,
  String type,
  String label,
  int hour,
  int minute,
  int minutes,
  int kcal,
  String source, {
  String? intensity,
  int? avgHr,
  int? distanceM,
}) => {
  'id': id,
  'date': _d(day),
  'type': type,
  'label': label,
  'started_at': DateTime(
    day.year,
    day.month,
    day.day,
    hour,
    minute,
  ).toUtc().toIso8601String(),
  'duration_s': minutes * 60,
  'intensity': ?intensity,
  'kcal': kcal,
  'distance_m': ?distanceM,
  'avg_hr': ?avgHr,
  'source': source,
  'editable': source == 'manual',
};

/// Course importée et football saisi à la main (SPO-01).
List<Map<String, Object?>> todayActivitiesJson(DateTime day) => [
  _activity(
    runningId,
    day,
    'running',
    'Course à pied',
    7,
    10,
    32,
    340,
    'health_connect',
    avgHr: 148,
    distanceM: 4800,
  ),
  _activity(
    footballId,
    day,
    'football',
    'Football',
    18,
    30,
    45,
    410,
    'manual',
    intensity: 'moderate',
  ),
];

/// Séance importée qui chevauche le football saisi (SPO-03).
Map<String, Object?> importedFootballJson(DateTime day) => _activity(
  importedFootballId,
  day,
  'football',
  'Football',
  18,
  25,
  50,
  455,
  'health_connect',
  avgHr: 151,
);

/// Aperçu de l'activité du jour (GET /me/activity).
/// [connected] : santé connectée ; [empty] : aucune donnée sur l'appareil.
ActivityOverview activityOverviewFixture({
  required DateTime today,
  required bool connected,
  required bool plus,
  bool empty = false,
  List<Map<String, Object?>>? activities,
  DateTime? lastSyncAt,
}) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  const week = [
    (2100, 2500),
    (2480, 2300),
    (1950, 2600),
    (2290, 2450),
    (2640, 2900),
    (2210, 2700),
    (1450, 2610),
  ];
  return ActivityOverview.fromJson({
    'date': _d(today),
    'steps': {
      'value': empty ? 0 : 6420,
      'target': 8000,
      'remaining': empty ? 8000 : 1580,
      'percent': empty ? 0 : 80,
      'status': 'under',
    },
    'distance_m': empty ? 0 : 4800,
    'active_kcal': empty ? 0 : 750,
    'active_minutes': empty ? 0 : 52,
    'health': {
      'connected': connected,
      if (connected) ...{
        'source': 'health_connect',
        'granted_types': ['steps', 'distance', 'active_calories', 'workouts'],
        'read_types_label': 'Pas, distance, calories actives, séances',
        'last_sync_at': (lastSyncAt ?? today.add(const Duration(hours: 11)))
            .toUtc()
            .toIso8601String(),
      },
    },
    'balance_day': {
      'consumed_kcal': 1450,
      'burned_kcal': empty ? 1860 : 2610,
      'difference_kcal': empty ? -410 : -1160,
      'status': 'deficit',
      'label': empty
          ? 'Journée calme pour l’instant.'
          : 'Journée active : ton objectif augmente de 135 kcal.',
    },
    'balance_week': [
      for (var i = 0; i < 7; i++)
        if (!monday.add(Duration(days: i)).isAfter(today))
          {
            'date': _d(monday.add(Duration(days: i))),
            'consumed_kcal': week[i].$1,
            'burned_kcal': week[i].$2,
          },
    ],
    'activities': empty
        ? <Object?>[]
        : (activities ?? todayActivitiesJson(today)),
    'recommended_workouts': workoutSummariesJson(plus: plus).take(2).toList(),
  });
}

/// Analyses croisées de la semaine (GET /me/insights), Plus.
List<Insight> insightsFixture(DateTime today) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return [
    for (final (i, kind, message) in [
      (
        1,
        'weekend_pattern',
        'Tu bouges plus le week-end, mais tu manges plus aussi : +420 kcal '
            'le samedi en moyenne, pour +1 800 pas.',
      ),
      (
        2,
        'low_steps',
        '3 jours sous les 4 000 pas cette semaine : mardi, mercredi et '
            'jeudi. Une marche de 15 min après le déjeuner ?',
      ),
      (
        3,
        'protein_training',
        'Tes protéines suivent ton sport : les jours de séance, tu atteins '
            '95 % de ton objectif protéines.',
      ),
    ])
      Insight.fromJson({
        'id': '0e1f2a3b-0010-4000-8000-00000000000$i',
        'week_start': _d(monday),
        'kind': kind,
        'message': message,
      }),
  ];
}
