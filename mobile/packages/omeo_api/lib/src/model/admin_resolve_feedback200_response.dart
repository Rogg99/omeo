//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_resolve_feedback200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminResolveFeedback200Response {
  /// Returns a new [AdminResolveFeedback200Response] instance.
  AdminResolveFeedback200Response({
    required this.status,

    this.createdContentId,
  });

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final String status;

  @JsonKey(name: r'created_content_id', required: false, includeIfNull: false)
  final String? createdContentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminResolveFeedback200Response &&
          other.status == status &&
          other.createdContentId == createdContentId;

  @override
  int get hashCode =>
      status.hashCode +
      (createdContentId == null ? 0 : createdContentId.hashCode);

  factory AdminResolveFeedback200Response.fromJson(Map<String, dynamic> json) =>
      _$AdminResolveFeedback200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminResolveFeedback200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
