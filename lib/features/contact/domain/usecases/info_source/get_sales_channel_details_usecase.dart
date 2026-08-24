import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import '../../repositories/contact_repository.dart';

class GetSalesChannelDetailsUseCase {
  final ContactRepository repository;
  GetSalesChannelDetailsUseCase(this.repository);

  Future<Either<String, List<InfoSource>>> call() async {
    return await repository.getSalesChannelDetails();
  }
}
