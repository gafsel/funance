import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_dialog.dart';

class CategoryFormField extends ConsumerWidget {
  const CategoryFormField({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.orderType,
    this.validator,
    this.decoration,
    this.enabled = true,
    this.autoOpen = false,
  });

  final CategoryModel? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<CategoryModel?> onChanged;
  final OrderType orderType;
  final FormFieldValidator<CategoryModel?>? validator;
  final bool enabled;
  final bool autoOpen;

  const CategoryFormField.transfer({
    super.key,
    this.decoration,
    this.validator,
  })  : initialValue = null,
        onChanged = _dummyOnChanged,
        orderType = OrderType.transfer,
        enabled = false,
        autoOpen = false;

  static void _dummyOnChanged(CategoryModel? _) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (autoOpen && initialValue == null && orderType != OrderType.transfer) {
      final isModalOpen = ModalRoute.of(context)?.isCurrent == false;
      if (!isModalOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final selectedCategory = await _showCategoryPicker(
            context,
            ref,
            orderType,
          );

          if (selectedCategory != null) {
            onChanged(selectedCategory);
          }
        });
      }
    }
    return FormField<CategoryModel?>(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      validator: validator,
      builder: (state) {
        final category = state.value;

        return InkWell(
          onTap: enabled
              ? () async {
                  final selectedCategory = await _showCategoryPicker(
                    context,
                    ref,
                    orderType,
                  );

                  if (selectedCategory != null || state.value != null) {
                    state.didChange(selectedCategory);
                    onChanged(selectedCategory);
                  }
                }
              : null,
          child: InputDecorator(
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: state.errorText,
              suffixIcon: enabled ? const Icon(Icons.chevron_right) : null,
            ),
            child: orderType == OrderType.transfer
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
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : category != null
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(
                              int.parse(
                                  category.color.replaceFirst('#', '0xFF')),
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              _getIconData(category.icon),
                              size: 16,
                              color: Color(
                                int.parse(
                                    category.color.replaceFirst('#', '0xFF')),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodyMedium,
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
    WidgetRef ref,
    OrderType orderType,
  ) async {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final categories = ref.watch(CategoryViewProviders.allStream).when(
              data: (data) => data
                  .where((c) => c.type == orderType.categoryType)
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
                  itemCount: categories.length + 4, // +1 for Add, +1 for Clear, +2 for Dividers
                  itemBuilder: (context, index) {
                    if (index < categories.length) {
                      final category = categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            int.parse(category.color.replaceFirst('#', '0xFF')),
                          ).withValues(alpha: 0.2),
                          child: Icon(
                            _getIconData(category.icon),
                            color: Color(
                              int.parse(
                                category.color.replaceFirst('#', '0xFF'),
                              ),
                            ),
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
                            builder: (context) => CategoryFormDialog(
                              initialType: orderType.categoryType,
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
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'school':
        return Icons.school;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'flight':
        return Icons.flight;
      case 'category':
        return Icons.category;
      case 'work':
        return Icons.work;
      case 'payments':
        return Icons.payments;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}
