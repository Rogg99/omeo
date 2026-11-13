import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';

/// Racine de l'application : thème, langues et navigation.
class OmeoApp extends ConsumerWidget {
  const OmeoApp({required this.home, super.key});

  /// Écran affiché tant que le routeur n'est pas branché.
  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).commonPlusName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: OmeoTheme.light(),
      darkTheme: OmeoTheme.dark(),
      // Le thème arabe change de famille de polices ; Directionality suit
      // la locale grâce aux délégués de localisation.
      builder: (context, child) {
        final arabic = Localizations.localeOf(context).languageCode == 'ar';
        if (!arabic) return child!;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: dark
              ? OmeoTheme.dark(arabic: true)
              : OmeoTheme.light(arabic: true),
          child: child!,
        );
      },
      home: home,
    );
  }
}
