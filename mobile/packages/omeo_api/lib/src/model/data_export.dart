//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data_export.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DataExport {
  /// Returns a new [DataExport] instance.
  DataExport({
    required this.id,

    required this.status,

    required this.requestedAt,

    this.downloadUrl,

    this.expiresAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DataExportStatusEnum status;

  @JsonKey(name: r'requested_at', required: true, includeIfNull: false)
  final DateTime requestedAt;

  @JsonKey(name: r'download_url', required: false, includeIfNull: false)
  final String? downloadUrl;

  @JsonKey(name: r'expires_at', required: false, includeIfNull: false)
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataExport &&
          other.id == id &&
          other.status == status &&
          other.requestedAt == requestedAt &&
          other.downloadUrl == downloadUrl &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      id.hashCode +
      status.hashCode +
      requestedAt.hashCode +
      (downloadUrl == null ? 0 : downloadUrl.hashCode) +
      (expiresAt == null ? 0 : expiresAt.hashCode);

  factory DataExport.fromJson(Map<String, dynamic> json) =>
      _$DataExportFromJson(json);

  Map<String, dynamic> toJson() => _$DataExportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DataExportStatusEnum {
  @JsonValue(r'queued')
  queued(r'queued'),
  @JsonValue(r'ready')
  ready(r'ready'),
  @JsonValue(r'expired')
  expired(r'expired');

  const DataExportStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
