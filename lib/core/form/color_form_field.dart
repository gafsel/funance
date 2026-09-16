import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

class ColorFormField extends StatelessWidget {
  const ColorFormField({
    super.key,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.decoration,
  });

  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onSaved;
  final FormFieldValidator<String?>? validator;
  final String? initialValue;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return FormField<String?>(
      enabled: onChanged != null,
      initialValue: initialValue,
      validator: validator,
      onSaved: onSaved,
      builder: (field) {
        return InputDecorator(
          decoration: (decoration ?? InputDecoration()).copyWith(
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppColors.selectionColors.map((color) {
              final colorHex =
                  '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              final isSelected = field.value?.toUpperCase() == colorHex;
              return GestureDetector(
                onTap: () {
                  field.didChange(colorHex);
                  onChanged?.call(colorHex);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
