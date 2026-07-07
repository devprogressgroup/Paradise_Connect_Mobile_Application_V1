import 'package:dartz/dartz.dart'; 
import '../../entities/attachment/attachment_type.dart';
import '../../repositories/contact_repository.dart';

class GetAttachmentTypesUseCase {
  final ContactRepository repository;

  GetAttachmentTypesUseCase(this.repository);

  
  
  Future<Either<String, List<AttachmentType>>> call() async {
    return await repository.getAttachmentTypes();
  }
}