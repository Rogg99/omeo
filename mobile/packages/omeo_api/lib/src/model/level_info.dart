//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'level_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LevelInfo {
  /// Returns a new [LevelInfo] instance.
  LevelInfo({
    required this.rank,

    required this.name,

    this.icon,

    this.minPoints,
  });

  @JsonKey(name: r'rank', required: true, includeIfNull: false)
  final int rank;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'icon', required: false, includeIfNull: false)
  final Image? icon;

  @JsonKey(name: r'min_points', required: false, includeIfNull: false)
  final int? minPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelInfo &&
          other.rank == rank &&
          other.name == name &&
          other.icon == icon &&
          other.minPoints == minPoints;

  @override
  int get hashCode =>
      rank.hashCode + name.hashCode + icon.hashCode + minPoints.hashCode;

  factory LevelInfo.fromJson(Map<String, dynamic> json) =>
      _$LevelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LevelInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
