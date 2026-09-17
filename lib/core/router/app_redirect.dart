import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';

/// A máquina de estados do boot: quem entra no app, para onde vai.
///
/// Estava escrita dentro do `redirect` do `GoRouter`, e por isso nenhum teste
/// conseguia alcançá-la sem montar o router inteiro — nenhum teste alcançava.
/// É a decisão mais cara de errar do app: um engano aqui prende o usuário no
/// splash, num laço `/invites` -> `/invites`, ou joga quem já tem workspace de
/// volta no onboarding.
///
/// Devolve o destino, ou `null` para "fica onde está".
String? appRedirect({
  required AsyncValue<UserModel?> auth,
  required WorkspaceState workspace,
  required InviteState invites,
  required String location,
}) {
  final isSplash = location == '/splash';

  // 1. Ainda não sabemos quem é. O splash é a sala de espera; qualquer outra
  //    rota volta para ela.
  if (auth.isLoading) {
    return isSplash ? null : '/splash';
  }

  final user = auth.valueOrNull;
  final isLoggingIn = location == '/login';

  // 2. Ninguém logado: só o login.
  if (user == null) {
    if (isLoggingIn) return null;
    return '/login';
  }

  // 3. Logado, mas workspace e convites ainda chegando. FICA ONDE ESTÁ — e
  //    não volta para o splash: o `notifyListeners` do refresh vai reavaliar
  //    quando o carregamento terminar, e mandar para o splash aqui faria a
  //    tela piscar a cada reavaliação.
  if (workspace.isLoading ||
      !workspace.initialLoadDone ||
      invites.isLoading ||
      !invites.initialLoadDone) {
    return null;
  }

  // 4. Carregado: login e splash não são mais lugares válidos.
  if (isLoggingIn || isSplash) {
    return '/';
  }

  // 5. Convite pendente vem antes de tudo: sem responder, o usuário pode
  //    acabar criando um workspace novo em vez de entrar no da família.
  if (invites.pendingInvites.isNotEmpty) {
    if (location != '/invites') return '/invites';
    return null;
  }

  // 6. Sem workspace, ou com um onboarding pela metade.
  final hasNoWorkspaces = workspace.availableWorkspaces.isEmpty;
  final needsOnboarding =
      (workspace.currentWorkspace?.lastOnboardingStep ??
          OnboardingSteps.done) !=
      OnboardingSteps.done;

  // `/accounts/form` é a exceção: o próprio onboarding abre essa rota para
  // cadastrar a primeira conta, e redirecioná-la de volta para `/onboarding`
  // seria um laço.
  if ((hasNoWorkspaces || needsOnboarding) &&
      location != '/onboarding' &&
      location != '/accounts/form') {
    return '/onboarding';
  }

  return null;
}
