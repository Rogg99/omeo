//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/content_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_transition_content_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTransitionContentRequest {
  /// Returns a new [AdminTransitionContentRequest] instance.
  AdminTransitionContentRequest({required this.to, this.comment});

  @JsonKey(name: r'to', required: true, includeIfNull: false)
  final ContentStatus to;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminTransitionContentRequest &&
          other.to == to &&
          other.comment == comment;

  @override
  int get hashCode => to.hashCode + comment.hashCode;

  factory AdminTransitionContentRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminTransitionContentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTransitionContentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
