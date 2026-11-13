//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/gauge.dart';
import 'package:omeo_api/src/model/activity.dart';
import 'package:omeo_api/src/model/health_connection.dart';
import 'package:omeo_api/src/model/activity_overview_balance_week_inner.dart';
import 'package:omeo_api/src/model/workout_summary.dart';
import 'package:omeo_api/src/model/balance.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityOverview {
  /// Returns a new [ActivityOverview] instance.
  ActivityOverview({
    required this.date,

    required this.steps,

    this.distanceM,

    this.activeKcal,

    this.activeMinutes,

    required this.health,

    required this.balanceDay,

    required this.balanceWeek,

    required this.activities,

    this.recommendedWorkouts,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final Gauge steps;

  @JsonKey(name: r'distance_m', required: false, includeIfNull: false)
  final int? distanceM;

  @JsonKey(name: r'active_kcal', required: false, includeIfNull: false)
  final int? activeKcal;

  @JsonKey(name: r'active_minutes', required: false, includeIfNull: false)
  final int? activeMinutes;

  @JsonKey(name: r'health', required: true, includeIfNull: false)
  final HealthConnection health;

  @JsonKey(name: r'balance_day', required: true, includeIfNull: false)
  final Balance balanceDay;

  @JsonKey(name: r'balance_week', required: true, includeIfNull: false)
  final List<ActivityOverviewBalanceWeekInner> balanceWeek;

  @JsonKey(name: r'activities', required: true, includeIfNull: false)
  final List<Activity> activities;

  @JsonKey(name: r'recommended_workouts', required: false, includeIfNull: false)
  final List<WorkoutSummary>? recommendedWorkouts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityOverview &&
          other.date == date &&
          other.steps == steps &&
          other.distanceM == distanceM &&
          other.activeKcal == activeKcal &&
          other.activeMinutes == activeMinutes &&
          other.health == health &&
          other.balanceDay == balanceDay &&
          other.balanceWeek == balanceWeek &&
          other.activities == activities &&
          other.recommendedWorkouts == recommendedWorkouts;

  @override
  int get hashCode =>
      date.hashCode +
      steps.hashCode +
      distanceM.hashCode +
      activeKcal.hashCode +
      activeMinutes.hashCode +
      health.hashCode +
      balanceDay.hashCode +
      balanceWeek.hashCode +
      activities.hashCode +
      recommendedWorkouts.hashCode;

  factory ActivityOverview.fromJson(Map<String, dynamic> json) =>
      _$ActivityOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
