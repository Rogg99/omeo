//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'insight.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Insight {
  /// Returns a new [Insight] instance.
  Insight({
    required this.id,

    required this.weekStart,

    this.kind,

    required this.message,

    this.data,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'week_start', required: true, includeIfNull: false)
  final DateTime weekStart;

  @JsonKey(name: r'kind', required: false, includeIfNull: false)
  final String? kind;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'data', required: false, includeIfNull: false)
  final Map<String, Object>? data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Insight &&
          other.id == id &&
          other.weekStart == weekStart &&
          other.kind == kind &&
          other.message == message &&
          other.data == data;

  @override
  int get hashCode =>
      id.hashCode +
      weekStart.hashCode +
      kind.hashCode +
      message.hashCode +
      data.hashCode;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);

  Map<String, dynamic> toJson() => _$InsightToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
