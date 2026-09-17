import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';

class IconFormField extends StatelessWidget {
  const IconFormField({
    super.key,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.decoration,
  });

  final String? initialValue;
  final FormFieldValidator<String?>? validator;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onSaved;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return FormField<String?>(
      initialValue: initialValue,
      validator: validator,
      enabled: onChanged != null,
      onSaved: onSaved,
      builder: (field) {
        return InputDecorator(
          decoration: (decoration ?? InputDecoration()).copyWith(
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IconsExtension.availableIcons.entries.map((entry) {
              final isSelected = field.value == entry.key;
              return GestureDetector(
                onTap: () {
                  field.didChange(entry.key);
                  onChanged?.call(entry.key);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : context.palette.paper2,
                    borderRadius: AppRadius.brSm,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : context.palette.line,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    entry.value,
                    size: 20,
                    color: isSelected
                        ? AppColors.goldInk
                        : context.palette.ink2,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
