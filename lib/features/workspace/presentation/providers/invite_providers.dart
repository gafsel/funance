import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/invite_repository_impl.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../domain/models/invite_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final inviteRepositoryProvider = Provider<IInviteRepository>((ref) {
  return InviteRepositoryImpl();
});

class InviteState {
  final List<InviteModel> pendingInvites;
  final bool isLoading;
  final bool initialLoadDone;

  InviteState({
    this.pendingInvites = const [],
    this.isLoading = false,
    this.initialLoadDone = false,
  });

  InviteState copyWith({
    List<InviteModel>? pendingInvites,
    bool? isLoading,
    bool? initialLoadDone,
  }) {
    return InviteState(
      pendingInvites: pendingInvites ?? this.pendingInvites,
      isLoading: isLoading ?? this.isLoading,
      initialLoadDone: initialLoadDone ?? this.initialLoadDone,
    );
  }
}

class InviteNotifier extends StateNotifier<InviteState> {
  final IInviteRepository _repository;

  InviteNotifier(this._repository) : super(InviteState());

  void reset() {
    state = InviteState();
  }

  Future<void> loadInvites(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final invites = await _repository.getPendingInvites(email);
      state = state.copyWith(
        pendingInvites: invites,
        isLoading: false,
        initialLoadDone: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, initialLoadDone: true);
    }
  }

  Future<void> respond(String inviteId, InviteStatus status) async {
    await _repository.respondToInvite(inviteId, status);
    state = state.copyWith(
      pendingInvites: state.pendingInvites.where((i) => i.id != inviteId).toList(),
    );
  }

  Future<void> sendInvite(InviteModel invite) async {
    await _repository.sendInvite(invite);
  }
}

final inviteNotifierProvider = StateNotifierProvider<InviteNotifier, InviteState>((ref) {
  final repository = ref.watch(inviteRepositoryProvider);
  final notifier = InviteNotifier(repository);

  ref.listen(authStateProvider, (previous, next) {
    next.when(
      data: (user) {
        if (user != null) {
          notifier.loadInvites(user.email);
        } else {
          notifier.reset();
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  });

  return notifier;
});
