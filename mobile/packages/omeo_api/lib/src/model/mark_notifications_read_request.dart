//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mark_notifications_read_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MarkNotificationsReadRequest {
  /// Returns a new [MarkNotificationsReadRequest] instance.
  MarkNotificationsReadRequest({this.ids, this.all});

  @JsonKey(name: r'ids', required: false, includeIfNull: false)
  final List<String>? ids;

  @JsonKey(name: r'all', required: false, includeIfNull: false)
  final bool? all;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkNotificationsReadRequest &&
          other.ids == ids &&
          other.all == all;

  @override
  int get hashCode => ids.hashCode + all.hashCode;

  factory MarkNotificationsReadRequest.fromJson(Map<String, dynamic> json) =>
      _$MarkNotificationsReadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MarkNotificationsReadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
