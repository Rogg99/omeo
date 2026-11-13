//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/kpi_series_series_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kpi_series.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KpiSeries {
  /// Returns a new [KpiSeries] instance.
  KpiSeries({this.total, this.deltaPercent, this.series});

  @JsonKey(name: r'total', required: false, includeIfNull: false)
  final int? total;

  @JsonKey(name: r'delta_percent', required: false, includeIfNull: false)
  final num? deltaPercent;

  @JsonKey(name: r'series', required: false, includeIfNull: false)
  final List<KpiSeriesSeriesInner>? series;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiSeries &&
          other.total == total &&
          other.deltaPercent == deltaPercent &&
          other.series == series;

  @override
  int get hashCode =>
      total.hashCode +
      (deltaPercent == null ? 0 : deltaPercent.hashCode) +
      series.hashCode;

  factory KpiSeries.fromJson(Map<String, dynamic> json) =>
      _$KpiSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$KpiSeriesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
