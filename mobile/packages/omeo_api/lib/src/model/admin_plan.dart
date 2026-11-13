//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plan_catalog_plans_inner_store_product_ids.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_plan.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPlan {
  /// Returns a new [AdminPlan] instance.
  AdminPlan({
    this.code,

    this.name,

    this.priceCents,

    this.interval,

    this.isFeatured,

    this.storeProductIds,

    this.webPriceId,

    this.active,
  });

  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final String? code;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final Map<String, String>? name;

  // minimum: 0
  @JsonKey(name: r'price_cents', required: false, includeIfNull: false)
  final int? priceCents;

  @JsonKey(name: r'interval', required: false, includeIfNull: false)
  final AdminPlanIntervalEnum? interval;

  @JsonKey(name: r'is_featured', required: false, includeIfNull: false)
  final bool? isFeatured;

  @JsonKey(name: r'store_product_ids', required: false, includeIfNull: false)
  final PlanCatalogPlansInnerStoreProductIds? storeProductIds;

  @JsonKey(name: r'web_price_id', required: false, includeIfNull: false)
  final String? webPriceId;

  @JsonKey(name: r'active', required: false, includeIfNull: false)
  final bool? active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPlan &&
          other.code == code &&
          other.name == name &&
          other.priceCents == priceCents &&
          other.interval == interval &&
          other.isFeatured == isFeatured &&
          other.storeProductIds == storeProductIds &&
          other.webPriceId == webPriceId &&
          other.active == active;

  @override
  int get hashCode =>
      code.hashCode +
      name.hashCode +
      priceCents.hashCode +
      interval.hashCode +
      isFeatured.hashCode +
      storeProductIds.hashCode +
      (webPriceId == null ? 0 : webPriceId.hashCode) +
      active.hashCode;

  factory AdminPlan.fromJson(Map<String, dynamic> json) =>
      _$AdminPlanFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminPlanIntervalEnum {
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'year')
  year(r'year'),
  @JsonValue(r'none')
  none(r'none');

  const AdminPlanIntervalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
