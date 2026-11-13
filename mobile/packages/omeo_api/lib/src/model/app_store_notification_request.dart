//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_store_notification_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppStoreNotificationRequest {
  /// Returns a new [AppStoreNotificationRequest] instance.
  AppStoreNotificationRequest({required this.signedPayload});

  @JsonKey(name: r'signedPayload', required: true, includeIfNull: false)
  final String signedPayload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStoreNotificationRequest &&
          other.signedPayload == signedPayload;

  @override
  int get hashCode => signedPayload.hashCode;

  factory AppStoreNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$AppStoreNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppStoreNotificationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
