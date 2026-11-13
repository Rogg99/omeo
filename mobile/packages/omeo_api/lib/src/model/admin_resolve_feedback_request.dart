//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_resolve_feedback_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminResolveFeedbackRequest {
  /// Returns a new [AdminResolveFeedbackRequest] instance.
  AdminResolveFeedbackRequest({
    required this.action,

    this.dishId,

    this.alias,

    this.note,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final AdminResolveFeedbackRequestActionEnum action;

  @JsonKey(name: r'dish_id', required: false, includeIfNull: false)
  final String? dishId;

  @JsonKey(name: r'alias', required: false, includeIfNull: false)
  final String? alias;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminResolveFeedbackRequest &&
          other.action == action &&
          other.dishId == dishId &&
          other.alias == alias &&
          other.note == note;

  @override
  int get hashCode =>
      action.hashCode + dishId.hashCode + alias.hashCode + note.hashCode;

  factory AdminResolveFeedbackRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminResolveFeedbackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminResolveFeedbackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminResolveFeedbackRequestActionEnum {
  @JsonValue(r'handled')
  handled(r'handled'),
  @JsonValue(r'ignore')
  ignore(r'ignore'),
  @JsonValue(r'create_dish')
  createDish(r'create_dish'),
  @JsonValue(r'create_food')
  createFood(r'create_food'),
  @JsonValue(r'add_alias')
  addAlias(r'add_alias'),
  @JsonValue(r'report_defect')
  reportDefect(r'report_defect');

  const AdminResolveFeedbackRequestActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
