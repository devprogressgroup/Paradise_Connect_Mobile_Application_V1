import 'package:dartz/dartz.dart';

import '../../repositories/contact_repository.dart';

class DeleteAttachmentUseCase {
  final ContactRepository repository;

  DeleteAttachmentUseCase(this.repository);

  Future<Either<String, void>> call({required int contactId,required int attachmentId,}) {
    return repository.deleteAttachment(contactId: contactId,attachmentId: attachmentId,);
  }
}