import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

/// Códigos do Firebase Auth que significam "o navegador não deixou abrir a
/// janela"; não são erro do usuário nem de configuração, e é neles que vale a
/// pena cair para o redirect.
const Set<String> _popupUnavailableCodes = {
  'popup-blocked',
  'operation-not-supported-in-this-environment',
  'web-storage-unsupported',
};

/// Códigos em que o usuário simplesmente desistiu. Cair para o redirect aqui
/// seria sequestrar a página de quem acabou de fechar a janela de propósito.
const Set<String> _popupCancelledCodes = {
  'popup-closed-by-user',
  'cancelled-popup-request',
  'user-cancelled',
};

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final IUserRepository _userRepository;

  /// O plugin `google_sign_in` é o caminho de Android/iOS/macOS.
  ///
  /// `late final` é o que importa aqui: na web a construção do `GoogleSignIn`
  /// dispara `init()` no plugin, que exige a meta tag
  /// `google-signin-client_id` e estourava um `Assertion failed: ... pass
  /// clientId when initializing GoogleSignIn` como erro assíncrono não
  /// tratado em toda sessão web. Sendo `late`, o objeto só nasce quando um
  /// caminho não-web realmente o usa.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Só `email`. O escopo `contacts.readonly` que havia aqui nunca foi lido
    // por nenhuma tela e é um escopo sensível: ele leva o Google a exigir
    // verificação do app e a barrar o consentimento na web.
    scopes: const ['email'],
  );

  AuthRepositoryImpl(this._userRepository);

  /// Na web o login pode ter terminado em `signInWithRedirect`: a página volta
  /// já autenticada e o resultado precisa ser consumido ANTES de olharmos o
  /// `authStateChanges`, senão um usuário novo entra sem documento no
  /// Firestore e a Home abre vazia.
  late final Future<void> _redirectSettled = _settlePendingRedirect();

  @override
  Stream<UserModel?> get authStateChanges => Stream.fromFuture(_redirectSettled)
      .switchMap((_) => _firebaseAuth.authStateChanges())
      .switchMap((user) {
        if (user == null) return Stream.value(null);
        return _userRepository.watchUser(user.uid);
      });

  Future<void> _settlePendingRedirect() async {
    if (!kIsWeb) return;

    try {
      final UserCredential credential = await _firebaseAuth
          .getRedirectResult();
      final User? user = credential.user;

      if (user != null) await _handleUserPersistance(user);
    } catch (_) {
      // Sem redirect pendente — o caso comum — ou o redirect falhou. Em
      // nenhum dos dois o app pode deixar de abrir: o stream de auth segue e
      // a tela de login aparece.
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      return kIsWeb ? await _signInWithGoogleOnWeb() : await _signInOnDevice();
    } on BusinessException {
      rethrow;
    } on FirebaseAuthException catch (e, s) {
      throw _handleFirebaseAuthException(e, s);
    } catch (e, s) {
      final errorStr = e.toString();
      if (errorStr.contains('keychain-error')) {
        throw BusinessException(
          ErrorCode.keychainError,
          originalError: e,
          stackTrace: s,
        );
      }
      if (errorStr.contains('sign_in_failed') ||
          errorStr.contains('ApiException: 10')) {
        throw BusinessException(
          ErrorCode.googleSignInConfigError,
          originalError: e,
          stackTrace: s,
        );
      }
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  /// Na web quem fala com o Google é o próprio Firebase Auth.
  ///
  /// O `google_sign_in` não entra: a linha 6.x depende de uma meta tag de
  /// client id que o app não tem, e mesmo configurada ela só devolveria uma
  /// credencial que o `signInWithPopup` já entrega sozinho.
  Future<UserModel> _signInWithGoogleOnWeb() async {
    final GoogleAuthProvider provider = GoogleAuthProvider()..addScope('email');

    try {
      return await _persistCredential(
        await _firebaseAuth.signInWithPopup(provider),
      );
    } on FirebaseAuthException catch (e, s) {
      if (!_popupUnavailableCodes.contains(e.code)) {
        throw _handleFirebaseAuthException(e, s);
      }

      // Bloqueador de popup ligado (ou navegador embutido, que nunca abre
      // janela). O redirect usa a própria aba e não depende de popup.
      await _firebaseAuth.signInWithRedirect(provider);

      // A aba já está saindo para o Google. Se o Future chegar a completar,
      // só resta avisar que o redirecionamento está em curso — devolver um
      // usuário aqui seria mentira.
      throw BusinessException(
        ErrorCode.signInRedirecting,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  Future<UserModel> _signInOnDevice() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw BusinessException(ErrorCode.signInCancelled);
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _persistCredential(
      await _firebaseAuth.signInWithCredential(credential),
    );
  }

  Future<UserModel> _persistCredential(UserCredential credential) async {
    final User? user = credential.user;

    if (user == null) throw BusinessException(ErrorCode.signInFailed);

    return _handleUserPersistance(user);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw BusinessException(ErrorCode.signInFailed);
      }

      final User firebaseUser = userCredential.user!;

      return await _handleUserPersistance(firebaseUser);
    } on FirebaseAuthException catch (e, s) {
      throw _handleFirebaseAuthException(e, s);
    } on BusinessException {
      rethrow;
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw BusinessException(ErrorCode.signUpFailed);
      }

      final User firebaseUser = userCredential.user!;

      await firebaseUser.updateDisplayName(displayName);

      return await _handleUserPersistance(
        firebaseUser,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e, s) {
      throw _handleFirebaseAuthException(e, s);
    } on BusinessException {
      rethrow;
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  BusinessException _handleFirebaseAuthException(
    FirebaseAuthException e,
    StackTrace s,
  ) {
    return BusinessException(
      authErrorCode(e.code, message: e.message),
      originalError: e,
      stackTrace: s,
    );
  }

  Future<UserModel> _handleUserPersistance(
    User firebaseUser, {
    String? displayName,
  }) async {
    // Verificar se o usuário já existe no Firestore
    UserModel? user = await _userRepository.getUserById(firebaseUser.uid);

    if (user == null) {
      // Criar novo usuário
      user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: displayName ?? firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUser(user);
    } else {
      // Atualizar lastLogin
      await _userRepository.updateUser(firebaseUser.uid, {
        'lastLogin': DateTime.now(),
        'displayName': displayName ?? firebaseUser.displayName,
      });

      user = await _userRepository.getUserById(firebaseUser.uid);
    }

    return user!;
  }

  @override
  Future<void> signOut() async {
    // O signOut do Firebase é o que efetivamente desloga o app; ele precisa
    // executar mesmo que o signOut do Google falhe.
    //
    // Na web nem chegamos a tocar no `google_sign_in`: não foi ele quem criou
    // a sessão, e acessá-lo aqui construiria o plugin só para vê-lo estourar
    // a assertion de client id.
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Falha ao limpar a sessão Google não deve impedir o logout do app.
      }
    }

    await _firebaseAuth.signOut();
  }
}

/// Traduz o `code` do Firebase Auth para o erro de negócio do app.
///
/// Fica fora da classe porque é pura: é o único ponto em que os códigos da web
/// (`popup-blocked`, `unauthorized-domain`) e os de dispositivo viram a mesma
/// lista, e é o que o teste exercita sem precisar de um FirebaseAuth vivo.
ErrorCode authErrorCode(String code, {String? message}) {
  if (_popupUnavailableCodes.contains(code)) {
    return ErrorCode.signInPopupBlocked;
  }

  if (_popupCancelledCodes.contains(code)) return ErrorCode.signInCancelled;

  switch (code) {
    case 'user-not-found':
    case 'user-disabled':
      return ErrorCode.userNotFound;
    case 'wrong-password':
    case 'invalid-credential':
      return ErrorCode.wrongPassword;
    case 'email-already-in-use':
      return ErrorCode.emailAlreadyInUse;
    case 'weak-password':
      return ErrorCode.weakPassword;
    case 'invalid-email':
      return ErrorCode.invalidEmail;
    case 'network-request-failed':
      return ErrorCode.networkRequestFailed;
    case 'unauthorized-domain':
      return ErrorCode.signInUnauthorizedDomain;
    case 'account-exists-with-different-credential':
      return ErrorCode.accountExistsWithDifferentCredential;
    case 'operation-not-allowed':
      return ErrorCode.signInProviderDisabled;
    default:
      if (message?.contains('keychain-error') ?? false) {
        return ErrorCode.keychainError;
      }
      return ErrorCode.unknown;
  }
}
