//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gauge.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Gauge {
  /// Returns a new [Gauge] instance.
  Gauge({
    required this.value,

    required this.target,

    this.remaining,

    this.overBy,

    required this.percent,

    this.status,
  });

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final num value;

  @JsonKey(name: r'target', required: true, includeIfNull: false)
  final num target;

  /// target - value, borné à 0 côté API
  @JsonKey(name: r'remaining', required: false, includeIfNull: false)
  final num? remaining;

  /// value - target, borné à 0 côté API (dépassement de l'objectif)
  @JsonKey(name: r'over_by', required: false, includeIfNull: false)
  final num? overBy;

  /// 0-100+ (arrondi API)
  @JsonKey(name: r'percent', required: true, includeIfNull: false)
  final int percent;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final GaugeStatusEnum? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gauge &&
          other.value == value &&
          other.target == target &&
          other.remaining == remaining &&
          other.overBy == overBy &&
          other.percent == percent &&
          other.status == status;

  @override
  int get hashCode =>
      value.hashCode +
      target.hashCode +
      remaining.hashCode +
      overBy.hashCode +
      percent.hashCode +
      status.hashCode;

  factory Gauge.fromJson(Map<String, dynamic> json) => _$GaugeFromJson(json);

  Map<String, dynamic> toJson() => _$GaugeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GaugeStatusEnum {
  @JsonValue(r'under')
  under(r'under'),
  @JsonValue(r'on_target')
  onTarget(r'on_target'),
  @JsonValue(r'over')
  over(r'over');

  const GaugeStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
