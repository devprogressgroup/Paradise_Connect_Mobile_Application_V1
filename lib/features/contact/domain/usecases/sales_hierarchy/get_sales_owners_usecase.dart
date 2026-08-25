import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import '../../repositories/contact_repository.dart';

class GetSalesOwnersUseCase {
  final ContactRepository repository;
  GetSalesOwnersUseCase(this.repository);

  Future<Either<String, ({List<DropdownOption> data, int lastPage, int total})>> call({int page = 1, int perPage = 20, String? search}) {
    return repository.getSalesOwners(page: page, perPage: perPage, search: search);
  }
}
