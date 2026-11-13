//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_analysis_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateAnalysisRequest {
  /// Returns a new [CreateAnalysisRequest] instance.
  CreateAnalysisRequest({
    required this.kind,

    required this.uploadId,

    required this.text,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final CreateAnalysisRequestKindEnum kind;

  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateAnalysisRequest &&
          other.kind == kind &&
          other.uploadId == uploadId &&
          other.text == text;

  @override
  int get hashCode => kind.hashCode + uploadId.hashCode + text.hashCode;

  factory CreateAnalysisRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAnalysisRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAnalysisRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateAnalysisRequestKindEnum {
  @JsonValue(r'text')
  text(r'text');

  const CreateAnalysisRequestKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
