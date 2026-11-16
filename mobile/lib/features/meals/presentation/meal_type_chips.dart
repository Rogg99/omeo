import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo_api/omeo_api.dart' show MealType;

/// Icône de chaque type de repas, comme dans les maquettes.
OmeoIcons mealTypeIcon(MealType type) => switch (type) {
  MealType.breakfast => OmeoIcons.cup,
  MealType.lunch => OmeoIcons.utensils,
  MealType.snack => OmeoIcons.apple,
  MealType.dinner => OmeoIcons.moon,
};

/// Choix du type de repas (petit-déjeuner, déjeuner, collation, dîner).
class MealTypeChips extends StatelessWidget {
  const MealTypeChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final MealType? selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in MealType.values)
          OmeoChip(
            label: l.appMealTypeName(type.value),
            icon: mealTypeIcon(type),
            selected: type == selected,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}
