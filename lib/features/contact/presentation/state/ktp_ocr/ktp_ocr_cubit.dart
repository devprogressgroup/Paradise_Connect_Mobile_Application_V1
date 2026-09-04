import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/datasources/ktp_ocr_remote_datasource.dart';
import 'ktp_ocr_state.dart';

class KtpOcrCubit extends Cubit<KtpOcrState> {
  final KtpOcrRemoteDataSource dataSource;

  KtpOcrCubit(this.dataSource) : super(const KtpOcrState());

  Future<void> scan({required Uint8List bytes, required String fileName}) async {
    emit(state.copyWith(status: KtpOcrStatus.loading));
    try {
      final result = await dataSource.scanKtp(bytes: bytes, fileName: fileName);
      emit(state.copyWith(status: KtpOcrStatus.loaded, result: result));
    } catch (e) {
      emit(KtpOcrState(status: KtpOcrStatus.error, error: cleanErrorMessage(e)));
    }
  }

  void reset() => emit(const KtpOcrState());
}
