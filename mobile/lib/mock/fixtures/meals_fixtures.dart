// Fixtures des repas, reprises des maquettes (previews/mobile/screens/
// 03-repas.js). Les totaux sont précalculés, comme le ferait l'API.
import 'package:omeo_api/omeo_api.dart';

Map<String, Object?> _n(int kcal, num p, num c, num f) => {
  'kcal': kcal,
  'protein_g': p,
  'carbs_g': c,
  'fat_g': f,
};

Map<String, Object?> _dish(
  String id,
  String name,
  String country,
  int kcal,
  num portion, {
  bool favorite = false,
}) => {
  'id': id,
  'name': name,
  'country': country,
  'standard_portion_g': portion,
  'kcal_per_portion': kcal,
  'is_favorite': favorite,
};

const thieboudienneId = '1a2b3c4d-0001-4000-8000-000000000001';
const yassaPoissonId = '1a2b3c4d-0001-4000-8000-000000000002';
const rizPoissonId = '1a2b3c4d-0001-4000-8000-000000000003';
const fonioPoissonId = '1a2b3c4d-0001-4000-8000-000000000004';
const ndoleId = '1a2b3c4d-0001-4000-8000-000000000005';
const allocoId = '1a2b3c4d-0001-4000-8000-000000000006';
const pouletYassaId = '1a2b3c4d-0001-4000-8000-000000000007';
const fonioLegumesId = '1a2b3c4d-0001-4000-8000-000000000008';
const sauceGomboId = '1a2b3c4d-0001-4000-8000-000000000009';

final _dishes = <String, Map<String, Object?>>{
  thieboudienneId: _dish(thieboudienneId, 'Thiéboudienne', 'SN', 640, 450),
  yassaPoissonId: _dish(yassaPoissonId, 'Yassa poisson', 'SN', 560, 400),
  rizPoissonId: _dish(rizPoissonId, 'Riz au poisson braisé', 'CI', 600, 420),
  fonioPoissonId: _dish(fonioPoissonId, 'Fonio au poisson', 'ML', 480, 380),
  ndoleId: _dish(ndoleId, 'Ndolé', 'CM', 520, 350),
  allocoId: _dish(allocoId, 'Alloco', 'CI', 360, 200),
  pouletYassaId: _dish(
    pouletYassaId,
    'Poulet yassa',
    'SN',
    610,
    420,
    favorite: true,
  ),
  fonioLegumesId: _dish(
    fonioLegumesId,
    'Fonio aux légumes',
    'BF',
    340,
    300,
    favorite: true,
  ),
  sauceGomboId: _dish(
    sauceGomboId,
    'Sauce gombo',
    'TG',
    180,
    150,
    favorite: true,
  ),
};

/// Résumé d'un plat du catalogue simulé.
DishSummary dishSummary(String id) =>
    DishSummary.fromJson(Map<String, dynamic>.from(_dishes[id]!));

/// Catalogue (GET /dishes) : récents, favoris ou recherche par nom et pays.
SearchDishes200Response dishSearchFixture({
  String? query,
  String? country,
  String scope = 'all',
}) {
  final ids = switch (scope) {
    'recent' => [ndoleId, allocoId],
    'favorites' => [
      for (final e in _dishes.entries)
        if (e.value['is_favorite'] == true) e.key,
    ],
    _ => _dishes.keys.toList(),
  };
  final q = query?.trim().toLowerCase() ?? '';
  return SearchDishes200Response.fromJson({
    'results': [
      for (final id in ids)
        if ((q.isEmpty ||
                '${_dishes[id]!['name']}'.toLowerCase().contains(q)) &&
            (country == null || _dishes[id]!['country'] == country))
          _dishes[id],
    ],
  });
}

/// Fiche d'un plat (GET /dishes/{id}).
DishDetail dishDetailFixture(String id, {required bool favorite}) {
  final d = _dishes[id]!;
  final kcal = d['kcal_per_portion']! as int;
  return DishDetail.fromJson({
    ...d,
    'is_favorite': favorite,
    'aliases': id == ndoleId ? ['ndolè'] : <String>[],
    'nutrients_per_portion': id == ndoleId
        ? _n(520, 29, 18, 38)
        : _n(kcal, 28, 64, 18),
  });
}

final List<Map<String, Object?>> _foods = [
  {
    'id': '2b3c4d5e-0002-4000-8000-000000000001',
    'name': 'Plantain mûr frit',
    'matched_alias': 'Alloco',
    'default_portion_g': 100,
    'per_100g': _n(250, 1.5, 40, 9),
  },
  {
    'id': '2b3c4d5e-0002-4000-8000-000000000002',
    'name': 'Plantain vert bouilli',
    'default_portion_g': 100,
    'per_100g': _n(122, 1.3, 32, 0.4),
  },
  {
    'id': '2b3c4d5e-0002-4000-8000-000000000003',
    'name': 'Plantain mûr bouilli',
    'default_portion_g': 100,
    'per_100g': _n(116, 0.8, 31, 0.2),
  },
  {
    'id': '2b3c4d5e-0002-4000-8000-000000000004',
    'name': 'Chips de plantain',
    'matched_alias': 'Banane chips',
    'default_portion_g': 100,
    'per_100g': _n(520, 2.3, 58, 33),
  },
];

/// Aliments (GET /foods?q=…), noms locaux compris.
List<FoodSummary> foodSearchFixture(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final f in _foods)
      if ('${f['name']} ${f['matched_alias'] ?? ''}'.toLowerCase().contains(q))
        FoodSummary.fromJson(f),
  ];
}

Map<String, Object?> _item(String id, String label, num g, int kcal, num c) => {
  'food_id': id,
  'label': label,
  'grams': g,
  'confidence': c,
  'nutrients': _n(kcal, 0, 0, 0),
};

Map<String, Object?> _quota(int remaining) => {
  'feature': 'photo_analysis',
  'limit': 3,
  'used': 3 - remaining,
  'remaining': remaining,
  'period': 'day',
};

/// Quotas (GET /me/quotas) selon le nombre d'analyses photo restantes.
List<Quota> quotasFixture({required int photoRemaining, required bool plus}) =>
    [
      Quota.fromJson(_quota(photoRemaining)),
      Quota.fromJson({
        'feature': 'text_analysis',
        'limit': plus ? 30 : 0,
        'used': plus ? 23 : 0,
        'remaining': plus ? 7 : 0,
        'period': 'month',
      }),
    ];

/// Analyse photo ou texte (POST /me/analyses puis GET /me/analyses/{id}).
/// [lowConfidence] donne l'état MEA-05 ; [failed] l'état MEA-08.
Analysis analysisFixture({
  required String id,
  required String status,
  required DateTime createdAt,
  String kind = 'photo',
  bool lowConfidence = false,
  bool failed = false,
  String? selectedDishId,
  int photoRemaining = 2,
}) {
  final base = <String, Object?>{
    'id': id,
    'kind': kind,
    'status': failed ? 'failed' : status,
    'created_at': createdAt.toUtc().toIso8601String(),
    'quota': _quota(photoRemaining),
  };
  if (failed) {
    return Analysis.fromJson({
      ...base,
      'failure_reason': 'blurry',
      'failure_message':
          "La photo est floue ou trop sombre. Cette analyse n'est pas "
          'décomptée.',
    });
  }
  if (status != 'succeeded') return Analysis.fromJson(base);

  final dishId = selectedDishId ?? thieboudienneId;
  final corrected = selectedDishId != null;
  return Analysis.fromJson({
    ...base,
    'dish': _dishes[dishId],
    'dish_label': _dishes[dishId]!['name'],
    'confidence': corrected ? 1 : (lowConfidence ? 0.58 : 0.91),
    'low_confidence': !corrected && lowConfidence,
    'alternatives': corrected
        ? <Object?>[]
        : [
            {
              'label': 'Yassa poisson',
              'dish': _dishes[yassaPoissonId],
              'probability_percent': 22,
            },
            {
              'label': 'Riz au poisson braisé',
              'dish': _dishes[rizPoissonId],
              'probability_percent': 9,
            },
            {
              'label': 'Fonio au poisson',
              'dish': _dishes[fonioPoissonId],
              'probability_percent': 4,
            },
          ],
    'items': [
      _item('2b3c4d5e-0003-4000-8000-000000000001', 'Riz brisé', 180, 250, .9),
      _item(
        '2b3c4d5e-0003-4000-8000-000000000002',
        'Poisson (mérou)',
        150,
        165,
        .88,
      ),
      _item(
        '2b3c4d5e-0003-4000-8000-000000000003',
        "Huile d'arachide",
        15,
        133,
        lowConfidence ? .41 : .8,
      ),
      _item('2b3c4d5e-0003-4000-8000-000000000004', 'Chou', 60, 15, .86),
      _item('2b3c4d5e-0003-4000-8000-000000000005', 'Carotte', 50, 20, .84),
      _item(
        '2b3c4d5e-0003-4000-8000-000000000006',
        'Manioc',
        100,
        160,
        lowConfidence ? .38 : .52,
      ),
    ],
    'totals': _n(640, 32, 86, 18),
    'suggested_meal_type': 'lunch',
    'suggested_recipe_id': '3c4d5e6f-0004-4000-8000-000000000001',
  });
}

/// Réponse « après » de POST /me/meals (MEA-09) : jour recalculé et points.
MealWriteResult mealWriteFixture({
  required String mealId,
  required MealInput input,
  required String title,
  required DateTime now,
}) {
  final date = input.date ?? now;
  final d =
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  Map<String, Object?> g(num v, num t, int p, num r) => {
    'value': v,
    'target': t,
    'remaining': r,
    'percent': p,
    'status': 'under',
  };
  return MealWriteResult.fromJson({
    'meal': {
      'id': mealId,
      'date': d,
      'eaten_at': now.toUtc().toIso8601String(),
      'meal_type': input.mealType.value,
      'source': input.source_.value,
      'title': title,
      'nutrients': _n(640, 32, 86, 18),
      'items': <Object?>[],
      'analysis_id': ?input.analysisId,
      'feedback_given': false,
      'created_at': now.toUtc().toIso8601String(),
    },
    'day': {
      'date': d,
      'kcal': g(1450, 2340, 62, 890),
      'protein': g(84, 128, 66, 44),
      'carbs': g(180, 270, 67, 90),
      'fat': g(42, 72, 58, 30),
      'water': g(1250, 2000, 63, 750),
      'meals_count': 3,
    },
    'rewards': {'points': 10, 'total_points': 650, 'streak': 12},
  });
}

/// Repas du journal (MEA-15) : alloco et poisson braisé, analyse photo
/// modifiée par l'utilisatrice.
Meal allocoMealFixture({required String id, required DateTime now}) =>
    Meal.fromJson({
      'id': id,
      'date':
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}',
      'eaten_at': DateTime(
        now.year,
        now.month,
        now.day,
        12,
        40,
      ).toUtc().toIso8601String(),
      'meal_type': 'lunch',
      'source': 'photo',
      'title': 'Alloco & poisson braisé',
      'nutrients': _n(810, 41, 92, 31),
      'items': [
        _item(
          '2b3c4d5e-0002-4000-8000-000000000001',
          'Banane plantain frite',
          200,
          500,
          .9,
        ),
        _item(
          '2b3c4d5e-0003-4000-8000-000000000010',
          'Poisson braisé (tilapia)',
          180,
          230,
          .9,
        ),
        _item(
          '2b3c4d5e-0003-4000-8000-000000000011',
          'Piment, oignon, tomate',
          60,
          25,
          .9,
        ),
        _item('2b3c4d5e-0003-4000-8000-000000000012', 'Attiéké', 50, 55, .9),
      ],
      'analysis_id': '5f6a7b8c-0005-4000-8000-000000000001',
      'feedback_given': true,
      'created_at': now.toUtc().toIso8601String(),
    });

/// Jour recalculé après la suppression d'un repas (réponse « après »).
DaySummary dayAfterDeleteFixture(DateTime date) {
  Map<String, Object?> g(num v, num t, int p, num r) => {
    'value': v,
    'target': t,
    'remaining': r,
    'percent': p,
    'status': 'under',
  };
  return DaySummary.fromJson({
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'kcal': g(640, 2340, 27, 1700),
    'protein': g(43, 128, 34, 85),
    'carbs': g(88, 270, 33, 182),
    'fat': g(11, 72, 15, 61),
    'water': g(1250, 2000, 63, 750),
    'meals_count': 2,
  });
}
