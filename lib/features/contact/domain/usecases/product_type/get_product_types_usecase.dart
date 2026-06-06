import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/repositories/contact_repository.dart';

class GetProductTypesUseCase {
  final ContactRepository repository;

  GetProductTypesUseCase(this.repository);

  Future<Either<String, List<String>>> call() async {
    return await repository.getProductTypes();
  }
}
