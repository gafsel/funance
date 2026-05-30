import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/controller/category_form_notifier.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class CategoryFormDialog extends StatelessWidget {
  final CategoryModel? category;
  final CategoryType? initialType;

  const CategoryFormDialog({super.key, this.category, this.initialType});

  static const Map<String, IconData> availableIcons = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'flash_on': Icons.flash_on,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'school': Icons.school,
    'health_and_safety': Icons.health_and_safety,
    'fitness_center': Icons.fitness_center,
    'theater_comedy': Icons.theater_comedy,
    'flight': Icons.flight,
    'category': Icons.category,
    'work': Icons.work,
    'payments': Icons.payments,
    'savings': Icons.savings,
    'pets': Icons.pets,
    'stroller': Icons.stroller,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'checkroom': Icons.checkroom,
    'medication': Icons.medication,
    'spa': Icons.spa,
    'face': Icons.face,
    'brushes': Icons.brush,
    'handyman': Icons.handyman,
    'cleaning_services': Icons.cleaning_services,
    'build': Icons.build,
    'subscriptions': Icons.subscriptions,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'celebration': Icons.celebration,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ManualForm<CategoryFormState, void, CategoryFormNotifier>(
      CategoryViewProviders.form(category),
      formBuilder: (context, snapshot) {
        final state = snapshot.model;
        final notifier = snapshot.notifier;

        return AlertDialog(
          title: Text(
            category == null
                ? l10n.categoryCreateTitle
                : l10n.categoryEditTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: state.name,
                  decoration: InputDecoration(
                    labelText: l10n.categoryNameLabel,
                  ),
                  onChanged: notifier.updateName,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CategoryType>(
                  value: state.type,
                  decoration: InputDecoration(
                    labelText: l10n.categoryTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CategoryType.income,
                      child: Text(l10n.categoryTypeIncome),
                    ),
                    DropdownMenuItem(
                      value: CategoryType.expense,
                      child: Text(l10n.categoryTypeExpense),
                    ),
                    DropdownMenuItem(
                      value: CategoryType.both,
                      child: Text(l10n.categoryTypeBoth),
                    ),
                  ],
                  onChanged: (val) => notifier.updateType(val!),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.categoryColorLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.categoryColors.map((color) {
                    final colorHex =
                        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                    final isSelected = state.color.toUpperCase() == colorHex;
                    return GestureDetector(
                      onTap: () => notifier.updateColor(colorHex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.categoryIconLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.entries
                      .map((entry) {
                        final isSelected = state.icon == entry.key;
                        return GestureDetector(
                          onTap: () => notifier.updateIcon(entry.key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(
                                      int.parse(
                                        state.color.replaceAll('#', '0xFF'),
                                      ),
                                    )
                                  : Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              entry.value,
                              size: 20,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            LoadingButton.elevated(
              onPressed: (loading) async {
                if (snapshot.validate()) {
                  final navigator = Navigator.of(context);

                  await loading(notifier.submit());

                  navigator.pop();
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }
}
