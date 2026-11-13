//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ConsentKind {
  @JsonValue(r'terms')
  terms(r'terms'),
  @JsonValue(r'privacy')
  privacy(r'privacy'),
  @JsonValue(r'health_data')
  healthData(r'health_data'),
  @JsonValue(r'marketing')
  marketing(r'marketing');

  const ConsentKind(this.value);

  final String value;

  @override
  String toString() => value;
}
