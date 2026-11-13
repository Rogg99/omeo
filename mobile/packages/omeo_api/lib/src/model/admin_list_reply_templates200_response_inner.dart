//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_reply_templates200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListReplyTemplates200ResponseInner {
  /// Returns a new [AdminListReplyTemplates200ResponseInner] instance.
  AdminListReplyTemplates200ResponseInner({
    required this.id,

    required this.name,

    this.category,

    required this.body,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final TicketCategory? category;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final Map<String, String> body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListReplyTemplates200ResponseInner &&
          other.id == id &&
          other.name == name &&
          other.category == category &&
          other.body == body;

  @override
  int get hashCode =>
      id.hashCode + name.hashCode + category.hashCode + body.hashCode;

  factory AdminListReplyTemplates200ResponseInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminListReplyTemplates200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminListReplyTemplates200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
