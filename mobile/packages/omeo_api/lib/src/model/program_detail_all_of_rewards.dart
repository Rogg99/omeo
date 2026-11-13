//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/badge_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_detail_all_of_rewards.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramDetailAllOfRewards {
  /// Returns a new [ProgramDetailAllOfRewards] instance.
  ProgramDetailAllOfRewards({this.points, this.badge});

  @JsonKey(name: r'points', required: false, includeIfNull: false)
  final int? points;

  @JsonKey(name: r'badge', required: false, includeIfNull: false)
  final BadgeRef? badge;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDetailAllOfRewards &&
          other.points == points &&
          other.badge == badge;

  @override
  int get hashCode => points.hashCode + badge.hashCode;

  factory ProgramDetailAllOfRewards.fromJson(Map<String, dynamic> json) =>
      _$ProgramDetailAllOfRewardsFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDetailAllOfRewardsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
