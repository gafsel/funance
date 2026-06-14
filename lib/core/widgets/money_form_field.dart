import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:intl/intl.dart';

class MoneyFormField extends StatelessWidget {
  const MoneyFormField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.decoration,
    this.enabled = true,
    this.style,
  });

  final double? initialValue;
  final ValueChanged<double?>? onChanged;
  final FormFieldValidator<double?>? validator;
  final InputDecoration? decoration;
  final bool enabled;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final symbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return TextFormField(
      initialValue: initialValue != null ? format.format(initialValue) : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      style: style,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        prefixText: symbol,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MoneyInputFormatter(format),
      ],
      validator: validator != null
          ? (value) => validator!(_parseValue(value))
          : null,
      onChanged: (value) => onChanged?.call(_parseValue(value)),
    );
  }

  double? _parseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits)! / 100;
  }
}

class _MoneyInputFormatter extends TextInputFormatter {
  _MoneyInputFormatter(this.format);

  final NumberFormat format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final double value = double.parse(newValue.text) / 100;
    final String formatted = format.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
