import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/controller/category_form_notifier.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../providers.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(CategoryViewProviders.allStream);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (rawCategories) {
          final categories = [...rawCategories]
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return categories.isEmpty
              ? Center(child: Text(l10n.categoryManagementEmpty))
              : ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(category.color.replaceAll('#', '0xFF')),
                        ),
                        child: Icon(
                          _getIconData(category.icon),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(category.name),
                      subtitle: Text(category.type.name.toUpperCase()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showCategoryDialog(context, ref, category),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, ref, category),
                          ),
                        ],
                      ),
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, [
    CategoryModel? category,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CategoryFormDialog(category: category),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle),
        content: Text(l10n.categoryDeleteConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              ref.read(CategoryDomainProviders.service).delete(category.id);
              Navigator.pop(context);
            },
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    return _availableIcons[iconName] ?? Icons.category;
  }

  static const Map<String, IconData> _availableIcons = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'home': Icons.home,
    'commute': Icons.commute,
    'category': Icons.category,
    'work': Icons.work,
    'school': Icons.school,
    'medical_services': Icons.medical_services,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'shopping_bag': Icons.shopping_bag,
    'payments': Icons.payments,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    'pets': Icons.pets,
    'cleaning_services': Icons.cleaning_services,
    'build': Icons.build,
    'subscriptions': Icons.subscriptions,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'celebration': Icons.celebration,
  };
}

class _CategoryFormDialog extends StatelessWidget {
  final CategoryModel? category;

  const _CategoryFormDialog({this.category});

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
                  children: CategoryManagementScreen._availableIcons.entries
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
