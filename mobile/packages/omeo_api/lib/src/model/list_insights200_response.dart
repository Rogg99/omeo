//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/insight.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_insights200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListInsights200Response {
  /// Returns a new [ListInsights200Response] instance.
  ListInsights200Response({required this.results, required this.nextCursor});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Insight> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListInsights200Response &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      results.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ListInsights200Response.fromJson(Map<String, dynamic> json) =>
      _$ListInsights200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListInsights200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
