import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart';
import 'reserve_unit_state.dart';

/// Step "Pilih Unit" di Reserve Order — dua sumber TERPISAH: katalog unit yang bisa dipilih baru
/// (`GET /api/reserve/unit-all`, cluster > produk > kavling, di-fetch bertahap sama seperti
/// `UnitPickerCubit` di fitur contact) dan unit yang SUDAH ADA buat kontak ini
/// (`GET /api/reserve/product-select`, buat auto-centang). Pola sama seperti `ReserveOrderListCubit`:
/// datasource langsung, tanpa layer usecase/repository.
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
      final clusters = await dataSource.getUnitTree(contactId: id, search: keyword.isEmpty ? null : keyword);

      // Fetch unit yang sudah ada buat kontak ini TERPISAH — gagal di sini tidak boleh
      // menyembunyikan katalog [clusters] yang sudah berhasil dimuat, cuma dicatat di
      // [ReserveUnitState.existingUnitsError] (ditampilkan sekali lewat snackbar).
      var existing = const <SelectedUnit>[];
      String? existingError;
      try {
        existing = await dataSource.getSelectedUnits(contactId: id);
      } catch (e) {
        existingError = cleanErrorMessage(e);
      }

      emit(state.copyWith(
        status: ReserveUnitStatus.loaded,
        clusters: clusters,
        existingUnits: existing,
        existingUnitsError: existingError,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReserveUnitStatus.error, error: cleanErrorMessage(e)));
    }
  }

  void setSearch(String value) => load(search: value.trim());

  void toggleCluster(int clusterId) {
    final s = Set<int>.from(state.expandedClusters);
    s.contains(clusterId) ? s.remove(clusterId) : s.add(clusterId);
    emit(state.copyWith(expandedClusters: s));
  }

  static String productKey(UnitProduct p) => '${p.companyId}|${p.productId}';

  Future<void> toggleProduct(UnitProduct product) async {
    final key = productKey(product);
    final s = Set<String>.from(state.expandedProducts);
    if (s.contains(key)) {
      s.remove(key);
      emit(state.copyWith(expandedProducts: s));
      return;
    }
    s.add(key);
    emit(state.copyWith(expandedProducts: s));
    if (!state.lotsByProduct.containsKey(key)) await loadLots(product);
  }

  /// Pastikan cluster [clusterId] & produk (`companyId|productId`) ke-expand — dipakai
  /// `_autoSelectAlreadyChosenUnits` di `reserve.dart` biar unit yang sudah ada (dari
  /// `GET /api/reserve/product-select`) langsung kelihatan tercentang di tree katalog begitu step
  /// "Pilih Unit" dibuka, bukan cuma nambah angka "N unit dipilih" di tree yang masih collapsed.
  /// Beda dari [toggleCluster]/[toggleProduct] yang TOGGLE, method ini cuma menambahkan (tidak
  /// pernah collapse yang sudah expanded).
  Future<void> expandProductFor({required int clusterId, required int companyId, required int productId}) async {
    final clusters = Set<int>.from(state.expandedClusters)..add(clusterId);
    final key = '$companyId|$productId';
    final products = Set<String>.from(state.expandedProducts)..add(key);
    emit(state.copyWith(expandedClusters: clusters, expandedProducts: products));

    if (state.lotsByProduct.containsKey(key)) return;
    for (final cluster in state.clusters) {
      if (cluster.projectId != clusterId) continue;
      for (final product in cluster.products) {
        if (product.productId == productId) {
          await loadLots(product);
          return;
        }
      }
    }
  }

  Future<void> loadLots(UnitProduct product) async {
    final id = _contactId;
    if (id == null) return;
    final key = productKey(product);
    emit(state.copyWith(loadingProductIds: {...state.loadingProductIds, key}));

    // `done` SENGAJA dihitung ulang dari `state.loadingProductIds` TERBARU di masing-masing cabang
    // di bawah (bukan sebelum `await`) — beberapa produk sering di-expand/di-load bersamaan (mis.
    // auto-expand banyak unit yang sudah ada sekaligus di `_autoSelectAlreadyChosenUnits`). Kalau
    // snapshot-nya diambil sebelum `await`, `loadLots` produk lain yang lagi jalan bareng bisa
    // ke-emit balik pakai snapshot basi begitu salah satunya lebih dulu selesai — override
    // `loadingProductIds` punya produk lain yang sebenarnya masih (atau sudah) loading.
    try {
      final lots = await dataSource.getUnitLots(
        productId: product.productId,
        townshipId: product.townshipId,
        companyId: product.companyId,
        contactId: id,
      );
      final map = Map<String, List<UnitLot>>.from(state.lotsByProduct)..[key] = lots;
      final done = Set<String>.from(state.loadingProductIds)..remove(key);
      emit(state.copyWith(lotsByProduct: map, loadingProductIds: done));
    } catch (e) {
      final done = Set<String>.from(state.loadingProductIds)..remove(key);
      emit(state.copyWith(loadingProductIds: done, error: cleanErrorMessage(e)));
    }
  }
}
