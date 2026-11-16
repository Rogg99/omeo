import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';

/// État visuel d'un champ (`.input.ok`, `.input.error`).
enum OmeoFieldState { normal, ok, error }

/// Champ de saisie des maquettes (`input`) : libellé, icône, aide ou erreur,
/// unité, et variante géante pour les nombres de l'onboarding.
class OmeoTextField extends StatelessWidget {
  const OmeoTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.help,
    this.error,
    this.state = OmeoFieldState.normal,
    this.unit,
    this.trailing,
    this.obscure = false,
    this.big = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;

  /// Libellé au-dessus du champ ; à défaut [hint] sert de libellé lu.
  final String? label;
  final String? hint;
  final OmeoIcons? icon;

  /// Texte d'aide sous le champ, remplacé par [error] s'il existe.
  final String? help;
  final String? error;
  final OmeoFieldState state;
  final String? unit;
  final Widget? trailing;
  final bool obscure;

  /// Nombre géant centré (poids, taille).
  final bool big;
  final int maxLines;

  /// Affiche le compteur « 12/60 » sous le champ.
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final effective = error != null ? OmeoFieldState.error : state;
    final borderColor = switch (effective) {
      OmeoFieldState.normal => null,
      OmeoFieldState.ok => t.primary,
      OmeoFieldState.error => t.danger,
    };
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
          borderSide: BorderSide(color: color, width: width),
        );
    final helpText = error ?? help;
    final style = big
        ? text.displaySmall?.copyWith(
            fontSize: 56,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : text.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Text(
              label!,
              style: text.labelLarge?.copyWith(color: t.text2),
            ),
          ),
        TextField(
          controller: controller,
          autofocus: autofocus,
          enabled: enabled,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: maxLines > 1 ? 3 : null,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          textCapitalization: textCapitalization,
          textAlign: big ? TextAlign.center : TextAlign.start,
          style: style,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : OmeoIcon(icon!, size: 20, color: t.text3),
            suffixIcon: trailing,
            suffixText: unit,
            suffixStyle: big
                ? text.headlineSmall?.copyWith(color: t.text3)
                : text.bodyLarge?.copyWith(color: t.text3),
            enabledBorder: borderColor == null ? null : border(borderColor),
            focusedBorder: borderColor == null ? null : border(borderColor, 2),
          ),
        ),
        if (helpText != null || maxLength != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: error != null,
                    child: Text(
                      helpText ?? '',
                      style: text.bodySmall?.copyWith(
                        color: switch (effective) {
                          OmeoFieldState.error => t.danger,
                          OmeoFieldState.ok => t.primaryText,
                          OmeoFieldState.normal => t.text3,
                        },
                      ),
                    ),
                  ),
                ),
                if (maxLength != null && controller != null)
                  ListenableBuilder(
                    listenable: controller!,
                    builder: (context, _) => Text(
                      '${controller!.text.characters.length}/$maxLength',
                      style: text.bodySmall?.copyWith(color: t.text3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bouton œil d'un champ mot de passe.
class ObscureToggle extends StatelessWidget {
  const ObscureToggle({
    required this.obscured,
    required this.onToggle,
    required this.showLabel,
    required this.hideLabel,
    super.key,
  });

  final bool obscured;
  final VoidCallback onToggle;
  final String showLabel;
  final String hideLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? showLabel : hideLabel,
      onPressed: onToggle,
      icon: OmeoIcon(
        obscured ? OmeoIcons.eye : OmeoIcons.eyeOff,
        size: 20,
        color: context.omeo.text3,
      ),
    );
  }
}

/// Interrupteur (`.switch`) avec cible tactile de 48 dp.
class OmeoSwitch extends StatelessWidget {
  const OmeoSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;

  /// `null` : interrupteur verrouillé.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      label: semanticLabel,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: t.primary,
        activeThumbColor: t.onPrimary,
        inactiveTrackColor: t.surface2,
        trackOutlineColor: WidgetStatePropertyAll(t.line),
      ),
    );
  }
}
