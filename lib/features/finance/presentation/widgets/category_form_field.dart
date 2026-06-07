import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_screen.dart';

class CategoryFormField extends ConsumerWidget {
  const CategoryFormField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.categoryType,
    this.validator,
    this.decoration,
    this.autoOpen = false,
    this.emptyMeansAll = false,
  }) : transfer = false,
       invoice = false;

  final CategoryModel? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<CategoryModel?>? onChanged;
  final CategoryType? categoryType;
  final FormFieldValidator<CategoryModel?>? validator;
  final bool autoOpen;
  final bool transfer;
  final bool invoice;
  final bool emptyMeansAll;

  const CategoryFormField.transfer({super.key, this.decoration, this.validator})
    : initialValue = null,
      onChanged = _dummyOnChanged,
      categoryType = null,
      transfer = true,
      autoOpen = false,
      emptyMeansAll = false,
      invoice = false;

  const CategoryFormField.invoice({super.key, this.decoration, this.validator})
    : initialValue = null,
      onChanged = _dummyOnChanged,
      categoryType = null,
      transfer = true,
      autoOpen = false,
      emptyMeansAll = false,
      invoice = true;

  static void _dummyOnChanged(CategoryModel? _) {}

  bool get enabled => onChanged != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormField<CategoryModel?>(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      validator: validator,
      builder: (state) {
        if (autoOpen &&
            state.value == null &&
            categoryType != null &&
            !transfer) {
          final isModalOpen = ModalRoute.of(context)?.isCurrent == false;
          if (!isModalOpen) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final selectedCategory = await _showCategoryPicker(
                context,
                categoryType!,
              );

              if (selectedCategory != null) {
                state.didChange(selectedCategory);
                onChanged?.call(selectedCategory);
              }
            });
          }
        }
        final category = state.value;

        return InkWell(
          onTap: enabled
              ? () async {
                  final selectedCategory = await _showCategoryPicker(
                    context,
                    categoryType,
                  );

                  if (selectedCategory != null || state.value != null) {
                    state.didChange(selectedCategory);
                    onChanged?.call(selectedCategory);
                  }
                }
              : null,
          child: InputDecorator(
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: state.errorText,
              suffixIcon: enabled ? const Icon(Icons.chevron_right) : null,
            ),
            child: invoice
                ? Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.error,
                        child: Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.transactionTypeInvoice,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black38),
                      ),
                    ],
                  )
                : transfer
                ? Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.brightCyan,
                        child: Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.transactionTypeTransfer,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black38),
                      ),
                    ],
                  )
                : category != null
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: category.color.asColor().withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          category.icon.asIcon(),
                          size: 16,
                          color: category.color.asColor(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: enabled ? null : Colors.black38,
                        ),
                      ),
                    ],
                  )
                : emptyMeansAll
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.all,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: enabled ? null : Colors.black38,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<CategoryModel?> _showCategoryPicker(
    BuildContext context,
    CategoryType? categoryType,
  ) async {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final categories = ref
                .watch(CategoryViewProviders.allStream)
                .when(
                  data: (data) => data
                      .where(
                        (c) => categoryType == null || c.type == categoryType,
                      )
                      .toList(),
                  error: (error, stack) => [],
                  loading: () => [],
                );

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.l10n.transactionCategoriesSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      itemCount: categories.length + 4,
                      // +1 for Add, +1 for Clear, +2 for Dividers
                      itemBuilder: (context, index) {
                        if (index < categories.length) {
                          CategoryModel category = categories[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: category.color
                                  .asColor()
                                  .withValues(alpha: 0.2),
                              child: Icon(
                                category.icon.asIcon(),
                                color: category.color.asColor(),
                              ),
                            ),
                            title: Text(category.name),
                            onTap: () => Navigator.pop(context, category),
                          );
                        }

                        if (index == categories.length) {
                          return const Divider();
                        }

                        if (index == categories.length + 1) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.add, color: Colors.grey),
                            ),
                            title: Text(context.l10n.categoryCreateTitle),
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

                        if (index == categories.length + 2) {
                          return const Divider();
                        }

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Icon(Icons.clear, color: Colors.grey),
                          ),
                          title: Text(context.l10n.clear),
                          onTap: () => Navigator.pop(context, null),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
