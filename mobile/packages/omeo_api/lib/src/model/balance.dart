//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'balance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Balance {
  /// Returns a new [Balance] instance.
  Balance({
    required this.consumedKcal,

    required this.burnedKcal,

    required this.differenceKcal,

    required this.status,

    this.label,
  });

  @JsonKey(name: r'consumed_kcal', required: true, includeIfNull: false)
  final int consumedKcal;

  @JsonKey(name: r'burned_kcal', required: true, includeIfNull: false)
  final int burnedKcal;

  @JsonKey(name: r'difference_kcal', required: true, includeIfNull: false)
  final int differenceKcal;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final BalanceStatusEnum status;

  /// Texte traduit
  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Balance &&
          other.consumedKcal == consumedKcal &&
          other.burnedKcal == burnedKcal &&
          other.differenceKcal == differenceKcal &&
          other.status == status &&
          other.label == label;

  @override
  int get hashCode =>
      consumedKcal.hashCode +
      burnedKcal.hashCode +
      differenceKcal.hashCode +
      status.hashCode +
      label.hashCode;

  factory Balance.fromJson(Map<String, dynamic> json) =>
      _$BalanceFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum BalanceStatusEnum {
  @JsonValue(r'deficit')
  deficit(r'deficit'),
  @JsonValue(r'balanced')
  balanced(r'balanced'),
  @JsonValue(r'surplus')
  surplus(r'surplus');

  const BalanceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
