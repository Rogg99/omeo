//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'week_day.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WeekDay {
  /// Returns a new [WeekDay] instance.
  WeekDay({
    required this.date,

    required this.label,

    this.dayNumber,

    required this.isToday,

    required this.status,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'day_number', required: false, includeIfNull: false)
  final int? dayNumber;

  @JsonKey(name: r'is_today', required: true, includeIfNull: false)
  final bool isToday;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final WeekDayStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekDay &&
          other.date == date &&
          other.label == label &&
          other.dayNumber == dayNumber &&
          other.isToday == isToday &&
          other.status == status;

  @override
  int get hashCode =>
      date.hashCode +
      label.hashCode +
      dayNumber.hashCode +
      isToday.hashCode +
      status.hashCode;

  factory WeekDay.fromJson(Map<String, dynamic> json) =>
      _$WeekDayFromJson(json);

  Map<String, dynamic> toJson() => _$WeekDayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WeekDayStatusEnum {
  @JsonValue(r'empty')
  empty(r'empty'),
  @JsonValue(r'partial')
  partial(r'partial'),
  @JsonValue(r'on_target')
  onTarget(r'on_target'),
  @JsonValue(r'over')
  over(r'over'),
  @JsonValue(r'under')
  under(r'under'),
  @JsonValue(r'future')
  future(r'future');

  const WeekDayStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
