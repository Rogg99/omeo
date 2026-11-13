//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/food_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_foods200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchFoods200Response {
  /// Returns a new [SearchFoods200Response] instance.
  SearchFoods200Response({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<FoodSummary> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFoods200Response && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory SearchFoods200Response.fromJson(Map<String, dynamic> json) =>
      _$SearchFoods200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchFoods200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
