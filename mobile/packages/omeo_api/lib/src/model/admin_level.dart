//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_level.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLevel {
  /// Returns a new [AdminLevel] instance.
  AdminLevel({
    required this.rank,

    required this.name,

    required this.minPoints,

    this.iconUploadId,
  });

  // minimum: 1
  @JsonKey(name: r'rank', required: true, includeIfNull: false)
  final int rank;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  // minimum: 0
  @JsonKey(name: r'min_points', required: true, includeIfNull: false)
  final int minPoints;

  @JsonKey(name: r'icon_upload_id', required: false, includeIfNull: false)
  final String? iconUploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminLevel &&
          other.rank == rank &&
          other.name == name &&
          other.minPoints == minPoints &&
          other.iconUploadId == iconUploadId;

  @override
  int get hashCode =>
      rank.hashCode +
      name.hashCode +
      minPoints.hashCode +
      iconUploadId.hashCode;

  factory AdminLevel.fromJson(Map<String, dynamic> json) =>
      _$AdminLevelFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLevelToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
