//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/dish_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analysis_alternative.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalysisAlternative {
  /// Returns a new [AnalysisAlternative] instance.
  AnalysisAlternative({
    required this.label,

    required this.dish,

    required this.probabilityPercent,
  });

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  /// Plat du catalogue correspondant, null s'il est absent (la recherche est alors pré-remplie avec label)
  @JsonKey(name: r'dish', required: true, includeIfNull: true)
  final DishSummary? dish;

  /// Arrondie par l'API
  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'probability_percent', required: true, includeIfNull: false)
  final int probabilityPercent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisAlternative &&
          other.label == label &&
          other.dish == dish &&
          other.probabilityPercent == probabilityPercent;

  @override
  int get hashCode =>
      label.hashCode +
      (dish == null ? 0 : dish.hashCode) +
      probabilityPercent.hashCode;

  factory AnalysisAlternative.fromJson(Map<String, dynamic> json) =>
      _$AnalysisAlternativeFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisAlternativeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
