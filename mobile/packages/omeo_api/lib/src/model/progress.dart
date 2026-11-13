//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/progress_summary_last7_inner.dart';
import 'package:omeo_api/src/model/health_connection.dart';
import 'package:omeo_api/src/model/progress_series_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Progress {
  /// Returns a new [Progress] instance.
  Progress({
    required this.metric,

    required this.range,

    required this.unit,

    required this.today,

    this.deltaVsYesterday,

    this.deltaPercent,

    this.target,

    this.average,

    this.empty,

    required this.series,

    required this.summaryLast7,

    this.health,
  });

  @JsonKey(name: r'metric', required: true, includeIfNull: false)
  final String metric;

  @JsonKey(name: r'range', required: true, includeIfNull: false)
  final String range;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final ProgressUnitEnum unit;

  @JsonKey(name: r'today', required: true, includeIfNull: false)
  final num today;

  @JsonKey(name: r'delta_vs_yesterday', required: false, includeIfNull: false)
  final num? deltaVsYesterday;

  @JsonKey(name: r'delta_percent', required: false, includeIfNull: false)
  final int? deltaPercent;

  @JsonKey(name: r'target', required: false, includeIfNull: false)
  final num? target;

  @JsonKey(name: r'average', required: false, includeIfNull: false)
  final num? average;

  /// Aucun repas encore : afficher l'illustration
  @JsonKey(name: r'empty', required: false, includeIfNull: false)
  final bool? empty;

  @JsonKey(name: r'series', required: true, includeIfNull: false)
  final List<ProgressSeriesInner> series;

  @JsonKey(name: r'summary_last_7', required: true, includeIfNull: false)
  final List<ProgressSummaryLast7Inner> summaryLast7;

  @JsonKey(name: r'health', required: false, includeIfNull: false)
  final HealthConnection? health;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Progress &&
          other.metric == metric &&
          other.range == range &&
          other.unit == unit &&
          other.today == today &&
          other.deltaVsYesterday == deltaVsYesterday &&
          other.deltaPercent == deltaPercent &&
          other.target == target &&
          other.average == average &&
          other.empty == empty &&
          other.series == series &&
          other.summaryLast7 == summaryLast7 &&
          other.health == health;

  @override
  int get hashCode =>
      metric.hashCode +
      range.hashCode +
      unit.hashCode +
      today.hashCode +
      deltaVsYesterday.hashCode +
      (deltaPercent == null ? 0 : deltaPercent.hashCode) +
      (target == null ? 0 : target.hashCode) +
      average.hashCode +
      empty.hashCode +
      series.hashCode +
      summaryLast7.hashCode +
      health.hashCode;

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProgressUnitEnum {
  @JsonValue(r'kcal')
  kcal(r'kcal'),
  @JsonValue(r'g')
  g(r'g');

  const ProgressUnitEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
