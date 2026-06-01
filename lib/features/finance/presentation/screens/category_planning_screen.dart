import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/controllers/category_planning_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';

class CategoryPlanningScreen extends ConsumerWidget {
  final CategoryType type;

  const CategoryPlanningScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = FinanceViewProviders.categoryPlanningForm(
      CategoryPlanningArgs(type: type),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == CategoryType.income ? l10n.planningIncomeLimits : l10n.planningExpenseLimits,
        ),
      ),
      body: ManualForm<CategoryPlanningState, void, CategoryPlanningNotifier>(
        provider,
        formBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: _buildCategoryList(context, state, notifier),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LoadingButton.elevated(
                  onPressed: (loading) async {
                    await loading(snapshot.notifier.submit());
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(l10n.planningSave),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoryPlanningState state, CategoryPlanningNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildCategoryItem(context, item, notifier);
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryPlanningFormItem item, CategoryPlanningNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.category.color.asColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.category.icon.asIcon(),
              color: item.category.color.asColor(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.name,
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (item.planningId != null)
                  Text(
                    AppLocalizations.of(context)!.planningLimitDefined,
                    style: const TextStyle(color: AppColors.limeGreen, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 80, maxWidth: 200),
            child: MoneyFormField(
              initialValue: item.amount > 0 ? item.amount : null,
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                notifier.updateAmount(item.category.id, value ?? 0.0);
              },
            ),
          ),
          if (item.amount > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
              onPressed: () {
                notifier.updateAmount(item.category.id, 0);
              },
            ),
        ],
      ),
    );
  }

}
