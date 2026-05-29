import 'package:freezed_annotation/freezed_annotation.dart';

part 'core_models.freezed.dart';

@freezed
sealed class QueryChunk<T> with _$QueryChunk<T> {
  factory QueryChunk({required List<T> items, dynamic nextChunckRef}) =
      _QueryChunk;

  const QueryChunk._();

  bool get hasNextChunk => nextChunckRef != null;
}

enum InfiniteListStatus { loading, found, error }

@freezed
sealed class InfiniteListState<Q, E> with _$InfiniteListState<Q, E> {
  const InfiniteListState._();
  factory InfiniteListState({
    required List<E> items,
    required Q query,
    required InfiniteListStatus status,
    dynamic nextChunkRef,
    dynamic error,
  }) = _InfiniteListState;

  bool get hasNextChunk => nextChunkRef != null;

}
