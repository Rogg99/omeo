//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/legal_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'legal_document.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LegalDocument {
  /// Returns a new [LegalDocument] instance.
  LegalDocument({
    required this.kind,

    required this.version,

    required this.title,

    required this.body,

    required this.publishedAt,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final LegalKind kind;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// Markdown
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'published_at', required: true, includeIfNull: false)
  final DateTime publishedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalDocument &&
          other.kind == kind &&
          other.version == version &&
          other.title == title &&
          other.body == body &&
          other.publishedAt == publishedAt;

  @override
  int get hashCode =>
      kind.hashCode +
      version.hashCode +
      title.hashCode +
      body.hashCode +
      publishedAt.hashCode;

  factory LegalDocument.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$LegalDocumentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
