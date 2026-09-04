import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/ktp/ktp_ocr_model.dart';

enum KtpOcrStatus { initial, loading, loaded, error }

class KtpOcrState extends Equatable {
  final KtpOcrStatus status;
  final KtpOcrModel? result;
  final String? error;

  const KtpOcrState({
    this.status = KtpOcrStatus.initial,
    this.result,
    this.error,
  });

  bool get isLoading => status == KtpOcrStatus.loading;

  KtpOcrState copyWith({
    KtpOcrStatus? status,
    KtpOcrModel? result,
    String? error,
  }) {
    return KtpOcrState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, result, error];
}
