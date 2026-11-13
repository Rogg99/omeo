//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_dish.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDish {
  /// Returns a new [AdminDish] instance.
  AdminDish({
    required this.name,

    this.aliases,

    required this.country,

    required this.standardPortionG,

    this.imageUploadId,

    this.recipeId,

    required this.components,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  @JsonKey(name: r'aliases', required: false, includeIfNull: false)
  final List<String>? aliases;

  @JsonKey(name: r'country', required: true, includeIfNull: false)
  final String country;

  @JsonKey(name: r'standard_portion_g', required: true, includeIfNull: false)
  final num standardPortionG;

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'components', required: true, includeIfNull: false)
  final List<MealItemInput> components;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDish &&
          other.name == name &&
          other.aliases == aliases &&
          other.country == country &&
          other.standardPortionG == standardPortionG &&
          other.imageUploadId == imageUploadId &&
          other.recipeId == recipeId &&
          other.components == components;

  @override
  int get hashCode =>
      name.hashCode +
      aliases.hashCode +
      country.hashCode +
      standardPortionG.hashCode +
      imageUploadId.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      components.hashCode;

  factory AdminDish.fromJson(Map<String, dynamic> json) =>
      _$AdminDishFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDishToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
