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
    state = state.copyWith(
      query: query ?? state.query,
      status: InfiniteListStatus.loading,
      items: [],
      nextChunkRef: null,
    );

    await _load();
  }

  more() async {
    state = state.copyWith(status: InfiniteListStatus.loading);

    await _load();
  }

  _load() async {
    try {
      state = state.copyWith(status: InfiniteListStatus.loading);

      final chunk = await executor(state.query, chunkRef: state.nextChunkRef);

      state = state.copyWith(
        items: [...state.items, ...chunk.items],
        nextChunkRef: chunk.nextChunckRef,
        status: InfiniteListStatus.found,
      );
    } catch (ex, stack) {
      log("Failed to retrieve next chunk", error: ex, stackTrace: stack);

      state = state.copyWith(status: InfiniteListStatus.error, error: ex);
    }
  }

  @protected
  void load() => _load();
}
