//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramSummary {
  /// Returns a new [ProgramSummary] instance.
  ProgramSummary({
    required this.id,

    required this.name,

    this.description,

    required this.goal,

    required this.weeks,

    this.cover,

    required this.locked,

    this.isActive,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramSummary &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.goal == goal &&
          other.weeks == weeks &&
          other.cover == cover &&
          other.locked == locked &&
          other.isActive == isActive;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      description.hashCode +
      goal.hashCode +
      weeks.hashCode +
      cover.hashCode +
      locked.hashCode +
      isActive.hashCode;

  factory ProgramSummary.fromJson(Map<String, dynamic> json) =>
      _$ProgramSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
