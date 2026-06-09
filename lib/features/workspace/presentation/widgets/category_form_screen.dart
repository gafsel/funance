import 'package:flutter/material.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/color_form_field.dart';
import 'package:funances/core/form/icon_form_field.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/controller/category_form_notifier.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class CategoryFormScreen extends StatelessWidget {
  final CategoryModel? category;
  final CategoryType? initialType;

  const CategoryFormScreen({super.key, this.category, this.initialType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = context.validations;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == null ? l10n.categoryCreateTitle : l10n.categoryEditTitle,
        ),
      ),
      body: ResponsiveForm<CategoryFormState, void, CategoryFormNotifier>(
        CategoryViewProviders.form(category),
        submitLabel: l10n.saveButton,
        onSuccess: (_) => Navigator.pop(context),
        onCancel: () => Navigator.pop(context),
        fieldsBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;

          return [
            ChipFormField<CategoryType>(
              initialValue: state.type,
              decoration: InputDecoration(labelText: l10n.categoryTypeLabel),
              options: [
                ChipFormFieldOption(
                  value: CategoryType.income,
                  label: l10n.categoryTypeIncome,
                ),
                ChipFormFieldOption(
                  value: CategoryType.expense,
                  label: l10n.categoryTypeExpense,
                ),
              ],
              onChanged: (val) => notifier.updateType(val!),
            ),
            TextFormField(
              initialValue: state.name,
              decoration: InputDecoration(labelText: l10n.categoryNameLabel),
              onChanged: notifier.updateName,
            ),
            ColorFormField(
              initialValue: state.color,
              decoration: InputDecoration(labelText: l10n.categoryColorLabel),
              onChanged: (color) {
                if (color != null) {
                  notifier.updateColor(color);
                }
              },
              validator: v.all([v.notEmpty()]),
            ),
            IconFormField(
              initialValue: state.icon,
              decoration: InputDecoration(labelText: l10n.categoryIconLabel),
              validator: v.all([v.notEmpty()]),
              onChanged: (icon) {
                if (icon != null) {
                  notifier.updateIcon(icon);
                }
              },
            ),
          ];
        },
      ),
    );
  }
}
