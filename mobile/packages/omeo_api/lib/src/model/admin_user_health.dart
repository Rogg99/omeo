//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/sex.dart';
import 'package:omeo_api/src/model/targets.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_health.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserHealth {
  /// Returns a new [AdminUserHealth] instance.
  AdminUserHealth({
    this.birthDate,

    this.sex,

    this.heightCm,

    this.currentWeightKg,

    this.targetWeightKg,

    this.targets,
  });

  @JsonKey(name: r'birth_date', required: false, includeIfNull: false)
  final DateTime? birthDate;

  @JsonKey(name: r'sex', required: false, includeIfNull: false)
  final Sex? sex;

  @JsonKey(name: r'height_cm', required: false, includeIfNull: false)
  final num? heightCm;

  @JsonKey(name: r'current_weight_kg', required: false, includeIfNull: false)
  final num? currentWeightKg;

  @JsonKey(name: r'target_weight_kg', required: false, includeIfNull: false)
  final num? targetWeightKg;

  @JsonKey(name: r'targets', required: false, includeIfNull: false)
  final Targets? targets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserHealth &&
          other.birthDate == birthDate &&
          other.sex == sex &&
          other.heightCm == heightCm &&
          other.currentWeightKg == currentWeightKg &&
          other.targetWeightKg == targetWeightKg &&
          other.targets == targets;

  @override
  int get hashCode =>
      birthDate.hashCode +
      sex.hashCode +
      heightCm.hashCode +
      currentWeightKg.hashCode +
      targetWeightKg.hashCode +
      targets.hashCode;

  factory AdminUserHealth.fromJson(Map<String, dynamic> json) =>
      _$AdminUserHealthFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserHealthToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
