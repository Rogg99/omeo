//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_point_rule.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPointRule {
  /// Returns a new [AdminPointRule] instance.
  AdminPointRule({
    required this.action,

    required this.points,

    this.cap,

    this.capPeriod,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  // minimum: 0
  @JsonKey(name: r'points', required: true, includeIfNull: false)
  final int points;

  @JsonKey(name: r'cap', required: false, includeIfNull: false)
  final int? cap;

  @JsonKey(name: r'cap_period', required: false, includeIfNull: false)
  final AdminPointRuleCapPeriodEnum? capPeriod;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPointRule &&
          other.action == action &&
          other.points == points &&
          other.cap == cap &&
          other.capPeriod == capPeriod;

  @override
  int get hashCode =>
      action.hashCode +
      points.hashCode +
      (cap == null ? 0 : cap.hashCode) +
      capPeriod.hashCode;

  factory AdminPointRule.fromJson(Map<String, dynamic> json) =>
      _$AdminPointRuleFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPointRuleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminPointRuleCapPeriodEnum {
  @JsonValue(r'day')
  day(r'day'),
  @JsonValue(r'week')
  week(r'week'),
  @JsonValue(r'none')
  none(r'none');

  const AdminPointRuleCapPeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
