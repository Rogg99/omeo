//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plant_summary.dart';
import 'package:omeo_api/src/model/recipe_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_tip.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserTip {
  /// Returns a new [UserTip] instance.
  UserTip({
    required this.id,

    required this.topic,

    required this.title,

    required this.body,

    required this.tier,

    this.locked,

    this.triggeredOn,

    this.relatedRecipes,

    this.relatedPlants,

    this.read,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'topic', required: true, includeIfNull: false)
  final String topic;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final UserTipTierEnum tier;

  @JsonKey(name: r'locked', required: false, includeIfNull: false)
  final bool? locked;

  @JsonKey(name: r'triggered_on', required: false, includeIfNull: false)
  final DateTime? triggeredOn;

  @JsonKey(name: r'related_recipes', required: false, includeIfNull: false)
  final List<RecipeSummary>? relatedRecipes;

  @JsonKey(name: r'related_plants', required: false, includeIfNull: false)
  final List<PlantSummary>? relatedPlants;

  @JsonKey(name: r'read', required: false, includeIfNull: false)
  final bool? read;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTip &&
          other.id == id &&
          other.topic == topic &&
          other.title == title &&
          other.body == body &&
          other.tier == tier &&
          other.locked == locked &&
          other.triggeredOn == triggeredOn &&
          other.relatedRecipes == relatedRecipes &&
          other.relatedPlants == relatedPlants &&
          other.read == read;

  @override
  int get hashCode =>
      id.hashCode +
      topic.hashCode +
      title.hashCode +
      body.hashCode +
      tier.hashCode +
      locked.hashCode +
      triggeredOn.hashCode +
      relatedRecipes.hashCode +
      relatedPlants.hashCode +
      read.hashCode;

  factory UserTip.fromJson(Map<String, dynamic> json) =>
      _$UserTipFromJson(json);

  Map<String, dynamic> toJson() => _$UserTipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UserTipTierEnum {
  @JsonValue(r'free')
  free(r'free'),
  @JsonValue(r'plus')
  plus(r'plus');

  const UserTipTierEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
