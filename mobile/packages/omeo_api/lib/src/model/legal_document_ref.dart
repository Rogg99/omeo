//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/legal_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'legal_document_ref.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LegalDocumentRef {
  /// Returns a new [LegalDocumentRef] instance.
  LegalDocumentRef({
    required this.kind,

    required this.version,

    required this.title,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final LegalKind kind;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalDocumentRef &&
          other.kind == kind &&
          other.version == version &&
          other.title == title;

  @override
  int get hashCode => kind.hashCode + version.hashCode + title.hashCode;

  factory LegalDocumentRef.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentRefFromJson(json);

  Map<String, dynamic> toJson() => _$LegalDocumentRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
