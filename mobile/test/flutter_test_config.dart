import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuration commune des tests : polices de l'app chargées pour que les
/// goldens « plateforme » ressemblent à l'écran réel. Les goldens CI
/// (police Ahem) restent stables d'une machine à l'autre et sont les seuls
/// comparés en intégration continue (variable d'environnement CI=true).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: Platform.environment['CI'] != 'true',
      ),
    ),
    run: testMain,
  );
}

Future<void> _loadFonts() async {
  const families = {
    'Space Grotesk': ['assets/fonts/SpaceGrotesk.ttf'],
    'DM Sans': ['assets/fonts/DMSans.ttf'],
    'Instrument Serif': ['assets/fonts/InstrumentSerif-Regular.ttf'],
    'IBM Plex Sans Arabic': [
      'assets/fonts/IBMPlexSansArabic-Regular.ttf',
      'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
