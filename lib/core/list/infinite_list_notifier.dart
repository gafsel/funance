import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/observability/app_logger.dart';

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

  Future<void> reset({Q? query}) async {
    if (!mounted) return;

    state = state.copyWith(
      query: query ?? state.query,
      status: InfiniteListStatus.loading,
      items: [],
      nextChunkRef: null,
    );

    await _load();
  }

  Future<void> more() async {
    if (!mounted) return;

    if (state.status == InfiniteListStatus.loading || !state.hasNextChunk) {
      return;
    }
    state = state.copyWith(status: InfiniteListStatus.loading);

    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    try {
      state = state.copyWith(status: InfiniteListStatus.loading);
      AppLogger.debug(
        'Carregando página: consulta ${state.query}, ref ${state.nextChunkRef}',
        name: 'list',
      );

      final chunk = await executor(state.query, chunkRef: state.nextChunkRef);
      AppLogger.debug(
        '${chunk.items.length} itens carregados; tem próxima: '
        '${chunk.hasNextChunk}',
        name: 'list',
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
        AppLogger.debug(
          'Página vazia com mais dados adiante; carregando a próxima',
          name: 'list',
        );
        await _load();
      }
    } catch (ex, stack) {
      AppLogger.error('Falha ao carregar a próxima página', ex, stack);

      if (mounted) {
        state = state.copyWith(status: InfiniteListStatus.error, error: ex);
      }
    }
  }

  @protected
  void load() => _load();
}
