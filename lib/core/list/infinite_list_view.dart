import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/l10n/app_localizations.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef SeparatorBuilder<T> = Widget Function(BuildContext context, T? before, T? after);

class InfiniteListView<Q, T> extends ConsumerWidget {
  const InfiniteListView._(this.provider,
      {super.key, required this.itemBuilder, this.emptyStateBuilder, this.separatorBuilder, this.padding});

  final StateNotifierProvider<
      InfiniteListNotifier<Q, T>,
      InfiniteListState<Q, T>
  > provider;
  final EdgeInsets? padding;
  final ItemBuilder<T> itemBuilder;
  final SeparatorBuilder<T>? separatorBuilder;
  final WidgetBuilder? emptyStateBuilder;

  factory InfiniteListView.builder(StateNotifierProvider<
      InfiniteListNotifier<Q, T>,
      InfiniteListState<Q, T>
  > provider, {EdgeInsets? padding, required ItemBuilder<
      T> itemBuilder, WidgetBuilder? emptyStateBuilder }) {
    return InfiniteListView._(provider,
      itemBuilder: itemBuilder,
      padding: padding,
      emptyStateBuilder: emptyStateBuilder,
    );
  }

  factory InfiniteListView.separator(StateNotifierProvider<
      InfiniteListNotifier<Q, T>,
      InfiniteListState<Q, T>
  > provider, {EdgeInsets? padding, required ItemBuilder<
      T> itemBuilder, WidgetBuilder? emptyStateBuilder, required SeparatorBuilder<
      T> separatorBuilder }) {
    return InfiniteListView._(provider,
      itemBuilder: itemBuilder,
      padding: padding,
      emptyStateBuilder: emptyStateBuilder,
      separatorBuilder: separatorBuilder,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.watch(provider.notifier);
    final state = ref.watch(provider);

    return ListView.builder(
      padding: padding,
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          if (state.status == InfiniteListStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == InfiniteListStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(height: 8),
                  Text(l10n.errorLoadingData),
                  TextButton(
                    onPressed: () => notifier.reset(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          } else if (state.hasNextChunk) {
            notifier.more();
          } else if (state.items.isEmpty) {
            return emptyStateBuilder?.call(context) ?? Center(
              child: Text(l10n.noRecordsFound),
            );
          }

          return SizedBox.shrink();
        }

        return itemBuilder(context, state.items[index]);
      },
    );
  }
}
