//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/audit_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_audit200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListAudit200Response {
  /// Returns a new [AdminListAudit200Response] instance.
  AdminListAudit200Response({
    required this.results,

    required this.count,

    required this.page,

    required this.pageSize,
  });

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<AuditEntry> results;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final int page;

  @JsonKey(name: r'page_size', required: true, includeIfNull: false)
  final int pageSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListAudit200Response &&
          other.results == results &&
          other.count == count &&
          other.page == page &&
          other.pageSize == pageSize;

  @override
  int get hashCode =>
      results.hashCode + count.hashCode + page.hashCode + pageSize.hashCode;

  factory AdminListAudit200Response.fromJson(Map<String, dynamic> json) =>
      _$AdminListAudit200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminListAudit200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
