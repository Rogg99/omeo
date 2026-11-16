import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/widgets/widgets.dart';

/// Coquille des onglets : la page de l'onglet courant sous la barre
/// flottante. Un onglet sans module enregistré reste visible mais inactif.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.branchTabs,
    this.onAddMeal,
    this.banners = const [],
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// Onglet de chaque branche, dans l'ordre des branches.
  final List<AppTab> branchTabs;
  final void Function(BuildContext context)? onAddMeal;

  /// Bandeaux des modules, au-dessus de la page de l'onglet.
  final List<Widget> banners;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = branchTabs[navigationShell.currentIndex];
    final shell = Scaffold(
      extendBody: true,
      body: banners.isEmpty
          ? navigationShell
          : Column(
              children: [
                SafeArea(bottom: false, child: Column(children: banners)),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: navigationShell,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: OmeoTabBar(
        tabs: [
          for (final tab in AppTab.values)
            (
              icon: tab.icon,
              label: tab.label(l),
              enabled: branchTabs.contains(tab),
            ),
        ],
        currentIndex: current.index,
        onSelect: (i) {
          final branch = branchTabs.indexOf(AppTab.values[i]);
          if (branch < 0) return;
          // Un nouvel appui sur l'onglet courant revient à sa racine.
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        fabLabel: l.appNavAddMeal,
        onFab: onAddMeal == null ? null : () => onAddMeal!(context),
      ),
    );
    return AddMealAction(onAddMeal: onAddMeal, child: shell);
  }
}

/// Action « Ajouter un repas » de la barre, offerte aux écrans des onglets
/// (le « + » de chaque repas du journal, par exemple).
class AddMealAction extends InheritedWidget {
  const AddMealAction({
    required this.onAddMeal,
    required super.child,
    super.key,
  });

  final void Function(BuildContext context)? onAddMeal;

  /// `null` hors de la coquille ou sans module des repas.
  static void Function(BuildContext context)? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AddMealAction>()?.onAddMeal;

  @override
  bool updateShouldNotify(AddMealAction oldWidget) =>
      onAddMeal != oldWidget.onAddMeal;
}
