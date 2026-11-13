//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_avatar_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetAvatarRequest {
  /// Returns a new [SetAvatarRequest] instance.
  SetAvatarRequest({required this.uploadId});

  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetAvatarRequest && other.uploadId == uploadId;

  @override
  int get hashCode => uploadId.hashCode;

  factory SetAvatarRequest.fromJson(Map<String, dynamic> json) =>
      _$SetAvatarRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetAvatarRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
