//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/program_day_view.dart';
import 'package:omeo_api/src/model/program_detail_all_of_rewards.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramDetail {
  /// Returns a new [ProgramDetail] instance.
  ProgramDetail({
    required this.id,

    required this.name,

    this.description,

    required this.goal,

    required this.weeks,

    this.cover,

    required this.locked,

    this.isActive,

    this.daysPreview,

    this.rewards,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final Goal goal;

  @JsonKey(name: r'weeks', required: true, includeIfNull: false)
  final int weeks;

  @JsonKey(name: r'cover', required: false, includeIfNull: false)
  final Image? cover;

  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  @JsonKey(name: r'is_active', required: false, includeIfNull: false)
  final bool? isActive;

  @JsonKey(name: r'days_preview', required: false, includeIfNull: false)
  final List<ProgramDayView>? daysPreview;

  @JsonKey(name: r'rewards', required: false, includeIfNull: false)
  final ProgramDetailAllOfRewards? rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDetail &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.goal == goal &&
          other.weeks == weeks &&
          other.cover == cover &&
          other.locked == locked &&
          other.isActive == isActive &&
          other.daysPreview == daysPreview &&
          other.rewards == rewards;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      description.hashCode +
      goal.hashCode +
      weeks.hashCode +
      cover.hashCode +
      locked.hashCode +
      isActive.hashCode +
      daysPreview.hashCode +
      rewards.hashCode;

  factory ProgramDetail.fromJson(Map<String, dynamic> json) =>
      _$ProgramDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
