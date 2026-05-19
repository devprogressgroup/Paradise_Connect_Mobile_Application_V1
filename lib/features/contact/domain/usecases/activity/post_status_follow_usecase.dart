import 'package:dartz/dartz.dart';
import '../../repositories/contact_repository.dart';

class PostStatusFollowUseCase {
  final ContactRepository repository;

  PostStatusFollowUseCase(this.repository);

  Future<Either<String, void>> call(List<int> activityIds) async {
    return await repository.postStatusFollow(activityIds);
  }
}
