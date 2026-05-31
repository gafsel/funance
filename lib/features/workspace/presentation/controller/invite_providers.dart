import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import '../../data/repositories/invite_repository_impl.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../domain/models/invite_model.dart';

part 'invite_providers.freezed.dart';

final inviteRepositoryProvider = Provider<IInviteRepository>((ref) {
  return InviteRepositoryImpl();
});

@freezed
sealed class InviteState with _$InviteState {
  const factory InviteState({
    @Default([]) List<InviteModel> pendingInvites,
    @Default(false) bool isLoading,
    @Default(false) bool initialLoadDone,
  }) = _InviteState;
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

  ref.listen(AuthDomainProviders.user, (previous, next) {
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

final sentInvitesProvider = StreamProvider<List<InviteModel>>((ref) {
  final user = ref.watch(AuthDomainProviders.user).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('invites')
      .where('senderId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => InviteModel.fromFirestore(doc)).toList());
});
