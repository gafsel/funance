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

  DateFormField({
    Key? key,
    this.onSaved,
    this.onChanged,
    this.validator,
    this.decoration = const InputDecoration(),
    this.initialValue,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
  }) : super(key: key);

  @override
  _DateFormFieldState createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  late TextEditingController _controller;
  DateFormat? _dateFormat;

  DateFormat get dateFormat => _dateFormat ?? DateFormat.yMd(context.locale);

  RegExp get dateRegExp =>
      RegExp("^${dateFormat.pattern!.replaceAll(RegExp("[dMy]"), "\\d")}\$");

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newDateFormat = DateFormat.yMd(context.locale);
    if (_dateFormat != newDateFormat) {
      _dateFormat = newDateFormat;
      if (widget.initialValue != null) {
        _controller.text = _dateFormat!.format(widget.initialValue!);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
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
        InputDecoration effectiveDecoration = (widget.decoration)
            .applyDefaults(Theme.of(field.context).inputDecorationTheme)
            .copyWith(
              errorText: field.errorText,
              suffixIcon: InkWell(
                onTap: !widget.enabled
                    ? null
                    : () {
                        DateTime initialDate =
                            field.value ?? new DateTime.now();

                        showDatePicker(
                          context: field.context,
                          initialDate: initialDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(initialDate.year + 1),
                          locale: Locale('pt', 'BR '),
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
                    var dateTime = dateFormat.parse(value);

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
    String formatado = _formatedAsDate(novo.text);

    int offset = formatado.length;

    if (novo.selection.start != novo.text.length) {
      offset = min(formatado.length, novo.selection.start);
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.fromPosition(TextPosition(offset: offset)),
    );
  }

  String _formatedAsDate(String value) {
    String formatado = "";
    String cc = value.unformated;

    if (cc.length > 8) {
      formatado =
          "${cc.substring(0, 2)}/${cc.substring(2, 4)}/${cc.substring(4, 8)}";
    } else if (cc.length > 4) {
      formatado =
          "${cc.substring(0, 2)}/${cc.substring(2, 4)}/${cc.substring(4)}";
    } else if (cc.length > 2) {
      formatado = "${cc.substring(0, 2)}/${cc.substring(2)}";
    } else if (cc.length > 0) {
      formatado = "$cc";
    }

    return formatado;
  }
}
