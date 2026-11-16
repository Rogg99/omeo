import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/subscription/presentation/quota_exhausted_sheet.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: OmeoTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('Free : Plus en option et alternative gratuite', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _app(
        QuotaExhaustedSheet(
          canUpgrade: true,
          resetsAt: DateTime(2026, 11, 17),
          onDiscoverPlus: () => taps.add('plus'),
          onSearchCatalog: () => taps.add('catalog'),
          onDismiss: () => taps.add('dismiss'),
        ),
      ),
    );
    expect(find.textContaining('Elles reviennent'), findsOneWidget);
    expect(find.text('Compris'), findsNothing);
    await tester.tap(find.text('Essayer Omeo Plus'));
    await tester.tap(find.text('Chercher le plat dans le catalogue'));
    expect(taps, ['plus', 'catalog']);
  });

  testWidgets('Plus : date de remise à zéro, sans proposition d’achat', (
    tester,
  ) async {
    var dismissed = 0;
    await tester.pumpWidget(
      _app(
        QuotaExhaustedSheet(
          canUpgrade: false,
          resetsAt: DateTime(2026, 11, 14),
          onDismiss: () => dismissed++,
        ),
      ),
    );
    expect(find.textContaining('Elles se rechargent le'), findsOneWidget);
    expect(find.text('Essayer Omeo Plus'), findsNothing);
    await tester.tap(find.text('Compris'));
    expect(dismissed, 1);
  });
}
