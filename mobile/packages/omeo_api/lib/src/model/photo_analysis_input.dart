//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'photo_analysis_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PhotoAnalysisInput {
  /// Returns a new [PhotoAnalysisInput] instance.
  PhotoAnalysisInput({required this.kind, required this.uploadId});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PhotoAnalysisInputKindEnum kind;

  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoAnalysisInput &&
          other.kind == kind &&
          other.uploadId == uploadId;

  @override
  int get hashCode => kind.hashCode + uploadId.hashCode;

  factory PhotoAnalysisInput.fromJson(Map<String, dynamic> json) =>
      _$PhotoAnalysisInputFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoAnalysisInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PhotoAnalysisInputKindEnum {
  @JsonValue(r'photo')
  photo(r'photo');

  const PhotoAnalysisInputKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
