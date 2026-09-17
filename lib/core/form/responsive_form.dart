import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/l10n/app_localizations.dart';

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
    this.pendingSyncMessage,
    this.onSubmit,
    this.submitEnabled,
    this.onCancel,
    this.submitButtonColor,
  });

  final AutoDisposeStateNotifierProvider<N, I> provider;
  final FieldsBuilder<I, O, N> fieldsBuilder;
  final BannerBuilder<I, O, N>? bannerBuilder;
  final String? submitLabel;
  final List<Widget> extraActions;
  final ValueChanged<O?>? onSuccess;

  /// Texto a mostrar quando o save ficou só no cache local.
  ///
  /// Sem isto vale o genérico. Um formulário cujo save tenha efeito de
  /// servidor — a conta, cujo saldo inicial e primeira fatura nascem lá —
  /// passa o seu, porque o genérico prometeria menos do que o usuário precisa
  /// saber.
  final String? pendingSyncMessage;
  final OnPressed<I, O, N>? onSubmit;
  final VoidCallback? onCancel;
  final bool Function(I state)? submitEnabled;
  final Color? submitButtonColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: SafeArea(
        child: ManualForm<I, O, N>(
          provider,
          formBuilder: (context, snapshot) {
            final banner = bannerBuilder?.call(context, snapshot);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner != null) ...[banner, const SizedBox(height: 16)],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ResponsiveGrid(
                    spacing: 16,
                    children: fieldsBuilder(context, snapshot),
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLargeWidth = constraints.maxWidth > 500;

                      if (isLargeWidth) {
                        return Row(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ...extraActions,
                            Spacer(),
                            _buildCancelButton(context, l10n),
                            _buildSubmitButton(context, snapshot, l10n),
                          ],
                        );
                      }

                      return Column(
                        spacing: 8,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSubmitButton(context, snapshot, l10n),
                          ...extraActions,
                          _buildCancelButton(context, l10n),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  LoadingButton _buildSubmitButton(
    BuildContext context,
    FormBuilderSnapshot<I, O, N> snapshot,
    AppLocalizations l10n,
  ) {
    return LoadingButton.filled(
      style: FilledButton.styleFrom(
        backgroundColor: submitButtonColor,
        foregroundColor: (submitButtonColor?.computeLuminance() ?? 0) < .5
            ? AppColors.pureWhite
            : AppColors.deepTurquoise,
      ),
      onPressed: (submitEnabled?.call(snapshot.model) ?? true)
          ? (loading) async {
              if (onSubmit != null) {
                await onSubmit!(snapshot, loading);
                return;
              }

              if (snapshot.validate()) {
                // Capturado ANTES do save: `onSuccess` costuma fechar a tela,
                // e o messenger do app sobrevive ao pop.
                final messenger = ScaffoldMessenger.of(context);
                final pendingText =
                    pendingSyncMessage ?? context.l10n.savePendingSync;

                final output = await loading(snapshot.notifier.submit());

                // Um save que não chegou ao servidor não é "salvo!": o
                // formulário fecha do mesmo jeito, mas dizendo a verdade
                // sobre onde o dado está.
                final Object notifier = snapshot.notifier;
                if (notifier is TracksWriteOutcome &&
                    notifier.lastWriteIsPending) {
                  messenger.showSnackBar(SnackBar(content: Text(pendingText)));
                }

                onSuccess?.call(output);
              }
            }
          : null,
      child: Text(submitLabel ?? l10n.saveButton),
    );
  }

  Widget _buildCancelButton(BuildContext context, AppLocalizations l10n) {
    if (onCancel != null) {
      return TextButton(onPressed: onCancel, child: Text(l10n.cancelButton));
    }

    return SizedBox.shrink();
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.spacing = 0.0});

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
                .map(
                  (child) => SizedBox(
                    width: child is FullWidthItem ? maxWidth : itemWidth,
                    child: child,
                  ),
                )
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
