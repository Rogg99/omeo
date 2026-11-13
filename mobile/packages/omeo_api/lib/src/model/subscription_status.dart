//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum SubscriptionStatus {
  @JsonValue(r'trial')
  trial(r'trial'),
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'grace')
  grace(r'grace'),
  @JsonValue(r'canceled')
  canceled(r'canceled'),
  @JsonValue(r'expired')
  expired(r'expired'),
  @JsonValue(r'refunded')
  refunded(r'refunded');

  const SubscriptionStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
