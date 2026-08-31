import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pitakapflutter/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pitakapflutter/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/auth/domain/repository/auth_repository.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/delete_account_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_out_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_up_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/watch_user_details_usecase.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasourceImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider)),
);

final watchAuthStateUseCaseProvider = Provider<WatchAuthStateUseCase>(
  (ref) => WatchAuthStateUseCase(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(watchAuthStateUseCaseProvider).call(),
);

final watchUserDetailsUseCaseProvider = Provider<WatchUserDetailsUseCase>(
  (ref) => WatchUserDetailsUseCase(ref.watch(authRepositoryProvider)),
);

final userDetailsProvider = StreamProvider.family<UserDetailsEntity?, String>(
  (ref, uid) => ref.watch(watchUserDetailsUseCaseProvider).call(uid),
);

final loginUserUseCaseProvider = Provider<LoginUserUseCase>(
  (ref) => LoginUserUseCase(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final signUpUserUseCaseProvider = Provider<SignUpUserUseCase>(
  (ref) => SignUpUserUseCase(ref.watch(authRepositoryProvider)),
);

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>(
  (ref) => SendPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => DeleteAccountUseCase(ref.watch(authRepositoryProvider)),
);
