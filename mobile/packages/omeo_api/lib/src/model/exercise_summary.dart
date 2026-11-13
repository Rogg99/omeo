//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExerciseSummary {
  /// Returns a new [ExerciseSummary] instance.
  ExerciseSummary({
    required this.id,

    required this.name,

    this.thumbnail,

    this.muscles,

    required this.level,

    this.equipment,

    required this.locked,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSummary &&
          other.id == id &&
          other.name == name &&
          other.thumbnail == thumbnail &&
          other.muscles == muscles &&
          other.level == level &&
          other.equipment == equipment &&
          other.locked == locked;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      thumbnail.hashCode +
      muscles.hashCode +
      level.hashCode +
      equipment.hashCode +
      locked.hashCode;

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
