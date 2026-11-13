//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/approval_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_approvals200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListApprovals200Response {
  /// Returns a new [AdminListApprovals200Response] instance.
  AdminListApprovals200Response({
    required this.results,

    required this.count,

    required this.page,

    required this.pageSize,
  });

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<ApprovalRequest> results;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final int page;

  @JsonKey(name: r'page_size', required: true, includeIfNull: false)
  final int pageSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListApprovals200Response &&
          other.results == results &&
          other.count == count &&
          other.page == page &&
          other.pageSize == pageSize;

  @override
  int get hashCode =>
      results.hashCode + count.hashCode + page.hashCode + pageSize.hashCode;

  factory AdminListApprovals200Response.fromJson(Map<String, dynamic> json) =>
      _$AdminListApprovals200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminListApprovals200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
