//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_invite_code200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckInviteCode200Response {
  /// Returns a new [CheckInviteCode200Response] instance.
  CheckInviteCode200Response({
    required this.valid,

    this.referrerFirstName,

    required this.trialDays,
  });

  @JsonKey(name: r'valid', required: true, includeIfNull: false)
  final bool valid;

  /// Pour « Awa t'invite »
  @JsonKey(name: r'referrer_first_name', required: false, includeIfNull: false)
  final String? referrerFirstName;

  @JsonKey(name: r'trial_days', required: true, includeIfNull: false)
  final int trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInviteCode200Response &&
          other.valid == valid &&
          other.referrerFirstName == referrerFirstName &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      valid.hashCode +
      (referrerFirstName == null ? 0 : referrerFirstName.hashCode) +
      trialDays.hashCode;

  factory CheckInviteCode200Response.fromJson(Map<String, dynamic> json) =>
      _$CheckInviteCode200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInviteCode200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
