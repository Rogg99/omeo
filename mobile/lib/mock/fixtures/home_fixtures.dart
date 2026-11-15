// Fixtures de l'accueil, reprises des maquettes (previews/mobile/screens/
// 02-accueil.js). Les valeurs calculées sont précalculées, comme le ferait
// l'API. Seules les dates sont dérivées du jour courant pour que la démo
// reste vivante (calcul toléré dans lib/mock/).
import 'package:omeo_api/omeo_api.dart';

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Semaine du lundi au dimanche contenant [selected].
List<Map<String, Object?>> _week(
  DateTime selected, {
  required DateTime today,
  required bool firstDay,
}) {
  final monday = selected.subtract(Duration(days: selected.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      () {
        final date = monday.add(Duration(days: i));
        final status = date.isAfter(today)
            ? 'future'
            : firstDay || date.isBefore(today.subtract(const Duration(days: 7)))
            ? 'empty'
            : date == today
            ? 'partial'
            : (i.isEven ? 'on_target' : 'under');
        return {
          'date': _d(date),
          'label': _dayLabels[i],
          'day_number': date.day,
          'is_today': date == today,
          'status': status,
        };
      }(),
  ];
}

Map<String, Object?> _gauge(
  num value,
  num target,
  int percent, {
  num? remaining,
  num? overBy,
  String status = 'under',
}) => {
  'value': value,
  'target': target,
  'remaining': ?remaining,
  'over_by': ?overBy,
  'percent': percent,
  'status': status,
};

Map<String, Object?> _rewards() => {
  'level': {'rank': 4, 'name': 'Cuisinier', 'min_points': 600},
  'total_points': 640,
  'streak': 12,
  'progress_to_next_percent': 64,
};

const _shortcuts = ['nutrition', 'sport', 'recipes', 'plants'];

/// Variante d'accueil servie par le mock.
enum HomeVariant { current, firstDay, past, over }

/// Accueil (GET /me/home) pour la variante et la date demandées.
/// [today] fige la date du jour (tests et goldens).
Home homeFixture(
  HomeVariant variant, {
  DateTime? date,
  DateTime? today,
  bool plus = false,
}) {
  today ??= _today();
  final selected = date ?? today;
  final firstDay = variant == HomeVariant.firstDay;

  final day = switch (variant) {
    HomeVariant.current => {
      'date': _d(selected),
      'kcal': _gauge(1450, 2340, 62, remaining: 890),
      'protein': _gauge(84, 128, 66, remaining: 44),
      'carbs': _gauge(180, 270, 67, remaining: 90),
      'fat': _gauge(42, 72, 58, remaining: 30),
      'water': _gauge(1250, 2000, 63, remaining: 750),
      'balance': {
        'consumed_kcal': 1450,
        'burned_kcal': 2610,
        'difference_kcal': -1160,
        'status': 'deficit',
      },
      'meals_count': 3,
    },
    HomeVariant.firstDay => {
      'date': _d(selected),
      'kcal': _gauge(0, 2340, 0, remaining: 2340),
      'protein': _gauge(0, 128, 0, remaining: 128),
      'carbs': _gauge(0, 270, 0, remaining: 270),
      'fat': _gauge(0, 72, 0, remaining: 72),
      'water': _gauge(0, 2000, 0, remaining: 2000),
      'meals_count': 0,
    },
    HomeVariant.past => {
      'date': _d(selected),
      'kcal': _gauge(2220, 2340, 95, remaining: 120, status: 'on_target'),
      'protein': _gauge(131, 128, 102, remaining: 0, status: 'on_target'),
      'carbs': _gauge(262, 270, 97, remaining: 8, status: 'on_target'),
      'fat': _gauge(70, 72, 97, remaining: 2, status: 'on_target'),
      'water': _gauge(2000, 2000, 100, remaining: 0, status: 'on_target'),
      'meals_count': 4,
    },
    HomeVariant.over => {
      'date': _d(selected),
      'kcal': _gauge(
        2520,
        2340,
        108,
        remaining: 0,
        overBy: 180,
        status: 'over',
      ),
      'protein': _gauge(110, 128, 86, remaining: 18),
      'carbs': _gauge(
        301,
        270,
        111,
        remaining: 0,
        overBy: 31,
        status: 'over',
      ),
      'fat': _gauge(70, 72, 97, remaining: 2, status: 'on_target'),
      'water': _gauge(1500, 2000, 75, remaining: 500),
      'balance': {
        'consumed_kcal': 2520,
        'burned_kcal': 2610,
        'difference_kcal': -90,
        'status': 'balanced',
      },
      'meals_count': 4,
    },
  };

  return Home.fromJson({
    'greeting': 'Bonjour, Awa',
    'date': _d(selected),
    'week': _week(selected, today: today, firstDay: firstDay),
    'day': day,
    'quick_actions': [
      {'kind': 'photo', 'enabled': true, 'remaining': firstDay ? 3 : 2},
      {
        'kind': 'voice',
        'enabled': plus,
        if (!plus) 'locked_reason': 'plan_required',
      },
      {'kind': 'catalog', 'enabled': true},
    ],
    if (variant == HomeVariant.current) ...{
      'active_program': {
        'enrollment_id': '7d3c9a52-3a8e-4c5b-9b8e-1f2a3b4c5d6e',
        'program_name': 'Mincir sans frustration',
        'day_index': 12,
        'total_days': 28,
        'percent': 43,
        'tasks_done': 2,
        'tasks_total': 3,
      },
      'active_challenges': [
        {
          'participation_id': '0b1c2d3e-4f50-4617-8899-aabbccddeeff',
          'name': "2 L d'eau par jour",
          'day_index': 5,
          'duration_days': 14,
          'today_status': 'pending',
          'today_progress': 0.63,
          'today_label': "1,25 L / 2 L aujourd'hui · validé automatiquement",
          'can_check': false,
        },
      ],
      'insight': {
        'id': '5e6f7a8b-9c0d-4e1f-8a2b-3c4d5e6f7a8b',
        'week_start': _d(today.subtract(Duration(days: today.weekday - 1))),
        'kind': 'weekend_pattern',
        'message':
            'Tu bouges plus le week-end, mais tu manges plus aussi : '
            '+420 kcal en moyenne le samedi.',
      },
    },
    'shortcuts': _shortcuts,
    'rewards': _rewards(),
  });
}
