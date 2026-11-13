//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/content_type_name.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_translation_coverage200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTranslationCoverage200ResponseInner {
  /// Returns a new [AdminTranslationCoverage200ResponseInner] instance.
  AdminTranslationCoverage200ResponseInner({
    required this.type,

    required this.locale,

    required this.total,

    required this.missing,

    this.percent,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ContentTypeName type;

  @JsonKey(name: r'locale', required: true, includeIfNull: false)
  final Locale locale;

  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'missing', required: true, includeIfNull: false)
  final int missing;

  @JsonKey(name: r'percent', required: false, includeIfNull: false)
  final num? percent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminTranslationCoverage200ResponseInner &&
          other.type == type &&
          other.locale == locale &&
          other.total == total &&
          other.missing == missing &&
          other.percent == percent;

  @override
  int get hashCode =>
      type.hashCode +
      locale.hashCode +
      total.hashCode +
      missing.hashCode +
      percent.hashCode;

  factory AdminTranslationCoverage200ResponseInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminTranslationCoverage200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminTranslationCoverage200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
