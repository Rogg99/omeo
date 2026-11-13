//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:omeo_api/src/model/analysis_item.dart';
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Meal {
  /// Returns a new [Meal] instance.
  Meal({
    required this.id,

    required this.date,

    this.eatenAt,

    required this.mealType,

    required this.source_,

    required this.title,

    this.photo,

    required this.nutrients,

    required this.items,

    this.analysisId,

    this.feedbackGiven,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'eaten_at', required: false, includeIfNull: false)
  final DateTime? eatenAt;

  @JsonKey(name: r'meal_type', required: true, includeIfNull: false)
  final MealType mealType;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final String source_;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'photo', required: false, includeIfNull: false)
  final Image? photo;

  @JsonKey(name: r'nutrients', required: true, includeIfNull: false)
  final Nutrients nutrients;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AnalysisItem> items;

  @JsonKey(name: r'analysis_id', required: false, includeIfNull: false)
  final String? analysisId;

  @JsonKey(name: r'feedback_given', required: false, includeIfNull: false)
  final bool? feedbackGiven;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meal &&
          other.id == id &&
          other.date == date &&
          other.eatenAt == eatenAt &&
          other.mealType == mealType &&
          other.source_ == source_ &&
          other.title == title &&
          other.photo == photo &&
          other.nutrients == nutrients &&
          other.items == items &&
          other.analysisId == analysisId &&
          other.feedbackGiven == feedbackGiven &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      date.hashCode +
      eatenAt.hashCode +
      mealType.hashCode +
      source_.hashCode +
      title.hashCode +
      (photo == null ? 0 : photo.hashCode) +
      nutrients.hashCode +
      items.hashCode +
      (analysisId == null ? 0 : analysisId.hashCode) +
      feedbackGiven.hashCode +
      createdAt.hashCode;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);

  Map<String, dynamic> toJson() => _$MealToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
