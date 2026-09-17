import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_elevation.dart';
import 'package:funances/core/theme/app_palette.dart';

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
                    // O aro de seleção é dourado e não branco: branco some
                    // sobre as cores claras da paleta, e o ouro é o token de
                    // "isto está escolhido" em todo o resto do app.
                    border: isSelected
                        ? const Border.fromBorderSide(AppElevation.goldRim)
                        : null,
                    boxShadow: isSelected
                        ? AppElevation.raised(context.palette.brightness)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          // A marca precisa aparecer sobre a cor escolhida
                          // pelo usuário, que pode ser clara ou escura.
                          color: color.computeLuminance() < 0.5
                              ? AppColors.inkInverse
                              : AppColors.inkLight,
                        )
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
