import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/repository/auth_repository.dart';

class DeleteAccountUseCase implements UseCase<void> {
  final AuthRepository repository;

  const DeleteAccountUseCase(this.repository);

  @override
  Future<void> call() => repository.deleteAccount();
}
