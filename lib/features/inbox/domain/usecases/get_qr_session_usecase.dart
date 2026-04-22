import '../repositories/inbox_contact_repository.dart';

class GetQrSessionUsecase {
  final InboxContactRepository repository;

  GetQrSessionUsecase(this.repository);

  Future<void> call({required String session}) {
    return repository.getQrSession(session: session);
  }
}
