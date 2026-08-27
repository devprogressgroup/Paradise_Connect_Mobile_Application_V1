import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import '../../repositories/contact_repository.dart';

class GetSalesChannelDetailsUseCase {
  final ContactRepository repository;
  GetSalesChannelDetailsUseCase(this.repository);

  Future<Either<String, ({List<DropdownOption> data, int lastPage, int total})>> call({int page = 1, int perPage = 30, String? search}) async {
    return await repository.getSalesChannelDetails(page: page, perPage: perPage, search: search);
  }
}
