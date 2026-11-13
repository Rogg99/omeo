//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/city.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_cities200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchCities200Response {
  /// Returns a new [SearchCities200Response] instance.
  SearchCities200Response({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<City> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchCities200Response && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory SearchCities200Response.fromJson(Map<String, dynamic> json) =>
      _$SearchCities200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchCities200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
