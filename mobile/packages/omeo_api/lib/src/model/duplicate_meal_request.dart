//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'duplicate_meal_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DuplicateMealRequest {
  /// Returns a new [DuplicateMealRequest] instance.
  DuplicateMealRequest({required this.date, required this.mealType});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'meal_type', required: true, includeIfNull: false)
  final MealType mealType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateMealRequest &&
          other.date == date &&
          other.mealType == mealType;

  @override
  int get hashCode => date.hashCode + mealType.hashCode;

  factory DuplicateMealRequest.fromJson(Map<String, dynamic> json) =>
      _$DuplicateMealRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DuplicateMealRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
