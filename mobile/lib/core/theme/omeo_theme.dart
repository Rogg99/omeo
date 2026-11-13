import 'package:flutter/material.dart';
import 'package:omeo/core/theme/tokens.g.dart';

/// Expose les tokens du thème actif aux widgets : `context.omeo.primary`.
@immutable
final class OmeoColors extends ThemeExtension<OmeoColors> {
  const OmeoColors(this.tokens);

  final OmeoThemeTokens tokens;

  @override
  OmeoColors copyWith({OmeoThemeTokens? tokens}) =>
      OmeoColors(tokens ?? this.tokens);

  /// Les tokens sont discrets : pas d'interpolation, bascule à mi-parcours.
  @override
  OmeoColors lerp(OmeoColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension OmeoThemeContext on BuildContext {
  OmeoThemeTokens get omeo => Theme.of(this).extension<OmeoColors>()!.tokens;
}

/// Construit le ThemeData Material à partir des tokens générés.
abstract final class OmeoTheme {
  static ThemeData light({bool arabic = false}) =>
      _build(OmeoTokens.light, Brightness.light, arabic: arabic);

  static ThemeData dark({bool arabic = false}) =>
      _build(OmeoTokens.dark, Brightness.dark, arabic: arabic);

  static ThemeData _build(
    OmeoThemeTokens t,
    Brightness brightness, {
    required bool arabic,
  }) {
    // En arabe, IBM Plex Sans Arabic prend la main pour tout le texte.
    final body = arabic ? OmeoTokens.fontArabic : OmeoTokens.fontBody;
    final display = arabic ? OmeoTokens.fontArabic : OmeoTokens.fontDisplay;
    const fallback = [OmeoTokens.fontArabic];

    TextStyle style(
      String family,
      double size,
      FontWeight weight, {
      double height = 1.35,
      double letterSpacing = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? t.text,
    );

    final textTheme = TextTheme(
      displayLarge: style(
        display,
        OmeoTokens.text5xl,
        OmeoTokens.weightSemibold,
        height: 1,
        letterSpacing: -1.5,
      ),
      displayMedium: style(
        display,
        OmeoTokens.text4xl,
        OmeoTokens.weightSemibold,
        height: 1.05,
        letterSpacing: -1,
      ),
      displaySmall: style(
        display,
        OmeoTokens.text3xl,
        OmeoTokens.weightSemibold,
        height: 1.1,
        letterSpacing: -0.6,
      ),
      headlineMedium: style(
        display,
        OmeoTokens.text2xl,
        OmeoTokens.weightSemibold,
        height: 1.15,
        letterSpacing: -0.4,
      ),
      headlineSmall: style(
        display,
        OmeoTokens.textXl,
        OmeoTokens.weightSemibold,
        height: 1.2,
        letterSpacing: -0.2,
      ),
      titleLarge: style(
        display,
        OmeoTokens.textLg,
        OmeoTokens.weightSemibold,
        height: 1.25,
      ),
      titleMedium: style(
        display,
        OmeoTokens.textMd,
        OmeoTokens.weightSemibold,
        height: 1.3,
      ),
      titleSmall: style(body, OmeoTokens.textSm, OmeoTokens.weightBold),
      bodyLarge: style(
        body,
        OmeoTokens.textMd,
        OmeoTokens.weightRegular,
        height: 1.5,
      ),
      bodyMedium: style(
        body,
        OmeoTokens.textSm,
        OmeoTokens.weightRegular,
        height: 1.45,
      ),
      bodySmall: style(
        body,
        OmeoTokens.textXs,
        OmeoTokens.weightRegular,
        height: 1.4,
        color: t.text3,
      ),
      labelLarge: style(
        body,
        OmeoTokens.textMd,
        OmeoTokens.weightSemibold,
        height: 1.2,
      ),
      labelMedium: style(
        body,
        OmeoTokens.textSm,
        OmeoTokens.weightSemibold,
        height: 1.2,
      ),
      labelSmall: style(
        body,
        OmeoTokens.textXs,
        OmeoTokens.weightBold,
        height: 1.2,
        letterSpacing: 0.4,
        color: t.text3,
      ),
    );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primarySoft,
      onPrimaryContainer: t.primaryText,
      secondary: t.accent,
      onSecondary: t.textInv,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.accentText,
      error: t.danger,
      onError: t.textInv,
      errorContainer: t.dangerSoft,
      onErrorContainer: t.danger,
      surface: t.surface,
      onSurface: t.text,
      onSurfaceVariant: t.text2,
      surfaceContainerLowest: t.surfaceSunk,
      surfaceContainerLow: t.bgElev,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surface2,
      surfaceContainerHighest: t.surface2,
      outline: t.lineStrong,
      outlineVariant: t.line,
      inverseSurface: t.contrast,
      onInverseSurface: t.onContrast,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    const pill = StadiumBorder();
    const buttonSize = Size(OmeoTokens.space12, 52);
    const touch = Size(OmeoTokens.space12, OmeoTokens.space12);

    OutlineInputBorder field(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(OmeoTokens.rSm),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.bg,
      fontFamily: body,
      fontFamilyFallback: fallback,
      textTheme: textTheme,
      dividerColor: t.line,
      splashFactory: InkSparkle.splashFactory,
      extensions: [OmeoColors(t)],
      dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.contrast,
          foregroundColor: t.onContrast,
          minimumSize: buttonSize,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.text,
          minimumSize: buttonSize,
          shape: pill,
          side: BorderSide(color: t.lineStrong, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primaryText,
          minimumSize: touch,
          textStyle: textTheme.labelMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.text,
          minimumSize: touch,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: t.text3),
        contentPadding: const EdgeInsets.all(OmeoTokens.space4),
        border: field(t.line),
        enabledBorder: field(t.line),
        focusedBorder: field(t.primary),
        errorBorder: field(t.danger),
        focusedErrorBorder: field(t.danger),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.bgElev,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: t.lineStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(OmeoTokens.rXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.contrast,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.onContrast),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmeoTokens.rSm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary),
    );
  }
}
