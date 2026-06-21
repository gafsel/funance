import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
  );
  final IUserRepository _userRepository;

  AuthRepositoryImpl(this._userRepository);

  @override
  Stream<UserModel?> get authStateChanges =>
      _firebaseAuth.authStateChanges().switchMap((user) {
        if (user == null) return Stream.value(null);
        return _userRepository.watchUser(user.uid);
      });

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');

        final UserCredential userCredential =
            await _firebaseAuth.signInWithPopup(googleProvider);

        if (userCredential.user == null) {
          throw BusinessException(ErrorCode.signInFailed);
        }

        return await _handleUserPersistance(userCredential.user!);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw BusinessException(ErrorCode.signInFailed);
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user == null) {
        throw BusinessException(ErrorCode.signInFailed);
      }

      final User firebaseUser = userCredential.user!;

      return await _handleUserPersistance(firebaseUser);
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
    switch (e.code) {
      case 'user-not-found':
        return BusinessException(
          ErrorCode.userNotFound,
          originalError: e,
          stackTrace: s,
        );
      case 'wrong-password':
        return BusinessException(
          ErrorCode.wrongPassword,
          originalError: e,
          stackTrace: s,
        );
      case 'email-already-in-use':
        return BusinessException(
          ErrorCode.emailAlreadyInUse,
          originalError: e,
          stackTrace: s,
        );
      case 'weak-password':
        return BusinessException(
          ErrorCode.weakPassword,
          originalError: e,
          stackTrace: s,
        );
      case 'invalid-email':
        return BusinessException(
          ErrorCode.invalidEmail,
          originalError: e,
          stackTrace: s,
        );
      case 'network-request-failed':
        return BusinessException(
          ErrorCode.networkRequestFailed,
          originalError: e,
          stackTrace: s,
        );
      case 'account-exists-with-different-credential':
        // Adicione este caso se necessário ou deixe no default
        return BusinessException(
          ErrorCode.unknown,
          originalError: e,
          stackTrace: s,
        );
      case 'invalid-credential':
        return BusinessException(
          ErrorCode.wrongPassword,
          originalError: e,
          stackTrace: s,
        );
      case 'user-disabled':
        return BusinessException(
          ErrorCode.userNotFound,
          originalError: e,
          stackTrace: s,
        );
      case 'operation-not-allowed':
        return BusinessException(
          ErrorCode.unknown,
          originalError: e,
          stackTrace: s,
        );
      default:
        if (e.message?.contains('keychain-error') ?? false) {
          return BusinessException(
            ErrorCode.keychainError,
            originalError: e,
            stackTrace: s,
          );
        }
        return BusinessException(
          ErrorCode.unknown,
          originalError: e,
          stackTrace: s,
        );
    }
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
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
