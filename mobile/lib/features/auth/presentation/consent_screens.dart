import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/auth_actions.dart';
import 'package:omeo_api/omeo_api.dart';

/// Ouvre la feuille des nouvelles conditions (SYS-05). Elle ne se ferme
/// qu'après acceptation : l'API refuse les appels tant que les documents
/// ne sont pas acceptés (403 consent_required).
Future<void> showConsentSheet({
  required BuildContext context,
  required List<String> documentKinds,
  required ValueChanged<String> onRead,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (context) => PopScope(
      canPop: false,
      child: OmeoSheet(
        child: ConsentSheet(documentKinds: documentKinds, onRead: onRead),
      ),
    ),
  );
}

/// Contenu de la feuille SYS-05 : documents modifiés, lecture complète,
/// acceptation obligatoire.
class ConsentSheet extends ConsumerWidget {
  const ConsentSheet({
    required this.documentKinds,
    required this.onRead,
    super.key,
  });

  /// Codes des documents (`terms`, `privacy`).
  final List<String> documentKinds;

  /// Ouvre le document complet (code du document).
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final key = documentKinds.join(',');
    final documents = ref.watch(pendingLegalDocumentsProvider(key));
    final accepting = ref.watch(consentProvider);

    return switch (documents) {
      AsyncValue(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(l.appAuthConsentTitle, style: text.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            l.appAuthConsentBody,
            style: text.bodyMedium?.copyWith(color: t.text2),
          ),
          const SizedBox(height: 16),
          OmeoCard(
            variant: OmeoCardVariant.sunk,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OmeoIcon(OmeoIcons.check, size: 18, color: t.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.appAuthConsentDocument(
                              d.title,
                              d.version,
                              context.longDate(d.publishedAt.toLocal()),
                            ),
                            style: text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (final d in value)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => onRead(d.kind.value),
                child: Text(l.appAuthConsentRead(d.title)),
              ),
            ),
          if (accepting.hasError) ...[
            const SizedBox(height: 8),
            Text(
              failureMessage(l, accepting.error!),
              style: text.bodySmall?.copyWith(color: t.danger),
            ),
          ],
          const SizedBox(height: 16),
          OmeoButton(
            label: l.appAuthConsentAccept,
            loading: accepting.isLoading,
            onPressed: () async {
              final ok = await ref.read(consentProvider.notifier).accept([
                for (final d in value)
                  LegalDocumentRef(
                    kind: d.kind,
                    version: d.version,
                    title: d.title,
                  ),
              ]);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),
          Text(
            l.appAuthConsentRequired,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: t.text3),
          ),
        ],
      ),
      AsyncValue(:final error?) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appAuthConsentLoadError,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => ref.invalidate(pendingLegalDocumentsProvider(key)),
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: OmeoSpinner()),
      ),
    };
  }
}

/// Lecture d'un document légal (texte Markdown renvoyé par l'API, affiché
/// en paragraphes).
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({required this.kind, super.key});

  final LegalKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final document = ref.watch(legalDocumentProvider(kind));
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OmeoTopBar(
              title: document.value?.title ?? '',
              eyebrow: document.value == null
                  ? null
                  : l.appAuthLegalVersion(
                      document.value!.version,
                      context.longDate(document.value!.publishedAt.toLocal()),
                    ),
              backLabel: l.commonActionBack,
            ),
            Expanded(
              child: switch (document) {
                AsyncValue(:final value?) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    for (final block in markdownBlocks(value.body))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: OmeoTokens.space3,
                        ),
                        child: block.heading
                            ? Semantics(
                                header: true,
                                child: Text(
                                  block.text,
                                  style: text.titleMedium,
                                ),
                              )
                            : Text(block.text, style: text.bodyMedium),
                      ),
                  ],
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appAuthConsentLoadError,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(legalDocumentProvider(kind)),
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

/// Découpe un Markdown simple en titres et paragraphes, sans syntaxe
/// visible (les documents légaux n'utilisent que titres, listes et gras).
List<({bool heading, String text})> markdownBlocks(String markdown) {
  final blocks = <({bool heading, String text})>[];
  for (final raw in markdown.split(RegExp(r'\n\s*\n'))) {
    final block = raw.trim();
    if (block.isEmpty) continue;
    final heading = block.startsWith('#');
    final cleaned = block
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .replaceAll(RegExp(r'\*\*|__'), '')
        .replaceAllMapped(
          RegExp(r'^\s*[-*]\s+', multiLine: true),
          (_) => '• ',
        );
    blocks.add((heading: heading, text: cleaned));
  }
  return blocks;
}

/// Rappel discret de vérification d'email (ACC-06), en haut de l'accueil.
class VerifyEmailBanner extends ConsumerWidget {
  const VerifyEmailBanner({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  /// Texte renvoyé par l'API avec la bannière `verify_email`.
  final String? message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final resend = ref.watch(resendVerificationProvider);
    return OmeoBanner(
      icon: OmeoIcons.mail,
      tone: OmeoTone.info,
      trailing: OmeoIconButton(
        icon: OmeoIcons.x,
        small: true,
        ghost: true,
        semanticLabel: l.commonActionClose,
        onPressed: onDismiss,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message ?? l.appAuthVerifyEmailBody),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: AlignmentDirectional.centerStart,
            ),
            onPressed: resend.isLoading
                ? null
                : () async {
                    final ok = await ref
                        .read(resendVerificationProvider.notifier)
                        .resend();
                    if (!context.mounted) return;
                    showOmeoToast(
                      context,
                      ok
                          ? l.appAuthVerifyEmailSent
                          : failureMessage(
                              l,
                              ref
                                  .read(
                                    resendVerificationProvider,
                                  )
                                  .error!,
                            ),
                    );
                  },
            child: Text(l.appAuthVerifyEmailResend),
          ),
        ],
      ),
    );
  }
}
