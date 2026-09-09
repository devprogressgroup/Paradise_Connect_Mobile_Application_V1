import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart';
import 'reserve_unit_state.dart';

/// Daftar unit (per deal milik kontak) untuk step "Pilih Unit" di Reserve Order — `GET
/// /api/reserve/unit-status`. Pola sama seperti `ReserveOrderListCubit`: datasource langsung, tanpa
/// layer usecase/repository.
class ReserveUnitCubit extends Cubit<ReserveUnitState> {
  final ReserveUnitRemoteDataSource dataSource;

  int? _contactId;

  ReserveUnitCubit(this.dataSource) : super(const ReserveUnitState());

  Future<void> load({int? contactId, String? search}) async {
    // Cubit ini singleton (satu instance dibagi lintas halaman lewat provider di `main.dart`) —
    // begitu Reserve Order dibuka untuk kontak yang BEDA dari sesi sebelumnya, state-nya di-reset
    // total (bukan `copyWith`) supaya unit kontak lama tidak nyangkut kelihatan di kontak baru.
    final isNewContact = contactId != null && contactId != _contactId;
    if (contactId != null) _contactId = contactId;
    final id = _contactId;
    if (id == null) return;

    final keyword = search ?? (isNewContact ? '' : state.search);
    emit(isNewContact
        ? ReserveUnitState(status: ReserveUnitStatus.loading, search: keyword)
        : state.copyWith(status: ReserveUnitStatus.loading, search: keyword));

    try {
      final result = await dataSource.getUnits(contactId: id, search: keyword, page: 1);
      emit(state.copyWith(
        status: ReserveUnitStatus.loaded,
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReserveUnitStatus.error, error: cleanErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final id = _contactId;
    if (id == null || state.loadingMore || !state.hasMore || state.status != ReserveUnitStatus.loaded) {
      return;
    }

    emit(state.copyWith(loadingMore: true));
    try {
      final result = await dataSource.getUnits(
        contactId: id,
        search: state.search,
        page: state.page + 1,
      );
      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      // Gagal load halaman berikutnya tidak mengosongkan daftar yang sudah tampil.
      emit(state.copyWith(loadingMore: false));
    }
  }

  void setSearch(String value) => load(search: value.trim());
}
