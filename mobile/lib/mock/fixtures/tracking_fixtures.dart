// Fixtures du journal, de la progression et du poids, reprises des maquettes
// (previews/mobile/screens/04-suivi.js). Les valeurs calculées sont
// précalculées ; seuls les dates et le petit recalcul de l'eau après un
// ajout sont faits ici, pour une démo vivante (calcul toléré dans lib/mock/).
import 'package:omeo_api/omeo_api.dart';

String _d(DateTime d) => d.toIso8601String().substring(0, 10);

Map<String, Object?> _gauge(num value, num target, {String status = 'under'}) {
  final percent = target == 0 ? 0 : (value * 100 / target).round();
  return {
    'value': value,
    'target': target,
    'remaining': value >= target ? 0 : target - value,
    'percent': percent,
    'status': value > target ? 'over' : status,
  };
}

Map<String, Object?> _meal(
  String id,
  DateTime date,
  String type,
  String title,
  int kcal,
) => {
  'id': id,
  'date': _d(date),
  'meal_type': type,
  'source': 'photo',
  'title': title,
  'nutrients': {'kcal': kcal, 'protein_g': 20, 'carbs_g': 60, 'fat_g': 15},
  'items': <Object?>[],
  'created_at': date.toUtc().toIso8601String(),
};

/// Eau du jour (ml) par défaut dans la démo.
const defaultWaterMl = 1250;
const waterTargetMl = 2600;

/// Journal d'un jour (GET /me/days/{date}). [empty] : journée sans saisie.
DayDetail dayDetailFixture(
  DateTime date, {
  required DateTime today,
  bool empty = false,
  int waterMl = defaultWaterMl,
}) {
  final groups = [
    ('breakfast', 'Petit-déjeuner'),
    ('lunch', 'Déjeuner'),
    ('snack', 'Collation'),
    ('dinner', 'Dîner'),
  ];
  final meals = <String, List<Map<String, Object?>>>{
    if (!empty) ...{
      'breakfast': [
        _meal(
          'a1b2c3d4-0001-4000-8000-000000000001',
          date,
          'breakfast',
          'Bouillie de mil',
          240,
        ),
        _meal(
          'a1b2c3d4-0001-4000-8000-000000000002',
          date,
          'breakfast',
          'Beignets haricots',
          400,
        ),
      ],
      'lunch': [
        _meal(
          'a1b2c3d4-0001-4000-8000-000000000003',
          date,
          'lunch',
          'Alloco & poisson braisé',
          810,
        ),
      ],
    },
  };
  int kcalOf(String type) => [
    for (final m in meals[type] ?? const <Map<String, Object?>>[])
      (m['nutrients']! as Map)['kcal'] as int,
  ].fold(0, (a, b) => a + b);
  final consumed = empty ? 0 : 1450;
  final previous = date.subtract(const Duration(days: 1));
  final next = date.add(const Duration(days: 1));
  return DayDetail.fromJson({
    'day': {
      'date': _d(date),
      'kcal': _gauge(consumed, 2340),
      'protein': _gauge(empty ? 0 : 84, 128),
      'carbs': _gauge(empty ? 0 : 180, 270),
      'fat': _gauge(empty ? 0 : 42, 72),
      'fiber': _gauge(empty ? 0 : 14, 30),
      'salt': _gauge(empty ? 0 : 3.1, 5),
      'water': _gauge(waterMl, waterTargetMl),
      'meals_count': empty ? 0 : 3,
    },
    'meals_by_type': [
      for (final (type, label) in groups)
        {
          'meal_type': type,
          'label': label,
          'kcal': kcalOf(type),
          'meals': meals[type] ?? const <Object?>[],
        },
    ],
    'water': {
      'date': _d(date),
      'gauge': _gauge(waterMl, waterTargetMl),
      'quick_add_ml': [250, 500],
    },
    'message': empty
        ? 'Pas encore de repas ce jour-là. Ajoute-les quand tu veux.'
        : 'Belle régularité ! Encore un dîner léger et riche en légumes, '
              'et ta journée sera complète.',
    'previous_date': _d(previous),
    'next_date': next.isAfter(today) ? null : _d(next),
  });
}

/// État des jours d'un mois : atteint, partiel ou vide, futur exclu.
List<GetCalendar200ResponseInner> calendarFixture(
  DateTime month, {
  required DateTime today,
}) {
  final days = DateTime(month.year, month.month + 1, 0).day;
  return [
    for (var d = 1; d <= days; d++)
      if (!DateTime(month.year, month.month, d).isAfter(today))
        GetCalendar200ResponseInner.fromJson({
          'date': _d(DateTime(month.year, month.month, d)),
          'status': d % 3 == 0
              ? 'partial'
              : d % 7 == 0
              ? 'empty'
              : 'on_target',
        }),
  ];
}

const _weekKcal = [2100, 2480, 1950, 2290, 2640, 2210, 1450];
const _weekSalt = [6.2, 4.1, 5.8, 3.9, 7.1, 4.4, 3.1];

/// Courbe d'un nutriment (GET /me/progress), avec la connexion santé.
Progress progressFixture(
  String metric,
  String range, {
  required DateTime today,
  bool empty = false,
  bool healthConnected = false,
}) {
  final length = switch (range) {
    '30d' => 30,
    '90d' => 90,
    '1y' => 52,
    _ => 7,
  };
  final step = range == '1y' ? 7 : 1;
  final factor = switch (metric) {
    'carbs' => 0.12,
    'fat' => 0.03,
    'protein' => 0.05,
    'fiber' => 0.007,
    _ => 1.0,
  };
  num valueAt(int i) =>
      metric == 'salt' ? _weekSalt[i % 7] : (_weekKcal[i % 7] * factor).round();
  final target = switch (metric) {
    'kcal' => 2340,
    'carbs' => 270,
    'fat' => 72,
    'protein' => 128,
    'fiber' => 30,
    _ => 5,
  };
  return Progress.fromJson({
    'metric': metric,
    'range': range,
    'unit': metric == 'kcal' ? 'kcal' : 'g',
    'today': empty ? 0 : valueAt(length - 1),
    'delta_vs_yesterday': empty ? 0 : -760,
    'delta_percent': empty ? null : -12,
    'target': target,
    'average': empty ? 0 : (metric == 'salt' ? 4.9 : (2160 * factor).round()),
    'empty': empty,
    'series': [
      for (var i = 0; i < length; i++)
        {
          'date': _d(today.subtract(Duration(days: (length - 1 - i) * step))),
          'value': empty ? null : valueAt(i),
          'status': empty ? 'empty' : 'under',
        },
    ],
    'summary_last_7': [
      for (var i = 0; i < 7; i++)
        {
          'date': _d(today.subtract(Duration(days: 6 - i))),
          'kcal': empty ? 0 : _weekKcal[i],
        },
    ],
    'health': {
      'connected': healthConnected,
      if (healthConnected) ...{
        'source': 'health_connect',
        'granted_types': ['steps', 'distance', 'active_calories', 'workouts'],
        'read_types_label':
            'Données lues : pas, distance, calories dépensées, séances',
        'last_sync_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 4))
            .toIso8601String(),
      },
    },
  });
}

/// Pesées de la démo : de 80,5 kg à 78,4 kg en deux mois.
List<Map<String, Object?>> weightSeriesFixture(DateTime today) {
  const values = [80.5, 80.1, 80.3, 79.6, 79.4, 79.0, 78.9, 78.4];
  return [
    for (var i = 0; i < values.length; i++)
      {
        'id': 'b0c0d0e0-0000-4000-8000-00000000000$i',
        'date': _d(today.subtract(Duration(days: (values.length - 1 - i) * 7))),
        'weight_kg': values[i],
        'source': i == values.length - 1 ? 'manual' : 'health_connect',
      },
  ];
}

WeightOverview weightOverviewFixture(
  List<Map<String, Object?>> series, {
  num targetKg = 74,
}) {
  final current = series.isEmpty ? null : series.last['weight_kg']! as num;
  return WeightOverview.fromJson({
    'current_kg': current,
    'target_kg': targetKg,
    'remaining_kg': current == null
        ? null
        : ((current - targetKg) * 10).round() / 10,
    'start_kg': series.isEmpty ? null : series.first['weight_kg'],
    'trend': 'down',
    'trend_kg_per_week': -0.3,
    'series': series,
  });
}

/// Réponse de POST /me/weights après une pesée.
AddWeight201Response addWeightFixture(WeightOverview overview) =>
    AddWeight201Response.fromJson({
      'overview': overview.toJson(),
      'targets': {
        'kcal': 2320,
        'protein_g': 127,
        'carbs_g': 268,
        'fat_g': 71,
        'fiber_g': 30,
        'salt_max_g': 5,
        'water_ml': waterTargetMl,
      },
      'rewards': {'points': 5, 'total_points': 645, 'streak': 12},
    });

AddWater201Response addWaterFixture(DateTime date, int waterMl) =>
    AddWater201Response.fromJson({
      'water': {
        'date': _d(date),
        'gauge': _gauge(waterMl, waterTargetMl),
        'quick_add_ml': [250, 500],
      },
      'rewards': {'points': 1, 'total_points': 641, 'streak': 12},
    });
