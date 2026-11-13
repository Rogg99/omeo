//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/exercise_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_exercises200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListExercises200Response {
  /// Returns a new [ListExercises200Response] instance.
  ListExercises200Response({required this.results, required this.nextCursor});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<ExerciseSummary> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListExercises200Response &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      results.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ListExercises200Response.fromJson(Map<String, dynamic> json) =>
      _$ListExercises200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListExercises200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
