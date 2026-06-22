import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

enum UnitPickerStatus { initial, loading, loaded, error }

class UnitPickerState extends Equatable {
  final UnitPickerStatus status;
  final List<UnitCluster> clusters;
  // Key produk = "companyId|productId" (KOMPOSIT) — 1 township bisa punya product_id sama beda company.
  final Map<String, List<UnitLot>> lotsByProduct; // key produk → kavling (lazy)
  final Set<String> loadingProductIds; // key produk yang lots-nya sedang dimuat
  final Set<int> expandedClusters; // projectId (unik per township → aman pakai int)
  final Set<String> expandedProducts; // key produk komposit
  final Map<String, SelectedUnit> selected; // key → unit terpilih
  final String search;
  final String? errorMessage;

  const UnitPickerState({
    this.status = UnitPickerStatus.initial,
    this.clusters = const [],
    this.lotsByProduct = const {},
    this.loadingProductIds = const {},
    this.expandedClusters = const {},
    this.expandedProducts = const {},
    this.selected = const {},
    this.search = '',
    this.errorMessage,
  });

  UnitPickerState copyWith({
    UnitPickerStatus? status,
    List<UnitCluster>? clusters,
    Map<String, List<UnitLot>>? lotsByProduct,
    Set<String>? loadingProductIds,
    Set<int>? expandedClusters,
    Set<String>? expandedProducts,
    Map<String, SelectedUnit>? selected,
    String? search,
    String? errorMessage,
  }) {
    return UnitPickerState(
      status: status ?? this.status,
      clusters: clusters ?? this.clusters,
      lotsByProduct: lotsByProduct ?? this.lotsByProduct,
      loadingProductIds: loadingProductIds ?? this.loadingProductIds,
      expandedClusters: expandedClusters ?? this.expandedClusters,
      expandedProducts: expandedProducts ?? this.expandedProducts,
      selected: selected ?? this.selected,
      search: search ?? this.search,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        clusters,
        lotsByProduct,
        loadingProductIds,
        expandedClusters,
        expandedProducts,
        selected,
        search,
        errorMessage,
      ];
}
