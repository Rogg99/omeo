//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard_active_users.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDashboardActiveUsers {
  /// Returns a new [AdminDashboardActiveUsers] instance.
  AdminDashboardActiveUsers({this.dau, this.wau, this.mau});

  @JsonKey(name: r'dau', required: false, includeIfNull: false)
  final int? dau;

  @JsonKey(name: r'wau', required: false, includeIfNull: false)
  final int? wau;

  @JsonKey(name: r'mau', required: false, includeIfNull: false)
  final int? mau;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboardActiveUsers &&
          other.dau == dau &&
          other.wau == wau &&
          other.mau == mau;

  @override
  int get hashCode => dau.hashCode + wau.hashCode + mau.hashCode;

  factory AdminDashboardActiveUsers.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardActiveUsersFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDashboardActiveUsersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
