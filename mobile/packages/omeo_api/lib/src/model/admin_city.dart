//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_city.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCity {
  /// Returns a new [AdminCity] instance.
  AdminCity({
    required this.name,

    required this.country,

    required this.timezone,

    this.isSuggested,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  @JsonKey(name: r'country', required: true, includeIfNull: false)
  final String country;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @JsonKey(name: r'is_suggested', required: false, includeIfNull: false)
  final bool? isSuggested;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCity &&
          other.name == name &&
          other.country == country &&
          other.timezone == timezone &&
          other.isSuggested == isSuggested;

  @override
  int get hashCode =>
      name.hashCode +
      country.hashCode +
      timezone.hashCode +
      isSuggested.hashCode;

  factory AdminCity.fromJson(Map<String, dynamic> json) =>
      _$AdminCityFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
