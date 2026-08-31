import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_up_user_usecase.dart';

abstract interface class AuthRepository {
  Stream<String?> authStateChanges();

  Stream<UserDetailsEntity?> watchUserDetails(String uid);

  Future<UserDetailsEntity> signUp(SignUpUseCaseParams params);

  Future<UserDetailsEntity> login(LoginUseCaseParams params);

  Future<UserDetailsEntity?> signInWithGoogle();

  Future<void> sendPasswordReset(SendPasswordResetUseCaseParams params);

  Future<void> signOut();

  Future<void> deleteAccount();
}
