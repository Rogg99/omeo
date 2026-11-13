//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum TicketStatus {
  @JsonValue(r'new')
  new_(r'new'),
  @JsonValue(r'open')
  open(r'open'),
  @JsonValue(r'waiting_user')
  waitingUser(r'waiting_user'),
  @JsonValue(r'resolved')
  resolved(r'resolved'),
  @JsonValue(r'closed')
  closed(r'closed');

  const TicketStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
