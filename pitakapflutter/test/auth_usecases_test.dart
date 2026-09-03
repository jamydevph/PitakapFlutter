import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/auth/domain/repository/auth_repository.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/delete_account_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_out_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_up_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/watch_user_details_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const diane = UserDetailsEntity(
  uid: 'uid-1',
  firstName: 'Diane',
  lastName: 'Magno',
  email: 'diane@pitakap.app',
);

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const LoginUseCaseParams(email: '', password: ''),
    );
    registerFallbackValue(
      const SignUpUseCaseParams(
        firstName: '',
        lastName: '',
        email: '',
        password: '',
      ),
    );
    registerFallbackValue(const SendPasswordResetUseCaseParams(email: ''));
  });

  setUp(() => repository = MockAuthRepository());

  group('LoginUserUseCase', () {
    const params = LoginUseCaseParams(
      email: 'diane@pitakap.app',
      password: 'secret123',
    );

    test('returns the user the repository resolves', () async {
      when(() => repository.login(any())).thenAnswer((_) async => diane);

      final result = await LoginUserUseCase(repository).call(params);

      expect(result, diane);
      verify(() => repository.login(params)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('passes the params through untouched', () async {
      when(() => repository.login(any())).thenAnswer((_) async => diane);

      await LoginUserUseCase(repository).call(params);

      final captured =
          verify(() => repository.login(captureAny())).captured.single
              as LoginUseCaseParams;

      expect(captured.email, 'diane@pitakap.app');
      expect(captured.password, 'secret123');
    });

    test('lets repository failures propagate untouched', () {
      when(() => repository.login(any())).thenThrow(
        const ServerFailure('Incorrect email or password'),
      );

      expect(
        () => LoginUserUseCase(repository).call(params),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.message,
            'message',
            'Incorrect email or password',
          ),
        ),
      );
    });
  });

  group('SignUpUserUseCase', () {
    const params = SignUpUseCaseParams(
      firstName: 'Diane',
      lastName: 'Magno',
      email: 'diane@pitakap.app',
      password: 'secret123',
    );

    test('returns the created profile', () async {
      when(() => repository.signUp(any())).thenAnswer((_) async => diane);

      final result = await SignUpUserUseCase(repository).call(params);

      expect(result, diane);
      verify(() => repository.signUp(params)).called(1);
    });

    test('carries every field the form collected', () async {
      when(() => repository.signUp(any())).thenAnswer((_) async => diane);

      await SignUpUserUseCase(repository).call(params);

      final captured =
          verify(() => repository.signUp(captureAny())).captured.single
              as SignUpUseCaseParams;

      expect(captured.firstName, 'Diane');
      expect(captured.lastName, 'Magno');
      expect(captured.email, 'diane@pitakap.app');
      expect(captured.password, 'secret123');
    });

    test('lets a duplicate-email failure propagate', () {
      when(() => repository.signUp(any())).thenThrow(
        const ServerFailure('That email is already registered'),
      );

      expect(
        () => SignUpUserUseCase(repository).call(params),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('SendPasswordResetUseCase', () {
    const params = SendPasswordResetUseCaseParams(
      email: 'diane@pitakap.app',
    );

    test('delegates to the repository', () async {
      when(() => repository.sendPasswordReset(any()))
          .thenAnswer((_) async {});

      await SendPasswordResetUseCase(repository).call(params);

      verify(() => repository.sendPasswordReset(params)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('lets failures propagate', () {
      when(() => repository.sendPasswordReset(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => SendPasswordResetUseCase(repository).call(params),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('SignOutUseCase', () {
    test('delegates to the repository and takes no params', () async {
      when(() => repository.signOut()).thenAnswer((_) async {});

      await SignOutUseCase(repository).call();

      verify(() => repository.signOut()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('lets failures propagate', () {
      when(() => repository.signOut())
          .thenThrow(const UnknownFailure('boom'));

      expect(
        () => SignOutUseCase(repository).call(),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('DeleteAccountUseCase', () {
    test('delegates to the repository and takes no params', () async {
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await DeleteAccountUseCase(repository).call();

      verify(() => repository.deleteAccount()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('⭐ it is NOT sign out — the two must never be confused', () async {
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await DeleteAccountUseCase(repository).call();

      verifyNever(() => repository.signOut());
    });

    test('⭐ a stale-login failure propagates so the UI can ask for a re-login', () {
      when(() => repository.deleteAccount())
          .thenThrow(const ServerFailure('Please sign in again to continue'));

      expect(
        () => DeleteAccountUseCase(repository).call(),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.message,
            'message',
            'Please sign in again to continue',
          ),
        ),
      );
    });

    test('a raw error is not swallowed into a success', () {
      when(() => repository.deleteAccount()).thenThrow(StateError('internal'));

      expect(
        () => DeleteAccountUseCase(repository).call(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('WatchAuthStateUseCase', () {
    test('forwards the repository stream', () {
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.value('uid-1'));

      expect(WatchAuthStateUseCase(repository).call(), emits('uid-1'));
    });

    test('⭐ a signed-out session is null, not an empty string', () {
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      expect(WatchAuthStateUseCase(repository).call(), emits(isNull));
    });

    test('⭐ sign-in then sign-out arrives as an ordered sequence', () {
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.fromIterable(['uid-1', null, 'uid-2']));

      expect(
        WatchAuthStateUseCase(repository).call(),
        emitsInOrder(['uid-1', null, 'uid-2']),
      );
    });

    test('lets stream failures propagate', () {
      when(() => repository.authStateChanges()).thenAnswer(
        (_) => Stream.error(const NetworkFailure('No internet connection')),
      );

      expect(
        WatchAuthStateUseCase(repository).call(),
        emitsError(isA<NetworkFailure>()),
      );
    });
  });

  group('WatchUserDetailsUseCase', () {
    test('forwards the stream for the requested uid', () {
      when(
        () => repository.watchUserDetails(any()),
      ).thenAnswer((_) => Stream.value(diane));

      expect(WatchUserDetailsUseCase(repository).call('uid-1'), emits(diane));
      verify(() => repository.watchUserDetails('uid-1')).called(1);
    });

    test('⭐ a missing profile document emits null rather than erroring', () {
      when(
        () => repository.watchUserDetails(any()),
      ).thenAnswer((_) => Stream.value(null));

      expect(WatchUserDetailsUseCase(repository).call('uid-1'), emits(isNull));
    });

    test('the uid is passed through untouched', () async {
      when(
        () => repository.watchUserDetails(any()),
      ).thenAnswer((_) => Stream.value(diane));

      WatchUserDetailsUseCase(repository).call('  uid-with-space  ');

      final captured = verify(
        () => repository.watchUserDetails(captureAny()),
      ).captured.single;

      expect(captured, '  uid-with-space  ');
    });

    test('lets stream failures propagate', () {
      when(() => repository.watchUserDetails(any())).thenAnswer(
        (_) => Stream.error(const ServerFailure('permission denied')),
      );

      expect(
        WatchUserDetailsUseCase(repository).call('uid-1'),
        emitsError(isA<ServerFailure>()),
      );
    });
  });
}
