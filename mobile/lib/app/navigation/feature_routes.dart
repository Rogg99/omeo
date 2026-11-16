import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/widgets/widgets.dart';

/// Onglets de la barre principale, dans l'ordre d'affichage (deux de chaque
/// côté de l'action centrale).
enum AppTab {
  home(OmeoIcons.home),
  progress(OmeoIcons.chart),
  journal(OmeoIcons.calendar),
  profile(OmeoIcons.user)
  ;

  const AppTab(this.icon);
  final OmeoIcons icon;

  String label(AppLocalizations l) => switch (this) {
    AppTab.home => l.appNavHome,
    AppTab.progress => l.appNavProgress,
    AppTab.journal => l.appNavJournal,
    AppTab.profile => l.appNavProfile,
  };
}

/// Contribution d'un module à la navigation. Chaque module expose la sienne
/// dans `features/<module>/<module>_routes.dart` ; le routeur les assemble.
@immutable
final class FeatureRoutes {
  const FeatureRoutes({
    this.tabs = const {},
    this.routes = const [],
    this.onAddMeal,
    this.redirect,
    this.refresh,
    this.shellBanner,
  });

  /// Routes d'un onglet (sa pile de navigation, sous la barre).
  final Map<AppTab, List<RouteBase>> tabs;

  /// Routes plein écran, au-dessus de la barre d'onglets.
  final List<RouteBase> routes;

  /// Action centrale « + » de la barre (fournie par le module des repas).
  final void Function(BuildContext context)? onAddMeal;

  /// Garde de navigation (session, consentements) : renvoie un chemin pour
  /// rediriger, ou `null`. La première garde qui redirige l'emporte.
  final FeatureRedirect? redirect;

  /// Signale au routeur de réévaluer les gardes (changement de session).
  final Listenable? refresh;

  /// Bandeau affiché en haut des onglets (hors connexion, par exemple).
  final Widget? shellBanner;
}

/// Fabrique des routes d'un module : elle peut lire des providers.
typedef FeatureRoutesBuilder = FeatureRoutes Function(Ref ref);

/// Garde synchrone : l'état qu'elle lit (session…) est déjà en mémoire.
typedef FeatureRedirect =
    String? Function(BuildContext context, GoRouterState state);
