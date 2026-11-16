import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';

/// Bandeau hors connexion (SYS-02) : persistant mais discret, avec le nombre
/// de repas en attente d'envoi. L'app reste utilisable.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingMealsCountProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget? banner = switch ((online, pending)) {
      (false, 0) => _Banner(
        icon: OmeoIcons.wifiOff,
        text: l.appMealOfflineBanner,
      ),
      (false, final n) => _Banner(
        icon: OmeoIcons.wifiOff,
        text: l.appMealOfflineBannerPending(n),
      ),
      (true, 0) => null,
      (true, final n) => _Banner(
        icon: OmeoIcons.cloudUp,
        text: l.appMealOfflineSyncing(n),
      ),
    };

    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : OmeoTokens.durationBase,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: banner ?? const SizedBox(width: double.infinity),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final OmeoIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: OmeoBanner(icon: icon, child: Text(text)),
    ),
  );
}
