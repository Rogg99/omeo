//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_exercise.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminExercise {
  /// Returns a new [AdminExercise] instance.
  AdminExercise({
    required this.name,

    required this.instructions,

    this.muscles,

    required this.level,

    this.equipment,

    required this.met,

    this.isFree,

    this.videoUploadId,

    this.subtitleUploadIds,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'instructions', required: true, includeIfNull: false)
  final Map<String, String> instructions;

  @JsonKey(name: r'muscles', required: false, includeIfNull: false)
  final List<String>? muscles;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final Level level;

  @JsonKey(name: r'equipment', required: false, includeIfNull: false)
  final List<String>? equipment;

  // minimum: 1
  // maximum: 20
  @JsonKey(name: r'met', required: true, includeIfNull: false)
  final num met;

  @JsonKey(name: r'is_free', required: false, includeIfNull: false)
  final bool? isFree;

  @JsonKey(name: r'video_upload_id', required: false, includeIfNull: false)
  final String? videoUploadId;

  @JsonKey(name: r'subtitle_upload_ids', required: false, includeIfNull: false)
  final Map<String, String>? subtitleUploadIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminExercise &&
          other.name == name &&
          other.instructions == instructions &&
          other.muscles == muscles &&
          other.level == level &&
          other.equipment == equipment &&
          other.met == met &&
          other.isFree == isFree &&
          other.videoUploadId == videoUploadId &&
          other.subtitleUploadIds == subtitleUploadIds;

  @override
  int get hashCode =>
      name.hashCode +
      instructions.hashCode +
      muscles.hashCode +
      level.hashCode +
      equipment.hashCode +
      met.hashCode +
      isFree.hashCode +
      videoUploadId.hashCode +
      subtitleUploadIds.hashCode;

  factory AdminExercise.fromJson(Map<String, dynamic> json) =>
      _$AdminExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminExerciseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
