//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_meals200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListMeals200Response {
  /// Returns a new [ListMeals200Response] instance.
  ListMeals200Response({required this.results, required this.nextCursor});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Meal> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListMeals200Response &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      results.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ListMeals200Response.fromJson(Map<String, dynamic> json) =>
      _$ListMeals200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListMeals200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
