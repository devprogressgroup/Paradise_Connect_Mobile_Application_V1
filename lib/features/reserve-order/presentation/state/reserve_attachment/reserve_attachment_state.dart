import 'package:equatable/equatable.dart';

enum ReserveAttachmentStatus { initial, loading, loaded, error }

class ReserveAttachmentState extends Equatable {
  final ReserveAttachmentStatus status;

  /// Berapa berkas yang sudah selesai naik dari [total] — dipakai untuk teks tombol
  /// ("Mengunggah 1/3...") supaya user tahu prosesnya masih jalan.
  final int uploaded;
  final int total;

  final String? error;

  const ReserveAttachmentState({
    this.status = ReserveAttachmentStatus.initial,
    this.uploaded = 0,
    this.total = 0,
    this.error,
  });

  bool get isLoading => status == ReserveAttachmentStatus.loading;

  ReserveAttachmentState copyWith({
    ReserveAttachmentStatus? status,
    int? uploaded,
    int? total,
    String? error,
  }) {
    return ReserveAttachmentState(
      status: status ?? this.status,
      uploaded: uploaded ?? this.uploaded,
      total: total ?? this.total,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, uploaded, total, error];
}
