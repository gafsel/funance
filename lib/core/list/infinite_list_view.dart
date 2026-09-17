import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/error_view.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef SeparatorBuilder<T> =
    Widget Function(BuildContext context, T? before, T? after);

class InfiniteListView<Q, T> extends ConsumerWidget {
  const InfiniteListView._(
    this.provider, {
    super.key,
    required this.itemBuilder,
    this.emptyStateBuilder,
    this.separatorBuilder,
    this.padding,
    this.footerBuilder,
  });

  final AutoDisposeStateNotifierProvider<
    InfiniteListNotifier<Q, T>,
    InfiniteListState<Q, T>
  >
  provider;
  final EdgeInsets? padding;
  final ItemBuilder<T> itemBuilder;
  final SeparatorBuilder<T>? separatorBuilder;
  final WidgetBuilder? emptyStateBuilder;
  final WidgetBuilder? footerBuilder;

  factory InfiniteListView.builder(
    AutoDisposeStateNotifierProvider<
      InfiniteListNotifier<Q, T>,
      InfiniteListState<Q, T>
    >
    provider, {
    EdgeInsets? padding,
    required ItemBuilder<T> itemBuilder,
    WidgetBuilder? emptyStateBuilder,
    WidgetBuilder? footerBuilder,
  }) {
    return InfiniteListView._(
      provider,
      itemBuilder: itemBuilder,
      padding: padding,
      emptyStateBuilder: emptyStateBuilder,
      footerBuilder: footerBuilder,
    );
  }

  factory InfiniteListView.separator(
    AutoDisposeStateNotifierProvider<
      InfiniteListNotifier<Q, T>,
      InfiniteListState<Q, T>
    >
    provider, {
    EdgeInsets? padding,
    required ItemBuilder<T> itemBuilder,
    WidgetBuilder? emptyStateBuilder,
    required SeparatorBuilder<T> separatorBuilder,
    WidgetBuilder? footerBuilder,
  }) {
    return InfiniteListView._(
      provider,
      itemBuilder: itemBuilder,
      padding: padding,
      emptyStateBuilder: emptyStateBuilder,
      separatorBuilder: separatorBuilder,
      footerBuilder: footerBuilder,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.watch(provider.notifier);
    final state = ref.watch(provider);

    final showLoader =
        state.status == InfiniteListStatus.loading ||
        state.status == InfiniteListStatus.error ||
        state.hasNextChunk;

    final showFooter =
        footerBuilder != null &&
        !state.hasNextChunk &&
        state.status != InfiniteListStatus.loading &&
        state.items.isNotEmpty;

    final itemCount =
        (state.items.length * 2) + (showLoader ? 1 : 0) + (showFooter ? 1 : 0);

    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Se for o último item e precisamos mostrar loader/erro
        if (index == itemCount - 1 && showLoader) {
          if (state.status == InfiniteListStatus.loading) {
            return const Padding(
              padding: AppSpacing.allMd,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == InfiniteListStatus.error) {
            // Antes havia aqui um segundo error view, com `Colors.red` cru:
            // toda lista paginada do app mostrava um erro visualmente
            // diferente do resto. Agora é o mesmo componente.
            return Padding(
              padding: AppSpacing.allMd,
              child: ErrorView(
                message: l10n.errorLoadingData,
                onRetry: notifier.reset,
              ),
            );
          } else if (state.hasNextChunk) {
            Future(() => notifier.more());
            return const SizedBox.shrink();
          }
        }

        // Se for o último item e precisamos mostrar o footer
        if (index == itemCount - 1 && showFooter) {
          return footerBuilder!(context);
        }

        final isSeparator = index % 2 == 0;
        final itemIndex = index ~/ 2;

        if (isSeparator) {
          final before = itemIndex > 0 ? state.items[itemIndex - 1] : null;
          final after = itemIndex < state.items.length
              ? state.items[itemIndex]
              : null;

          return separatorBuilder?.call(context, before, after) ??
              const SizedBox.shrink();
        }

        if (itemIndex < state.items.length) {
          return itemBuilder(context, state.items[itemIndex]);
        }

        if (state.items.isEmpty && !showLoader) {
          return emptyStateBuilder?.call(context) ??
              EmptyState.message(l10n.noRecordsFound);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
