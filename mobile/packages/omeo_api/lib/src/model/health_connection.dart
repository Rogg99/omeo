//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_connection.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthConnection {
  /// Returns a new [HealthConnection] instance.
  HealthConnection({
    required this.connected,

    this.source_,

    this.grantedTypes,

    this.readTypesLabel,

    this.lastSyncAt,
  });

  @JsonKey(name: r'connected', required: true, includeIfNull: false)
  final bool connected;

  @JsonKey(name: r'source', required: false, includeIfNull: false)
  final HealthConnectionSource_Enum? source_;

  @JsonKey(name: r'granted_types', required: false, includeIfNull: false)
  final List<String>? grantedTypes;

  /// « Données lues : pas, calories, … »
  @JsonKey(name: r'read_types_label', required: false, includeIfNull: false)
  final String? readTypesLabel;

  @JsonKey(name: r'last_sync_at', required: false, includeIfNull: false)
  final DateTime? lastSyncAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthConnection &&
          other.connected == connected &&
          other.source_ == source_ &&
          other.grantedTypes == grantedTypes &&
          other.readTypesLabel == readTypesLabel &&
          other.lastSyncAt == lastSyncAt;

  @override
  int get hashCode =>
      connected.hashCode +
      (source_ == null ? 0 : source_.hashCode) +
      grantedTypes.hashCode +
      readTypesLabel.hashCode +
      (lastSyncAt == null ? 0 : lastSyncAt.hashCode);

  factory HealthConnection.fromJson(Map<String, dynamic> json) =>
      _$HealthConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$HealthConnectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthConnectionSource_Enum {
  @JsonValue(r'health_connect')
  healthConnect(r'health_connect'),
  @JsonValue(r'apple_health')
  appleHealth(r'apple_health');

  const HealthConnectionSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
