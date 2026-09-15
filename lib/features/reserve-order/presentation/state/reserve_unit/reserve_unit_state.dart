import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

enum ReserveUnitStatus { initial, loading, loaded, error }

class ReserveUnitState extends Equatable {
  final ReserveUnitStatus status;

  /// Katalog cluster > produk dari `GET /api/reserve/unit-all?contact_id=…` — buat pilih unit BARU.
  final List<UnitCluster> clusters;
  final Set<int> expandedClusters;
  final Set<String> expandedProducts;
  final Map<String, List<UnitLot>> lotsByProduct;
  final Set<String> loadingProductIds;

  /// Deal/unit yang SUDAH ADA buat kontak ini (`GET /api/reserve/product-select`) — terpisah dari
  /// [clusters], dipakai buat auto-centang & seksi "Unit yang Sudah Dipilih Sebelumnya".
  final List<SelectedUnit> existingUnits;

  /// Pesan error dari fetch [existingUnits] — non-blocking (katalog [clusters] tetap tampil kalau
  /// ini gagal), cuma buat dikasih tau lewat snackbar sekali di `ReservePage`.
  final String? existingUnitsError;

  final String search;
  final String? error;

  const ReserveUnitState({
    this.status = ReserveUnitStatus.initial,
    this.clusters = const [],
    this.expandedClusters = const {},
    this.expandedProducts = const {},
    this.lotsByProduct = const {},
    this.loadingProductIds = const {},
    this.existingUnits = const [],
    this.existingUnitsError,
    this.search = '',
    this.error,
  });

  bool get isLoading => status == ReserveUnitStatus.loading;

  ReserveUnitState copyWith({
    ReserveUnitStatus? status,
    List<UnitCluster>? clusters,
    Set<int>? expandedClusters,
    Set<String>? expandedProducts,
    Map<String, List<UnitLot>>? lotsByProduct,
    Set<String>? loadingProductIds,
    List<SelectedUnit>? existingUnits,
    String? existingUnitsError,
    String? search,
    String? error,
  }) {
    return ReserveUnitState(
      status: status ?? this.status,
      clusters: clusters ?? this.clusters,
      expandedClusters: expandedClusters ?? this.expandedClusters,
      expandedProducts: expandedProducts ?? this.expandedProducts,
      lotsByProduct: lotsByProduct ?? this.lotsByProduct,
      loadingProductIds: loadingProductIds ?? this.loadingProductIds,
      existingUnits: existingUnits ?? this.existingUnits,
      // Sengaja tidak `?? this.existingUnitsError` (sama pola dengan `error`) — begitu fetch-nya
      // diulang & kali ini berhasil, errornya mesti reset ke null, bukan nyangkut dari percobaan
      // sebelumnya.
      existingUnitsError: existingUnitsError,
      search: search ?? this.search,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        clusters,
        expandedClusters,
        expandedProducts,
        lotsByProduct,
        loadingProductIds,
        existingUnits,
        existingUnitsError,
        search,
        error,
      ];
}
