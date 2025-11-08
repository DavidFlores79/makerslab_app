import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_color.dart';

class PXCustomTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? errorText;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final Function(String value)? onChanged;
  final Duration debounceDuration;
  final InputBorder? border;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final TextEditingController?
  controller; // opcional si quieres control externo
  final int? maxLines;
  final bool readOnly;
  final TextAlign? textAlign;
  final FocusNode? focusNode;

  const PXCustomTextField({
    super.key,
    this.labelText,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.style,
    this.contentPadding,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.border,
    this.obscureText = false,
    this.hintText,
    this.validator,
    this.maxLength,
    this.controller,
    this.maxLines,
    this.readOnly = false,
    this.textAlign,
    this.focusNode,
  });

  @override
  State<PXCustomTextField> createState() => _PXCustomTextFieldState();
}

class _PXCustomTextFieldState extends State<PXCustomTextField> {
  Timer? _debounce;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(widget.debounceDuration, () {
      if (widget.onChanged != null) widget.onChanged!(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      validator: widget.validator,
      inputFormatters:
          widget.keyboardType == TextInputType.datetime
              ? [DateInputFormatter()]
              : widget.keyboardType == TextInputType.number ||
                  widget.keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
      decoration: InputDecoration(
        counterText: "",
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        prefixStyle: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.gray800,
        ),
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.gray600,
        ),
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.gray700,
        ),
        border: widget.border ?? const OutlineInputBorder(),
        contentPadding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        errorText: widget.errorText,
        errorStyle: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
        suffixIcon:
            widget.obscureText
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.gray600,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
                : null,
      ),
      style: widget.style ?? theme.textTheme.bodyLarge,
      onChanged: _onChanged,
      maxLines: widget.maxLines ?? 1,
      textAlign: widget.textAlign ?? TextAlign.start,
      maxLength:
          widget.maxLength ??
          (widget.keyboardType == TextInputType.phone ? 10 : null),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Eliminar cualquier caracter que no sea dígito
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Insertar "/" en la posición 2 y 4 (dd/MM/yyyy)
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
