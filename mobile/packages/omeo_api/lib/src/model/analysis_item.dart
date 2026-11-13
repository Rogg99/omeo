//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analysis_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalysisItem {
  /// Returns a new [AnalysisItem] instance.
  AnalysisItem({
    required this.foodId,

    required this.label,

    required this.grams,

    this.confidence,

    this.nutrients,
  });

  @JsonKey(name: r'food_id', required: true, includeIfNull: false)
  final String foodId;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'grams', required: true, includeIfNull: false)
  final num grams;

  @JsonKey(name: r'confidence', required: false, includeIfNull: false)
  final num? confidence;

  @JsonKey(name: r'nutrients', required: false, includeIfNull: false)
  final Nutrients? nutrients;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisItem &&
          other.foodId == foodId &&
          other.label == label &&
          other.grams == grams &&
          other.confidence == confidence &&
          other.nutrients == nutrients;

  @override
  int get hashCode =>
      foodId.hashCode +
      label.hashCode +
      grams.hashCode +
      confidence.hashCode +
      nutrients.hashCode;

  factory AnalysisItem.fromJson(Map<String, dynamic> json) =>
      _$AnalysisItemFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
