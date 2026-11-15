import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/core/platform/external_links.dart';
import 'package:omeo/features/support/presentation/system_screens.dart';
import 'package:omeo/features/support/support_paths.dart';

/// Routes du module support : écrans bloquants (426, compte suspendu).
FeatureRoutes supportRoutes(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return FeatureRoutes(
    routes: [
      GoRoute(
        path: SupportPaths.upgrade,
        builder: (context, state) => UpgradeRequiredScreen(
          onUpdate: () async => openExternal(await storeUri(config)),
        ),
      ),
      GoRoute(
        path: SupportPaths.suspended,
        builder: (context, state) => AccountSuspendedScreen(
          onContact: () => unawaited(
            openExternal(supportUri(state.uri.queryParameters['support'])),
          ),
        ),
      ),
    ],
  );
}
