
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../providers.dart';
import 'package:funances/core/widgets/error_view.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: l10n.expenses),
            Tab(text: l10n.incomes),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          _CategoryList(
            type: CategoryType.expense,
            onUpdate: (category) => _showCategoryDialog(context, category),
            onDelete: (category) => _confirmDelete(context, ref, category),
          ),
          _CategoryList(
            type: CategoryType.income,
            onUpdate: (category) => _showCategoryDialog(context, category),
            onDelete: (category) => _confirmDelete(context, ref, category),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, [CategoryModel? category]) {
    context.push(
      category == null
          ? '/workspace/categories/form'
          : '/workspace/categories/form?id=${category.id}',
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
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    required this.type,
    required this.onUpdate,
    required this.onDelete,
  });

  final CategoryType type;
  final ValueChanged<CategoryModel> onUpdate;
  final ValueChanged<CategoryModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(CategoryViewProviders.allStream);

    return categoriesAsync.when(
      data: (rawCategories) {
        // A gestão só lista o que o usuário pode manter: categorias de
        // sistema e excluídas logicamente ficam fora.
        final categories =
            [...rawCategories]
                .where((c) => c.type == type && c.isSelectable)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

        return categories.isEmpty
            ? Center(child: Text(l10n.categoryManagementEmpty))
            : ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  // Defesa dupla: a lista já exclui categorias de sistema, mas
                  // se alguma escapar ela não pode oferecer editar/excluir —
                  // as rules do Firestore negam a escrita e o toque daria
                  // permission-denied.
                  final isManaged = category.isVirtual || category.isSystem;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(category.color.replaceAll('#', '0xFF')),
                      ),
                      child: Icon(
                        category.icon.asIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(category.type.name.toUpperCase()),
                    trailing: isManaged ? null : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onUpdate(category),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => onDelete(category),
                        ),
                      ],
                    ),
                  );
                },
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorView.forError(
            context,
            err,
            onRetry: () => ref.invalidate(CategoryViewProviders.allStream),
          ),
        ),
      ),
    );
  }
}
