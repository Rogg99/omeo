//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_badge.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminBadge {
  /// Returns a new [AdminBadge] instance.
  AdminBadge({
    required this.code,

    required this.family,

    required this.name,

    this.description,

    required this.condition,

    this.bonusPoints,

    this.iconUploadId,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'family', required: true, includeIfNull: false)
  final AdminBadgeFamilyEnum family;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  @JsonKey(name: r'condition', required: true, includeIfNull: false)
  final Map<String, Object> condition;

  @JsonKey(name: r'bonus_points', required: false, includeIfNull: false)
  final int? bonusPoints;

  @JsonKey(name: r'icon_upload_id', required: false, includeIfNull: false)
  final String? iconUploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminBadge &&
          other.code == code &&
          other.family == family &&
          other.name == name &&
          other.description == description &&
          other.condition == condition &&
          other.bonusPoints == bonusPoints &&
          other.iconUploadId == iconUploadId;

  @override
  int get hashCode =>
      code.hashCode +
      family.hashCode +
      name.hashCode +
      description.hashCode +
      condition.hashCode +
      bonusPoints.hashCode +
      iconUploadId.hashCode;

  factory AdminBadge.fromJson(Map<String, dynamic> json) =>
      _$AdminBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminBadgeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminBadgeFamilyEnum {
  @JsonValue(r'streak')
  streak(r'streak'),
  @JsonValue(r'nutrition')
  nutrition(r'nutrition'),
  @JsonValue(r'hydration')
  hydration(r'hydration'),
  @JsonValue(r'activity')
  activity(r'activity'),
  @JsonValue(r'challenge')
  challenge(r'challenge'),
  @JsonValue(r'program')
  program(r'program'),
  @JsonValue(r'discovery')
  discovery(r'discovery'),
  @JsonValue(r'referral')
  referral(r'referral');

  const AdminBadgeFamilyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
