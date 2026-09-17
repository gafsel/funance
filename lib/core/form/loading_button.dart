import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/utils/error_messages.dart';

typedef LoadingWrapper = Future<T?> Function<T>(Future<T?> future);
typedef LoadingCallback = Function(LoadingWrapper wrapper);

typedef LoadingButtonBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      VoidCallback? onPressed,
    );

class LoadingButton extends StatefulWidget {
  final LoadingButtonBuilder builder;
  final Widget? child;
  final LoadingCallback? onPressed;
  final ButtonStyle? style;

  const LoadingButton._(this.builder, {this.child, this.onPressed, this.style});

  factory LoadingButton.elevated({
    Widget? child,
    LoadingCallback? onPressed,
    ButtonStyle? style,
  }) {
    return LoadingButton._(
      (context, child, onPressed) {
        return ElevatedButton(onPressed: onPressed, style: style, child: child);
      },
      style: style,
      onPressed: onPressed,
      child: child,
    );
  }

  factory LoadingButton.filled({
    Widget? child,
    LoadingCallback? onPressed,
    ButtonStyle? style,
  }) {
    return LoadingButton._(
      (context, child, onPressed) {
        return FilledButton(onPressed: onPressed, style: style, child: child);
      },
      style: style,
      onPressed: onPressed,
      child: child,
    );
  }

  factory LoadingButton.outlineIcon({
    required Widget icon,
    required Widget label,
    LoadingCallback? onPressed,
    ButtonStyle? style,
  }) {
    return LoadingButton._(
      (context, child, onPressed) {
        return OutlinedButton.icon(
          icon: icon,
          onPressed: onPressed,
          style: style,
          label: child,
        );
      },
      style: style,
      onPressed: onPressed,
      child: label,
    );
  }

  factory LoadingButton.icon(
    Widget icon, {
    LoadingCallback? onPressed,
    ButtonStyle? style,
  }) {
    return LoadingButton._(
      (context, child, onPressed) {
        return IconButton(onPressed: onPressed, style: style, icon: child);
      },
      style: style,
      onPressed: onPressed,
      child: icon,
    );
  }

  factory LoadingButton.text({
    required Widget child,
    LoadingCallback? onPressed,
    ButtonStyle? style,
  }) {
    return LoadingButton._(
      (context, child, onPressed) {
        return TextButton(onPressed: onPressed, style: style, child: child);
      },
      style: style,
      onPressed: onPressed,
      child: child,
    );
  }

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _buildChild(),
      !_loading && widget.onPressed != null ? _act : null,
    );
  }

  Widget _buildChild() {
    return AnimatedCrossFade(
      firstChild: widget.child ?? Container(),
      secondChild: _buildLoader(context),
      crossFadeState: _loading
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildLoader(BuildContext context) {
    final theme = Theme.of(context);

    // 1) Pega o estilo base do ElevatedButton no tema
    final ButtonStyle? themeStyle = theme.elevatedButtonTheme.style;

    // 2) Estilo final = tema.merge(style do widget)
    final ButtonStyle effectiveStyle = (themeStyle ?? const ButtonStyle())
        .merge(widget.style);

    // 3) Resolve estados (botão "normal")
    const Set<WidgetState> states = {};

    final TextStyle? textStyle =
        effectiveStyle.textStyle?.resolve(states) ?? theme.textTheme.labelLarge;

    final Color foregroundColor =
        effectiveStyle.foregroundColor?.resolve(states) ??
        theme.colorScheme.onPrimary;

    final double fontSize = textStyle?.fontSize ?? 14.0;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: SizedBox(
        height: fontSize - 2,
        width: fontSize - 2,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      ),
    );
  }

  void _act() {
    widget.onPressed!(_interceptor);
  }

  Future<T?> _interceptor<T>(Future<T?> future) async {
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    // O redirecionamento é o único caso em que o giro CONTINUA: a aba está
    // saindo para o Google, e devolver o botão ao normal daria a impressão de
    // que o clique não pegou.
    bool keepLoading = false;

    try {
      FocusScope.of(context).requestFocus(FocusNode());

      setState(() {
        _loading = true;
      });

      return await future;
    } on BusinessException catch (ex) {
      if (ex.code.isInformational) {
        keepLoading = ex.code == ErrorCode.signInRedirecting;

        // Nada aconteceu de errado: sem snackbar e sem relançar. "Nenhum
        // resultado" é exatamente o que o usuário pediu ao desistir, e
        // relançar transformaria isso num erro não tratado — que na web ainda
        // viraria um evento de crash.
        return null;
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(ex.code.message(context))),
      );
      rethrow;
    } catch (ex, stack) {
      developer.log(
        'Erro não tratado no LoadingButton',
        name: 'funances.LoadingButton',
        error: ex,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      if (mounted && !keepLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
