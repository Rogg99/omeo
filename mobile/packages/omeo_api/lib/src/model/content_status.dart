//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ContentStatus {
  @JsonValue(r'draft')
  draft(r'draft'),
  @JsonValue(r'review')
  review(r'review'),
  @JsonValue(r'published')
  published(r'published'),
  @JsonValue(r'archived')
  archived(r'archived');

  const ContentStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
