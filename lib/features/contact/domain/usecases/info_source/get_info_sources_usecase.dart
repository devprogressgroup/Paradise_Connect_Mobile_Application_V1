import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import '../../repositories/contact_repository.dart';

class GetInfoSourcesUseCase {
  final ContactRepository repository;
  GetInfoSourcesUseCase(this.repository);

  Future<Either<String, List<InfoSource>>> call({int? type, int? userId, String? salesChannel}) async {
    return await repository.getInfoSources(type: type, userId: userId, salesChannel: salesChannel);
  }
}