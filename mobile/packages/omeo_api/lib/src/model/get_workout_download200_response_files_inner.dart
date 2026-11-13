//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_workout_download200_response_files_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GetWorkoutDownload200ResponseFilesInner {
  /// Returns a new [GetWorkoutDownload200ResponseFilesInner] instance.
  GetWorkoutDownload200ResponseFilesInner({
    required this.exerciseId,

    required this.url,

    required this.size,
  });

  @JsonKey(name: r'exercise_id', required: true, includeIfNull: false)
  final String exerciseId;

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetWorkoutDownload200ResponseFilesInner &&
          other.exerciseId == exerciseId &&
          other.url == url &&
          other.size == size;

  @override
  int get hashCode => exerciseId.hashCode + url.hashCode + size.hashCode;

  factory GetWorkoutDownload200ResponseFilesInner.fromJson(
    Map<String, dynamic> json,
  ) => _$GetWorkoutDownload200ResponseFilesInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetWorkoutDownload200ResponseFilesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
