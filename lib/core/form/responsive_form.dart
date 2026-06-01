import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';

typedef FieldsBuilder<I, O, N extends FormNotifier<I, O>> =
    List<Widget> Function(
      BuildContext context,
      FormBuilderSnapshot<I, O, N> snapshot,
    );

typedef OnPressed<I, O, N extends FormNotifier<I, O>> =
    Future<void> Function(
      FormBuilderSnapshot<I, O, N> snapshot,
      LoadingWrapper loading,
    );

class FullWidthItem extends StatelessWidget {
  const FullWidthItem(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}


typedef BannerBuilder<I, O, N extends FormNotifier<I, O>> =
    MaterialBanner? Function(
      BuildContext context,
      FormBuilderSnapshot<I, O, N> snapshot,
    );

class ResponsiveForm<I, O, N extends FormNotifier<I, O>>
    extends StatelessWidget {
  const ResponsiveForm(
    this.provider, {
    super.key,
    required this.fieldsBuilder,
    this.bannerBuilder,
    this.submitLabel,
    this.extraActions = const [],
    this.onSuccess,
    this.onSubmit,
  });

  final AutoDisposeStateNotifierProvider<N, I> provider;
  final FieldsBuilder<I, O, N> fieldsBuilder;
  final BannerBuilder<I, O, N>? bannerBuilder;
  final String? submitLabel;
  final List<Widget> extraActions;
  final ValueChanged<O?>? onSuccess;
  final OnPressed<I, O, N>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: ManualForm<I, O, N>(
          provider,
          formBuilder: (context, snapshot) {
            final banner = bannerBuilder?.call(context, snapshot);
            return Column(
              children: [
                if (banner != null) ...[
                  banner,
                  const SizedBox(height: 16),
                ],
                _ResponsiveGrid(
                  spacing: 16,
                  children: fieldsBuilder(context, snapshot),
                ),
                Divider(height: 32),
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...extraActions,
                    LoadingButton.elevated(
                      child: Text(submitLabel ?? l10n.saveButton),
                      onPressed: (loading) async {
                        if (onSubmit != null) {
                          await onSubmit!(snapshot, loading);
                          return;
                        }

                        if (snapshot.validate()) {
                          final output = await loading(
                            snapshot.notifier.submit(),
                          );

                          onSuccess?.call(output);
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 0.0,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isLargeScreen = maxWidth > 800;

        if (isLargeScreen) {
          final int columns = (maxWidth / 350).toInt().clamp(1, 4);
          final double itemWidth =
              (maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children
                .map((child) => SizedBox(width: child is FullWidthItem ? maxWidth : itemWidth, child: child))
                .toList(),
          );
        }

        return Column(
          spacing: spacing,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}
