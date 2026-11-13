//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kpi_series_series_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KpiSeriesSeriesInner {
  /// Returns a new [KpiSeriesSeriesInner] instance.
  KpiSeriesSeriesInner({this.date, this.value});

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @JsonKey(name: r'value', required: false, includeIfNull: false)
  final num? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiSeriesSeriesInner &&
          other.date == date &&
          other.value == value;

  @override
  int get hashCode => date.hashCode + value.hashCode;

  factory KpiSeriesSeriesInner.fromJson(Map<String, dynamic> json) =>
      _$KpiSeriesSeriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$KpiSeriesSeriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
