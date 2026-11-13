//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_revisions200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListRevisions200ResponseInner {
  /// Returns a new [AdminListRevisions200ResponseInner] instance.
  AdminListRevisions200ResponseInner({
    required this.id,

    required this.author,

    required this.createdAt,

    this.snapshot,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final String author;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'snapshot', required: false, includeIfNull: false)
  final Object? snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListRevisions200ResponseInner &&
          other.id == id &&
          other.author == author &&
          other.createdAt == createdAt &&
          other.snapshot == snapshot;

  @override
  int get hashCode =>
      id.hashCode + author.hashCode + createdAt.hashCode + snapshot.hashCode;

  factory AdminListRevisions200ResponseInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminListRevisions200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminListRevisions200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
