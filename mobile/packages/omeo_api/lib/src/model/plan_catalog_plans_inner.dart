//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plan_catalog_plans_inner_store_product_ids.dart';
import 'package:omeo_api/src/model/money.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog_plans_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalogPlansInner {
  /// Returns a new [PlanCatalogPlansInner] instance.
  PlanCatalogPlansInner({
    required this.code,

    required this.name,

    required this.price,

    this.monthlyEquivalent,

    this.savingsPercent,

    required this.interval,

    required this.featured,

    this.storeProductIds,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'price', required: true, includeIfNull: false)
  final Money price;

  @JsonKey(name: r'monthly_equivalent', required: false, includeIfNull: false)
  final Money? monthlyEquivalent;

  @JsonKey(name: r'savings_percent', required: false, includeIfNull: false)
  final int? savingsPercent;

  @JsonKey(name: r'interval', required: true, includeIfNull: false)
  final PlanCatalogPlansInnerIntervalEnum interval;

  @JsonKey(name: r'featured', required: true, includeIfNull: false)
  final bool featured;

  @JsonKey(name: r'store_product_ids', required: false, includeIfNull: false)
  final PlanCatalogPlansInnerStoreProductIds? storeProductIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalogPlansInner &&
          other.code == code &&
          other.name == name &&
          other.price == price &&
          other.monthlyEquivalent == monthlyEquivalent &&
          other.savingsPercent == savingsPercent &&
          other.interval == interval &&
          other.featured == featured &&
          other.storeProductIds == storeProductIds;

  @override
  int get hashCode =>
      code.hashCode +
      name.hashCode +
      price.hashCode +
      monthlyEquivalent.hashCode +
      (savingsPercent == null ? 0 : savingsPercent.hashCode) +
      interval.hashCode +
      featured.hashCode +
      storeProductIds.hashCode;

  factory PlanCatalogPlansInner.fromJson(Map<String, dynamic> json) =>
      _$PlanCatalogPlansInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogPlansInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PlanCatalogPlansInnerIntervalEnum {
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'year')
  year(r'year'),
  @JsonValue(r'none')
  none(r'none');

  const PlanCatalogPlansInnerIntervalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
