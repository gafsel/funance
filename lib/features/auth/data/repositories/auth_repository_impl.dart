import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  final IUserRepository _userRepository;

  AuthRepositoryImpl(this._userRepository);

  @override
  Stream<UserModel?> get authStateChanges => _firebaseAuth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return await _userRepository.getUserById(user.uid);
      });

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      return await _handleUserPersistance(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e.toString().contains('keychain-error')) {
        throw BusinessException(ErrorCode.keychainError, originalError: e);
      }
      throw BusinessException(ErrorCode.unknown, originalError: e);
    }
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      return await _handleUserPersistance(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw BusinessException(ErrorCode.unknown, originalError: e);
    }
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      await firebaseUser.updateDisplayName(displayName);
      
      return await _handleUserPersistance(firebaseUser, displayName: displayName);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw BusinessException(ErrorCode.unknown, originalError: e);
    }
  }

  BusinessException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return BusinessException(ErrorCode.userNotFound, originalError: e);
      case 'wrong-password':
        return BusinessException(ErrorCode.wrongPassword, originalError: e);
      case 'email-already-in-use':
        return BusinessException(ErrorCode.emailAlreadyInUse, originalError: e);
      case 'weak-password':
        return BusinessException(ErrorCode.weakPassword, originalError: e);
      case 'invalid-email':
        return BusinessException(ErrorCode.invalidEmail, originalError: e);
      case 'network-request-failed':
        return BusinessException(ErrorCode.networkRequestFailed, originalError: e);
      default:
        if (e.message?.contains('keychain-error') ?? false) {
          return BusinessException(ErrorCode.keychainError, originalError: e);
        }
        return BusinessException(ErrorCode.unknown, originalError: e);
    }
  }

  Future<UserModel?> _handleUserPersistance(User firebaseUser, {String? displayName}) async {
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

    return user;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
