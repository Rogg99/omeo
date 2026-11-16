import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/auth_actions.dart';
import 'package:omeo/features/auth/data/social_sign_in.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';
import 'package:omeo_api/omeo_api.dart';

/// Boutons Google et Apple, masqués sans connexion sociale configurée.
class SocialButtons extends ConsumerWidget {
  const SocialButtons({required this.onSelect, super.key, this.busy = false});

  final ValueChanged<SocialAuthRequestProviderEnum> onSelect;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final available = ref.watch(socialSignInProvider)?.available ?? const {};
    if (available.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in SocialAuthRequestProviderEnum.values)
          if (available.contains(p))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OmeoButton(
                label: p == SocialAuthRequestProviderEnum.google
                    ? l.appAuthContinueGoogle
                    : l.appAuthContinueApple,
                variant: OmeoButtonVariant.social,
                onPressed: busy ? null : () => onSelect(p),
              ),
            ),
      ],
    );
  }
}

/// Champ mot de passe avec bouton œil.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.hint,
    super.key,
    this.icon = OmeoIcons.lock,
    this.state = OmeoFieldState.normal,
    this.newPassword = false,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final OmeoIcons icon;
  final OmeoFieldState state;

  /// Saisie d'un nouveau mot de passe (gestionnaires de mots de passe).
  final bool newPassword;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OmeoTextField(
      controller: widget.controller,
      hint: widget.hint,
      icon: widget.icon,
      state: widget.state,
      obscure: _obscured,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: [
        if (widget.newPassword)
          AutofillHints.newPassword
        else
          AutofillHints.password,
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      trailing: ObscureToggle(
        obscured: _obscured,
        onToggle: () => setState(() => _obscured = !_obscured),
        showLabel: l.appAuthShowPassword,
        hideLabel: l.appAuthHidePassword,
      ),
    );
  }
}

/// Connexion (ACC-01) et son état d'erreur (ACC-02). Le message ne révèle
/// jamais si l'email existe ; les champs sont conservés.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    required this.onForgotPassword,
    required this.onStart,
    super.key,
  });

  /// Reçoit l'email saisi pour le préremplir (ACC-03).
  final ValueChanged<String> onForgotPassword;
  final VoidCallback onStart;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    unawaited(
      ref
          .read(loginProvider.notifier)
          .submit(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final login = ref.watch(loginProvider);
    final social = ref.watch(socialAuthProvider);
    final error = login.error ?? social.error;
    final credentialsError =
        error is ProblemFailure && error.code == 'invalid_credentials';
    final busy = login.isLoading || social.isLoading;
    final fieldState = credentialsError
        ? OmeoFieldState.error
        : OmeoFieldState.normal;

    return BottomActionsScaffold(
      header: OmeoTopBar(title: '', backLabel: l.commonActionBack),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: OmeoLogo(size: 40),
            ),
            const SizedBox(height: 24),
            ScreenTitle(
              l.appAuthLoginTitle,
              subtitle: l.appAuthLoginSubtitle,
            ),
            if (error != null) ...[
              const SizedBox(height: 24),
              Semantics(
                liveRegion: true,
                child: OmeoBanner(
                  icon: OmeoIcons.alert,
                  tone: OmeoTone.danger,
                  child: Text(
                    credentialsError
                        ? l.appAuthLoginInvalid
                        : _socialError(l, error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SocialButtons(
              busy: busy,
              onSelect: (p) =>
                  unawaited(ref.read(socialAuthProvider.notifier).submit(p)),
            ),
            if (ref.watch(socialSignInProvider) != null) ...[
              const SizedBox(height: 10),
              OrDivider(l.appAuthOr),
              const SizedBox(height: 20),
            ],
            OmeoTextField(
              controller: _email,
              hint: l.appAuthEmail,
              icon: OmeoIcons.mail,
              state: fieldState,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 10),
            PasswordField(
              controller: _password,
              hint: l.appAuthPassword,
              state: fieldState,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => widget.onForgotPassword(_email.text.trim()),
                child: Text(l.appAuthForgotLink),
              ),
            ),
            const SizedBox(height: 16),
            OmeoButton(
              label: l.appAuthLoginAction,
              loading: busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l.appAuthNoAccount,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: context.omeo.text2),
                ),
                TextButton(
                  onPressed: widget.onStart,
                  child: Text(l.appAuthStartLink),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: const [],
    );
  }

  /// Un compte social inexistant renvoie `validation_error` : on invite à
  /// commencer l'onboarding.
  String _socialError(AppLocalizations l, Object error) =>
      error is ProblemFailure && error.code == ProblemCodes.validationError
      ? l.appAuthSocialNoAccount
      : failureMessage(l, error);
}

/// Mot de passe oublié (ACC-03) : un seul champ, prérempli si connu.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    required this.onSent,
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;
  final ValueChanged<String> onSent;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    final ok = await ref.read(forgotPasswordProvider.notifier).submit(email);
    if (ok && mounted) widget.onSent(email);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(forgotPasswordProvider);
    return BottomActionsScaffold(
      header: OmeoTopBar(title: '', backLabel: l.commonActionBack),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: HeroBadge(OmeoIcons.key),
          ),
          const SizedBox(height: 20),
          ScreenTitle(l.appAuthForgotTitle, subtitle: l.appAuthForgotBody),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: _email,
            builder: (context, _) => OmeoTextField(
              controller: _email,
              hint: l.appAuthEmail,
              icon: OmeoIcons.mail,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              error: state.hasError ? failureMessage(l, state.error!) : null,
              onSubmitted: (_) => unawaited(_submit()),
            ),
          ),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: _email,
          builder: (context, _) => OmeoButton(
            label: l.appAuthForgotAction,
            loading: state.isLoading,
            onPressed: _email.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}

/// Lien envoyé (ACC-04) : ouverture de la messagerie et renvoi après délai.
class ResetLinkSentScreen extends ConsumerStatefulWidget {
  const ResetLinkSentScreen({
    required this.email,
    required this.onOpenMail,
    super.key,
    this.resendDelay = const Duration(seconds: 60),
  });

  final String email;
  final VoidCallback onOpenMail;
  final Duration resendDelay;

  @override
  ConsumerState<ResetLinkSentScreen> createState() =>
      _ResetLinkSentScreenState();
}

class _ResetLinkSentScreenState extends ConsumerState<ResetLinkSentScreen> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = widget.resendDelay.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(forgotPasswordProvider.notifier)
        .submit(widget.email);
    if (ok && mounted) setState(_startCountdown);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final waiting = _secondsLeft > 0;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final countdown = '${_secondsLeft ~/ 60}:$seconds';
    return BottomActionsScaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            const HeroBadge(OmeoIcons.mail, size: 84),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l.appAuthSentTitle,
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.appAuthSentBody(widget.email),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: t.text2),
            ),
          ],
        ),
      ),
      actions: [
        OmeoButton(label: l.appAuthOpenMail, onPressed: widget.onOpenMail),
        OmeoButton(
          label: waiting ? l.appAuthResendIn(countdown) : l.appAuthResend,
          variant: OmeoButtonVariant.ghost,
          loading: ref.watch(forgotPasswordProvider).isLoading,
          onPressed: waiting ? null : _resend,
        ),
      ],
    );
  }
}

/// Nouveau mot de passe depuis le lien reçu (ACC-05). L'API déconnecte
/// toutes les sessions existantes.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    required this.token,
    required this.onDone,
    super.key,
  });

  final String token;
  final VoidCallback onDone;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      PasswordRules.allMet(_password.text) && _password.text == _confirm.text;

  Future<void> _submit() async {
    final ok = await ref
        .read(resetPasswordProvider.notifier)
        .submit(token: widget.token, password: _password.text);
    if (!ok || !mounted) return;
    showOmeoToast(
      context,
      AppLocalizations.of(context).appAuthResetDone,
      icon: OmeoIcons.check,
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(resetPasswordProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([_password, _confirm]),
      builder: (context, _) {
        final mismatch =
            _confirm.text.isNotEmpty && _confirm.text != _password.text;
        return BottomActionsScaffold(
          header: OmeoTopBar(
            title: l.appAuthResetTitle,
            backLabel: l.commonActionClose,
            close: true,
          ),
          body: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.hasError) ...[
                  OmeoBanner(
                    icon: OmeoIcons.alert,
                    tone: OmeoTone.danger,
                    child: Text(
                      state.error is ProblemFailure &&
                              (state.error! as ProblemFailure).fieldErrors
                                  .containsKey('token')
                          ? l.appAuthResetLinkExpired
                          : failureMessage(l, state.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PasswordField(
                  controller: _password,
                  hint: l.appAuthNewPassword,
                  newPassword: true,
                  autofocus: true,
                  state: PasswordRules.allMet(_password.text)
                      ? OmeoFieldState.ok
                      : OmeoFieldState.normal,
                ),
                const SizedBox(height: 12),
                OmeoTextField(
                  controller: _confirm,
                  hint: l.appAuthConfirmPassword,
                  icon: OmeoIcons.shieldCheck,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  state: _valid ? OmeoFieldState.ok : OmeoFieldState.normal,
                  error: mismatch ? l.appAuthPasswordMismatch : null,
                ),
                const SizedBox(height: 12),
                PasswordRulesCard(password: _password.text),
                const SizedBox(height: OmeoTokens.space3),
                OmeoBanner(
                  icon: OmeoIcons.logout,
                  child: Text(l.appAuthResetSignsOutEverywhere),
                ),
              ],
            ),
          ),
          actions: [
            OmeoButton(
              label: l.commonActionSave,
              loading: state.isLoading,
              onPressed: _valid ? _submit : null,
            ),
          ],
        );
      },
    );
  }
}
