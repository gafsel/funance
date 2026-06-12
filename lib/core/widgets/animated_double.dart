import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';

class AnimatedDouble extends ImplicitlyAnimatedWidget {
  final double value;
  final String Function(BuildContext, double)? formatter;

  // Text properties
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const AnimatedDouble({
    super.key,
    required this.value,
    this.formatter,
    required super.duration,
    super.curve = Curves.linear,
    super.onEnd,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  factory AnimatedDouble.currency(
    double value, {
    Key? key,
    required Duration duration,
    Curve curve = Curves.linear,
    VoidCallback? onEnd,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    return AnimatedDouble(
      key: key,
      value: value,
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      formatter: (context, v) =>
          v.asCurrency(locale: locale?.toLanguageTag() ?? context.locale),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  factory AnimatedDouble.percent(
    double value, {
    Key? key,
    required Duration duration,
    Curve curve = Curves.linear,
    VoidCallback? onEnd,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    return AnimatedDouble(
      key: key,
      value: value,
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      formatter: (context, v) =>
          v.asPercent(locale: locale?.toLanguageTag() ?? context.locale),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  @override
  ImplicitlyAnimatedWidgetState<AnimatedDouble> createState() =>
      _AnimatedDoubleState();
}

class _AnimatedDoubleState
    extends ImplicitlyAnimatedWidgetState<AnimatedDouble> {
  Tween<double>? _value;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _value =
        visitor(
              _value,
              widget.value,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentValue = _value?.evaluate(animation) ?? widget.value;
        final textToShow =
            widget.formatter?.call(context, currentValue) ??
            currentValue.toString();

        return Text(
          textToShow,
          style: widget.style,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          locale: widget.locale,
          softWrap: widget.softWrap,
          overflow: widget.overflow,
          textScaleFactor: widget.textScaleFactor,
          maxLines: widget.maxLines,
          semanticsLabel: widget.semanticsLabel,
          textWidthBasis: widget.textWidthBasis,
          textHeightBehavior: widget.textHeightBehavior,
          selectionColor: widget.selectionColor,
        );
      },
    );
  }
}
