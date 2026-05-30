import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_dialog.dart';
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
      builder: (context) => CategoryFormDialog(category: category),
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

  static const Map<String, IconData> _availableIcons = CategoryFormDialog.availableIcons;
}

