import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/core/config/app_config.dart';
import 'package:omeo/features/support/presentation/system_screens.dart';
import 'package:omeo/features/tracking/presentation/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Chemins de l'app. Les liens profonds `omeo://` et `https://my-omeo.app`
/// arrivent sur ces mêmes chemins.
abstract final class Routes {
  static const home = '/';
  static const upgrade = '/upgrade';
  static const suspended = '/suspended';
}

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

final routerProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const Scaffold(
          body: HomeScreen(
            unreadNotifications: 0,
            // Les destinations sont branchées avec leurs modules.
            navigation: (
              openHelp: null,
              openNotifications: null,
              quickAction: null,
              openJournal: null,
              openShortcut: null,
              openProgram: null,
              openChallenge: null,
              openRewards: null,
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.upgrade,
        builder: (context, state) => UpgradeRequiredScreen(
          onUpdate: () async => openExternal(await storeUri(config)),
        ),
      ),
      GoRoute(
        path: Routes.suspended,
        builder: (context, state) => AccountSuspendedScreen(
          onContact: () => unawaited(
            openExternal(
              Uri.parse(
                state.uri.queryParameters['support'] ??
                    '${AppConfig.websiteUrl}/support',
              ),
            ),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
