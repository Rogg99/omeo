//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/badge_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_badge.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserBadge {
  /// Returns a new [UserBadge] instance.
  UserBadge({
    required this.badge,

    required this.family,

    this.description,

    required this.state,

    required this.progressPercent,

    this.progressLabel,

    this.earnedAt,
  });

  @JsonKey(name: r'badge', required: true, includeIfNull: false)
  final BadgeRef badge;

  @JsonKey(name: r'family', required: true, includeIfNull: false)
  final String family;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final UserBadgeStateEnum state;

  @JsonKey(name: r'progress_percent', required: true, includeIfNull: false)
  final int progressPercent;

  @JsonKey(name: r'progress_label', required: false, includeIfNull: false)
  final String? progressLabel;

  @JsonKey(name: r'earned_at', required: false, includeIfNull: false)
  final DateTime? earnedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge &&
          other.badge == badge &&
          other.family == family &&
          other.description == description &&
          other.state == state &&
          other.progressPercent == progressPercent &&
          other.progressLabel == progressLabel &&
          other.earnedAt == earnedAt;

  @override
  int get hashCode =>
      badge.hashCode +
      family.hashCode +
      description.hashCode +
      state.hashCode +
      progressPercent.hashCode +
      progressLabel.hashCode +
      (earnedAt == null ? 0 : earnedAt.hashCode);

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$UserBadgeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UserBadgeStateEnum {
  @JsonValue(r'locked')
  locked(r'locked'),
  @JsonValue(r'in_progress')
  inProgress(r'in_progress'),
  @JsonValue(r'earned')
  earned(r'earned');

  const UserBadgeStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
