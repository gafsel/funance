import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/model/core_models.dart';

typedef QueryFunction<Q, E> =
    Future<QueryChunk<E>> Function(Q query, {dynamic chunkRef});

abstract class InfiniteListNotifier<Q, E>
    extends StateNotifier<InfiniteListState<Q, E>> {
  final QueryFunction<Q, E> executor;

  InfiniteListNotifier({required this.executor, required Q initialQuery})
    : super(
        InfiniteListState(
          items: [],
          query: initialQuery,
          status: InfiniteListStatus.loading,
        ),
      );

  reset({Q? query}) async {
    if (!mounted) return;

    state = state.copyWith(
      query: query ?? state.query,
      status: InfiniteListStatus.loading,
      items: [],
      nextChunkRef: null,
    );

    await _load();
  }

  more() async {
    if (!mounted) return;

    if (state.status == InfiniteListStatus.loading || !state.hasNextChunk)
      return;
    state = state.copyWith(status: InfiniteListStatus.loading);

    await _load();
  }

  _load() async {
    if (!mounted) return;

    try {
      state = state.copyWith(status: InfiniteListStatus.loading);
      log(
        "Loading chunk with query: ${state.query}, ref: ${state.nextChunkRef}",
      );

      final chunk = await executor(state.query, chunkRef: state.nextChunkRef);
      log(
        "Loaded ${chunk.items.length} items. Has next: ${chunk.hasNextChunk}",
      );

      final newItems = [...state.items, ...chunk.items];

      state = state.copyWith(
        items: newItems,
        nextChunkRef: chunk.nextChunckRef,
        status: InfiniteListStatus.found,
      );

      // Se o chunk retornou itens vazios mas tem um nextChunkRef,
      // significa que o filtro em memória removeu tudo, então buscamos mais.
      if (chunk.items.isEmpty && chunk.hasNextChunk) {
        log("Chunk is empty but has more data, loading next...");
        await _load();
      }
    } catch (ex, stack) {
      log("Failed to retrieve next chunk", error: ex, stackTrace: stack);

      if (mounted) {
        state = state.copyWith(status: InfiniteListStatus.error, error: ex);
      }
    }
  }

  @protected
  void load() => _load();
}
