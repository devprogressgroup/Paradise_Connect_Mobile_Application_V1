import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class OcrKtpUseCase {
  final ReserveOrderRepository repository;

  OcrKtpUseCase(this.repository);

  Future<Either<String, Map<String, dynamic>>> call(
    Uint8List imageBytes, {
    String? filename,
  }) async {
    return await repository.ocrKtp(imageBytes, filename: filename);
  }
}
