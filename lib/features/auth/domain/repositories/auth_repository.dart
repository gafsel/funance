import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

abstract class IAuthRepository {
  Stream<UserModel?> get authStateChanges;

  /// Erros trazidos pelo RETORNO de um `signInWithRedirect`.
  ///
  /// Este caminho não tem para onde devolver uma exceção: quem pediu o login
  /// foi uma página que já não existe — o navegador saiu para o Google e
  /// voltou com o app recarregado do zero. Sem este fluxo, uma recusa no
  /// retorno (e-mail já usado por outro provedor, domínio não autorizado,
  /// provedor desligado) fazia a tela de login reaparecer muda.
  Stream<ErrorCode> get redirectErrors;

  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
}
