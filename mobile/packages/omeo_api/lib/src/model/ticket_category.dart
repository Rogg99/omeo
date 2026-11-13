//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum TicketCategory {
  @JsonValue(r'question')
  question(r'question'),
  @JsonValue(r'technical')
  technical(r'technical'),
  @JsonValue(r'billing')
  billing(r'billing'),
  @JsonValue(r'suggestion')
  suggestion(r'suggestion'),
  @JsonValue(r'personal_data')
  personalData(r'personal_data'),
  @JsonValue(r'account_deletion')
  accountDeletion(r'account_deletion');

  const TicketCategory(this.value);

  final String value;

  @override
  String toString() => value;
}
