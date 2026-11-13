//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/entitlements.dart';
import 'package:omeo_api/src/model/rewards_summary.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/legal_document_ref.dart';
import 'package:omeo_api/src/model/me_preferences.dart';
import 'package:omeo_api/src/model/me_profile.dart';
import 'package:omeo_api/src/model/targets.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Me {
  /// Returns a new [Me] instance.
  Me({
    required this.id,

    required this.email,

    required this.emailVerified,

    this.hasPassword,

    required this.locale,

    this.createdAt,

    required this.profile,

    required this.targets,

    required this.entitlements,

    required this.preferences,

    this.pendingDocuments,

    this.rewardsSummary,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'email_verified', required: true, includeIfNull: false)
  final bool emailVerified;

  @JsonKey(name: r'has_password', required: false, includeIfNull: false)
  final bool? hasPassword;

  @JsonKey(name: r'locale', required: true, includeIfNull: false)
  final Locale locale;

  @JsonKey(name: r'created_at', required: false, includeIfNull: false)
  final DateTime? createdAt;

  @JsonKey(name: r'profile', required: true, includeIfNull: false)
  final MeProfile profile;

  @JsonKey(name: r'targets', required: true, includeIfNull: false)
  final Targets targets;

  @JsonKey(name: r'entitlements', required: true, includeIfNull: false)
  final Entitlements entitlements;

  @JsonKey(name: r'preferences', required: true, includeIfNull: false)
  final MePreferences preferences;

  @JsonKey(name: r'pending_documents', required: false, includeIfNull: false)
  final List<LegalDocumentRef>? pendingDocuments;

  @JsonKey(name: r'rewards_summary', required: false, includeIfNull: false)
  final RewardsSummary? rewardsSummary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Me &&
          other.id == id &&
          other.email == email &&
          other.emailVerified == emailVerified &&
          other.hasPassword == hasPassword &&
          other.locale == locale &&
          other.createdAt == createdAt &&
          other.profile == profile &&
          other.targets == targets &&
          other.entitlements == entitlements &&
          other.preferences == preferences &&
          other.pendingDocuments == pendingDocuments &&
          other.rewardsSummary == rewardsSummary;

  @override
  int get hashCode =>
      id.hashCode +
      email.hashCode +
      emailVerified.hashCode +
      hasPassword.hashCode +
      locale.hashCode +
      createdAt.hashCode +
      profile.hashCode +
      targets.hashCode +
      entitlements.hashCode +
      preferences.hashCode +
      pendingDocuments.hashCode +
      rewardsSummary.hashCode;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  Map<String, dynamic> toJson() => _$MeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
