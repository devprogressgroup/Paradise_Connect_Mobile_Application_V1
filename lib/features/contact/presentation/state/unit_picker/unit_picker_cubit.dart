import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/domain/usecases/unit/unit_picker_usecase.dart';
import 'unit_picker_state.dart';


class UnitPickerCubit extends Cubit<UnitPickerState> {
  final GetUnitHierarchyUseCase getHierarchy;
  final GetUnitLotsUseCase getLots;

  int _townshipId = 0;
  String? townshipName;
  bool _requireKavling = false;

  UnitPickerCubit(this.getHierarchy, this.getLots) : super(const UnitPickerState());


  Future<void> init(
    int townshipId, {
    String? townshipName,
    List<SelectedUnit> initial = const [],
    bool requireKavling = false,
  }) async {
    _townshipId = townshipId;
    this.townshipName = townshipName;
    _requireKavling = requireKavling;
    // Placeholder bawaan kontak langsung dibuang kalau sudah ada unit pasti.
    final hasDecided = initial.any((u) => !u.isUndecided);
    final sel = {
      for (final u in initial)
        if (!(hasDecided && _isPlaceholder(u))) u.key: u,
    };
    emit(const UnitPickerState().copyWith(selected: sel));
    await loadTree();
  }

  // Batas tipe yang di-expand otomatis saat search, supaya kata kunci yang terlalu umum
  // tidak memicu banyak request kavling sekaligus (cluster tetap di-expand semua).
  static const _autoExpandMaxProducts = 10;

  Future<void> loadTree() async {
    final search = state.search;
    emit(state.copyWith(status: UnitPickerStatus.loading));
    final res = await getHierarchy(townshipId: _townshipId, search: search.isEmpty ? null : search);
    // Respons kata kunci lama dibuang kalau user sudah mengetik kata kunci baru.
    if (search != state.search) return;
    res.fold(
      (f) => emit(state.copyWith(status: UnitPickerStatus.error, errorMessage: f)),
      (clusters) {
        emit(state.copyWith(status: UnitPickerStatus.loaded, clusters: clusters));
        if (search.isNotEmpty) _autoExpand(clusters);
      },
    );
  }

  // Hasil search langsung dibuka sampai level kavling supaya yang cocok langsung kelihatan.
  void _autoExpand(List<UnitCluster> clusters) {
    final products = [for (final c in clusters) ...c.products];
    final expandProducts = products.length <= _autoExpandMaxProducts;
    emit(state.copyWith(
      expandedClusters: {for (final c in clusters) c.projectId},
      expandedProducts: expandProducts ? {for (final p in products) productKey(p)} : const {},
    ));
    if (!expandProducts) return;
    for (final p in products) {
      loadLots(p);
    }
  }

  void setSearch(String q) {
    if (q == state.search) return;
    // Cache kavling ikut terfilter search → dibuang tiap ganti kata kunci, expand juga di-reset.
    emit(state.copyWith(
      search: q,
      lotsByProduct: const {},
      loadingProductIds: const {},
      expandedClusters: const {},
      expandedProducts: const {},
    ));
    loadTree();
  }

  void toggleCluster(int projectId) {
    final s = Set<int>.from(state.expandedClusters);
    s.contains(projectId) ? s.remove(projectId) : s.add(projectId);
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
    if (!state.lotsByProduct.containsKey(key)) {
      await loadLots(product);
    }
  }

  Future<void> loadLots(UnitProduct product) async {
    final key = productKey(product);
    final search = state.search;
    emit(state.copyWith(loadingProductIds: {...state.loadingProductIds, key}));

    // BE: cari nama cluster/tipe → semua kavlingnya; cari nama kavling → hanya yang cocok.
    final res = await getLots(
      productId: product.productId,
      townshipId: product.townshipId != 0 ? product.townshipId : _townshipId,
      companyId: product.companyId,
      search: search.isEmpty ? null : search,
    );
    if (search != state.search) return;
    final done = Set<String>.from(state.loadingProductIds)..remove(key);
    res.fold(
      (f) => emit(state.copyWith(loadingProductIds: done, errorMessage: f)),
      (lots) {
        final map = Map<String, List<UnitLot>>.from(state.lotsByProduct)..[key] = lots;
        emit(state.copyWith(lotsByProduct: map, loadingProductIds: done));
      },
    );
  }

  
  // "Belum tentukan kavling" bawaan kontak (tanpa produk). Pilihan "Belum menentukan kavling"
  // dari picker selalu membawa produk, jadi tidak termasuk di sini.
  static bool _isPlaceholder(SelectedUnit u) => u.isUndecided && u.productId == null;

  bool isSelected(String key) => state.selected.containsKey(key);
  List<SelectedUnit> get selectedList => state.selected.values.toList();

  void _toggle(SelectedUnit u) {
    final m = Map<String, SelectedUnit>.from(state.selected);
    if (m.containsKey(u.key)) {
      m.remove(u.key);
    } else {
      m[u.key] = u;
      // Begitu unit pasti (kavling / waiting list) dipilih, placeholder "belum tentukan kavling"
      // dibuang supaya tidak ikut dikirim ke BE. "Belum menentukan kavling" yang memang dipilih
      // user tetap dipertahankan, kecuali di mode wajib kavling (semua undecided dibuang).
      if (!u.isUndecided) {
        m.removeWhere((_, s) => _requireKavling ? s.isUndecided : _isPlaceholder(s));
      }
    }
    emit(state.copyWith(selected: m));
  }

  
  void toggleLot(UnitCluster cluster, UnitProduct product, UnitLot lot) => _toggle(SelectedUnit(
        townshipId: cluster.townshipId != 0 ? cluster.townshipId : _townshipId,
        companyId: cluster.companyId,
        clusterId: cluster.projectId,
        clusterName: cluster.projectName,
        productId: product.productId,
        productName: product.displayName,
        propertyId: lot.propertyId,
        propertyName: lot.propertyName,
        isTipeHoek: lot.isTipeHoek,
      ));

  void toggleWaiting(UnitCluster cluster, UnitProduct product) => _toggle(SelectedUnit(
        townshipId: cluster.townshipId != 0 ? cluster.townshipId : _townshipId,
        companyId: cluster.companyId,
        clusterId: cluster.projectId,
        clusterName: cluster.projectName,
        productId: product.productId,
        productName: product.displayName,
        isWaitingList: true,
      ));

  void toggleUndecided(UnitCluster cluster, UnitProduct product) => _toggle(SelectedUnit(
        townshipId: cluster.townshipId != 0 ? cluster.townshipId : _townshipId,
        companyId: cluster.companyId,
        clusterId: cluster.projectId,
        clusterName: cluster.projectName,
        productId: product.productId,
        productName: product.displayName,
      ));

  void removeKey(String key) {
    final m = Map<String, SelectedUnit>.from(state.selected)..remove(key);
    emit(state.copyWith(selected: m));
  }
}
