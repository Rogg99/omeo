//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum PlanTier {
  @JsonValue(r'trial')
  trial(r'trial'),
  @JsonValue(r'free')
  free(r'free'),
  @JsonValue(r'plus')
  plus(r'plus');

  const PlanTier(this.value);

  final String value;

  @override
  String toString() => value;
}
