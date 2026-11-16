import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/features/subscription/presentation/referral_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';

void main() {
  testWidgets('code, partage WhatsApp, jours gagnés et filleuls', (
    tester,
  ) async {
    final shared = <String>[];
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            SubscriptionMockRepository(MockBackend(latency: Duration.zero)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OmeoTheme.light(),
          home: ReferralScreen(
            navigation: (
              onBack: () {},
              shareOnWhatsApp: (m) => shared.add('whatsapp:$m'),
              shareElsewhere: (m) => shared.add('other:$m'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AWA7'), findsOneWidget);
    expect(find.text('14 / 35'), findsOneWidget);
    expect(find.text('Fatou D.'), findsOneWidget);
    expect(find.text('En attente : premier repas'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Copier le code'));
    await tester.pump();
    expect(clipboard, 'AWA7');
    expect(find.text('Code copié'), findsOneWidget);

    await tester.tap(find.text('Partager sur WhatsApp'));
    await tester.tap(find.text('Autres applis'));
    expect(shared, hasLength(2));
    expect(shared.first, startsWith('whatsapp:'));
    expect(shared.first, contains('https://my-omeo.app/i/AWA7'));
  });
}
