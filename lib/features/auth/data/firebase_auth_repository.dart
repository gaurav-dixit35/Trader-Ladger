import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  Future<void>? _initializingGoogleSignIn;
  static const _driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  @override
  AppUser? get currentUser => _mapUser(firebaseAuth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    return firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapUser(credential.user);
  }

  @override
  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapUser(credential.user);
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final googleUser = await googleSignIn.authenticate(
      scopeHint: const [_driveFileScope],
    );
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await firebaseAuth.signInWithCredential(credential);
    return _mapUser(userCredential.user);
  }

  @override
  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _initializingGoogleSignIn ??= googleSignIn.initialize();
  }

  AppUser? _mapUser(User? user) {
    final email = user?.email;
    if (user == null || email == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      email: email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
