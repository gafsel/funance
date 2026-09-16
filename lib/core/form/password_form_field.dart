import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final InputDecoration? decoration;
  final FormFieldValidator<String?>? validator;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;
  final TextInputAction? textInputAction;

  const PasswordFormField({
    super.key,
    this.decoration,
    this.validator,
    this.initialValue,
    this.onChanged,
    this.textInputAction,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscure,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        suffixIcon: InkWell(
          onTap: _toggleObscure,
          child: Icon(
            _obscure ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      ),
      validator: widget.validator,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
    );
  }

  void _toggleObscure() {
    setState(() {
      _obscure = !_obscure;
    });
  }
}
