//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Channel {
  @JsonValue(r'google_play')
  googlePlay(r'google_play'),
  @JsonValue(r'app_store')
  appStore(r'app_store'),
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'grant')
  grant(r'grant');

  const Channel(this.value);

  final String value;

  @override
  String toString() => value;
}
