import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/widgets/category_picker_sheet.dart';

class CategoryFormField extends ConsumerWidget {
  const CategoryFormField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.categoryType,
    this.validator,
    this.decoration,
    this.autoOpen = false,
    this.showNewOption = true,
    this.emptyMeansAll = false,
    this.style,
  }) : transfer = false,
       invoice = false;

  final CategoryModel? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<CategoryModel?>? onChanged;
  final CategoryType? categoryType;
  final FormFieldValidator<CategoryModel?>? validator;
  final TextStyle? style;
  final bool autoOpen;
  final bool transfer;
  final bool invoice;
  final bool showNewOption;
  final bool emptyMeansAll;

  const CategoryFormField.transfer({
    super.key,
    this.decoration,
    this.validator,
    this.style,
  }) : initialValue = null,
       onChanged = _dummyOnChanged,
       categoryType = null,
       transfer = true,
       autoOpen = false,
       emptyMeansAll = false,
       invoice = false,
       showNewOption = false;

  const CategoryFormField.invoice({
    super.key,
    this.decoration,
    this.validator,
    this.style,
  }) : initialValue = null,
       onChanged = _dummyOnChanged,
       categoryType = null,
       transfer = true,
       autoOpen = false,
       emptyMeansAll = false,
       invoice = true,
       showNewOption = false;

  static void _dummyOnChanged(CategoryModel? _) {}

  bool get enabled => onChanged != null && !transfer && !invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return FormField<CategoryModel?>(
      initialValue: initialValue,
      validator: validator,
      builder: (state) {
        if (autoOpen &&
            state.value == null &&
            categoryType != null &&
            !transfer &&
            !invoice) {
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
                        backgroundColor: AppColors.danger,
                        child: Icon(
                          Icons.credit_card,
                          size: 16,
                          color: AppColors.inkInverse,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.l10n.transactionTypeInvoice,
                        style:
                            style ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: palette.ink3,
                            ),
                      ),
                    ],
                  )
                : transfer
                ? Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.teal,
                        child: Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: AppColors.inkInverse,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.l10n.transactionTypeTransfer,
                        style:
                            style ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: palette.ink3,
                            ),
                      ),
                    ],
                  )
                : category != null
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        // A cor da categoria é DADO: é a que o usuário
                        // escolheu na paleta de seleção.
                        backgroundColor: category.color.asColor().withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          category.icon.asIcon(),
                          size: 16,
                          color: category.color.asColor(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        category.name,
                        style:
                            style ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: enabled ? null : palette.ink3,
                            ),
                      ),
                    ],
                  )
                : emptyMeansAll
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: palette.line,
                        child: Icon(
                          Icons.category,
                          size: 16,
                          color: palette.ink3,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.l10n.all,
                        style:
                            style ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: enabled ? null : palette.ink3,
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
    return CategoryPickerSheet.show(
      context,
      categoryType: categoryType,
      // `emptyMeansAll` marca o uso como filtro de extrato/relatório: ali as
      // categorias virtuais e de sistema precisam aparecer para o usuário
      // conseguir filtrar lançamentos que já existem nelas.
      excludeVirtual: !emptyMeansAll,
      excludeSystem: !emptyMeansAll,
      showAddOption: showNewOption,
    );
  }
}
