import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon._({
    this.category,
    this.invoice = false,
    this.transfer = false,
  });

  factory CategoryIcon.forCategory(CategoryModel category) {
    return CategoryIcon._(category: category);
  }

  factory CategoryIcon.forInstallment(InstallmentModel installment) {
    return CategoryIcon._(
      category: installment.category,
      invoice: installment.isInvoice,
      transfer: installment.type == OrderType.transfer,
    );
  }

  factory CategoryIcon.transfer() {
    return CategoryIcon._(transfer: true);
  }

  factory CategoryIcon.invoice() {
    return CategoryIcon._(invoice: true);
  }

  final CategoryModel? category;
  final bool invoice;
  final bool transfer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allXs,
      decoration: BoxDecoration(
        color: invoice
            ? AppColors.danger
            : transfer
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : (category?.color.asColor() ?? AppColors.surfaceDeep).withValues(
                alpha: 0.1,
              ),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(
        invoice
            ? Icons.credit_card
            : transfer
            ? Icons.swap_horiz
            : category?.icon.asIcon() ?? Icons.category,
        color: invoice
            ? AppColors.inkInverse
            : transfer
            ? Theme.of(context).colorScheme.primary
            : category?.color.asColor() ?? AppColors.surfaceDeep,
        size: 20,
      ),
    );
  }
}
