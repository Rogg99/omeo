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
    return Scaffold(
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
  }
}
