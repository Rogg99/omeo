import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/theme/omeo_theme.dart';

/// Variante d'affichage testée : clair, sombre ou arabe (RTL).
enum DisplayVariant { light, dark, arabic }

/// Habille un widget avec le thème, la langue et le sens de lecture.
Widget wrapForTest(
  Widget child, {
  DisplayVariant variant = DisplayVariant.light,
  double textScale = 1,
  bool reduceMotion = false,
}) {
  final arabic = variant == DisplayVariant.arabic;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(arabic ? 'ar' : 'fr'),
    supportedLocales: const [Locale('fr'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: variant == DisplayVariant.dark
        ? OmeoTheme.dark()
        : OmeoTheme.light(arabic: arabic),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Habillage léger pour les goldens : thème, langue et sens de lecture, sans
/// Scaffold (la taille suit le contenu).
Widget themedForGolden(
  Widget child, {
  DisplayVariant variant = DisplayVariant.light,
}) {
  final arabic = variant == DisplayVariant.arabic;
  final theme = variant == DisplayVariant.dark
      ? OmeoTheme.dark()
      : OmeoTheme.light(arabic: arabic);
  return Localizations(
    locale: Locale(arabic ? 'ar' : 'fr'),
    delegates: GlobalMaterialLocalizations.delegates,
    child: Theme(
      data: theme,
      child: Builder(
        builder: (context) => Material(
          color: theme.scaffoldBackgroundColor,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!,
            child: child,
          ),
        ),
      ),
    ),
  );
}

extension PumpOmeo on WidgetTester {
  Future<void> pumpOmeo(
    Widget child, {
    DisplayVariant variant = DisplayVariant.light,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    await pumpWidget(
      wrapForTest(
        child,
        variant: variant,
        textScale: textScale,
        reduceMotion: reduceMotion,
      ),
    );
    await pumpAndSettle();
  }
}
