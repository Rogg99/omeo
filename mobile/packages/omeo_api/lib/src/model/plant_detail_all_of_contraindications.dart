//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plant_detail_all_of_contraindications.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlantDetailAllOfContraindications {
  /// Returns a new [PlantDetailAllOfContraindications] instance.
  PlantDetailAllOfContraindications({this.code, this.label});

  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final String? code;

  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantDetailAllOfContraindications &&
          other.code == code &&
          other.label == label;

  @override
  int get hashCode => code.hashCode + label.hashCode;

  factory PlantDetailAllOfContraindications.fromJson(
    Map<String, dynamic> json,
  ) => _$PlantDetailAllOfContraindicationsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PlantDetailAllOfContraindicationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
