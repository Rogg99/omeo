import 'dart:io';

import 'package:omeo/core/config/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une URL externe (navigateur ou store).
Future<void> openExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Fiche de l'app sur son store, pour la mise à jour forcée.
Future<Uri> storeUri(AppConfig config) async {
  if (Platform.isIOS && config.iosAppStoreId.isNotEmpty) {
    return Uri.parse('https://apps.apple.com/app/id${config.iosAppStoreId}');
  }
  final info = await PackageInfo.fromPlatform();
  return Uri.parse(
    'https://play.google.com/store/apps/details?id=${info.packageName}',
  );
}

/// Page de support du site.
Uri supportUri([String? url]) =>
    Uri.parse(url ?? '${AppConfig.websiteUrl}/support');
