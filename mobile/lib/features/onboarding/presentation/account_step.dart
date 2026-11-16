import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/auth_actions.dart';
import 'package:omeo/features/auth/data/social_sign_in.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';
import 'package:omeo/features/auth/presentation/login_screens.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/onboarding/presentation/step_scaffold.dart';
import 'package:omeo_api/omeo_api.dart';

/// Format d'un code d'invitation (contrat : 4 à 10 lettres ou chiffres).
final _inviteFormat = RegExp(r'^[A-Za-z0-9]{4,10}$');
const _inviteMaxLength = 10;

/// Étape 9 (ONB-13, ONB-14) : code d'invitation d'abord, puis Google /
/// Apple ou email, et consentements séparés.
class AccountStepScreen extends ConsumerStatefulWidget {
  const AccountStepScreen({
    required this.onBack,
    required this.onSubmitted,
    required this.onOpenLegal,
    super.key,
    this.initialInviteCode,
  });

  final VoidCallback onBack;

  /// Inscription lancée : écran d'attente du calcul du plan.
  final VoidCallback onSubmitted;

  /// Ouvre un document légal (`terms`, `privacy`).
  final ValueChanged<String> onOpenLegal;

  /// Code reçu par le lien d'installation, prérempli.
  final String? initialInviteCode;

  @override
  ConsumerState<AccountStepScreen> createState() => _AccountStepScreenState();
}

class _AccountStepScreenState extends ConsumerState<AccountStepScreen> {
  late final _invite = TextEditingController(text: widget.initialInviteCode);
  final _email = TextEditingController();
  final _password = TextEditingController();
  Timer? _debounce;
  String _checkedCode = '';
  bool _termsAccepted = false;
  bool _healthAccepted = false;
  bool _marketing = false;
  late final _termsLink = TapGestureRecognizer()
    ..onTap = () => widget.onOpenLegal('terms');
  late final _privacyLink = TapGestureRecognizer()
    ..onTap = () => widget.onOpenLegal('privacy');

  @override
  void initState() {
    super.initState();
    _checkedCode = _validInvite(_invite.text) ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _invite.dispose();
    _email.dispose();
    _password.dispose();
    _termsLink.dispose();
    _privacyLink.dispose();
    super.dispose();
  }

  static String? _validInvite(String? raw) {
    final code = (raw ?? '').trim();
    return _inviteFormat.hasMatch(code) ? code.toUpperCase() : null;
  }

  void _onInviteChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => setState(() => _checkedCode = _validInvite(value) ?? ''),
    );
  }

  /// Code envoyé à l'inscription : seulement s'il a été reconnu valide. Un
  /// code invalide ne bloque jamais l'inscription.
  String? get _inviteToSend {
    if (_checkedCode.isEmpty) return null;
    final check = ref.read(inviteCheckProvider(_checkedCode)).value;
    return check?.valid ?? false ? _checkedCode : null;
  }

  bool get _consentsOk => _termsAccepted && _healthAccepted;

  bool get _canSubmit =>
      _consentsOk &&
      _email.text.trim().contains('@') &&
      PasswordRules.allMet(_password.text);

  Future<void> _submit() async {
    final locale = Localizations.localeOf(context).languageCode;
    unawaited(
      ref.read(registrationProvider.notifier).register((
        email: _email.text,
        password: _password.text,
        inviteCode: _inviteToSend,
        marketing: _marketing,
        locale: locale,
      )),
    );
    widget.onSubmitted();
  }

  Future<void> _social(SocialAuthRequestProviderEnum provider) async {
    if (!_consentsOk) {
      showOmeoToast(
        context,
        AppLocalizations.of(context).appOnboardingConsentFirst,
        icon: OmeoIcons.info,
      );
      return;
    }
    final draft = await ref.read(onboardingProvider.future);
    final config = await ref.read(publicConfigProvider.future);
    if (!mounted) return;
    await ref
        .read(socialAuthProvider.notifier)
        .submit(
          provider,
          signUp: (
            profile: draft.toProfile(
              locale: Localizations.localeOf(context).languageCode,
              timezone: ref.read(deviceTimezoneProvider),
            ),
            consents: registrationConsents(
              legalVersions: config.legalVersions,
              marketing: _marketing,
            ),
            inviteCode: _inviteToSend,
          ),
        );
    if (ref.read(socialAuthProvider).value != null) {
      unawaited(ref.read(onboardingProvider.notifier).clear());
      widget.onSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final registration = ref.watch(registrationProvider);
    final social = ref.watch(socialAuthProvider);
    final error = registration.error ?? social.error;
    final hasSocial = ref.watch(socialSignInProvider) != null;

    return ListenableBuilder(
      listenable: Listenable.merge([_email, _password, _invite]),
      builder: (context, _) => BottomActionsScaffold(
        header: StepHeader(step: onboardingTotalSteps, onBack: widget.onBack),
        body: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              ScreenTitle(
                l.appOnboardingAccountTitle,
                subtitle: l.appOnboardingAccountSubtitle,
                large: false,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: OmeoBanner(
                    icon: OmeoIcons.alert,
                    tone: OmeoTone.danger,
                    child: Text(_errorMessage(l, error)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _InviteField(
                controller: _invite,
                checkedCode: _checkedCode,
                onChanged: _onInviteChanged,
              ),
              if (hasSocial) ...[
                const SizedBox(height: 16),
                SocialButtons(
                  busy: social.isLoading,
                  onSelect: (p) => unawaited(_social(p)),
                ),
                const SizedBox(height: 6),
                OrDivider(l.appOnboardingOrEmail),
              ],
              const SizedBox(height: 16),
              OmeoTextField(
                controller: _email,
                hint: l.appAuthEmail,
                icon: OmeoIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 10),
              PasswordField(
                controller: _password,
                hint: l.appAuthPassword,
                newPassword: true,
              ),
              const SizedBox(height: 10),
              PasswordRulesCard(password: _password.text),
              const SizedBox(height: 20),
              _ConsentRow(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v),
                requirement: l.appOnboardingConsentRequired,
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l.appOnboardingConsentTermsBefore),
                      _link(l.appOnboardingConsentTermsLink, _termsLink, t),
                      TextSpan(text: l.appOnboardingConsentTermsBetween),
                      _link(l.appOnboardingConsentPrivacyLink, _privacyLink, t),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ConsentRow(
                value: _healthAccepted,
                onChanged: (v) => setState(() => _healthAccepted = v),
                requirement: l.appOnboardingConsentRequired,
                label: Text(l.appOnboardingConsentHealth),
              ),
              const SizedBox(height: 12),
              _ConsentRow(
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
                requirement: l.appOnboardingConsentOptional,
                label: Text(l.appOnboardingConsentMarketing),
              ),
            ],
          ),
        ),
        actions: [
          OmeoButton(
            label: l.appOnboardingCreateAccount,
            loading: registration.isLoading,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }

  InlineSpan _link(
    String label,
    GestureRecognizer recognizer,
    OmeoThemeTokens t,
  ) => TextSpan(
    text: label,
    style: TextStyle(
      color: t.primaryText,
      decoration: TextDecoration.underline,
      fontWeight: OmeoTokens.weightSemibold,
    ),
    recognizer: recognizer,
  );

  String _errorMessage(AppLocalizations l, Object error) {
    if (error is ProblemFailure) {
      if (error.fieldErrors.containsKey('email') || error.code == 'conflict') {
        return l.appOnboardingEmailTaken;
      }
      if (error.fieldErrors.containsKey('password')) {
        return l.appOnboardingPasswordRejected;
      }
    }
    return failureMessage(l, error);
  }
}

/// Code d'invitation (facultatif), vérifié pendant la saisie. Un code
/// inconnu reste non bloquant (ONB-14).
class _InviteField extends ConsumerWidget {
  const _InviteField({
    required this.controller,
    required this.checkedCode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String checkedCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final check = checkedCode.isEmpty
        ? null
        : ref.watch(inviteCheckProvider(checkedCode));
    final result = check?.value;
    final valid = result?.valid ?? false;
    final invalid = result != null && !result.valid;
    return OmeoTextField(
      controller: controller,
      hint: l.appOnboardingInviteHint,
      icon: OmeoIcons.gift,
      maxLength: _inviteMaxLength,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
      ],
      state: valid ? OmeoFieldState.ok : OmeoFieldState.normal,
      trailing: switch (check) {
        AsyncValue(isLoading: true) => const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox.square(dimension: 18, child: OmeoSpinner(size: 18)),
        ),
        _ when valid => Padding(
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: Center(
            widthFactor: 1,
            child: OmeoTag(
              l.appOnboardingInviteDays(result!.trialDays),
              icon: OmeoIcons.check,
            ),
          ),
        ),
        _ => null,
      },
      help: valid && result!.referrerFirstName != null
          ? l.appOnboardingInviteFrom(result.referrerFirstName!)
          : l.appOnboardingInviteHelp,
      error: invalid ? l.appOnboardingInviteInvalid(result.trialDays) : null,
      onChanged: onChanged,
    );
  }
}

/// Case de consentement avec sa mention « Obligatoire » ou « Facultatif ».
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.requirement,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  final String requirement;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(OmeoTokens.rSm),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                checked: value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SelectionMark(selected: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: text.bodyMedium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label,
                      Text(
                        requirement,
                        style: text.bodySmall?.copyWith(color: t.text3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
