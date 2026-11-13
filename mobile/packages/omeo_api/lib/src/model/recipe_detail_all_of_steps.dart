//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_detail_all_of_steps.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDetailAllOfSteps {
  /// Returns a new [RecipeDetailAllOfSteps] instance.
  RecipeDetailAllOfSteps({required this.order, required this.text, this.image});

  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final int order;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final Image? image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDetailAllOfSteps &&
          other.order == order &&
          other.text == text &&
          other.image == image;

  @override
  int get hashCode => order.hashCode + text.hashCode + image.hashCode;

  factory RecipeDetailAllOfSteps.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailAllOfStepsFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDetailAllOfStepsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
