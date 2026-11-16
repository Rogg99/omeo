import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/units/units.dart';
import 'package:omeo/features/auth/data/local_store.dart';
import 'package:omeo_api/omeo_api.dart';

/// Nombre d'étapes du questionnaire avant la création du compte.
const onboardingQuestionSteps = 8;

/// Objectifs qui s'excluent : perdre du poids et prendre de la masse.
const Map<Goal, Goal> incompatibleGoals = {
  Goal.loseWeight: Goal.gainMuscle,
  Goal.gainMuscle: Goal.loseWeight,
};

/// Réponses aux étapes 1 à 8, gardées sur le téléphone jusqu'à la création
/// du compte.
@immutable
final class OnboardingDraft {
  const OnboardingDraft({
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.sex,
    this.cityId,
    this.cityLabel,
    this.cityCountry,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.goals = const {},
    this.heightUnit = UnitSystem.metric,
    this.weightUnit = UnitSystem.metric,
    this.step = 1,
  });

  factory OnboardingDraft.fromJson(Map<String, Object?> json) {
    T? pick<T>(String key) => json[key] is T ? json[key] as T : null;
    final birth = pick<String>('birth_date');
    return OnboardingDraft(
      firstName: pick<String>('first_name') ?? '',
      lastName: pick<String>('last_name') ?? '',
      birthDate: birth == null ? null : DateTime.tryParse(birth),
      sex: Sex.values.where((s) => s.value == pick<String>('sex')).firstOrNull,
      cityId: pick<String>('city_id'),
      cityLabel: pick<String>('city_label'),
      cityCountry: pick<String>('city_country'),
      heightCm: pick<num>('height_cm')?.toDouble(),
      weightKg: pick<num>('weight_kg')?.toDouble(),
      targetWeightKg: pick<num>('target_weight_kg')?.toDouble(),
      goals: {
        for (final g in pick<List<Object?>>('goals') ?? const <Object?>[])
          ...Goal.values.where((v) => v.value == g),
      },
      heightUnit: pick<String>('height_unit') == UnitSystem.imperial.name
          ? UnitSystem.imperial
          : UnitSystem.metric,
      weightUnit: pick<String>('weight_unit') == UnitSystem.imperial.name
          ? UnitSystem.imperial
          : UnitSystem.metric,
      step: (pick<int>('step') ?? 1).clamp(1, onboardingQuestionSteps + 1),
    );
  }

  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final Sex? sex;
  final String? cityId;
  final String? cityLabel;
  final String? cityCountry;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final Set<Goal> goals;
  final UnitSystem heightUnit;
  final UnitSystem weightUnit;

  /// Dernière étape atteinte (9 : création du compte).
  final int step;

  static const nameMaxLength = 40;
  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;
  static const minWeightKg = 30.0;
  static const maxWeightKg = 300.0;

  /// Vrai si l'étape [n] a une réponse valide (le bouton Continuer s'active).
  bool isStepComplete(int n) => switch (n) {
    1 => firstName.trim().isNotEmpty && lastName.trim().isNotEmpty,
    2 => birthDate != null,
    3 => sex != null,
    4 => (cityLabel ?? '').trim().isNotEmpty,
    5 => _inRange(heightCm, minHeightCm, maxHeightCm),
    6 => _inRange(weightKg, minWeightKg, maxWeightKg),
    7 => _inRange(targetWeightKg, minWeightKg, maxWeightKg),
    8 => goals.isNotEmpty,
    _ => false,
  };

  /// Toutes les réponses nécessaires à l'inscription sont là.
  bool get isComplete => [
    for (var i = 1; i <= onboardingQuestionSteps; i++) i,
  ].every(isStepComplete);

  static bool _inRange(double? v, double min, double max) =>
      v != null && v >= min && v <= max;

  /// Profil envoyé à POST /auth/register ou /auth/social.
  OnboardingProfile toProfile({required String locale, String? timezone}) =>
      OnboardingProfile(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        birthDate: birthDate!,
        sex: sex!,
        cityId: cityId,
        cityLabel: cityLabel?.trim(),
        heightCm: heightCm!,
        weightKg: weightKg!,
        targetWeightKg: targetWeightKg!,
        goals: goals,
        locale: Locale.values.where((l) => l.value == locale).firstOrNull,
        timezone: timezone,
      );

  Map<String, Object?> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    if (birthDate != null)
      'birth_date': birthDate!.toIso8601String().substring(0, 10),
    if (sex != null) 'sex': sex!.value,
    'city_id': ?cityId,
    'city_label': ?cityLabel,
    'city_country': ?cityCountry,
    'height_cm': ?heightCm,
    'weight_kg': ?weightKg,
    'target_weight_kg': ?targetWeightKg,
    'goals': [for (final g in goals) g.value],
    'height_unit': heightUnit.name,
    'weight_unit': weightUnit.name,
    'step': step,
  };

  OnboardingDraft copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    Sex? sex,
    ({String? id, String label, String? country})? city,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    Set<Goal>? goals,
    UnitSystem? heightUnit,
    UnitSystem? weightUnit,
    int? step,
  }) => OnboardingDraft(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    cityId: city == null ? cityId : city.id,
    cityLabel: city == null ? cityLabel : city.label,
    cityCountry: city == null ? cityCountry : city.country,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    goals: goals ?? this.goals,
    heightUnit: heightUnit ?? this.heightUnit,
    weightUnit: weightUnit ?? this.weightUnit,
    step: step ?? this.step,
  );

  /// Poids actuel ou cible saisi ; `null` quand le champ est vidé.
  OnboardingDraft withWeight(double? kg, {required bool target}) =>
      OnboardingDraft.fromJson({
        ...toJson(),
        target ? 'target_weight_kg' : 'weight_kg': kg,
      });

  @override
  bool operator ==(Object other) =>
      other is OnboardingDraft &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// Persistance du brouillon (chiffrée : il contient des données de santé).
final class OnboardingDraftStore {
  const OnboardingDraftStore(this._store);

  final LocalStore _store;
  static const _key = 'omeo.onboarding.draft';

  Future<OnboardingDraft> read() async {
    final raw = await _store.read(_key);
    if (raw == null) return const OnboardingDraft();
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?>
          ? OnboardingDraft.fromJson(json)
          : const OnboardingDraft();
    } on FormatException {
      return const OnboardingDraft();
    }
  }

  Future<void> write(OnboardingDraft draft) =>
      _store.write(_key, jsonEncode(draft.toJson()));

  /// Effacé une fois le compte créé.
  Future<void> clear() => _store.delete(_key);
}

final onboardingDraftStoreProvider = Provider<OnboardingDraftStore>(
  (ref) => OnboardingDraftStore(ref.watch(localStoreProvider)),
);
