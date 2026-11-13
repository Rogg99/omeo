//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/water.dart';
import 'package:omeo_api/src/model/day_detail_meals_by_type_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'day_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DayDetail {
  /// Returns a new [DayDetail] instance.
  DayDetail({
    required this.day,

    required this.mealsByType,

    required this.water,

    required this.message,

    this.previousDate,

    this.nextDate,
  });

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  @JsonKey(name: r'meals_by_type', required: true, includeIfNull: false)
  final List<DayDetailMealsByTypeInner> mealsByType;

  @JsonKey(name: r'water', required: true, includeIfNull: false)
  final Water water;

  /// Encouragement adapté à la journée
  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'previous_date', required: false, includeIfNull: false)
  final DateTime? previousDate;

  @JsonKey(name: r'next_date', required: false, includeIfNull: false)
  final DateTime? nextDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayDetail &&
          other.day == day &&
          other.mealsByType == mealsByType &&
          other.water == water &&
          other.message == message &&
          other.previousDate == previousDate &&
          other.nextDate == nextDate;

  @override
  int get hashCode =>
      day.hashCode +
      mealsByType.hashCode +
      water.hashCode +
      message.hashCode +
      previousDate.hashCode +
      (nextDate == null ? 0 : nextDate.hashCode);

  factory DayDetail.fromJson(Map<String, dynamic> json) =>
      _$DayDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DayDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
