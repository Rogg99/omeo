//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mark_notifications_read200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MarkNotificationsRead200Response {
  /// Returns a new [MarkNotificationsRead200Response] instance.
  MarkNotificationsRead200Response({required this.unreadCount});

  @JsonKey(name: r'unread_count', required: true, includeIfNull: false)
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkNotificationsRead200Response &&
          other.unreadCount == unreadCount;

  @override
  int get hashCode => unreadCount.hashCode;

  factory MarkNotificationsRead200Response.fromJson(
    Map<String, dynamic> json,
  ) => _$MarkNotificationsRead200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$MarkNotificationsRead200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
