import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/error/firestore_error_mapper.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/core/utils/display_name.dart';
import 'package:pitakapflutter/feature/auth/data/datasources/auth_error_mapper.dart';
import 'package:pitakapflutter/feature/auth/data/model/user_details_model.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_up_user_usecase.dart';

abstract interface class AuthRemoteDatasource {
  Stream<String?> authStateChanges();

  Stream<UserDetailsModel?> watchUserDetails(String uid);

  Future<UserDetailsModel> signUp(SignUpUseCaseParams params);

  Future<UserDetailsModel> login(LoginUseCaseParams params);

  Future<UserDetailsModel?> signInWithGoogle();

  Future<void> sendPasswordReset(SendPasswordResetUseCaseParams params);

  Future<void> signOut();

  Future<void> deleteAccount();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDatasourceImpl({
    required this.auth,
    required this.firestore,
    required this.googleSignIn,
  });

  bool _googleReady = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    await googleSignIn.initialize();
    _googleReady = true;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return firestore.collection(Keys.userDetailsCollection).doc(uid);
  }

  @override
  Stream<String?> authStateChanges() {
    return auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Stream<UserDetailsModel?> watchUserDetails(String uid) {
    return _userDoc(uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? UserDetailsModel.fromDoc(snapshot) : null,
        )
        .handleError((Object error) => throw FirestoreErrorMapper.from(error));
  }

  @override
  Future<UserDetailsModel> signUp(SignUpUseCaseParams params) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const UnknownFailure('Sign up did not return an account');
      }

      final profile = UserDetailsModel(
        uid: uid,
        firstName: params.firstName,
        lastName: params.lastName,
        email: params.email,
      );

      await _userDoc(uid).set(profile.toCreateMap());

      return profile;
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  @override
  Future<UserDetailsModel> login(LoginUseCaseParams params) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const UnknownFailure('Sign in did not return an account');
      }

      final snapshot = await _userDoc(uid).get();
      if (!snapshot.exists) {
        throw const ServerFailure('No profile found for this account');
      }

      return UserDetailsModel.fromDoc(snapshot);
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  @override
  Future<UserDetailsModel?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final GoogleSignInAccount account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) return null;
        rethrow;
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const ServerFailure('Google did not return a sign-in token');
      }

      final credential = await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const UnknownFailure('Sign in did not return an account');
      }

      final snapshot = await _userDoc(uid).get();
      if (snapshot.exists) return UserDetailsModel.fromDoc(snapshot);

      final name = splitDisplayName(account.displayName);
      final profile = UserDetailsModel(
        uid: uid,
        firstName: name.firstName,
        lastName: name.lastName,
        email: account.email,
      );

      await _userDoc(uid).set(profile.toCreateMap());

      return profile;
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  @override
  Future<void> sendPasswordReset(SendPasswordResetUseCaseParams params) async {
    try {
      await auth.sendPasswordResetEmail(email: params.email);
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_googleReady) await googleSignIn.signOut();
      await auth.signOut();
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = auth.currentUser;

      if (user == null) {
        throw const UnknownFailure('No signed-in account to delete');
      }

      final uid = user.uid;

      await _deleteOwnedDocuments(Keys.subscriptionsCollection, uid);
      await _deleteOwnedDocuments(Keys.expensesCollection, uid);
      await _userDoc(uid).delete();

      await user.delete();

      if (_googleReady) await googleSignIn.signOut();
    } catch (error) {
      throw AuthErrorMapper.from(error);
    }
  }

  Future<void> _deleteOwnedDocuments(String collection, String uid) async {
    final owned = await firestore
        .collection(collection)
        .where(Keys.userId, isEqualTo: uid)
        .get();

    if (owned.docs.isEmpty) return;

    final batch = firestore.batch();

    for (final document in owned.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }
}
