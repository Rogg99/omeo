//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum StaffRole {
  @JsonValue(r'superadmin')
  superadmin(r'superadmin'),
  @JsonValue(r'content')
  content(r'content'),
  @JsonValue(r'support')
  support(r'support'),
  @JsonValue(r'finance')
  finance(r'finance'),
  @JsonValue(r'moderation')
  moderation(r'moderation');

  const StaffRole(this.value);

  final String value;

  @override
  String toString() => value;
}
