//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/get_workout_download200_response_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_workout_download200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GetWorkoutDownload200Response {
  /// Returns a new [GetWorkoutDownload200Response] instance.
  GetWorkoutDownload200Response({required this.expiresAt, required this.files});

  @JsonKey(name: r'expires_at', required: true, includeIfNull: false)
  final DateTime expiresAt;

  @JsonKey(name: r'files', required: true, includeIfNull: false)
  final List<GetWorkoutDownload200ResponseFilesInner> files;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetWorkoutDownload200Response &&
          other.expiresAt == expiresAt &&
          other.files == files;

  @override
  int get hashCode => expiresAt.hashCode + files.hashCode;

  factory GetWorkoutDownload200Response.fromJson(Map<String, dynamic> json) =>
      _$GetWorkoutDownload200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetWorkoutDownload200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
