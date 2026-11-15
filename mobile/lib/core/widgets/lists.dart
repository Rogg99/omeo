import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';
import 'package:omeo/core/widgets/surfaces.dart';

/// Groupe de lignes dans une carte (`.list`), séparées par un filet.
class OmeoList extends StatelessWidget {
  const OmeoList({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(OmeoTokens.rLg),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(color: t.line),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne de liste (`li`) : pastille, titre, sous-titre et chevron.
class OmeoListTile extends StatelessWidget {
  const OmeoListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.iconTone = OmeoTone.primary,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final OmeoIcons? icon;
  final OmeoTone iconTone;

  /// Remplace la pastille d'icône (case à cocher, vignette…).
  final Widget? leading;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final lead =
        leading ??
        (icon == null
            ? null
            : BadgeIcon(icon!, tone: danger ? OmeoTone.danger : iconTone));
    final end =
        trailing ??
        (showChevron
            ? OmeoIcon(
                OmeoIcons.chevR,
                size: 20,
                color: t.text3,
                mirrorInRtl: true,
              )
            : null);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: OmeoTokens.weightSemibold,
                        height: 1.3,
                        color: danger ? t.danger : t.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: text.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.35,
                          color: t.text2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: 14), end],
            ],
          ),
        ),
      ),
    );
  }
}

/// Intitulé de groupe au-dessus d'une liste (`.list-label`).
class ListLabel extends StatelessWidget {
  const ListLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 10),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.96,
          ),
        ),
      ),
    );
  }
}

/// Titre de section (`.sec-title`) avec lien ou texte d'appoint à droite.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailingText,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 28, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: text.headlineSmall?.copyWith(fontSize: 19),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!))
          else if (trailingText != null)
            Text(
              trailingText!,
              style: text.bodySmall?.copyWith(fontSize: 11.5, color: t.text3),
            ),
        ],
      ),
    );
  }
}

/// Puce sélectionnable (`.chip`).
class OmeoChip extends StatelessWidget {
  const OmeoChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final OmeoIcons? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final fg = selected ? t.onContrast : t.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.contrast : t.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? t.contrast : t.lineStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: OmeoTokens.sizeTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  OmeoIcon(icon!, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: OmeoTokens.weightMedium,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contrôle segmenté (`.seg`).
class OmeoSegmented<T> extends StatelessWidget {
  const OmeoSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<({T value, String label})> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(OmeoTokens.rPill),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: s.value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(s.value),
                  child: AnimatedContainer(
                    duration: OmeoTokens.durationBase,
                    curve: OmeoTokens.ease,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: s.value == selected ? t.surface : null,
                      borderRadius: BorderRadius.circular(OmeoTokens.rPill),
                      boxShadow: s.value == selected ? t.shadow1 : null,
                    ),
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 13.5,
                        color: s.value == selected ? t.text : t.text2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Option de choix (onboarding) : carte avec titre, détail et sélection.
class OmeoOption extends StatelessWidget {
  const OmeoOption({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
    this.subtitle,
    this.leading,
    this.multiple = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      checked: multiple ? selected : null,
      selected: multiple ? null : selected,
      child: AnimatedContainer(
        duration: OmeoTokens.durationBase,
        curve: OmeoTokens.ease,
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(t.surface, t.primarySoft, 0.55)
              : t.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? t.primary : t.line,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 14)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: text.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: t.text2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SelectionMark(selected: selected, square: multiple),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Case à cocher (`.check`) ou bouton radio (`.radio`), purement visuels.
class SelectionMark extends StatelessWidget {
  const SelectionMark({required this.selected, super.key, this.square = true});

  final bool selected;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return AnimatedContainer(
      duration: OmeoTokens.durationFast,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? t.primary : (square ? t.surface : null),
        borderRadius: BorderRadius.circular(square ? 7 : 12),
        border: Border.all(
          color: selected ? t.primary : t.lineStrong,
          width: 2,
        ),
      ),
      child: selected
          ? OmeoIcon(
              OmeoIcons.check,
              size: square ? 16 : 14,
              strokeWidth: 3,
              color: t.onPrimary,
            )
          : null,
    );
  }
}
