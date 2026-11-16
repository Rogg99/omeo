// Fixtures de l'abonnement et du parrainage, reprises des maquettes
// (previews/mobile/screens/08-plus.js). Prix en USD, formatés par l'API.
import 'package:omeo_api/omeo_api.dart';

/// État d'abonnement servi par le mock.
enum SubscriptionVariant { trial, free, plusStore, grace }

const annualProductGoogle = 'omeo_plus_annual';
const monthlyProductGoogle = 'omeo_plus_monthly';
const annualProductApple = 'app.myomeo.plus.annual';
const monthlyProductApple = 'app.myomeo.plus.monthly';

Map<String, Object?> _money(int cents, String formatted) => {
  'amount_cents': cents,
  'currency': 'USD',
  'formatted': formatted,
};

/// Offres (GET /billing/plans).
PlanCatalog planCatalogFixture() => PlanCatalog.fromJson({
  'plans': [
    {
      'code': 'plus_annual',
      'name': 'Annuel',
      'price': _money(4699, r'46,99 $'),
      'monthly_equivalent': _money(392, r'3,92 $'),
      'savings_percent': 13,
      'interval': 'year',
      'featured': true,
      'store_product_ids': {
        'google': annualProductGoogle,
        'apple': annualProductApple,
      },
    },
    {
      'code': 'plus_monthly',
      'name': 'Mensuel',
      'price': _money(449, r'4,49 $'),
      'interval': 'month',
      'featured': false,
      'store_product_ids': {
        'google': monthlyProductGoogle,
        'apple': monthlyProductApple,
      },
    },
  ],
  'comparison': [
    for (final (feature, label, free, plus) in [
      (
        'photo_analysis',
        '140 analyses photo par mois',
        '3 / jour',
        '140 / mois',
      ),
      (
        'text_analysis',
        'Saisie vocale et texte (140 / mois)',
        '—',
        '140 / mois',
      ),
      ('workouts', 'Toutes les séances, hors connexion', 'Sélection', 'Toutes'),
      ('programs', 'Programmes et challenges illimités', '1', 'Illimités'),
      ('progress', 'Progression sur 30 j, 90 j et 1 an', '7 j', '1 an'),
      ('insights', 'Analyses croisées et bilan hebdo', '—', 'Oui'),
      ('recipes', 'Toutes les recettes', 'Sélection', 'Toutes'),
    ])
      {'feature': feature, 'label': label, 'free': free, 'plus': plus},
  ],
});

Map<String, Object?> _quota(
  String feature,
  int limit,
  int used,
  String period, {
  DateTime? resetsAt,
}) => {
  'feature': feature,
  'limit': limit,
  'used': used,
  'remaining': limit - used,
  'period': period,
  'resets_at': ?resetsAt?.toUtc().toIso8601String(),
};

/// État de l'abonnement (GET /me/subscription) pour la variante demandée.
/// [now] fige la date courante (tests).
SubscriptionState subscriptionFixture(
  SubscriptionVariant variant, {
  DateTime? now,
}) {
  now ??= DateTime.now();
  final features = {
    'voice_input': variant != SubscriptionVariant.free,
    'insights': variant != SubscriptionVariant.free,
    'offline_workouts': variant != SubscriptionVariant.free,
  };
  final monthReset = DateTime(now.year, now.month, 14).isAfter(now)
      ? DateTime(now.year, now.month, 14)
      : DateTime(now.year, now.month + 1, 14);
  return SubscriptionState.fromJson(switch (variant) {
    SubscriptionVariant.trial => {
      'entitlements': {
        'tier': 'trial',
        'trial_ends_at': now
            .add(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
        'features': features,
      },
      'trial_days_left': 2,
      'quotas': [
        _quota('photo_analysis', 28, 10, 'trial'),
        _quota('text_analysis', 10, 3, 'trial'),
      ],
      'can_purchase_in_app': true,
      'can_manage': 'none',
      'web_checkout_allowed': false,
    },
    SubscriptionVariant.free => {
      'entitlements': {'tier': 'free', 'features': features},
      'quotas': [
        _quota(
          'photo_analysis',
          3,
          1,
          'day',
          resetsAt: DateTime(now.year, now.month, now.day + 1),
        ),
        _quota('text_analysis', 0, 0, 'month'),
      ],
      'can_purchase_in_app': true,
      'can_manage': 'none',
      'web_checkout_allowed': false,
    },
    SubscriptionVariant.plusStore => {
      'entitlements': {
        'tier': 'plus',
        'plus_until': DateTime(
          now.year + 1,
          10,
          14,
        ).toUtc().toIso8601String(),
        'features': features,
      },
      'subscription': {
        'plan_code': 'plus_annual',
        'plan_name': 'Plus annuel',
        'channel': 'google_play',
        'status': 'active',
        'current_period_end': DateTime(
          now.year + 1,
          10,
          14,
        ).toUtc().toIso8601String(),
        'auto_renew': true,
        'price': _money(4699, r'46,99 $ / an'),
      },
      'granted_days_left': 14,
      'quotas': [
        _quota('photo_analysis', 140, 98, 'month', resetsAt: monthReset),
        _quota('text_analysis', 140, 31, 'month', resetsAt: monthReset),
      ],
      'can_purchase_in_app': false,
      'can_manage': 'store',
      'web_checkout_allowed': false,
    },
    SubscriptionVariant.grace => {
      'entitlements': {
        'tier': 'plus',
        'plus_until': now
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'features': features,
      },
      'subscription': {
        'plan_code': 'plus_monthly',
        'plan_name': 'Plus mensuel',
        'channel': 'web',
        'status': 'grace',
        'current_period_end': now
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'auto_renew': true,
        'price': _money(449, r'4,49 $'),
      },
      'quotas': [
        _quota('photo_analysis', 140, 40, 'month', resetsAt: monthReset),
        _quota('text_analysis', 140, 12, 'month', resetsAt: monthReset),
      ],
      'can_purchase_in_app': false,
      'can_manage': 'web',
      'web_checkout_allowed': true,
    },
  });
}

/// Historique des paiements (GET /me/payments), tous canaux confondus.
ListPayments200Response paymentsFixture() => ListPayments200Response.fromJson({
  'results': [
    for (final (id, date, channel, description, cents, formatted, status) in [
      (
        'p4',
        '2026-10-14',
        'google_play',
        'Plus annuel',
        4699,
        r'46,99 $',
        'succeeded',
      ),
      (
        'p3',
        '2026-09-14',
        'google_play',
        'Plus mensuel',
        449,
        r'4,49 $',
        'succeeded',
      ),
      (
        'p2',
        '2026-08-14',
        'google_play',
        'Plus mensuel',
        449,
        r'4,49 $',
        'succeeded',
      ),
      ('p1', '2026-08-02', 'web', 'Plus mensuel', 449, r'4,49 $', 'refunded'),
    ])
      {
        'id': '7b8c9d0e-0007-4000-8000-00000000000${id.substring(1)}',
        'channel': channel,
        'description': description,
        'amount': _money(cents, formatted),
        'status': status,
        'paid_at': '${date}T10:00:00Z',
      },
  ],
});

/// Parrainage (GET /me/referral).
ReferralOverview referralFixture() => ReferralOverview.fromJson({
  'code': 'AWA7',
  'share_url': 'https://my-omeo.app/i/AWA7',
  'share_message':
      "J'utilise Omeo pour suivre mes repas. Avec mon code AWA7, tu as "
      "7 jours d'Omeo Plus offerts : https://my-omeo.app/i/AWA7",
  'validated_count': 2,
  'pending_count': 1,
  'days_earned': 14,
  'days_cap': 35,
  'referees': [
    {'first_name': 'Fatou D.', 'status': 'validated', 'date': '2026-10-02'},
    {'first_name': 'Moussa K.', 'status': 'validated', 'date': '2026-10-20'},
    {'first_name': 'Sandrine N.', 'status': 'pending', 'date': '2026-11-08'},
  ],
});
