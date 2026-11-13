//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_overview_referees_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReferralOverviewRefereesInner {
  /// Returns a new [ReferralOverviewRefereesInner] instance.
  ReferralOverviewRefereesInner({this.firstName, this.status, this.date});

  @JsonKey(name: r'first_name', required: false, includeIfNull: false)
  final String? firstName;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final ReferralOverviewRefereesInnerStatusEnum? status;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralOverviewRefereesInner &&
          other.firstName == firstName &&
          other.status == status &&
          other.date == date;

  @override
  int get hashCode => firstName.hashCode + status.hashCode + date.hashCode;

  factory ReferralOverviewRefereesInner.fromJson(Map<String, dynamic> json) =>
      _$ReferralOverviewRefereesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralOverviewRefereesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReferralOverviewRefereesInnerStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'validated')
  validated(r'validated'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const ReferralOverviewRefereesInnerStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
