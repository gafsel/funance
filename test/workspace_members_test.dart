import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/domain/repositories/invite_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/workspace_service.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_members_notifier.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_members_screen.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

const _dono = 'uid-dono';
const _convidado = 'uid-convidado';

class _RecordingAnalytics implements AnalyticsService {
  final List<String> events = [];

  @override
  Future<void> logMemberRemoved() async {
    events.add(AnalyticsEvents.memberRemoved);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  _FakeWorkspaceRepository({this.members = const [], this.removeError});

  List<UserModel> members;
  final Object? removeError;
  final List<({String workspaceId, String memberId})> removals = [];

  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async =>
      members;

  @override
  Future<void> removeWorkspaceMember(
    String workspaceId,
    String memberId,
  ) async {
    if (removeError != null) throw removeError!;

    removals.add((workspaceId: workspaceId, memberId: memberId));
    members = members.where((m) => m.id != memberId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeInviteRepository implements IInviteRepository {
  _FakeInviteRepository({this.invites = const []});

  final List<InviteModel> invites;
  final List<String> resent = [];
  final List<String> cancelled = [];

  @override
  Stream<List<InviteModel>> watchWorkspacePendingInvites(String workspaceId) =>
      Stream.value(invites);

  @override
  Future<void> resendInvite(String inviteId) async => resent.add(inviteId);

  @override
  Future<void> cancelInvite(String inviteId) async => cancelled.add(inviteId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

UserModel _user(String id, String name) => UserModel(
  id: id,
  email: '$id@funances.test',
  displayName: name,
  createdAt: DateTime(2026, 1, 1),
);

InviteModel _invite({String id = 'inv-1'}) => InviteModel(
  id: id,
  workspace: WorkspaceModel(
    id: 'ws-1',
    name: 'Casa',
    type: WorkspaceType.personal,
    members: const [_dono],
    createdAt: DateTime(2026, 1, 1),
  ),
  senderId: _dono,
  senderName: 'Gabriel',
  receiverEmail: 'convidado@funances.test',
  status: InviteStatus.pending,
  createdAt: DateTime(2026, 9, 10),
);

WorkspaceMembersNotifier _notifier({
  required _FakeWorkspaceRepository workspaceRepository,
  required _FakeInviteRepository inviteRepository,
  required String currentUserId,
  AnalyticsService? analytics,
}) => WorkspaceMembersNotifier(
  workspaceService: WorkspaceService(workspaceRepository),
  inviteRepository: inviteRepository,
  analytics: analytics ?? _RecordingAnalytics(),
  workspaceId: 'ws-1',
  ownerId: _dono,
  currentUserId: currentUserId,
);

Widget _hosted(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: child,
      ),
    );

void main() {
  group('WorkspaceMembersNotifier', () {
    test('carrega membros e convites pendentes', () async {
      final inviteRepository = _FakeInviteRepository(invites: [_invite()]);
      final notifier = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(
          members: [_user(_dono, 'Gabriel'), _user(_convidado, 'Ana')],
        ),
        inviteRepository: inviteRepository,
        currentUserId: _dono,
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.members, hasLength(2));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.pendingInvites, hasLength(1));
      expect(notifier.state.invitesLoaded, isTrue);
    });

    test('o dono remove um membro e emite member_removed', () async {
      final workspaceRepository = _FakeWorkspaceRepository(
        members: [_user(_dono, 'Gabriel'), _user(_convidado, 'Ana')],
      );
      final analytics = _RecordingAnalytics();
      final notifier = _notifier(
        workspaceRepository: workspaceRepository,
        inviteRepository: _FakeInviteRepository(),
        currentUserId: _dono,
        analytics: analytics,
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      final error = await notifier.removeMember(_user(_convidado, 'Ana'));

      expect(error, isNull);
      expect(workspaceRepository.removals, [
        (workspaceId: 'ws-1', memberId: _convidado),
      ]);
      expect(notifier.state.members.map((m) => m.id), [_dono]);
      expect(analytics.events, [AnalyticsEvents.memberRemoved]);
    });

    test('a recusa do servidor volta como mensagem, não como sucesso', () async {
      final notifier = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(
          members: [_user(_dono, 'Gabriel'), _user(_convidado, 'Ana')],
          removeError: BusinessException(
            ErrorCode.unknown,
            message: 'Apenas o dono do workspace pode executar esta operação.',
          ),
        ),
        inviteRepository: _FakeInviteRepository(),
        currentUserId: _convidado,
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      final error = await notifier.removeMember(_user(_dono, 'Gabriel'));

      expect(error, 'Apenas o dono do workspace pode executar esta operação.');
      expect(notifier.state.members, hasLength(2), reason: 'nada foi removido');
      expect(notifier.state.busyMemberId, isNull);
    });

    test('isOwner só é verdade para members[0]', () async {
      final dono = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(),
        inviteRepository: _FakeInviteRepository(),
        currentUserId: _dono,
      );
      addTearDown(dono.dispose);

      final membro = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(),
        inviteRepository: _FakeInviteRepository(),
        currentUserId: _convidado,
      );
      addTearDown(membro.dispose);

      expect(dono.isOwner, isTrue);
      expect(membro.isOwner, isFalse);
    });

    test('reenviar e cancelar convite chegam no repositório', () async {
      final inviteRepository = _FakeInviteRepository(invites: [_invite()]);
      final notifier = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(),
        inviteRepository: inviteRepository,
        currentUserId: _dono,
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(await notifier.resendInvite(_invite()), isNull);
      expect(await notifier.cancelInvite(_invite(id: 'inv-2')), isNull);

      expect(inviteRepository.resent, ['inv-1']);
      expect(inviteRepository.cancelled, ['inv-2']);
      expect(notifier.state.busyInviteId, isNull);
    });
  });

  group('WorkspaceMembersScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      required String currentUserId,
      List<UserModel> members = const [],
      List<InviteModel> invites = const [],
    }) async {
      final notifier = _notifier(
        workspaceRepository: _FakeWorkspaceRepository(members: members),
        inviteRepository: _FakeInviteRepository(invites: invites),
        currentUserId: currentUserId,
      );
      // Sem addTearDown: quem descarta o notifier é o ProviderScope, e
      // descartar duas vezes estoura.
      await tester.pumpWidget(
        _hosted(
          const WorkspaceMembersScreen(),
          overrides: [
            WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-1'),
            WorkspaceViewProviders.membersManagement.overrideWith(
              (ref) => notifier,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('o dono vê a ação de remover, mas não para si mesmo', (
      tester,
    ) async {
      await pump(
        tester,
        currentUserId: _dono,
        members: [_user(_dono, 'Gabriel'), _user(_convidado, 'Ana')],
      );

      expect(find.text('Gabriel'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Dono'), findsNothing, reason: 'o papel vai no subtítulo');
      expect(find.textContaining('Dono'), findsOneWidget);
      // Uma única ação de remover: a do convidado.
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });

    testWidgets('um membro comum não vê ação de remover', (tester) async {
      await pump(
        tester,
        currentUserId: _convidado,
        members: [_user(_dono, 'Gabriel'), _user(_convidado, 'Ana')],
      );

      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    });

    testWidgets('estado vazio de convites', (tester) async {
      await pump(tester, currentUserId: _dono, members: [_user(_dono, 'G')]);

      expect(find.text('Nenhum convite aguardando resposta.'), findsOneWidget);
    });

    testWidgets('convite pendente traz reenviar e cancelar', (tester) async {
      await pump(
        tester,
        currentUserId: _dono,
        members: [_user(_dono, 'Gabriel')],
        invites: [_invite()],
      );

      expect(find.text('convidado@funances.test'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
