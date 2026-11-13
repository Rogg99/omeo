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

part 'admin_content_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminContentItem {
  /// Returns a new [AdminContentItem] instance.
  AdminContentItem({
    required this.id,

    required this.type,

    required this.title,

    required this.status,

    required this.missingLocales,

    this.thumbnail,

    required this.updatedAt,

    this.updatedBy,

    required this.version,

    required this.data,

    this.computed,
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

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @JsonKey(name: r'data', required: true, includeIfNull: false)
  final Map<String, Object> data;

  /// Valeurs calculées (nutriments, durée…), lecture seule
  @JsonKey(name: r'computed', required: false, includeIfNull: false)
  final Map<String, Object>? computed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminContentItem &&
          other.id == id &&
          other.type == type &&
          other.title == title &&
          other.status == status &&
          other.missingLocales == missingLocales &&
          other.thumbnail == thumbnail &&
          other.updatedAt == updatedAt &&
          other.updatedBy == updatedBy &&
          other.version == version &&
          other.data == data &&
          other.computed == computed;

  @override
  int get hashCode =>
      id.hashCode +
      type.hashCode +
      title.hashCode +
      status.hashCode +
      missingLocales.hashCode +
      (thumbnail == null ? 0 : thumbnail.hashCode) +
      updatedAt.hashCode +
      (updatedBy == null ? 0 : updatedBy.hashCode) +
      version.hashCode +
      data.hashCode +
      computed.hashCode;

  factory AdminContentItem.fromJson(Map<String, dynamic> json) =>
      _$AdminContentItemFromJson(json);

  Map<String, dynamic> toJson() => _$AdminContentItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
