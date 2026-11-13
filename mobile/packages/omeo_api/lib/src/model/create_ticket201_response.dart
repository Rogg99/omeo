//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_ticket201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateTicket201Response {
  /// Returns a new [CreateTicket201Response] instance.
  CreateTicket201Response({required this.number});

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTicket201Response && other.number == number;

  @override
  int get hashCode => number.hashCode;

  factory CreateTicket201Response.fromJson(Map<String, dynamic> json) =>
      _$CreateTicket201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTicket201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
