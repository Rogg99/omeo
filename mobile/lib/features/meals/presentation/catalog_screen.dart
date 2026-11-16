import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/catalog_controller.dart';
import 'package:omeo_api/omeo_api.dart' show DishSummary;

/// Délai avant de lancer la recherche pendant la frappe.
const _searchDebounce = Duration(milliseconds: 300);

/// Drapeau d'un code pays ISO à deux lettres (présentation seule).
String countryFlag(String code) => String.fromCharCodes(
  code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
);

/// Catalogue de plats (MEA-13) : recherche, filtre par pays, récents et
/// favoris en tête pour aller vite.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({
    required this.onClose,
    required this.onDish,
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<DishSummary> onDish;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      _searchDebounce,
      () => ref.read(catalogQueryProvider.notifier).search(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(catalogQueryProvider);
    final content = ref.watch(catalogProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OmeoTopBar(
              title: l.appMealCatalogTitle,
              backLabel: l.commonActionClose,
              close: true,
              onBack: widget.onClose,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.appMealCatalogSearchHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 14, end: 8),
                    child: OmeoIcon(OmeoIcons.search, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                ),
              ),
            ),
            const SizedBox(height: OmeoTokens.space3),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  OmeoChip(
                    label: l.appMealCatalogAllCountries,
                    selected: query.country == null,
                    onTap: () => ref
                        .read(catalogQueryProvider.notifier)
                        .filterCountry(null),
                  ),
                  for (final code in catalogCountries)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: OmeoChip(
                        label:
                            '${countryFlag(code)} '
                            '${l.appMealCatalogCountry(code)}',
                        selected: query.country == code,
                        onTap: () => ref
                            .read(catalogQueryProvider.notifier)
                            .filterCountry(code),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (content) {
                AsyncValue(:final value?) => _CatalogList(
                  content: value,
                  onDish: widget.onDish,
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appMealCatalogErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(catalogProvider),
                ),
                _ => const _CatalogSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({required this.content, required this.onDish});

  final CatalogContent content;
  final ValueChanged<DishSummary> onDish;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final results = content.results;
    if (results != null && results.isEmpty) {
      return EmptyState(
        icon: OmeoIcons.search,
        title: l.appMealCatalogEmptyTitle,
        message: l.appMealCatalogEmptyBody,
      );
    }
    final sections = results != null
        ? [(l.appMealCatalogResults, results)]
        : [
            if (content.recent.isNotEmpty)
              (l.appMealCatalogRecent, content.recent),
            if (content.favorites.isNotEmpty)
              (l.appMealCatalogFavorites, content.favorites),
          ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        for (final (title, dishes) in sections) ...[
          const SizedBox(height: OmeoTokens.space4),
          Eyebrow(title),
          const SizedBox(height: OmeoTokens.space2),
          OmeoList(
            children: [
              for (final dish in dishes)
                DishTile(dish: dish, onTap: () => onDish(dish)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Ligne d'un plat : vignette, nom, portion standard et bouton d'ajout.
class DishTile extends StatelessWidget {
  const DishTile({required this.dish, required this.onTap, super.key});

  final DishSummary dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final kcal = dish.kcalPerPortion;
    return OmeoListTile(
      leading: DishThumb(url: dish.image?.url),
      title: dish.name,
      subtitle: kcal == null ? null : l.appMealCatalogPortion(kcal),
      showChevron: false,
      trailing: Semantics(
        label: l.appMealCatalogAdd(dish.name),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.primarySoft,
            borderRadius: BorderRadius.circular(OmeoTokens.rPill),
          ),
          child: Center(
            child: OmeoIcon(OmeoIcons.plus, size: 18, color: t.primaryText),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Vignette d'un plat, ou un pictogramme si le plat n'a pas d'image.
class DishThumb extends StatelessWidget {
  const DishThumb({required this.url, super.key, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final placeholder = ColoredBox(
      color: t.primarySoft,
      child: Center(
        child: OmeoIcon(OmeoIcons.utensils, color: t.primaryText, size: 20),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 80, height: 12),
        SizedBox(height: 12),
        Skeleton(height: 72, radius: OmeoTokens.rLg),
        SizedBox(height: 8),
        Skeleton(height: 72, radius: OmeoTokens.rLg),
        SizedBox(height: 24),
        Skeleton(width: 80, height: 12),
        SizedBox(height: 12),
        Skeleton(height: 72, radius: OmeoTokens.rLg),
      ],
    ),
  );
}
