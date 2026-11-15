import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo/mock/fixtures/home_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo_api/omeo_api.dart';

/// Accueil simulé : la variante dépend du scénario et du jour demandé.
final class HomeMockRepository implements HomeRepository {
  const HomeMockRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Home> getHome({DateTime? date}) => _backend.call(() {
    final scenario = _backend.scenario;
    final plus = scenario == MockScenario.plus;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = date == null
        ? today
        : DateTime(date.year, date.month, date.day);
    final variant = switch (scenario) {
      MockScenario.firstLaunch || MockScenario.emptyDay => HomeVariant.firstDay,
      _ when day == today => HomeVariant.current,
      _ when day == today.subtract(const Duration(days: 1)) => HomeVariant.over,
      _ => HomeVariant.past,
    };
    return homeFixture(variant, date: day, plus: plus);
  });
}
