//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request_account_deletion200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RequestAccountDeletion200Response {
  /// Returns a new [RequestAccountDeletion200Response] instance.
  RequestAccountDeletion200Response({
    required this.scheduledFor,

    required this.storeSubscriptionActive,

    this.storeChannel,
  });

  @JsonKey(name: r'scheduled_for', required: true, includeIfNull: false)
  final DateTime scheduledFor;

  @JsonKey(
    name: r'store_subscription_active',
    required: true,
    includeIfNull: false,
  )
  final bool storeSubscriptionActive;

  @JsonKey(name: r'store_channel', required: false, includeIfNull: false)
  final Channel? storeChannel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestAccountDeletion200Response &&
          other.scheduledFor == scheduledFor &&
          other.storeSubscriptionActive == storeSubscriptionActive &&
          other.storeChannel == storeChannel;

  @override
  int get hashCode =>
      scheduledFor.hashCode +
      storeSubscriptionActive.hashCode +
      storeChannel.hashCode;

  factory RequestAccountDeletion200Response.fromJson(
    Map<String, dynamic> json,
  ) => _$RequestAccountDeletion200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RequestAccountDeletion200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
