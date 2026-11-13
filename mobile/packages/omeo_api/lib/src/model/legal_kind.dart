//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum LegalKind {
  @JsonValue(r'terms')
  terms(r'terms'),
  @JsonValue(r'privacy')
  privacy(r'privacy'),
  @JsonValue(r'cookies')
  cookies(r'cookies'),
  @JsonValue(r'legal_notice')
  legalNotice(r'legal_notice');

  const LegalKind(this.value);

  final String value;

  @override
  String toString() => value;
}
