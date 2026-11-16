import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/auth/auth_paths.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/onboarding/data/onboarding_draft.dart';
import 'package:omeo/features/onboarding/onboarding_paths.dart';
import 'package:omeo/features/onboarding/presentation/account_step.dart';
import 'package:omeo/features/onboarding/presentation/plan_screens.dart';
import 'package:omeo/features/onboarding/presentation/question_steps.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';

/// Reprend le questionnaire à la dernière étape atteinte. Le retour
/// remonte ensuite les étapes une à une.
Future<void> resumeOnboarding(Ref ref, BuildContext context) async {
  final draft = await ref.read(onboardingProvider.future);
  if (!context.mounted) return;
  context.go(
    draft.step > onboardingQuestionSteps
        ? OnboardingPaths.account
        : OnboardingPaths.stepOf(draft.step),
  );
}

/// Routes du questionnaire (ONB-04 à ONB-16).
FeatureRoutes onboardingRoutes(Ref ref) => FeatureRoutes(
  routes: [
    GoRoute(
      path: OnboardingPaths.step,
      builder: (context, state) {
        final n = (int.tryParse(state.pathParameters['n'] ?? '') ?? 1).clamp(
          1,
          onboardingQuestionSteps,
        );
        return QuestionStepScreen(
          key: ValueKey(n),
          step: n,
          onNext: () => context.push(
            n < onboardingQuestionSteps
                ? OnboardingPaths.stepOf(n + 1)
                : OnboardingPaths.account,
          ),
          onBack: () => _back(
            context,
            n > 1 ? OnboardingPaths.stepOf(n - 1) : AuthPaths.welcome,
          ),
        );
      },
    ),
    GoRoute(
      path: OnboardingPaths.account,
      builder: (context, state) => AccountStepScreen(
        initialInviteCode: state.uri.queryParameters['invite'],
        onBack: () => _back(
          context,
          OnboardingPaths.stepOf(onboardingQuestionSteps),
        ),
        onSubmitted: () => context.go(OnboardingPaths.computing),
        onOpenLegal: (kind) => context.push(AuthPaths.legalOf(kind)),
      ),
    ),
    GoRoute(
      path: OnboardingPaths.computing,
      builder: (context, state) => PlanComputingScreen(
        onReady: () => context.go(OnboardingPaths.ready),
        onFailed: () => context.go(OnboardingPaths.account),
      ),
    ),
    GoRoute(
      path: OnboardingPaths.ready,
      builder: (context, state) =>
          PlanReadyScreen(onStart: () => context.go(TrackingPaths.home)),
    ),
  ],
);

void _back(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
