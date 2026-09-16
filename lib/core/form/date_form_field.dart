import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/string_util.dart';
import 'package:intl/intl.dart';

class DateFormField extends StatefulWidget {
  final ValueChanged<DateTime?>? onSaved;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime?>? validator;
  final InputDecoration decoration;
  final DateTime? initialValue;
  final AutovalidateMode autovalidateMode;
  final bool enabled;

  const DateFormField({
    super.key,
    this.onSaved,
    this.onChanged,
    this.validator,
    this.decoration = const InputDecoration(),
    this.initialValue,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
  });

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  late TextEditingController _controller;
  DateFormat? _dateFormat;

  DateFormat get dateFormat =>
      _dateFormat ?? DateFormat(context.l10n.dateInputPattern, context.locale);

  RegExp get dateRegExp =>
      RegExp("^${dateFormat.pattern!.replaceAll(RegExp("[dMy]"), "\\d")}\$");

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newDateFormat = DateFormat(context.l10n.dateInputPattern, context.locale);
    if (_dateFormat != newDateFormat) {
      _dateFormat = newDateFormat;
      if (widget.initialValue != null) {
        _controller.text = _dateFormat!.format(widget.initialValue!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      onSaved: widget.onSaved,
      validator: widget.validator,
      initialValue: widget.initialValue,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final InputDecoration effectiveDecoration = (widget.decoration)
            .applyDefaults(Theme.of(field.context).inputDecorationTheme)
            .copyWith(
              errorText: field.errorText,
              suffixIcon: InkWell(
                onTap: !widget.enabled
                    ? null
                    : () {
                        final DateTime initialDate = field.value ?? DateTime.now();

                        showDatePicker(
                          context: field.context,
                          initialDate: initialDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(initialDate.year + 1),
                          locale: Locale(context.locale),
                        ).then((dateTime) {
                          if (dateTime != null) {
                            field.didChange(dateTime);

                            _controller.text = dateFormat.format(dateTime);

                            if (widget.onChanged != null) {
                              widget.onChanged!(dateTime);
                            }
                          }
                        });
                      },
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(
                    field.context,
                  ).inputDecorationTheme.labelStyle?.color,
                ),
              ),
            );

        return TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: effectiveDecoration,
          enabled: widget.enabled,
          inputFormatters: [TextInputFormatter.withFunction(_formatData)],
          onChanged: widget.enabled
              ? (value) {
                  if (dateRegExp.hasMatch(value)) {
                    final dateTime = dateFormat.parse(value);

                    field.didChange(dateTime);

                    if (widget.onChanged != null) {
                      widget.onChanged!(dateTime);
                    }
                  } else {
                    field.didChange(null);

                    if (widget.onChanged != null) {
                      widget.onChanged!(null);
                    }
                  }
                }
              : null,
        );
      },
    );
  }

  TextEditingValue _formatData(TextEditingValue antigo, TextEditingValue novo) {
    final String mark = dateFormat.pattern!.replaceAll(RegExp("[dMy]"), "#");

    final String formatado = novo.text.getFormated(mark);

    int offset = formatado.length;

    if (novo.selection.start != novo.text.length) {
      offset = min(formatado.length, novo.selection.start);
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.fromPosition(TextPosition(offset: offset)),
    );
  }
}
