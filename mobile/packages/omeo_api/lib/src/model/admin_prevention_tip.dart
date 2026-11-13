//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_prevention_tip.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPreventionTip {
  /// Returns a new [AdminPreventionTip] instance.
  AdminPreventionTip({
    required this.code,

    required this.topic,

    required this.title,

    required this.body,

    required this.trigger,

    required this.tier,

    this.relatedRecipeIds,

    this.relatedPlantIds,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'topic', required: true, includeIfNull: false)
  final AdminPreventionTipTopicEnum topic;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final Map<String, String> title;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final Map<String, String> body;

  @JsonKey(name: r'trigger', required: true, includeIfNull: false)
  final Map<String, Object> trigger;

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final AdminPreventionTipTierEnum tier;

  @JsonKey(name: r'related_recipe_ids', required: false, includeIfNull: false)
  final List<String>? relatedRecipeIds;

  @JsonKey(name: r'related_plant_ids', required: false, includeIfNull: false)
  final List<String>? relatedPlantIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPreventionTip &&
          other.code == code &&
          other.topic == topic &&
          other.title == title &&
          other.body == body &&
          other.trigger == trigger &&
          other.tier == tier &&
          other.relatedRecipeIds == relatedRecipeIds &&
          other.relatedPlantIds == relatedPlantIds;

  @override
  int get hashCode =>
      code.hashCode +
      topic.hashCode +
      title.hashCode +
      body.hashCode +
      trigger.hashCode +
      tier.hashCode +
      relatedRecipeIds.hashCode +
      relatedPlantIds.hashCode;

  factory AdminPreventionTip.fromJson(Map<String, dynamic> json) =>
      _$AdminPreventionTipFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPreventionTipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminPreventionTipTopicEnum {
  @JsonValue(r'water')
  water(r'water'),
  @JsonValue(r'salt')
  salt(r'salt'),
  @JsonValue(r'sugar')
  sugar(r'sugar'),
  @JsonValue(r'fiber')
  fiber(r'fiber'),
  @JsonValue(r'activity')
  activity(r'activity'),
  @JsonValue(r'protein')
  protein(r'protein');

  const AdminPreventionTipTopicEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminPreventionTipTierEnum {
  @JsonValue(r'free')
  free(r'free'),
  @JsonValue(r'plus')
  plus(r'plus');

  const AdminPreventionTipTierEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
