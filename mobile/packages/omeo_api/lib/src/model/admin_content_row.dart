//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/content_type_name.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/content_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_content_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminContentRow {
  /// Returns a new [AdminContentRow] instance.
  AdminContentRow({
    required this.id,

    required this.type,

    required this.title,

    required this.status,

    required this.missingLocales,

    this.thumbnail,

    required this.updatedAt,

    this.updatedBy,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ContentTypeName type;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ContentStatus status;

  @JsonKey(name: r'missing_locales', required: true, includeIfNull: false)
  final List<Locale> missingLocales;

  @JsonKey(name: r'thumbnail', required: false, includeIfNull: false)
  final Image? thumbnail;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final DateTime updatedAt;

  @JsonKey(name: r'updated_by', required: false, includeIfNull: false)
  final String? updatedBy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminContentRow &&
          other.id == id &&
          other.type == type &&
          other.title == title &&
          other.status == status &&
          other.missingLocales == missingLocales &&
          other.thumbnail == thumbnail &&
          other.updatedAt == updatedAt &&
          other.updatedBy == updatedBy;

  @override
  int get hashCode =>
      id.hashCode +
      type.hashCode +
      title.hashCode +
      status.hashCode +
      missingLocales.hashCode +
      (thumbnail == null ? 0 : thumbnail.hashCode) +
      updatedAt.hashCode +
      (updatedBy == null ? 0 : updatedBy.hashCode);

  factory AdminContentRow.fromJson(Map<String, dynamic> json) =>
      _$AdminContentRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminContentRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
