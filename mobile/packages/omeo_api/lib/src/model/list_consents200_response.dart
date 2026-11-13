//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/legal_document_ref.dart';
import 'package:omeo_api/src/model/consent_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_consents200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListConsents200Response {
  /// Returns a new [ListConsents200Response] instance.
  ListConsents200Response({
    required this.consents,

    required this.pendingDocuments,
  });

  @JsonKey(name: r'consents', required: true, includeIfNull: false)
  final List<ConsentState> consents;

  @JsonKey(name: r'pending_documents', required: true, includeIfNull: false)
  final List<LegalDocumentRef> pendingDocuments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListConsents200Response &&
          other.consents == consents &&
          other.pendingDocuments == pendingDocuments;

  @override
  int get hashCode => consents.hashCode + pendingDocuments.hashCode;

  factory ListConsents200Response.fromJson(Map<String, dynamic> json) =>
      _$ListConsents200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListConsents200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
