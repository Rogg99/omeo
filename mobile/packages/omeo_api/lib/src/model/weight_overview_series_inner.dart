//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weight_overview_series_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WeightOverviewSeriesInner {
  /// Returns a new [WeightOverviewSeriesInner] instance.
  WeightOverviewSeriesInner({
    required this.id,

    required this.date,

    required this.weightKg,

    required this.source_,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'weight_kg', required: true, includeIfNull: false)
  final num weightKg;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final WeightOverviewSeriesInnerSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightOverviewSeriesInner &&
          other.id == id &&
          other.date == date &&
          other.weightKg == weightKg &&
          other.source_ == source_;

  @override
  int get hashCode =>
      id.hashCode + date.hashCode + weightKg.hashCode + source_.hashCode;

  factory WeightOverviewSeriesInner.fromJson(Map<String, dynamic> json) =>
      _$WeightOverviewSeriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$WeightOverviewSeriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WeightOverviewSeriesInnerSource_Enum {
  @JsonValue(r'manual')
  manual(r'manual'),
  @JsonValue(r'health_connect')
  healthConnect(r'health_connect'),
  @JsonValue(r'apple_health')
  appleHealth(r'apple_health');

  const WeightOverviewSeriesInnerSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
