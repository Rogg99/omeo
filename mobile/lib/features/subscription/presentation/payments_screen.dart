import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/subscription/application/subscription_controller.dart';
import 'package:omeo_api/omeo_api.dart' show Payment, PaymentStatusEnum;

/// Historique des paiements (PLS-06) : tous canaux confondus, montants tels
/// que renvoyés par l'API, reçus quand ils existent.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({
    required this.onBack,
    required this.onReceipt,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<Uri> onReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final payments = ref.watch(paymentsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appPlusPaymentsTitle,
              backLabel: l.commonActionBack,
              onBack: onBack,
            ),
            Expanded(
              child: switch (payments) {
                AsyncValue(:final value?) when value.isEmpty => EmptyState(
                  icon: OmeoIcons.receipt,
                  title: l.appPlusPaymentsEmpty,
                ),
                AsyncValue(:final value?) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    OmeoList(
                      children: [
                        for (final p in value)
                          _PaymentTile(payment: p, onReceipt: onReceipt),
                      ],
                    ),
                    const SizedBox(height: OmeoTokens.space3),
                    Text(
                      l.appPlusPaymentsNote,
                      style: text.labelSmall?.copyWith(color: t.text3),
                    ),
                  ],
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appPlusPaymentsErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(paymentsProvider),
                ),
                _ => const Center(child: OmeoSpinner()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onReceipt});

  final Payment payment;
  final ValueChanged<Uri> onReceipt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final channel = l.appPlusSubscriptionChannel(payment.channel.value);
    final description = payment.description;
    final receipt = payment.receiptUrl;
    final flagged = payment.status != PaymentStatusEnum.succeeded;
    return OmeoListTile(
      leading: const BadgeIcon(
        OmeoIcons.receipt,
        tone: OmeoTone.neutral,
        size: BadgeSize.small,
      ),
      title: description == null
          ? channel
          : l.appPlusPaymentsLine(description, channel),
      subtitle: MaterialLocalizations.of(
        context,
      ).formatMediumDate(payment.paidAt.toLocal()),
      showChevron: false,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            payment.amount.formatted ?? '',
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (flagged) ...[
            const SizedBox(height: OmeoTokens.space1),
            OmeoTag(
              l.appPlusPaymentsStatus(payment.status.value),
              tone: payment.status == PaymentStatusEnum.failed
                  ? OmeoTone.danger
                  : OmeoTone.neutral,
            ),
          ],
        ],
      ),
      onTap: receipt == null ? null : () => onReceipt(Uri.parse(receipt)),
    );
  }
}
