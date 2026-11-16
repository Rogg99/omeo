// Fixtures de l'authentification et du compte, reprises des maquettes
// (previews/mobile/screens/01-onboarding.js et 09-profil.js). Les objectifs
// sont précalculés, comme le ferait l'API.
import 'package:omeo_api/omeo_api.dart';

/// Compte de démonstration du flavor mock.
const demoEmail = 'awa@exemple.com';
const demoPassword = 'Omeo2026!';

/// Code d'invitation reconnu par le mock (ONB-13) ; tout autre code au bon
/// format est inconnu (ONB-14).
const demoInviteCode = 'AWA2026';

Map<String, Object?> meJson({
  String email = demoEmail,
  String tier = 'trial',
  bool emailVerified = true,
  String firstName = 'Awa',
  String lastName = 'Diallo',
  List<Map<String, Object?>> pendingDocuments = const [],
  Map<String, Object?> preferences = const {
    'theme': 'system',
    'unit_weight': 'kg',
    'unit_height': 'cm',
    'unit_volume': 'cl',
  },
  Map<String, Object?>? profile,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': '3f2b8c1e-9a4d-4e6b-8c2a-1d5e7f9a0b3c',
    'email': email,
    'email_verified': emailVerified,
    'has_password': true,
    'locale': 'fr',
    'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
    'profile':
        profile ??
        {
          'first_name': firstName,
          'last_name': lastName,
          'initials': '${firstName[0]}${lastName[0]}',
          'birth_date': '1996-04-14',
          'age': 30,
          'sex': 'female',
          'city': {
            'id': '6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f40',
            'name': 'Yaoundé',
            'country': 'CM',
            'timezone': 'Africa/Douala',
          },
          'city_label': 'Yaoundé',
          'height_cm': 168,
          'current_weight_kg': 78.4,
          'target_weight_kg': 74,
          'goals': ['lose_weight', 'eat_balanced', 'prevent_diabetes'],
          'activity_adjustment': true,
          'timezone': 'Africa/Douala',
        },
    'targets': {
      'kcal': 2340,
      'protein_g': 128,
      'carbs_g': 270,
      'fat_g': 72,
      'fiber_g': 30,
      'salt_max_g': 5,
      'water_ml': 2600,
      'bmr_kcal': 1520,
    },
    'entitlements': {
      'tier': tier,
      'trial_ends_at': tier == 'trial'
          ? now.add(const Duration(days: 2)).toIso8601String()
          : null,
      'plus_until': tier == 'plus'
          ? now.add(const Duration(days: 30)).toIso8601String()
          : null,
      'features': {
        'text_analysis': tier != 'free',
        'progress_long_range': tier != 'free',
        'programs': tier != 'free',
        'insights': tier != 'free',
        'offline_workouts': tier == 'plus',
        'streak_freeze': tier != 'free',
      },
    },
    'preferences': preferences,
    'pending_documents': pendingDocuments,
    'rewards_summary': {
      'level': {'rank': 4, 'name': 'Cuisinier', 'min_points': 600},
      'total_points': 640,
      'streak': 12,
      'progress_to_next_percent': 64,
    },
  };
}

Me meFixture({String tier = 'trial', bool emailVerified = true}) =>
    Me.fromJson(meJson(tier: tier, emailVerified: emailVerified));

/// Me après une inscription : profil repris du brouillon de l'onboarding.
Me meFromOnboarding(OnboardingProfile p, String email) => Me.fromJson(
  meJson(
    email: email,
    emailVerified: false,
    firstName: p.firstName,
    lastName: p.lastName,
    profile: {
      'first_name': p.firstName,
      'last_name': p.lastName,
      'initials': '${p.firstName[0]}${p.lastName[0]}'.toUpperCase(),
      'birth_date': p.birthDate.toIso8601String().substring(0, 10),
      'sex': p.sex.value,
      'city_label': p.cityLabel,
      'height_cm': p.heightCm,
      'current_weight_kg': p.weightKg,
      'target_weight_kg': p.targetWeightKg,
      'goals': [for (final g in p.goals) g.value],
      'activity_adjustment': true,
    },
  ),
);

AuthResult authResult(Me me, {bool created = false, String? inviteStatus}) =>
    AuthResult.fromJson({
      'tokens': {
        'access': 'mock-access-${DateTime.now().microsecondsSinceEpoch}',
        'refresh': 'mock-refresh-${DateTime.now().microsecondsSinceEpoch}',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
      },
      'me': me.toJson(),
      'created': created,
      'invite_code_status': ?inviteStatus,
    });

AppConfig appConfigFixture() => AppConfig.fromJson({
  'min_version': {'android': '1.0.0', 'ios': '1.0.0'},
  'latest_version': {'android': '1.0.0', 'ios': '1.0.0'},
  'locales': ['fr', 'en', 'es', 'pt', 'ar', 'zh', 'ja', 'de'],
  'features': <String, bool>{},
  'min_age': 16,
  'trial_days': {'default': 3, 'with_invite': 7},
  'quotas_display': <String, Object?>{},
  'legal_versions': {'terms': 3, 'privacy': 4},
  'support_email': 'support@my-omeo.app',
});

const _cities = [
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f40', 'Yaoundé', 'Cameroun'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f41', 'Yaoundé — Mvog-Ada', 'Cameroun'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f42', 'Dakar', 'Sénégal'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f43', 'Abidjan', "Côte d'Ivoire"),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f44', 'Lomé', 'Togo'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f45', 'Douala', 'Cameroun'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f46', 'Cotonou', 'Bénin'),
  ('6a1f0c2e-1b3d-4c5e-8f7a-9b0c1d2e3f47', 'Bamako', 'Mali'),
];

/// Villes populaires sans requête, sinon filtrage par début de nom.
List<City> citiesFixture(String? query) {
  final q = (query ?? '').toLowerCase();
  final all = [
    for (final (id, name, country) in _cities)
      City(id: id, name: name, country: country),
  ];
  if (q.isEmpty) return all.where((c) => !c.name.contains('—')).toList();
  return all.where((c) => c.name.toLowerCase().startsWith(q)).toList();
}

LegalDocument legalFixture(LegalKind kind) => LegalDocument.fromJson({
  'kind': kind.value,
  'version': kind == LegalKind.privacy ? 4 : 3,
  'title': switch (kind) {
    LegalKind.terms => "Conditions d'utilisation",
    LegalKind.privacy => 'Politique de confidentialité',
    LegalKind.cookies => 'Politique cookies',
    LegalKind.legalNotice => 'Mentions légales',
  },
  'published_at': '2026-12-01T00:00:00Z',
  'body':
      '# Ce qui change\n\n'
      '- Nouvel hébergeur des photos de repas (UE)\n'
      '- Durée de conservation des photos : 24 mois\n'
      "- Précisions sur l'export de tes données\n\n"
      '# Tes droits\n\n'
      'Tu peux consulter, corriger, exporter ou supprimer tes données à '
      'tout moment depuis le profil.',
});
