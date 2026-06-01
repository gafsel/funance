import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

import '../../data/repositories/invite_repository_impl.dart';
import '../../domain/models/invite_model.dart';
import '../../domain/repositories/invite_repository.dart';

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
  final WorkspaceNotifier workspaceNotifier;
  late UserModel user;

  InviteNotifier(this._repository, this.workspaceNotifier)
    : super(InviteState());

  void reset() {
    state = InviteState();
  }

  Future<void> loadInvites(UserModel user) async {
    this.user = user;
    state = state.copyWith(isLoading: true);
    try {
      final invites = await _repository.getPendingInvites(user.email);
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
    final invite = state.pendingInvites
        .where((iv) => iv.id == inviteId)
        .firstOrNull;

    if (invite == null) {
      return;
    }

    await _repository.respondToInvite(inviteId, status);

    state = state.copyWith(
      pendingInvites: state.pendingInvites
          .where((i) => i.id != inviteId)
          .toList(),
    );

    if (status == InviteStatus.accepted) {
      workspaceNotifier.loadWorkspaces(user.id, invite.workspace.id, true);
    }
  }

  Future<void> sendInvite(InviteModel invite) async {
    await _repository.sendInvite(invite);
  }
}

final inviteNotifierProvider =
    StateNotifierProvider<InviteNotifier, InviteState>((ref) {
      final notifier = InviteNotifier(
        ref.watch(inviteRepositoryProvider),
        ref.watch(WorkspaceViewProviders.workspace.notifier),
      );

      ref.listen(AuthDomainProviders.user, (previous, next) {
        next.when(
          data: (user) {
            if (user != null) {
              notifier.loadInvites(user);
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
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => InviteModel.fromFirestore(doc)).toList(),
      );
});
