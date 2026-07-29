import '../repositories/inbox_contact_repository.dart';

class RequestPairCodeUsecase {
  final InboxContactRepository repository;

  RequestPairCodeUsecase(this.repository);

  Future<void> call({required String session}) {
    return repository.requestPairCode(session: session);
  }
}
