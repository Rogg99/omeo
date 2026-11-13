//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rule_def.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RuleDef {
  /// Returns a new [RuleDef] instance.
  RuleDef({
    required this.metric,

    required this.operator_,

    required this.threshold,

    this.period,
  });

  @JsonKey(name: r'metric', required: true, includeIfNull: false)
  final RuleDefMetricEnum metric;

  @JsonKey(name: r'operator', required: true, includeIfNull: false)
  final RuleDefOperator_Enum operator_;

  @JsonKey(name: r'threshold', required: true, includeIfNull: false)
  final num threshold;

  @JsonKey(name: r'period', required: false, includeIfNull: false)
  final RuleDefPeriodEnum? period;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleDef &&
          other.metric == metric &&
          other.operator_ == operator_ &&
          other.threshold == threshold &&
          other.period == period;

  @override
  int get hashCode =>
      metric.hashCode +
      operator_.hashCode +
      threshold.hashCode +
      period.hashCode;

  factory RuleDef.fromJson(Map<String, dynamic> json) =>
      _$RuleDefFromJson(json);

  Map<String, dynamic> toJson() => _$RuleDefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RuleDefMetricEnum {
  @JsonValue(r'water_ml')
  waterMl(r'water_ml'),
  @JsonValue(r'steps')
  steps(r'steps'),
  @JsonValue(r'active_minutes')
  activeMinutes(r'active_minutes'),
  @JsonValue(r'meals_count')
  mealsCount(r'meals_count'),
  @JsonValue(r'protein_g')
  proteinG(r'protein_g'),
  @JsonValue(r'kcal_within_target')
  kcalWithinTarget(r'kcal_within_target'),
  @JsonValue(r'workout_completed')
  workoutCompleted(r'workout_completed'),
  @JsonValue(r'weight_logged')
  weightLogged(r'weight_logged'),
  @JsonValue(r'manual')
  manual(r'manual');

  const RuleDefMetricEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RuleDefOperator_Enum {
  @JsonValue(r'gte')
  gte(r'gte'),
  @JsonValue(r'lte')
  lte(r'lte');

  const RuleDefOperator_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RuleDefPeriodEnum {
  @JsonValue(r'day')
  day(r'day');

  const RuleDefPeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
