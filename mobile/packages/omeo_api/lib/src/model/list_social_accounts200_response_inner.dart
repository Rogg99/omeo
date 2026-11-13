//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_social_accounts200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListSocialAccounts200ResponseInner {
  /// Returns a new [ListSocialAccounts200ResponseInner] instance.
  ListSocialAccounts200ResponseInner({
    required this.provider,

    required this.email,
  });

  @JsonKey(name: r'provider', required: true, includeIfNull: false)
  final ListSocialAccounts200ResponseInnerProviderEnum provider;

  @JsonKey(name: r'email', required: true, includeIfNull: true)
  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListSocialAccounts200ResponseInner &&
          other.provider == provider &&
          other.email == email;

  @override
  int get hashCode => provider.hashCode + (email == null ? 0 : email.hashCode);

  factory ListSocialAccounts200ResponseInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListSocialAccounts200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListSocialAccounts200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ListSocialAccounts200ResponseInnerProviderEnum {
  @JsonValue(r'google')
  google(r'google'),
  @JsonValue(r'apple')
  apple(r'apple');

  const ListSocialAccounts200ResponseInnerProviderEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
