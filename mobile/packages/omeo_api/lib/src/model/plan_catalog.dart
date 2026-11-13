//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plan_catalog_plans_inner.dart';
import 'package:omeo_api/src/model/plan_catalog_comparison_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalog {
  /// Returns a new [PlanCatalog] instance.
  PlanCatalog({required this.plans, required this.comparison});

  @JsonKey(name: r'plans', required: true, includeIfNull: false)
  final List<PlanCatalogPlansInner> plans;

  @JsonKey(name: r'comparison', required: true, includeIfNull: false)
  final List<PlanCatalogComparisonInner> comparison;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalog &&
          other.plans == plans &&
          other.comparison == comparison;

  @override
  int get hashCode => plans.hashCode + comparison.hashCode;

  factory PlanCatalog.fromJson(Map<String, dynamic> json) =>
      _$PlanCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
