import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/router.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/support/presentation/system_screens.dart';
import 'package:omeo/features/support/support_paths.dart';

/// Racine de l'application : thème, langues, navigation et erreurs globales.
class OmeoApp extends ConsumerWidget {
  const OmeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).commonPlusName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: OmeoTheme.light(),
      darkTheme: OmeoTheme.dark(),
      routerConfig: router,
      // En arabe, le thème change de famille de polices ; Directionality
      // suit la locale grâce aux délégués de localisation.
      builder: (context, child) {
        final arabic = Localizations.localeOf(context).languageCode == 'ar';
        final dark = Theme.of(context).brightness == Brightness.dark;
        final themed = arabic
            ? Theme(
                data: dark
                    ? OmeoTheme.dark(arabic: true)
                    : OmeoTheme.light(arabic: true),
                child: child!,
              )
            : child!;
        return GlobalErrorListener(router: router, child: themed);
      },
    );
  }
}

/// Réagit aux erreurs globales de l'API, quel que soit l'écran affiché.
class GlobalErrorListener extends ConsumerStatefulWidget {
  const GlobalErrorListener({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<GlobalErrorListener> createState() =>
      _GlobalErrorListenerState();
}

class _GlobalErrorListenerState extends ConsumerState<GlobalErrorListener> {
  StreamSubscription<GlobalErrorEvent>? _subscription;
  bool _quotaSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(globalErrorBusProvider).events.listen(_handle);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _handle(GlobalErrorEvent event) {
    switch (event) {
      case UpgradeRequired():
        widget.router.go(SupportPaths.upgrade);
      case AccountSuspended(:final supportUrl):
        widget.router.go(
          Uri(
            path: SupportPaths.suspended,
            queryParameters: {'support': ?supportUrl},
          ).toString(),
        );
      case QuotaExceeded(:final canUpgrade, :final resetsAt):
        unawaited(_showQuota(canUpgrade: canUpgrade, resetsAt: resetsAt));
      // Présentation de Plus, réacceptation des CGU et déconnexion :
      // traitées par les modules abonnement, compte et authentification.
      case PlanRequired() || ConsentRequired() || SignedOut():
        break;
    }
  }

  Future<void> _showQuota({
    required bool canUpgrade,
    DateTime? resetsAt,
  }) async {
    final context = widget.router.routerDelegate.navigatorKey.currentContext;
    if (_quotaSheetOpen || context == null) return;
    _quotaSheetOpen = true;
    final l = AppLocalizations.of(context);
    await showOmeoSheet<void>(
      context: context,
      title: l.appSystemQuotaTitle,
      closeLabel: l.commonActionClose,
      builder: (_) => QuotaSheet(canUpgrade: canUpgrade, resetsAt: resetsAt),
    );
    _quotaSheetOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
