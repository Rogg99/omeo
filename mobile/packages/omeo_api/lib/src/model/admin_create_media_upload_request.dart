//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_create_media_upload_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCreateMediaUploadRequest {
  /// Returns a new [AdminCreateMediaUploadRequest] instance.
  AdminCreateMediaUploadRequest({
    required this.kind,

    required this.contentType,

    required this.size,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final AdminCreateMediaUploadRequestKindEnum kind;

  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final String contentType;

  // maximum: 524288000
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCreateMediaUploadRequest &&
          other.kind == kind &&
          other.contentType == contentType &&
          other.size == size;

  @override
  int get hashCode => kind.hashCode + contentType.hashCode + size.hashCode;

  factory AdminCreateMediaUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminCreateMediaUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCreateMediaUploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminCreateMediaUploadRequestKindEnum {
  @JsonValue(r'image')
  image(r'image'),
  @JsonValue(r'video')
  video(r'video'),
  @JsonValue(r'subtitles')
  subtitles(r'subtitles');

  const AdminCreateMediaUploadRequestKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
