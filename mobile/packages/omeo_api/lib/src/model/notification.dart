//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Notification {
  /// Returns a new [Notification] instance.
  Notification({
    required this.id,

    required this.category,

    required this.title,

    required this.body,

    this.deeplink,

    this.image,

    required this.createdAt,

    required this.read,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'deeplink', required: false, includeIfNull: false)
  final String? deeplink;

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final Image? image;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'read', required: true, includeIfNull: false)
  final bool read;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          other.id == id &&
          other.category == category &&
          other.title == title &&
          other.body == body &&
          other.deeplink == deeplink &&
          other.image == image &&
          other.createdAt == createdAt &&
          other.read == read;

  @override
  int get hashCode =>
      id.hashCode +
      category.hashCode +
      title.hashCode +
      body.hashCode +
      (deeplink == null ? 0 : deeplink.hashCode) +
      (image == null ? 0 : image.hashCode) +
      createdAt.hashCode +
      read.hashCode;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
