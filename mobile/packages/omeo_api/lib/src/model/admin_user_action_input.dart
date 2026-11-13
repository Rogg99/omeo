//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_action_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserActionInput {
  /// Returns a new [AdminUserActionInput] instance.
  AdminUserActionInput({
    required this.action,

    this.days,

    this.feature,

    required this.reason,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final AdminUserActionInputActionEnum action;

  // minimum: 1
  // maximum: 365
  @JsonKey(name: r'days', required: false, includeIfNull: false)
  final int? days;

  @JsonKey(name: r'feature', required: false, includeIfNull: false)
  final AdminUserActionInputFeatureEnum? feature;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserActionInput &&
          other.action == action &&
          other.days == days &&
          other.feature == feature &&
          other.reason == reason;

  @override
  int get hashCode =>
      action.hashCode + days.hashCode + feature.hashCode + reason.hashCode;

  factory AdminUserActionInput.fromJson(Map<String, dynamic> json) =>
      _$AdminUserActionInputFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserActionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminUserActionInputActionEnum {
  @JsonValue(r'suspend')
  suspend(r'suspend'),
  @JsonValue(r'reactivate')
  reactivate(r'reactivate'),
  @JsonValue(r'resend_verification')
  resendVerification(r'resend_verification'),
  @JsonValue(r'send_password_reset')
  sendPasswordReset(r'send_password_reset'),
  @JsonValue(r'extend_trial')
  extendTrial(r'extend_trial'),
  @JsonValue(r'grant_plus_days')
  grantPlusDays(r'grant_plus_days'),
  @JsonValue(r'reset_quota')
  resetQuota(r'reset_quota'),
  @JsonValue(r'export_data')
  exportData(r'export_data'),
  @JsonValue(r'delete_data')
  deleteData(r'delete_data');

  const AdminUserActionInputActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminUserActionInputFeatureEnum {
  @JsonValue(r'photo_analysis')
  photoAnalysis(r'photo_analysis'),
  @JsonValue(r'text_analysis')
  textAnalysis(r'text_analysis');

  const AdminUserActionInputFeatureEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
