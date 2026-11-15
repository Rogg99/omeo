import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/buttons.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';

/// En-tête des onglets principaux (`appbar`) : logo, aide, notifications.
class OmeoAppBar extends StatelessWidget {
  const OmeoAppBar({
    required this.helpLabel,
    required this.notificationsLabel,
    required this.unreadCount,
    this.onHelp,
    this.onNotifications,
    super.key,
  });

  final String helpLabel;

  /// Libellé lu, qui inclut déjà le nombre de non lues.
  final String notificationsLabel;
  final int unreadCount;
  final VoidCallback? onHelp;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 14, 10),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: OmeoLogo(),
            ),
          ),
          OmeoIconButton(
            icon: OmeoIcons.help,
            semanticLabel: helpLabel,
            onPressed: onHelp,
          ),
          OmeoIconButton(
            icon: OmeoIcons.bell,
            semanticLabel: notificationsLabel,
            badgeCount: unreadCount,
            onPressed: onNotifications,
          ),
        ],
      ),
    );
  }
}

/// En-tête des pages empilées (`topbar`) : retour, titre centré, action.
class OmeoTopBar extends StatelessWidget {
  const OmeoTopBar({
    required this.title,
    required this.backLabel,
    super.key,
    this.eyebrow,
    this.trailing,
    this.close = false,
    this.onBack,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final String backLabel;

  /// Croix au lieu d'une flèche (écrans modaux).
  final bool close;

  /// Par défaut : `Navigator.maybePop`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
      child: Row(
        children: [
          OmeoIconButton(
            icon: close ? OmeoIcons.x : OmeoIcons.chevL,
            mirrorInRtl: !close,
            semanticLabel: backLabel,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!),
                  const SizedBox(height: 4),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.square(dimension: OmeoTokens.space12),
        ],
      ),
    );
  }
}

/// Sur-titre en capitales espacées (`.eyebrow`).
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 11,
        height: 1,
        letterSpacing: 1.3,
        fontWeight: OmeoTokens.weightSemibold,
        color: color,
      ),
    );
  }
}

/// Onglet de la barre principale. `enabled` à faux : onglet visible mais
/// inactif (module pas encore disponible).
typedef OmeoTab = ({OmeoIcons icon, String label, bool enabled});

/// Barre d'onglets flottante avec action centrale (`tabbar` + `fab`).
/// Quatre onglets : deux de chaque côté du bouton d'ajout.
class OmeoTabBar extends StatelessWidget {
  const OmeoTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.fabLabel,
    this.onFab,
    super.key,
  }) : assert(tabs.length == 4, 'La barre a exactement quatre onglets.');

  final List<OmeoTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final String fabLabel;

  /// Action centrale ; inactive si `null`.
  final VoidCallback? onFab;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget tab(int i) => Expanded(
      child: _TabItem(
        tab: tabs[i],
        selected: i == currentIndex,
        onTap: tabs[i].enabled
            ? () {
                if (i != currentIndex) {
                  unawaited(HapticFeedback.selectionClick());
                }
                onSelect(i);
              }
            : null,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom > 0 ? bottom : 14),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: t.shadow2,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: t.line),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              container: true,
              explicitChildNodes: true,
              child: Row(
                children: [
                  tab(0),
                  tab(1),
                  SizedBox(
                    width: 76,
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -18),
                        child: _Fab(label: fabLabel, onTap: onFab),
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final OmeoTab tab;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final color = selected ? t.primaryText : t.text3;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: tab.label,
      container: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Opacity(
          opacity: onTap == null && !selected ? 0.4 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: OmeoTokens.durationBase,
                width: 52,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? t.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: OmeoIcon(tab.icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected
                      ? OmeoTokens.weightBold
                      : OmeoTokens.weightMedium,
                  color: color,
                ),
                // La barre garde sa hauteur : le texte des onglets ne grossit
                // pas au-delà de 1,3 fois.
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: t.contrast.withValues(alpha: 0.45),
              offset: const Offset(0, 10),
              blurRadius: 22,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Material(
          color: t.contrast,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    unawaited(HapticFeedback.mediumImpact());
                    onTap!();
                  },
            child: SizedBox.square(
              dimension: 62,
              child: Center(
                child: OmeoIcon(OmeoIcons.plus, size: 28, color: t.onContrast),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jour du bandeau de la semaine.
typedef DayStripItem = ({
  String shortName,
  String number,
  String semanticLabel,
  bool hasEntries,
  bool isFuture,
});

/// Bandeau de la semaine (`days`) : sept jours, un sélectionné.
class DayStrip extends StatelessWidget {
  const DayStrip({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<DayStripItem> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _Day(
                day: days[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
                tokens: t,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });

  final DayStripItem day;
  final bool selected;
  final VoidCallback onTap;
  final OmeoThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final fg = selected ? t.onContrast : t.text;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);
    return Semantics(
      button: !day.isFuture,
      selected: selected,
      label: day.semanticLabel,
      container: true,
      excludeSemantics: true,
      child: Opacity(
        opacity: day.isFuture && !selected ? 0.45 : 1,
        child: Material(
          color: selected ? t.contrast : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: selected ? t.contrast : t.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: day.isFuture ? null : onTap,
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.shortName.toUpperCase(),
                        textScaler: scaler,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: OmeoTokens.weightSemibold,
                          letterSpacing: 0.6,
                          color: selected ? fg.withValues(alpha: 0.7) : t.text3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.number,
                        textScaler: scaler,
                        style: TextStyle(
                          fontFamily: Theme.of(
                            context,
                          ).textTheme.titleMedium?.fontFamily,
                          fontSize: 17,
                          fontWeight: OmeoTokens.weightSemibold,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                  if (day.hasEntries)
                    Positioned(
                      bottom: 7,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? t.accent : t.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
