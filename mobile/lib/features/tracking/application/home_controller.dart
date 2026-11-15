import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Jour affiché sur l'accueil ; `null` pour aujourd'hui.
class SelectedHomeDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  // Le jour affiché est un état simple : un setter suffit.
  // ignore: avoid_setters_without_getters
  set day(DateTime? date) => state = date;
}

final selectedHomeDayProvider = NotifierProvider<SelectedHomeDay, DateTime?>(
  SelectedHomeDay.new,
);

/// Accueil du jour sélectionné. Garde les données précédentes pendant le
/// rechargement (pas de squelette au changement de jour).
final homeProvider = FutureProvider<Home>((ref) {
  final date = ref.watch(selectedHomeDayProvider);
  return ref.watch(homeRepositoryProvider).getHome(date: date);
});
