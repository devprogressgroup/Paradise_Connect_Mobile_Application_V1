import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

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

/// Kiriman yang punya laporan terbuka, untuk daftar laporan approver.
class FeedReportedPost extends Equatable {
  final FeedPostEntity post;
  final int reportCount;
  final List<FeedReportNote> reports;

  const FeedReportedPost({required this.post, required this.reportCount, this.reports = const []});

  @override
  List<Object?> get props => [post, reportCount, reports];
}
