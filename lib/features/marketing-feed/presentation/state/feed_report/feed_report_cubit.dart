import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class FeedReportState {
  final bool loading;
  final List<FeedReportedPost> reports;
  final String? error;

  /// Kiriman yang baru saya laporkan di sesi ini (tombol Laporkan jadi nonaktif sebelum daftar dimuat ulang).
  final Set<int> reportedIds;

  const FeedReportState({
    this.loading = false,
    this.reports = const [],
    this.error,
    this.reportedIds = const {},
  });

  FeedReportState copyWith({
    bool? loading,
    List<FeedReportedPost>? reports,
    String? error,
    Set<int>? reportedIds,
  }) {
    return FeedReportState(
      loading: loading ?? this.loading,
      reports: reports ?? this.reports,
      error: error,
      reportedIds: reportedIds ?? this.reportedIds,
    );
  }
}

/// Lapor kiriman (semua user) dan daftar laporan untuk approver (ApproveReject).
class FeedReportCubit extends Cubit<FeedReportState> {
  final MarketingFeedRepository repository;

  FeedReportCubit({required this.repository}) : super(const FeedReportState());

  /// Balikan: pesan error, atau null kalau laporan terkirim.
  Future<String?> report(int postId, String reason, String? note) async {
    final result = await repository.reportPost(postId, reason, note);
    return result.fold(
      (message) {
        // Server menolak laporan ganda: anggap sudah dilaporkan supaya tombol ikut nonaktif.
        if (message.toLowerCase().contains('sudah melaporkan')) _markReported(postId);
        return message;
      },
      (_) {
        _markReported(postId);
        return null;
      },
    );
  }

  void _markReported(int postId) {
    if (isClosed || state.reportedIds.contains(postId)) return;
    emit(state.copyWith(reportedIds: {...state.reportedIds, postId}));
  }

  Future<void> loadReports() async {
    emit(state.copyWith(loading: true));
    final result = await repository.getReportedPosts();
    if (isClosed) return;
    result.fold(
      (message) => emit(state.copyWith(loading: false, error: message)),
      (list) => emit(state.copyWith(loading: false, reports: list, error: null)),
    );
  }

  /// Balikan: pesan error, atau null kalau berhasil. Kiriman yang sudah diputuskan hilang dari daftar.
  Future<String?> decide(int postId, String action) async {
    final result = await repository.decideReport(postId, action);
    return result.fold((message) => message, (_) {
      emit(state.copyWith(reports: state.reports.where((r) => r.post.id != postId).toList()));
      return null;
    });
  }
}
