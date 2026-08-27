import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import '../../repositories/contact_repository.dart';

class GetSalesManagersUseCase {
  final ContactRepository repository;
  GetSalesManagersUseCase(this.repository);

  Future<Either<String, ({List<DropdownOption> data, int lastPage, int total})>> call({int page = 1, int perPage = 20, String? search}) {
    return repository.getSalesManagers(page: page, perPage: perPage, search: search);
  }
}
