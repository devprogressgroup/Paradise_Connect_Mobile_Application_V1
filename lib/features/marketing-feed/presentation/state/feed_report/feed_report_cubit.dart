import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class FeedReportState {
  final bool loading;
  final List<FeedReportedPost> reports;
  final String? error;

  const FeedReportState({this.loading = false, this.reports = const [], this.error});
}

/// Lapor kiriman (semua user) dan daftar laporan untuk approver (ApproveReject).
class FeedReportCubit extends Cubit<FeedReportState> {
  final MarketingFeedRepository repository;

  FeedReportCubit({required this.repository}) : super(const FeedReportState());

  /// Balikan: pesan error, atau null kalau laporan terkirim.
  Future<String?> report(int postId, String reason, String? note) async {
    final result = await repository.reportPost(postId, reason, note);
    return result.fold((message) => message, (_) => null);
  }

  Future<void> loadReports() async {
    emit(FeedReportState(loading: true, reports: state.reports));
    final result = await repository.getReportedPosts();
    if (isClosed) return;
    result.fold(
      (message) => emit(FeedReportState(error: message, reports: state.reports)),
      (list) => emit(FeedReportState(reports: list)),
    );
  }

  /// Balikan: pesan error, atau null kalau berhasil. Kiriman yang sudah diputuskan hilang dari daftar.
  Future<String?> decide(int postId, String action) async {
    final result = await repository.decideReport(postId, action);
    return result.fold((message) => message, (_) {
      emit(FeedReportState(reports: state.reports.where((r) => r.post.id != postId).toList()));
      return null;
    });
  }
}
