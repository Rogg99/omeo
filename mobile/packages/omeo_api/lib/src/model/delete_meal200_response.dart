//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_meal200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteMeal200Response {
  /// Returns a new [DeleteMeal200Response] instance.
  DeleteMeal200Response({required this.day});

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteMeal200Response && other.day == day;

  @override
  int get hashCode => day.hashCode;

  factory DeleteMeal200Response.fromJson(Map<String, dynamic> json) =>
      _$DeleteMeal200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteMeal200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
