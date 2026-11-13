//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_recipe_ingredients_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminRecipeIngredientsInner {
  /// Returns a new [AdminRecipeIngredientsInner] instance.
  AdminRecipeIngredientsInner({
    required this.foodId,

    required this.grams,

    this.display,
  });

  @JsonKey(name: r'food_id', required: true, includeIfNull: false)
  final String foodId;

  @JsonKey(name: r'grams', required: true, includeIfNull: false)
  final num grams;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'display', required: false, includeIfNull: false)
  final Map<String, String>? display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRecipeIngredientsInner &&
          other.foodId == foodId &&
          other.grams == grams &&
          other.display == display;

  @override
  int get hashCode => foodId.hashCode + grams.hashCode + display.hashCode;

  factory AdminRecipeIngredientsInner.fromJson(Map<String, dynamic> json) =>
      _$AdminRecipeIngredientsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminRecipeIngredientsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
