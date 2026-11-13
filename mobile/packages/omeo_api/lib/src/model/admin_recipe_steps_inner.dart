//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_recipe_steps_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminRecipeStepsInner {
  /// Returns a new [AdminRecipeStepsInner] instance.
  AdminRecipeStepsInner({required this.text, this.imageUploadId});

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final Map<String, String> text;

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRecipeStepsInner &&
          other.text == text &&
          other.imageUploadId == imageUploadId;

  @override
  int get hashCode => text.hashCode + imageUploadId.hashCode;

  factory AdminRecipeStepsInner.fromJson(Map<String, dynamic> json) =>
      _$AdminRecipeStepsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminRecipeStepsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
