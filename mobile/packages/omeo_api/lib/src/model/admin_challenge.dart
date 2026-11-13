//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/rule_def.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_challenge.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminChallenge {
  /// Returns a new [AdminChallenge] instance.
  AdminChallenge({
    required this.name,

    this.description,

    required this.durationDays,

    required this.rule,

    this.successThreshold = 0.8,

    this.pointsPerDay,

    this.pointsCompletion,

    this.badgeId,

    this.coverUploadId,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  // minimum: 7
  // maximum: 30
  @JsonKey(name: r'duration_days', required: true, includeIfNull: false)
  final int durationDays;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final RuleDef rule;

  // minimum: 0.5
  // maximum: 1
  @JsonKey(
    defaultValue: 0.8,
    name: r'success_threshold',
    required: false,
    includeIfNull: false,
  )
  final num? successThreshold;

  @JsonKey(name: r'points_per_day', required: false, includeIfNull: false)
  final int? pointsPerDay;

  @JsonKey(name: r'points_completion', required: false, includeIfNull: false)
  final int? pointsCompletion;

  @JsonKey(name: r'badge_id', required: false, includeIfNull: false)
  final String? badgeId;

  @JsonKey(name: r'cover_upload_id', required: false, includeIfNull: false)
  final String? coverUploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminChallenge &&
          other.name == name &&
          other.description == description &&
          other.durationDays == durationDays &&
          other.rule == rule &&
          other.successThreshold == successThreshold &&
          other.pointsPerDay == pointsPerDay &&
          other.pointsCompletion == pointsCompletion &&
          other.badgeId == badgeId &&
          other.coverUploadId == coverUploadId;

  @override
  int get hashCode =>
      name.hashCode +
      description.hashCode +
      durationDays.hashCode +
      rule.hashCode +
      successThreshold.hashCode +
      pointsPerDay.hashCode +
      pointsCompletion.hashCode +
      (badgeId == null ? 0 : badgeId.hashCode) +
      coverUploadId.hashCode;

  factory AdminChallenge.fromJson(Map<String, dynamic> json) =>
      _$AdminChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminChallengeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
