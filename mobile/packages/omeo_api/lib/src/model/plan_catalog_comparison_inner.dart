//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog_comparison_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalogComparisonInner {
  /// Returns a new [PlanCatalogComparisonInner] instance.
  PlanCatalogComparisonInner({
    required this.feature,

    required this.label,

    this.trial,

    required this.free,

    required this.plus,
  });

  @JsonKey(name: r'feature', required: true, includeIfNull: false)
  final String feature;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'trial', required: false, includeIfNull: false)
  final String? trial;

  @JsonKey(name: r'free', required: true, includeIfNull: false)
  final String free;

  @JsonKey(name: r'plus', required: true, includeIfNull: false)
  final String plus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalogComparisonInner &&
          other.feature == feature &&
          other.label == label &&
          other.trial == trial &&
          other.free == free &&
          other.plus == plus;

  @override
  int get hashCode =>
      feature.hashCode +
      label.hashCode +
      trial.hashCode +
      free.hashCode +
      plus.hashCode;

  factory PlanCatalogComparisonInner.fromJson(Map<String, dynamic> json) =>
      _$PlanCatalogComparisonInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogComparisonInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
