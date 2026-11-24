import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/core/utils/helpers/impersonation_manager.dart';
import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';
import 'package:progress_group/features/app-menu/domain/usecases/get_app_menu_usecase.dart';
import 'app_menu_state.dart';

/// Menu sidebar murni dari server, disimpan di memori selama app berjalan.
///
/// - Menu yang sudah ada dipakai ulang (tanpa request) sampai app ditutup atau user logout.
/// - Setelah logout, cache dibuang supaya login berikutnya mengambil menu untuk user yang baru.
/// - Gagal dan belum ada menu: sidebar tanpa modul; percobaan ulang dibatasi [_retryInterval]
///   supaya server yang mati tidak memicu request di setiap pindah halaman.
class AppMenuCubit extends Cubit<AppMenuState> {
  final GetAppMenuUseCase getAppMenuUseCase;

  static const _retryInterval = Duration(seconds: 60);

  DateTime? _lastAttemptAt;
  Future<void>? _inFlight;

  /// Naik setiap [reset]; hasil request yang sudah tertinggal generasi dibuang.
  int _generation = 0;

  AppMenuCubit({required this.getAppMenuUseCase})
    : super(const AppMenuState()) {
    AppRouter.authNotifier.addListener(_onAuthChanged);
    ImpersonationManager.nameNotifier.addListener(_onImpersonationChanged);
  }

  /// Logout: cache dibuang, tidak ada request karena belum login.
  void _onAuthChanged() {
    if (!AppRouter.authNotifier.value) reset();
  }

  /// Mulai/berhenti impersonasi: menu milik user lain, jadi cache dibuang dan diambil ulang
  /// (kalau masih login, token sudah berganti).
  void _onImpersonationChanged() {
    reset();
    if (AppRouter.authNotifier.value) load();
  }

  /// Ambil menu kalau belum ada di memori. Dipanggil dari mana saja; tanpa request kalau sudah ada.
  Future<void> load() {
    final running = _inFlight;
    if (running != null) return running;
    if (state.menu != null) return Future.value();
    final last = _lastAttemptAt;
    if (last != null && DateTime.now().difference(last) < _retryInterval) {
      return Future.value();
    }
    final future = _load();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  /// Buang menu di memori (dipanggil saat logout).
  void reset() {
    _generation++;
    _inFlight = null;
    _lastAttemptAt = null;
    if (!isClosed) emit(const AppMenuState());
  }

  Future<void> _load() async {
    final generation = _generation;
    _lastAttemptAt = DateTime.now();
    emit(state.copyWith(isLoading: true));

    final result = await getAppMenuUseCase();
    if (isClosed || generation != _generation) return;

    final menu = result.fold<AppMenuEntity?>((_) => null, (r) => r);
    if (menu != null) {
      emit(AppMenuState(menu: menu));
      return;
    }

    emit(state.copyWith(isLoading: false));
  }

  @override
  Future<void> close() {
    AppRouter.authNotifier.removeListener(_onAuthChanged);
    ImpersonationManager.nameNotifier.removeListener(_onImpersonationChanged);
    return super.close();
  }
}
