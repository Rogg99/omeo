//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_upload_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateUploadRequest {
  /// Returns a new [CreateUploadRequest] instance.
  CreateUploadRequest({
    required this.kind,

    required this.contentType,

    required this.size,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final CreateUploadRequestKindEnum kind;

  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final CreateUploadRequestContentTypeEnum contentType;

  // minimum: 1
  // maximum: 8388608
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateUploadRequest &&
          other.kind == kind &&
          other.contentType == contentType &&
          other.size == size;

  @override
  int get hashCode => kind.hashCode + contentType.hashCode + size.hashCode;

  factory CreateUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateUploadRequestKindEnum {
  @JsonValue(r'meal_photo')
  mealPhoto(r'meal_photo'),
  @JsonValue(r'avatar')
  avatar(r'avatar'),
  @JsonValue(r'support_attachment')
  supportAttachment(r'support_attachment');

  const CreateUploadRequestKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CreateUploadRequestContentTypeEnum {
  @JsonValue(r'image/jpeg')
  imageSlashJpeg(r'image/jpeg'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'image/webp')
  imageSlashWebp(r'image/webp'),
  @JsonValue(r'image/heic')
  imageSlashHeic(r'image/heic');

  const CreateUploadRequestContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
