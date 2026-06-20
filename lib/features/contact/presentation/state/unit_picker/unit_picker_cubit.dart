import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/domain/usecases/unit/unit_picker_usecase.dart';
import 'unit_picker_state.dart';

/// Cubit Unit Picker (Model A) — tree cluster→tipe + lazy kavling per tipe + multi-select.
class UnitPickerCubit extends Cubit<UnitPickerState> {
  final GetUnitHierarchyUseCase getHierarchy;
  final GetUnitLotsUseCase getLots;

  int _townshipId = 0;
  String? townshipName;

  UnitPickerCubit(this.getHierarchy, this.getLots) : super(const UnitPickerState());

  /// Mulai picker untuk satu township + seleksi awal (saat edit).
  Future<void> init(int townshipId, {String? townshipName, List<SelectedUnit> initial = const []}) async {
    _townshipId = townshipId;
    this.townshipName = townshipName;
    final sel = {for (final u in initial) u.key: u};
    emit(const UnitPickerState().copyWith(selected: sel));
    await loadTree();
  }

  Future<void> loadTree() async {
    emit(state.copyWith(status: UnitPickerStatus.loading));
    final res = await getHierarchy(townshipId: _townshipId, search: state.search.isEmpty ? null : state.search);
    res.fold(
      (f) => emit(state.copyWith(status: UnitPickerStatus.error, errorMessage: f)),
      (clusters) => emit(state.copyWith(status: UnitPickerStatus.loaded, clusters: clusters)),
    );
  }

  void setSearch(String q) {
    emit(state.copyWith(search: q));
    loadTree();
  }

  void toggleCluster(int projectId) {
    final s = Set<int>.from(state.expandedClusters);
    s.contains(projectId) ? s.remove(projectId) : s.add(projectId);
    emit(state.copyWith(expandedClusters: s));
  }

  Future<void> toggleProduct(int productId) async {
    final s = Set<int>.from(state.expandedProducts);
    if (s.contains(productId)) {
      s.remove(productId);
      emit(state.copyWith(expandedProducts: s));
      return;
    }
    s.add(productId);
    emit(state.copyWith(expandedProducts: s));
    if (!state.lotsByProduct.containsKey(productId)) {
      await loadLots(productId);
    }
  }

  Future<void> loadLots(int productId) async {
    emit(state.copyWith(loadingProductIds: {...state.loadingProductIds, productId}));
    final res = await getLots(productId: productId);
    final done = Set<int>.from(state.loadingProductIds)..remove(productId);
    res.fold(
      (f) => emit(state.copyWith(loadingProductIds: done, errorMessage: f)),
      (lots) {
        final map = Map<int, List<UnitLot>>.from(state.lotsByProduct)..[productId] = lots;
        emit(state.copyWith(lotsByProduct: map, loadingProductIds: done));
      },
    );
  }

  // ── Seleksi ──────────────────────────────────────────────
  bool isSelected(String key) => state.selected.containsKey(key);
  List<SelectedUnit> get selectedList => state.selected.values.toList();

  void _toggle(SelectedUnit u) {
    final m = Map<String, SelectedUnit>.from(state.selected);
    m.containsKey(u.key) ? m.remove(u.key) : m[u.key] = u;
    emit(state.copyWith(selected: m));
  }

  void toggleLot(UnitCluster cluster, UnitProduct product, UnitLot lot) => _toggle(SelectedUnit(
        townshipId: _townshipId,
        clusterId: cluster.projectId,
        clusterName: cluster.projectName,
        productId: product.productId,
        productName: product.displayName,
        propertyId: lot.propertyId,
        propertyName: lot.propertyName,
        isTipeHoek: lot.isTipeHoek,
      ));

  void toggleWaiting(UnitCluster cluster, UnitProduct product) => _toggle(SelectedUnit(
        townshipId: _townshipId,
        clusterId: cluster.projectId,
        clusterName: cluster.projectName,
        productId: product.productId,
        productName: product.displayName,
        isWaitingList: true,
      ));

  void toggleUndecided(UnitCluster cluster, UnitProduct product) => _toggle(SelectedUnit(
        townshipId: _townshipId,
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
