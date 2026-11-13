//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'badge_ref.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BadgeRef {
  /// Returns a new [BadgeRef] instance.
  BadgeRef({required this.id, this.code, required this.name, this.icon});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final String? code;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'icon', required: false, includeIfNull: false)
  final Image? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeRef &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.icon == icon;

  @override
  int get hashCode =>
      id.hashCode + code.hashCode + name.hashCode + icon.hashCode;

  factory BadgeRef.fromJson(Map<String, dynamic> json) =>
      _$BadgeRefFromJson(json);

  Map<String, dynamic> toJson() => _$BadgeRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
