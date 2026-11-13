//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/level.dart';
import 'package:omeo_api/src/model/media.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExerciseDetail {
  /// Returns a new [ExerciseDetail] instance.
  ExerciseDetail({
    required this.id,

    required this.name,

    this.thumbnail,

    this.muscles,

    required this.level,

    this.equipment,

    required this.locked,

    required this.instructions,

    required this.video,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'thumbnail', required: false, includeIfNull: false)
  final Image? thumbnail;

  @JsonKey(name: r'muscles', required: false, includeIfNull: false)
  final List<String>? muscles;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final Level level;

  @JsonKey(name: r'equipment', required: false, includeIfNull: false)
  final List<String>? equipment;

  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  @JsonKey(name: r'instructions', required: true, includeIfNull: false)
  final String instructions;

  @JsonKey(name: r'video', required: true, includeIfNull: false)
  final Media video;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseDetail &&
          other.id == id &&
          other.name == name &&
          other.thumbnail == thumbnail &&
          other.muscles == muscles &&
          other.level == level &&
          other.equipment == equipment &&
          other.locked == locked &&
          other.instructions == instructions &&
          other.video == video;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      thumbnail.hashCode +
      muscles.hashCode +
      level.hashCode +
      equipment.hashCode +
      locked.hashCode +
      instructions.hashCode +
      video.hashCode;

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
