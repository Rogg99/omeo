//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plan_tier.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'entitlements.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Entitlements {
  /// Returns a new [Entitlements] instance.
  Entitlements({
    required this.tier,

    this.trialEndsAt,

    this.plusUntil,

    required this.features,
  });

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final PlanTier tier;

  @JsonKey(name: r'trial_ends_at', required: false, includeIfNull: false)
  final DateTime? trialEndsAt;

  @JsonKey(name: r'plus_until', required: false, includeIfNull: false)
  final DateTime? plusUntil;

  /// Clé = feature, valeur = autorisée
  @JsonKey(name: r'features', required: true, includeIfNull: false)
  final Map<String, bool> features;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entitlements &&
          other.tier == tier &&
          other.trialEndsAt == trialEndsAt &&
          other.plusUntil == plusUntil &&
          other.features == features;

  @override
  int get hashCode =>
      tier.hashCode +
      (trialEndsAt == null ? 0 : trialEndsAt.hashCode) +
      (plusUntil == null ? 0 : plusUntil.hashCode) +
      features.hashCode;

  factory Entitlements.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsFromJson(json);

  Map<String, dynamic> toJson() => _$EntitlementsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
