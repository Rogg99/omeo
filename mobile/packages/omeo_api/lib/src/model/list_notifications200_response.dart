//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/notification.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_notifications200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListNotifications200Response {
  /// Returns a new [ListNotifications200Response] instance.
  ListNotifications200Response({
    required this.results,

    required this.nextCursor,

    required this.unreadCount,
  });

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Notification> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'unread_count', required: true, includeIfNull: false)
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListNotifications200Response &&
          other.results == results &&
          other.nextCursor == nextCursor &&
          other.unreadCount == unreadCount;

  @override
  int get hashCode =>
      results.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      unreadCount.hashCode;

  factory ListNotifications200Response.fromJson(Map<String, dynamic> json) =>
      _$ListNotifications200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListNotifications200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
