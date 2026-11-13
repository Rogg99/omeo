//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard_retention.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDashboardRetention {
  /// Returns a new [AdminDashboardRetention] instance.
  AdminDashboardRetention({this.d1, this.d7, this.d30});

  @JsonKey(name: r'd1', required: false, includeIfNull: false)
  final num? d1;

  @JsonKey(name: r'd7', required: false, includeIfNull: false)
  final num? d7;

  @JsonKey(name: r'd30', required: false, includeIfNull: false)
  final num? d30;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboardRetention &&
          other.d1 == d1 &&
          other.d7 == d7 &&
          other.d30 == d30;

  @override
  int get hashCode => d1.hashCode + d7.hashCode + d30.hashCode;

  factory AdminDashboardRetention.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardRetentionFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDashboardRetentionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
