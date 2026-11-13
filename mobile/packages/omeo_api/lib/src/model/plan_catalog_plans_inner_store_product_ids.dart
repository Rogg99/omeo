//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog_plans_inner_store_product_ids.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalogPlansInnerStoreProductIds {
  /// Returns a new [PlanCatalogPlansInnerStoreProductIds] instance.
  PlanCatalogPlansInnerStoreProductIds({this.google, this.apple});

  @JsonKey(name: r'google', required: false, includeIfNull: false)
  final String? google;

  @JsonKey(name: r'apple', required: false, includeIfNull: false)
  final String? apple;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalogPlansInnerStoreProductIds &&
          other.google == google &&
          other.apple == apple;

  @override
  int get hashCode => google.hashCode + apple.hashCode;

  factory PlanCatalogPlansInnerStoreProductIds.fromJson(
    Map<String, dynamic> json,
  ) => _$PlanCatalogPlansInnerStoreProductIdsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PlanCatalogPlansInnerStoreProductIdsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
