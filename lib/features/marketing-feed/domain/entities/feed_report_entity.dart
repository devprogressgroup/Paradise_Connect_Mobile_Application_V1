import 'package:equatable/equatable.dart';

/// Alasan laporan kiriman. Nilai [code] sama dengan yang disimpan di server (t_feed_report.reason).
enum FeedReportReason {
  spam('spam', 'Spam'),
  tidakPantas('tidak_pantas', 'Tidak pantas'),
  infoSalah('info_salah', 'Informasi salah'),
  sara('sara', 'SARA / sensitif'),
  lainnya('lainnya', 'Lainnya');

  final String code;
  final String label;
  const FeedReportReason(this.code, this.label);

  static String labelOf(String code) => FeedReportReason.values
      .firstWhere((r) => r.code == code, orElse: () => FeedReportReason.lainnya)
      .label;
}

/// Satu laporan dari pelapor (tanpa identitas pelapor).
class FeedReportNote extends Equatable {
  final String reason;
  final String? note;
  final DateTime createdAt;
  final String reporterName;

  const FeedReportNote({
    required this.reason,
    this.note,
    required this.createdAt,
    this.reporterName = 'User',
  });

  @override
  List<Object?> get props => [reason, note, createdAt, reporterName];
}
