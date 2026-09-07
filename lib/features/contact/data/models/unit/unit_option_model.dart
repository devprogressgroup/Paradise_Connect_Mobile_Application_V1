import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

/// Satu kavling di daftar "Pilih Unit" (Reserve Order) — hasil `GET /property/units/hierarchy`
/// mode `flat=1`, yaitu daftar kavling se-township yang bisa dicari langsung tanpa menelusuri
/// cluster → tipe dulu.
///
/// Beda dari [UnitLot] (mode LOTS, per tipe) yang cuma membawa property + status_id: di sini nama
/// cluster/produk dan NAMA status ikut, karena barisnya berdiri sendiri di daftar.
class UnitOption {
  final int propertyId;
  final String propertyName;
  final double? propTotalArea;
  final int? statusId;
  final String? statusName;

  /// Dihitung di server (status = "Available"). Kavling non-available tidak bisa dipilih.
  final bool isAvailable;

  final int productId;
  final String productName;
  final int clusterId;
  final String clusterName;
  final int townshipId;
  final int companyId;

  const UnitOption({
    required this.propertyId,
    required this.propertyName,
    this.propTotalArea,
    this.statusId,
    this.statusName,
    this.isAvailable = false,
    required this.productId,
    required this.productName,
    required this.clusterId,
    required this.clusterName,
    required this.townshipId,
    required this.companyId,
  });

  factory UnitOption.fromJson(Map<String, dynamic> json) {
    return UnitOption(
      propertyId: _int(json['property_id']),
      propertyName: (json['property_name'] ?? '').toString(),
      propTotalArea: json['prop_total_area'] is num ? (json['prop_total_area'] as num).toDouble() : null,
      statusId: json['status_id'] == null ? null : _int(json['status_id']),
      statusName: json['status_name']?.toString(),
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      productId: _int(json['product_id']),
      productName: (json['product_name'] ?? '').toString(),
      clusterId: _int(json['cluster_id']),
      clusterName: (json['cluster_name'] ?? '').toString(),
      townshipId: _int(json['township_id']),
      companyId: _int(json['company_id']),
    );
  }

  /// Baris kedua di kartu unit: "Cluster · Produk · 150 m²".
  ///
  /// Mockup menampilkan harga di posisi ini, tapi harga TIDAK ada di database inventory
  /// (`m_property_lot`/`m_sellable_unit`) — sumbernya relay Paradise Dynamics Web2 lewat
  /// `POST /api/property-pricing`, satu request per unit, jadi tidak bisa dipakai untuk daftar.
  /// Luas dipakai sebagai gantinya sampai ada endpoint harga massal.
  String get subtitle {
    final area = propTotalArea;
    return [
      if (clusterName.isNotEmpty) clusterName,
      if (productName.isNotEmpty) productName,
      if (area != null && area > 0) '${area % 1 == 0 ? area.toInt() : area} m²',
    ].join(' · ');
  }

  /// Kunci pembanding pilihan — sama seperti [SelectedUnit.key], property_id saja tidak cukup
  /// karena bisa sama di company yang berbeda.
  String get key => '$townshipId|$companyId|$productId|$propertyId';

  SelectedUnit toSelectedUnit() => SelectedUnit(
        townshipId: townshipId,
        companyId: companyId,
        clusterId: clusterId,
        clusterName: clusterName,
        productId: productId,
        productName: productName,
        propertyId: propertyId,
        propertyName: propertyName,
      );

  static int _int(dynamic value) => value is int ? value : (int.tryParse('${value ?? ''}') ?? 0);
}

class UnitOptionsPage {
  final List<UnitOption> items;
  final int page;
  final bool hasMore;

  const UnitOptionsPage({required this.items, required this.page, required this.hasMore});
}
