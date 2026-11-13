import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/app/app.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';

void main() {
  testWidgets('le thème expose les tokens du mode clair', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      ProviderScope(
        child: OmeoApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(captured.omeo.primary, OmeoTokens.light.primary);
  });

  testWidgets('arabe : sens de droite à gauche et police arabe', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(Directionality.of(captured), TextDirection.rtl);
    expect(
      OmeoTheme.dark(arabic: true).textTheme.bodyLarge?.fontFamily,
      OmeoTokens.fontArabic,
    );
  });
}
