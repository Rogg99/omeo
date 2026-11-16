import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:omeo_api/omeo_api.dart';

/// Durée maximale relue à chaque synchronisation (30 jours).
const maxSyncWindow = Duration(days: 30);

/// Disponibilité de la source santé de l'appareil.
enum HealthAvailability {
  available,

  /// Android : Health Connect est à installer ou à mettre à jour.
  needsInstall,
  unsupported,
}

/// Lecture seule de Health Connect (Android) et HealthKit (iOS). Jamais
/// simulée, même en flavor mock : autorisation et lecture réelles. Aucune
/// écriture.
abstract interface class HealthReader {
  HealthSyncInputSource_Enum get source;

  Future<HealthAvailability> availability();

  /// Ouvre l'installation de Health Connect (Android).
  Future<void> install();

  /// Demande l'autorisation de lecture ; renvoie les types accordés (vide si
  /// refusé). Appelée au moment où elle sert, jamais à l'onboarding.
  Future<List<SetHealthConnectionRequestGrantedTypesEnum>> requestAccess();

  /// Totaux par jour, séances et pesées depuis [since] (30 jours au plus).
  Future<HealthSyncInput> read({required DateTime since, DateTime? until});
}

/// Implémentation réelle (package health).
final class DeviceHealthReader implements HealthReader {
  DeviceHealthReader() : _health = Health();

  final Health _health;
  bool _configured = false;

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  HealthDataType get _distance => _ios
      ? HealthDataType.DISTANCE_WALKING_RUNNING
      : HealthDataType.DISTANCE_DELTA;

  /// Types lus, avec leur correspondance dans le contrat.
  Map<HealthDataType, SetHealthConnectionRequestGrantedTypesEnum>
  get _types => {
    HealthDataType.STEPS: SetHealthConnectionRequestGrantedTypesEnum.steps,
    _distance: SetHealthConnectionRequestGrantedTypesEnum.distance,
    HealthDataType.ACTIVE_ENERGY_BURNED:
        SetHealthConnectionRequestGrantedTypesEnum.activeCalories,
    HealthDataType.WORKOUT: SetHealthConnectionRequestGrantedTypesEnum.workouts,
    HealthDataType.WEIGHT: SetHealthConnectionRequestGrantedTypesEnum.weight,
    HealthDataType.HEART_RATE:
        SetHealthConnectionRequestGrantedTypesEnum.heartRate,
  };

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  HealthSyncInputSource_Enum get source => _ios
      ? HealthSyncInputSource_Enum.appleHealth
      : HealthSyncInputSource_Enum.healthConnect;

  @override
  Future<HealthAvailability> availability() async {
    await _configure();
    if (_ios) return HealthAvailability.available;
    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthAvailability.needsInstall,
      _ => HealthAvailability.unsupported,
    };
  }

  @override
  Future<void> install() => _health.installHealthConnect();

  @override
  Future<List<SetHealthConnectionRequestGrantedTypesEnum>>
  requestAccess() async {
    await _configure();
    final types = _types.keys.toList();
    final granted = await _health.requestAuthorization(
      types,
      permissions: [for (final _ in types) HealthDataAccess.READ],
    );
    if (!granted) return const [];
    // HealthKit ne dit pas quels types de lecture sont accordés : on
    // considère la demande acceptée dans son ensemble.
    return _types.values.toList();
  }

  @override
  Future<HealthSyncInput> read({
    required DateTime since,
    DateTime? until,
  }) async {
    await _configure();
    final end = until ?? DateTime.now();
    final earliest = end.subtract(maxSyncWindow);
    final start = since.isBefore(earliest) ? earliest : since;
    final points = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(
        types: _types.keys.toList(),
        startTime: start,
        endTime: end,
      ),
    );

    // Totaux par jour local : la lecture de l'appareil est la seule
    // agrégation faite par le mobile (l'API calcule le reste).
    final days = <DateTime, _DayTotals>{};
    final workouts = <HealthSyncInputWorkoutsInner>[];
    final weights = <HealthSyncInputWeightsInner>[];
    for (final p in points) {
      final local = p.dateFrom.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final totals = days.putIfAbsent(day, _DayTotals.new);
      final value = p.value;
      switch (p.type) {
        case HealthDataType.WORKOUT when value is WorkoutHealthValue:
          workouts.add(
            HealthSyncInputWorkoutsInner(
              externalId: p.uuid,
              type: value.workoutActivityType.name.toLowerCase(),
              startedAt: p.dateFrom.toUtc(),
              durationS: p.dateTo.difference(p.dateFrom).inSeconds,
              kcal: value.totalEnergyBurned,
              distanceM: value.totalDistance,
            ),
          );
        case HealthDataType.WEIGHT when value is NumericHealthValue:
          weights.add(
            HealthSyncInputWeightsInner(
              measuredAt: p.dateFrom.toUtc(),
              weightKg: value.numericValue,
            ),
          );
        case HealthDataType.STEPS when value is NumericHealthValue:
          totals.steps += value.numericValue.round();
        case HealthDataType.ACTIVE_ENERGY_BURNED
            when value is NumericHealthValue:
          totals.activeKcal += value.numericValue.round();
        case _ when p.type == _distance && value is NumericHealthValue:
          totals.distanceM += value.numericValue.round();
        case _:
          break;
      }
    }
    return HealthSyncInput(
      source_: source,
      days: [
        for (final e in days.entries)
          HealthSyncInputDaysInner(
            date: e.key,
            steps: e.value.steps,
            distanceM: e.value.distanceM,
            activeKcal: e.value.activeKcal,
          ),
      ],
      workouts: workouts,
      weights: weights,
    );
  }
}

class _DayTotals {
  int steps = 0;
  int distanceM = 0;
  int activeKcal = 0;
}

/// Lecteur santé de l'appareil (réel dans tous les flavors).
final healthReaderProvider = Provider<HealthReader>(
  (ref) => DeviceHealthReader(),
);
