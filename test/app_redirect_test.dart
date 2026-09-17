import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/router/app_redirect.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';

/// F4.10 §6.5, risco nº 5 — o `redirect` do router é a máquina de estados do
/// boot e não tinha NENHUM teste: nenhum teste do app construía o
/// `routerProvider`. Um erro aqui prende o usuário no splash, num laço
/// `/invites` -> `/invites`, ou joga quem já tem workspace de volta no
/// onboarding.

final _usuario = UserModel(
  id: 'u1',
  email: 'a@b.com',
  createdAt: DateTime(2026, 1, 1),
);

final _workspacePronto = WorkspaceModel(
  id: 'ws',
  name: 'Casa',
  type: WorkspaceType.personal,
  members: const ['u1'],
  createdAt: DateTime(2026, 1, 1),
  lastOnboardingStep: OnboardingSteps.done,
);

WorkspaceState _workspace({
  bool isLoading = false,
  bool initialLoadDone = true,
  List<WorkspaceModel> disponiveis = const [],
  WorkspaceModel? atual,
}) => WorkspaceState(
  isLoading: isLoading,
  initialLoadDone: initialLoadDone,
  availableWorkspaces: disponiveis,
  currentWorkspace: atual,
);

InviteState _convites({
  bool isLoading = false,
  bool initialLoadDone = true,
  List<InviteModel> pendentes = const [],
}) => InviteState(
  isLoading: isLoading,
  initialLoadDone: initialLoadDone,
  pendingInvites: pendentes,
);

final _convitePendente = InviteModel(
  id: 'i1',
  workspace: _workspacePronto.copyWith(id: 'ws-2', name: 'Família'),
  senderId: 'u2',
  senderName: 'Maria',
  receiverEmail: 'a@b.com',
  status: InviteStatus.pending,
  createdAt: DateTime(2026, 3, 1),
);

String? _destino({
  AsyncValue<UserModel?>? auth,
  WorkspaceState? workspace,
  InviteState? convites,
  String location = '/',
}) => appRedirect(
  auth: auth ?? AsyncValue.data(_usuario),
  workspace:
      workspace ??
      _workspace(disponiveis: [_workspacePronto], atual: _workspacePronto),
  invites: convites ?? _convites(),
  location: location,
);

void main() {
  group('ainda não sabemos quem é', () {
    test('qualquer rota vai para o splash', () {
      for (final rota in ['/', '/login', '/invites', '/history']) {
        expect(
          _destino(auth: const AsyncValue.loading(), location: rota),
          '/splash',
          reason: 'vindo de $rota',
        );
      }
    });

    test('quem JÁ está no splash fica — senão é um laço', () {
      expect(
        _destino(auth: const AsyncValue.loading(), location: '/splash'),
        isNull,
      );
    });
  });

  group('deslogado', () {
    test('vai para o login, venha de onde vier', () {
      for (final rota in ['/', '/splash', '/invites', '/history']) {
        expect(
          _destino(auth: const AsyncValue.data(null), location: rota),
          '/login',
          reason: 'vindo de $rota',
        );
      }
    });

    test('quem já está no login fica', () {
      expect(
        _destino(auth: const AsyncValue.data(null), location: '/login'),
        isNull,
      );
    });

    test('um erro de auth não é "carregando": cai no login', () {
      expect(
        _destino(
          auth: AsyncValue.error(Exception('sem rede'), StackTrace.empty),
          location: '/',
        ),
        '/login',
      );
    });
  });

  group('logado, mas os dados ainda chegando', () {
    test('fica onde está — e NÃO volta para o splash', () {
      // Voltar para o splash aqui faria a tela piscar a cada reavaliação do
      // redirect, que o refresh dispara várias vezes durante o boot.
      final carregando = [
        (_workspace(isLoading: true), _convites()),
        (_workspace(initialLoadDone: false), _convites()),
        (_workspace(), _convites(isLoading: true)),
        (_workspace(), _convites(initialLoadDone: false)),
      ];

      for (final (ws, inv) in carregando) {
        expect(
          _destino(workspace: ws, convites: inv, location: '/history'),
          isNull,
        );
      }
    });

    test('nem mesmo o splash é abandonado antes da hora', () {
      expect(
        _destino(workspace: _workspace(isLoading: true), location: '/splash'),
        isNull,
      );
    });
  });

  group('tudo carregado', () {
    test('login e splash deixam de ser lugares válidos', () {
      expect(_destino(location: '/login'), '/');
      expect(_destino(location: '/splash'), '/');
    });

    test('quem está numa rota normal fica', () {
      expect(_destino(location: '/history'), isNull);
      expect(_destino(location: '/'), isNull);
    });
  });

  group('convites pendentes', () {
    test('vêm antes de tudo — inclusive do onboarding', () {
      // Sem responder o convite, o usuário acabaria criando um workspace novo
      // em vez de entrar no da família.
      expect(
        _destino(
          workspace: _workspace(),
          convites: _convites(pendentes: [_convitePendente]),
          location: '/',
        ),
        '/invites',
      );
    });

    test('quem já está em /invites fica — senão é um laço', () {
      expect(
        _destino(
          convites: _convites(pendentes: [_convitePendente]),
          location: '/invites',
        ),
        isNull,
      );
    });

    test('respondido o convite, a navegação volta ao normal', () {
      expect(_destino(convites: _convites(), location: '/invites'), isNull);
    });
  });

  group('onboarding', () {
    test('sem nenhum workspace, vai para o onboarding', () {
      expect(
        _destino(
          workspace: _workspace(disponiveis: []),
          location: '/',
        ),
        '/onboarding',
      );
    });

    test('com onboarding pela metade, também', () {
      final incompleto = _workspacePronto.copyWith(
        lastOnboardingStep: OnboardingSteps.accounts,
      );

      expect(
        _destino(
          workspace: _workspace(disponiveis: [incompleto], atual: incompleto),
          location: '/',
        ),
        '/onboarding',
      );
    });

    test('quem já está no onboarding fica', () {
      expect(
        _destino(workspace: _workspace(), location: '/onboarding'),
        isNull,
      );
    });

    test('/accounts/form é a exceção: o onboarding abre essa rota', () {
      // Redirecionar de volta para /onboarding aqui seria um laço, e o
      // usuário nunca conseguiria cadastrar a primeira conta.
      expect(
        _destino(workspace: _workspace(), location: '/accounts/form'),
        isNull,
      );
    });

    test('com o onboarding concluído, ninguém é mandado de volta', () {
      expect(_destino(location: '/'), isNull);
      expect(_destino(location: '/planning'), isNull);
    });

    test('workspace nulo com lista vazia não explode: manda ao onboarding', () {
      expect(
        _destino(
          workspace: _workspace(disponiveis: [], atual: null),
          location: '/history',
        ),
        '/onboarding',
      );
    });
  });
}
