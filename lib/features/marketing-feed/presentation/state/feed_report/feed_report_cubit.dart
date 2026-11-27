import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class FeedReportState {
  /// Kiriman yang baru saya laporkan di sesi ini (tombol Laporkan jadi nonaktif sebelum daftar dimuat ulang).
  final Set<int> reportedIds;

  /// Kartu Wall of Fame yang baru saya laporkan di sesi ini (id kartu, terpisah dari id kiriman).
  final Set<int> reportedFameIds;

  const FeedReportState({
    this.reportedIds = const {},
    this.reportedFameIds = const {},
  });

  FeedReportState copyWith({
    Set<int>? reportedIds,
    Set<int>? reportedFameIds,
  }) {
    return FeedReportState(
      reportedIds: reportedIds ?? this.reportedIds,
      reportedFameIds: reportedFameIds ?? this.reportedFameIds,
    );
  }
}

/// Lapor kiriman dan kartu Wall of Fame (semua user), serta keputusan approver (ApproveReject).
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

  /// Lapor kartu Wall of Fame — POST wall-of-fame/cards/{id}/report. Balikan sama seperti [report].
  Future<String?> reportFame(int cardId, String reason, String? note) async {
    final result = await repository.reportFameCard(cardId, reason, note);
    return result.fold(
      (message) {
        if (message.toLowerCase().contains('sudah melaporkan')) _markFameReported(cardId);
        return message;
      },
      (_) {
        _markFameReported(cardId);
        return null;
      },
    );
  }

  void _markReported(int postId) {
    if (isClosed || state.reportedIds.contains(postId)) return;
    emit(state.copyWith(reportedIds: {...state.reportedIds, postId}));
  }

  void _markFameReported(int cardId) {
    if (isClosed || state.reportedFameIds.contains(cardId)) return;
    emit(state.copyWith(reportedFameIds: {...state.reportedFameIds, cardId}));
  }

  /// Balikan: pesan error, atau null kalau berhasil.
  /// [kind] = post (default) atau fame; [id] = id kiriman atau id kartu sesuai kind.
  Future<String?> decide(int id, String action, {String kind = 'post'}) async {
    final result = await repository.decideReport(id, action, kind: kind);
    return result.fold((message) => message, (_) => null);
  }
}
