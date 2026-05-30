import 'package:flutter/material.dart';

class ChipFormField<T> extends FormField<T> {
  final List<ChipFormFieldOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;

  ChipFormField({
    super.key,
    required this.options,
    super.initialValue,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    this.onChanged,
    this.decoration = const InputDecoration(),
    bool enabled = true,
  }) : super(
          enabled: enabled,
          builder: (FormFieldState<T> field) {
            final InputDecoration effectiveDecoration = decoration
                .applyDefaults(Theme.of(field.context).inputDecorationTheme)
                .copyWith(errorText: field.errorText);

            return InputDecorator(
              decoration: effectiveDecoration,
              isEmpty: field.value == null,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: options.map((option) {
                  return ChoiceChip(
                    label: Text(option.label),
                    selected: field.value == option.value,
                    showCheckmark: false,
                    onSelected: enabled
                        ? (bool selected) {
                            final newValue = selected ? option.value : null;
                            field.didChange(newValue);
                            if (onChanged != null) {
                              onChanged(newValue);
                            }
                          }
                        : null,
                  );
                }).toList(),
              ),
            );
          },
        );
}

class ChipFormFieldOption<T> {
  final T value;
  final String label;

  const ChipFormFieldOption({
    required this.value,
    required this.label,
  });
}
