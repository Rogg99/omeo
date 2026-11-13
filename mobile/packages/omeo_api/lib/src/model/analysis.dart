//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:omeo_api/src/model/analysis_item.dart';
import 'package:omeo_api/src/model/quota.dart';
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/analysis_alternative.dart';
import 'package:omeo_api/src/model/dish_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analysis.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Analysis {
  /// Returns a new [Analysis] instance.
  Analysis({
    required this.id,

    required this.kind,

    required this.status,

    this.failureReason,

    this.failureMessage,

    this.photo,

    this.dish,

    this.dishLabel,

    this.confidence,

    this.lowConfidence,

    this.alternatives,

    this.items,

    this.totals,

    this.suggestedMealType,

    this.suggestedRecipeId,

    this.quota,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final AnalysisKindEnum kind;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AnalysisStatusEnum status;

  @JsonKey(name: r'failure_reason', required: false, includeIfNull: false)
  final AnalysisFailureReasonEnum? failureReason;

  @JsonKey(name: r'failure_message', required: false, includeIfNull: false)
  final String? failureMessage;

  @JsonKey(name: r'photo', required: false, includeIfNull: false)
  final Image? photo;

  @JsonKey(name: r'dish', required: false, includeIfNull: false)
  final DishSummary? dish;

  @JsonKey(name: r'dish_label', required: false, includeIfNull: false)
  final String? dishLabel;

  @JsonKey(name: r'confidence', required: false, includeIfNull: false)
  final num? confidence;

  @JsonKey(name: r'low_confidence', required: false, includeIfNull: false)
  final bool? lowConfidence;

  /// Autres plats envisagés, par probabilité décroissante (rubrique « Pas satisfait ? »)
  @JsonKey(name: r'alternatives', required: false, includeIfNull: false)
  final List<AnalysisAlternative>? alternatives;

  @JsonKey(name: r'items', required: false, includeIfNull: false)
  final List<AnalysisItem>? items;

  @JsonKey(name: r'totals', required: false, includeIfNull: false)
  final Nutrients? totals;

  @JsonKey(name: r'suggested_meal_type', required: false, includeIfNull: false)
  final MealType? suggestedMealType;

  @JsonKey(name: r'suggested_recipe_id', required: false, includeIfNull: false)
  final String? suggestedRecipeId;

  @JsonKey(name: r'quota', required: false, includeIfNull: false)
  final Quota? quota;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Analysis &&
          other.id == id &&
          other.kind == kind &&
          other.status == status &&
          other.failureReason == failureReason &&
          other.failureMessage == failureMessage &&
          other.photo == photo &&
          other.dish == dish &&
          other.dishLabel == dishLabel &&
          other.confidence == confidence &&
          other.lowConfidence == lowConfidence &&
          other.alternatives == alternatives &&
          other.items == items &&
          other.totals == totals &&
          other.suggestedMealType == suggestedMealType &&
          other.suggestedRecipeId == suggestedRecipeId &&
          other.quota == quota &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      kind.hashCode +
      status.hashCode +
      (failureReason == null ? 0 : failureReason.hashCode) +
      (failureMessage == null ? 0 : failureMessage.hashCode) +
      (photo == null ? 0 : photo.hashCode) +
      (dish == null ? 0 : dish.hashCode) +
      (dishLabel == null ? 0 : dishLabel.hashCode) +
      (confidence == null ? 0 : confidence.hashCode) +
      lowConfidence.hashCode +
      alternatives.hashCode +
      items.hashCode +
      totals.hashCode +
      suggestedMealType.hashCode +
      (suggestedRecipeId == null ? 0 : suggestedRecipeId.hashCode) +
      quota.hashCode +
      createdAt.hashCode;

  factory Analysis.fromJson(Map<String, dynamic> json) =>
      _$AnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AnalysisKindEnum {
  @JsonValue(r'photo')
  photo(r'photo'),
  @JsonValue(r'text')
  text(r'text');

  const AnalysisKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AnalysisStatusEnum {
  @JsonValue(r'queued')
  queued(r'queued'),
  @JsonValue(r'processing')
  processing(r'processing'),
  @JsonValue(r'succeeded')
  succeeded(r'succeeded'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AnalysisStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AnalysisFailureReasonEnum {
  @JsonValue(r'blurry')
  blurry(r'blurry'),
  @JsonValue(r'no_food')
  noFood(r'no_food'),
  @JsonValue(r'unsupported')
  unsupported(r'unsupported'),
  @JsonValue(r'provider_error')
  providerError(r'provider_error'),
  @JsonValue(r'timeout')
  timeout(r'timeout');

  const AnalysisFailureReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
