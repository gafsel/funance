import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/core/observability/app_logger.dart';

class LoadingPopupMenuItem<T> extends PopupMenuEntry<T> {
  final Widget child;
  final LoadingCallback? onTap;
  @override
  final double height;

  const LoadingPopupMenuItem({
    super.key,
    required this.child,
    this.onTap,
    this.height = kMinInteractiveDimension,
  });

  @override
  bool represents(T? value) => false;

  @override
  State<LoadingPopupMenuItem<T>> createState() =>
      _LoadingPopupMenuItemState<T>();
}

class _LoadingPopupMenuItemState<T> extends State<LoadingPopupMenuItem<T>> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !_loading && widget.onTap != null ? _act : null,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: AnimatedCrossFade(
          firstChild: widget.child,
          secondChild: _buildLoader(context),
          crossFadeState: _loading
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  Widget _buildLoader(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  void _act() {
    widget.onTap!(_interceptor);
  }

  Future<R?> _interceptor<R>(Future<R?> future) async {
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(
      context,
    );
    try {
      setState(() {
        _loading = true;
      });

      final result = await future;

      if (mounted) {
        Navigator.of(context).pop(result);
      }

      return result;
    } on BusinessException catch (ex) {
      // A mensagem é localizada via context, que pode ter sido desmontado
      // durante o await.
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(ex.code.message(context))),
        );
      }
      rethrow;
    } catch (ex, stack) {
      AppLogger.error('LoadingPopupMenuItem: erro não tratado', ex, stack);
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
