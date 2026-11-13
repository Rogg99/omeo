//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/admin_program_days_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_program.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminProgram {
  /// Returns a new [AdminProgram] instance.
  AdminProgram({
    required this.name,

    this.description,

    required this.goal,

    required this.weeks,

    this.points,

    this.badgeId,

    this.coverUploadId,

    required this.days,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final Goal goal;

  // minimum: 1
  // maximum: 52
  @JsonKey(name: r'weeks', required: true, includeIfNull: false)
  final int weeks;

  @JsonKey(name: r'points', required: false, includeIfNull: false)
  final int? points;

  @JsonKey(name: r'badge_id', required: false, includeIfNull: false)
  final String? badgeId;

  @JsonKey(name: r'cover_upload_id', required: false, includeIfNull: false)
  final String? coverUploadId;

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<AdminProgramDaysInner> days;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProgram &&
          other.name == name &&
          other.description == description &&
          other.goal == goal &&
          other.weeks == weeks &&
          other.points == points &&
          other.badgeId == badgeId &&
          other.coverUploadId == coverUploadId &&
          other.days == days;

  @override
  int get hashCode =>
      name.hashCode +
      description.hashCode +
      goal.hashCode +
      weeks.hashCode +
      points.hashCode +
      (badgeId == null ? 0 : badgeId.hashCode) +
      coverUploadId.hashCode +
      days.hashCode;

  factory AdminProgram.fromJson(Map<String, dynamic> json) =>
      _$AdminProgramFromJson(json);

  Map<String, dynamic> toJson() => _$AdminProgramToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
