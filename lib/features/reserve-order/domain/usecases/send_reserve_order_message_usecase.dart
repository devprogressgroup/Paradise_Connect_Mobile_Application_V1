import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class SendReserveOrderMessageUseCase {
  final ReserveOrderRepository repository;

  SendReserveOrderMessageUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
    String message, {
    Uint8List? attachmentBytes,
    String? attachmentPath,
    String? attachmentName,
    int? contactAttachmentId,
  }) async {
    return await repository.sendReserveOrderMessage(
      reserveOrderId,
      message,
      attachmentBytes: attachmentBytes,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      contactAttachmentId: contactAttachmentId,
    );
  }
}
