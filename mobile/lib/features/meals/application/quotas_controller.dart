import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Quotas du compte (GET /me/quotas), relus avant chaque photo.
final FutureProvider<List<Quota>> quotasProvider =
    FutureProvider.autoDispose<List<Quota>>(
      (ref) => ref.watch(mealsRepositoryProvider).getQuotas(),
    );

/// Quota d'une fonctionnalité, s'il est renvoyé par l'API.
Quota? quotaFor(List<Quota> quotas, QuotaFeatureEnum feature) {
  for (final q in quotas) {
    if (q.feature == feature) return q;
  }
  return null;
}
