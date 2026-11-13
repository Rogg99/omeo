//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_series_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgressSeriesInner {
  /// Returns a new [ProgressSeriesInner] instance.
  ProgressSeriesInner({required this.date, required this.value, this.status});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final num? value;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final ProgressSeriesInnerStatusEnum? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressSeriesInner &&
          other.date == date &&
          other.value == value &&
          other.status == status;

  @override
  int get hashCode =>
      date.hashCode + (value == null ? 0 : value.hashCode) + status.hashCode;

  factory ProgressSeriesInner.fromJson(Map<String, dynamic> json) =>
      _$ProgressSeriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressSeriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProgressSeriesInnerStatusEnum {
  @JsonValue(r'under')
  under(r'under'),
  @JsonValue(r'on_target')
  onTarget(r'on_target'),
  @JsonValue(r'over')
  over(r'over'),
  @JsonValue(r'empty')
  empty(r'empty');

  const ProgressSeriesInnerStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
