import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/subscription_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

void main() {
  late MockBackend backend;
  late SubscriptionMockRepository repo;

  setUp(() {
    backend = MockBackend(latency: Duration.zero);
    repo = SubscriptionMockRepository(backend);
  });

  test("l'état suit le scénario", () async {
    expect((await repo.getSubscription()).entitlements.tier, PlanTier.trial);
    backend.setScenario(MockScenario.free);
    expect((await repo.getSubscription()).entitlements.tier, PlanTier.free);
    backend.setScenario(MockScenario.plusGrace);
    final grace = await repo.getSubscription();
    expect(grace.subscription?.status, SubscriptionStatus.grace);
    expect(grace.canManage, SubscriptionStateCanManageEnum.web);
  });

  test("l'annuel est mis en avant avec son économie", () async {
    final plans = (await repo.listPlans()).plans;
    final annual = plans.firstWhere((p) => p.featured);
    expect(annual.savingsPercent, 13);
    expect(annual.price.formatted, r'46,99 $');
  });

  test('un achat vérifié passe en Plus', () async {
    backend.setScenario(MockScenario.free);
    final state = await repo.verifyPurchase(
      const GooglePlayReceipt(
        productId: 'omeo_plus_annual',
        purchaseToken: 't',
      ),
      idempotencyKey: 'k',
    );
    expect(state.entitlements.tier, PlanTier.plus);
    expect((await repo.getSubscription()).entitlements.tier, PlanTier.plus);
  });

  test('preuve vide : refus selon le code', () {
    expect(
      repo.verifyPurchase(const AppStoreReceipt(''), idempotencyKey: 'k'),
      throwsA(
        isA<ProblemFailure>().having((f) => f.code, 'code', 'invalid_receipt'),
      ),
    );
  });

  test('restauration sans achat : état inchangé', () async {
    backend.setScenario(MockScenario.free);
    final state = await repo.restorePurchases(const []);
    expect(state.entitlements.tier, PlanTier.free);
  });

  test('parrainage : jours gagnés et filleuls', () async {
    final referral = await repo.getReferral();
    expect((referral.daysEarned, referral.daysCap), (14, 35));
    expect(referral.referees, hasLength(3));
  });
}
