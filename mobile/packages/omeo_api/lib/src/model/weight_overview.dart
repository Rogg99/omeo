//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/weight_overview_series_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weight_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WeightOverview {
  /// Returns a new [WeightOverview] instance.
  WeightOverview({
    required this.currentKg,

    required this.targetKg,

    required this.remainingKg,

    this.startKg,

    this.trend,

    this.trendKgPerWeek,

    this.bmi,

    required this.series,

    this.nextReminder,
  });

  @JsonKey(name: r'current_kg', required: true, includeIfNull: true)
  final num? currentKg;

  @JsonKey(name: r'target_kg', required: true, includeIfNull: false)
  final num targetKg;

  @JsonKey(name: r'remaining_kg', required: true, includeIfNull: true)
  final num? remainingKg;

  @JsonKey(name: r'start_kg', required: false, includeIfNull: false)
  final num? startKg;

  @JsonKey(name: r'trend', required: false, includeIfNull: false)
  final WeightOverviewTrendEnum? trend;

  @JsonKey(name: r'trend_kg_per_week', required: false, includeIfNull: false)
  final num? trendKgPerWeek;

  @JsonKey(name: r'bmi', required: false, includeIfNull: false)
  final num? bmi;

  @JsonKey(name: r'series', required: true, includeIfNull: false)
  final List<WeightOverviewSeriesInner> series;

  @JsonKey(name: r'next_reminder', required: false, includeIfNull: false)
  final DateTime? nextReminder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightOverview &&
          other.currentKg == currentKg &&
          other.targetKg == targetKg &&
          other.remainingKg == remainingKg &&
          other.startKg == startKg &&
          other.trend == trend &&
          other.trendKgPerWeek == trendKgPerWeek &&
          other.bmi == bmi &&
          other.series == series &&
          other.nextReminder == nextReminder;

  @override
  int get hashCode =>
      (currentKg == null ? 0 : currentKg.hashCode) +
      targetKg.hashCode +
      (remainingKg == null ? 0 : remainingKg.hashCode) +
      (startKg == null ? 0 : startKg.hashCode) +
      trend.hashCode +
      (trendKgPerWeek == null ? 0 : trendKgPerWeek.hashCode) +
      (bmi == null ? 0 : bmi.hashCode) +
      series.hashCode +
      (nextReminder == null ? 0 : nextReminder.hashCode);

  factory WeightOverview.fromJson(Map<String, dynamic> json) =>
      _$WeightOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$WeightOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WeightOverviewTrendEnum {
  @JsonValue(r'down')
  down(r'down'),
  @JsonValue(r'stable')
  stable(r'stable'),
  @JsonValue(r'up')
  up(r'up'),
  @JsonValue(r'unknown')
  unknown(r'unknown');

  const WeightOverviewTrendEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
