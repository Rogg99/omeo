//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Image {
  /// Returns a new [Image] instance.
  Image({required this.url, this.width, this.height, this.blurhash});

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @JsonKey(name: r'width', required: false, includeIfNull: false)
  final int? width;

  @JsonKey(name: r'height', required: false, includeIfNull: false)
  final int? height;

  @JsonKey(name: r'blurhash', required: false, includeIfNull: false)
  final String? blurhash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Image &&
          other.url == url &&
          other.width == width &&
          other.height == height &&
          other.blurhash == blurhash;

  @override
  int get hashCode =>
      url.hashCode + width.hashCode + height.hashCode + blurhash.hashCode;

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
