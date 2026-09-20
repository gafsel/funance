import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_screen.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/presentation/display_names.dart';

class CategoryPickerSheet extends ConsumerWidget {
  final CategoryType? categoryType;
  final bool showClearOption;
  final bool showAddOption;
  final bool excludeVirtual;
  final bool excludeSystem;
  final String? title;

  const CategoryPickerSheet({
    super.key,
    this.categoryType,
    this.showClearOption = true,
    this.showAddOption = true,
    this.excludeVirtual = true,
    this.excludeSystem = true,
    this.title,
  });

  static Future<CategoryModel?> show(
    BuildContext context, {
    CategoryType? categoryType,
    bool showClearOption = true,
    bool showAddOption = true,
    bool excludeVirtual = true,
    bool excludeSystem = true,
    String? title,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CategoryPickerSheet(
        categoryType: categoryType,
        showClearOption: showClearOption,
        showAddOption: showAddOption,
        excludeVirtual: excludeVirtual,
        excludeSystem: excludeSystem,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(CategoryViewProviders.allStream);
    // Sem rede, a lista vazia dizia "você não tem categorias" — o que é uma
    // afirmação, e errada. Quando a leitura falha, o seletor diz o que houve e
    // oferece tentar de novo.
    if (categoriesAsync.hasError) {
      return SafeArea(
        child: Padding(
          padding: AppSpacing.allLg,
          child: ErrorView.forError(
            context,
            categoriesAsync.error,
            onRetry: () => Retry.categories(ref),
          ),
        ),
      );
    }

    final categories = categoriesAsync.when(
          data: (data) => data
              .where(
                (c) =>
                    (categoryType == null || c.type == categoryType) &&
                    (!c.isVirtual || !excludeVirtual) &&
                    // Excluídas logicamente nunca são selecionáveis; as de
                    // sistema só aparecem onde a lista serve a relatório.
                    !c.isDeleted &&
                    (!c.isSystem || !excludeSystem),
              )
              .toList(),
          error: (error, stack) => <CategoryModel>[],
          loading: () => <CategoryModel>[],
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: AppSpacing.allMd,
            child: Text(
              title ?? l10n.transactionCategoriesSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              itemCount: categories.length +
                  (showAddOption ? 2 : 0) +
                  (showClearOption ? 2 : 0),
              itemBuilder: (context, index) {
                if (index < categories.length) {
                  final CategoryModel category = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          category.color.asColor().withValues(alpha: 0.2),
                      child: Icon(
                        category.icon.asIcon(),
                        color: category.color.asColor(),
                      ),
                    ),
                    title: Text(category.displayName(l10n)),
                    onTap: () => Navigator.pop(context, category),
                  );
                }

                int currentIndex = categories.length;

                if (showAddOption) {
                  if (index == currentIndex) return const Divider();
                  if (index == currentIndex + 1) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.transparent,
                        child: Icon(Icons.add, color: context.palette.ink3),
                      ),
                      title: Text(l10n.categoryCreateTitle),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => CategoryFormScreen(
                            initialType: categoryType,
                          ),
                        );
                      },
                    );
                  }
                  currentIndex += 2;
                }

                if (showClearOption) {
                  if (index == currentIndex) return const Divider();
                  if (index == currentIndex + 1) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.transparent,
                        child: Icon(Icons.clear, color: context.palette.ink3),
                      ),
                      title: Text(l10n.clear),
                      onTap: () => Navigator.pop(context, null),
                    );
                  }
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
