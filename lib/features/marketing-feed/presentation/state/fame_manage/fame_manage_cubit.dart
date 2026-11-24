import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';
import 'fame_manage_state.dart';

/// Halaman kelola Wall of Fame (admin mobile): hak akses dari backend, daftar program + kartu,
/// dan aksi per kartu (tayangkan, ke draf, hapus, unggah/hapus poster).
class FameManageCubit extends Cubit<FameManageState> {
  final MarketingFeedRepository repository;

  FameManageCubit({required this.repository}) : super(const FameManageState());

  /// Memuat hak akses, lalu daftar kartu kalau boleh mengubah.
  Future<void> load() async {
    emit(state.copyWith(status: FameManageStatus.loading));
    final accessResult = await repository.getFameAccess();
    if (isClosed) return;

    String? error;
    FameAccessEntity? access;
    accessResult.fold((m) => error = m, (a) => access = a);
    if (error != null || access == null) {
      emit(
        state.copyWith(
          status: FameManageStatus.error,
          errorMessage: error ?? 'Gagal mengambil hak akses Wall of Fame.',
        ),
      );
      return;
    }
    if (!access!.canEdit) {
      emit(FameManageState(status: FameManageStatus.loaded, access: access));
      return;
    }
    await _reloadPrograms(access);
  }

  Future<void> _reloadPrograms([FameAccessEntity? access]) async {
    final result = await repository.getFameManage();
    if (isClosed) return;
    String? error;
    List<FameManageProgramEntity>? programs;
    result.fold((m) => error = m, (p) => programs = p);
    if (error != null) {
      // Hak akses sudah valid walau daftar program gagal: jangan hilangkan izin user (sumber tombol & filter Wall of Fame).
      emit(
        state.copyWith(
          status: FameManageStatus.error,
          errorMessage: error,
          access: access ?? state.access,
          busy: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: FameManageStatus.loaded,
        access: access ?? state.access,
        programs: programs ?? const [],
        busy: false,
      ),
    );
  }

  /// Menjalankan satu aksi lalu memuat ulang daftar. Balikan: pesan error, atau null kalau berhasil.
  Future<String?> _run(Future<void> Function() action) async {
    emit(state.copyWith(busy: true));
    String? error;
    final result = await _capture(action);
    if (isClosed) return null;
    error = result;
    if (error != null) {
      emit(state.copyWith(busy: false));
      return error;
    }
    await _reloadPrograms();
    return null;
  }

  Future<String?> _capture(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Aksi cepat per kartu. Balikan null kalau berhasil.
  Future<String?> setStatus(int cardId, String status) => _run(() async {
    final r = await repository.setFameCardStatus(cardId, status, null);
    r.fold((m) => throw m, (_) {});
  });

  Future<String?> deleteCard(int cardId) => _run(() async {
    final r = await repository.deleteFameCard(cardId);
    r.fold((m) => throw m, (_) {});
  });

  Future<String?> deleteCardPoster(int cardId) => _run(() async {
    final r = await repository.deleteFameCardMedia(cardId);
    r.fold((m) => throw m, (_) {});
  });

  Future<String?> uploadCardPoster(int cardId, FeedMediaEntity media) =>
      _run(() async {
        final r = await repository.uploadFameCardMedia(cardId, media);
        r.fold((m) => throw m, (_) {});
      });
}
