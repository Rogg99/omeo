import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/presentation/camera_screen.dart';

void main() {
  testWidgets('caméra refusée : réglages, galerie et fermeture', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: CameraDeniedView(
          onClose: () => taps.add('close'),
          onOpenSettings: () => taps.add('settings'),
          onPickFromGallery: () => taps.add('gallery'),
        ),
      ),
    );
    expect(find.text('Omeo a besoin de ta caméra'), findsOneWidget);
    await tester.tap(find.text('Ouvrir les réglages'));
    await tester.tap(find.text('Choisir dans la galerie'));
    await tester.tap(find.bySemanticsLabel('Fermer'));
    expect(taps, ['settings', 'gallery', 'close']);
  });
}
