


class UnitCluster {
  final int projectId; 
  final int companyId; 
  final int townshipId;
  final String projectName;
  final List<UnitProduct> products;

  const UnitCluster({
    required this.projectId,
    this.companyId = 0,
    this.townshipId = 0,
    required this.projectName,
    this.products = const [],
  });

  factory UnitCluster.fromJson(Map<String, dynamic> j) => UnitCluster(
        projectId: j['project_id'] ?? 0,
        companyId: j['company_id'] ?? 0,
        townshipId: j['township_id'] ?? 0,
        projectName: (j['project_name'] ?? '').toString(),
        products: ((j['products'] as List?) ?? const [])
            .map((e) => UnitProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UnitProduct {
  final int productId; 
  final int companyId; 
  final int townshipId;
  final String? productName;
  final String displayName;
  final String? spec; 
  final int? productCategoryId;
  final double? luasBangunan;
  final int? jumlahLantai;
  final int? jumlahKamar;
  final int? jumlahKamarMandi;

  const UnitProduct({
    required this.productId,
    this.companyId = 0,
    this.townshipId = 0,
    this.productName,
    required this.displayName,
    this.spec,
    this.productCategoryId,
    this.luasBangunan,
    this.jumlahLantai,
    this.jumlahKamar,
    this.jumlahKamarMandi,
  });

  factory UnitProduct.fromJson(Map<String, dynamic> j) => UnitProduct(
        productId: j['product_id'] ?? 0,
        companyId: j['company_id'] ?? 0,
        townshipId: j['township_id'] ?? 0,
        productName: j['product_name']?.toString(),
        displayName: (j['display_name'] ?? j['product_name'] ?? '').toString(),
        spec: j['spec']?.toString(),
        productCategoryId: j['product_category_id'],
        luasBangunan: j['luas_bangunan'] is num ? (j['luas_bangunan'] as num).toDouble() : null,
        jumlahLantai: j['jumlah_lantai'],
        jumlahKamar: j['jumlah_kamar'],
        jumlahKamarMandi: j['jumlah_kamar_mandi'],
      );
}

class UnitLot {
  final int propertyId; 
  final String propertyName; 
  final double? propTotalArea; 
  final bool isTipeHoek; 
  final bool isTipeKhusus;
  final int? statusId; 

  const UnitLot({
    required this.propertyId,
    required this.propertyName,
    this.propTotalArea,
    this.isTipeHoek = false,
    this.isTipeKhusus = false,
    this.statusId,
  });

  factory UnitLot.fromJson(Map<String, dynamic> j) => UnitLot(
        propertyId: j['property_id'] ?? 0,
        propertyName: (j['property_name'] ?? '').toString(),
        propTotalArea: j['prop_total_area'] is num ? (j['prop_total_area'] as num).toDouble() : null,
        isTipeHoek: j['is_tipe_hoek'] == true || j['is_tipe_hoek'] == 1,
        isTipeKhusus: j['is_tipe_khusus'] == true || j['is_tipe_khusus'] == 1,
        statusId: j['status_id'],
      );
}


class SelectedUnit {
  final int townshipId; 
  final int companyId; 
  final int clusterId; 
  final String clusterName;
  final int? productId; 
  final String? productName;
  final int? propertyId; 
  final String? propertyName; 
  final bool isWaitingList;
  final bool isTipeHoek;

  const SelectedUnit({
    required this.townshipId,
    this.companyId = 0,
    required this.clusterId,
    required this.clusterName,
    this.productId,
    this.productName,
    this.propertyId,
    this.propertyName,
    this.isWaitingList = false,
    this.isTipeHoek = false,
    this.statusProspectId,
    this.lostDate,
  });

  
  final int? statusProspectId;
  
  final String? lostDate;

  
  factory SelectedUnit.fromContactJson(Map<String, dynamic> j) => SelectedUnit(
        townshipId: j['township_id'] ?? 0,
        companyId: j['company_id'] ?? 0,
        clusterId: j['cluster_id'] ?? 0,
        clusterName: (j['cluster_name'] ?? '').toString(),
        productId: j['product_id'],
        productName: j['product_name']?.toString(),
        propertyId: j['property_id'],
        propertyName: j['property_name']?.toString(),
        isWaitingList: j['is_waiting_list'] == true || j['is_waiting_list'] == 1,
        isTipeHoek: j['is_tipe_hoek'] == true || j['is_tipe_hoek'] == 1,
        statusProspectId: j['status_prospect_id'],
        lostDate: j['lost_date']?.toString(),
      );

  
  bool get isLost => lostDate != null && lostDate!.isNotEmpty;

  
  String get key =>
      '$clusterId|${productId ?? 0}|${propertyId ?? 0}|${isWaitingList ? 1 : 0}';

  
  String get label {
    final t = productName ?? '-';
    if (propertyId != null) return '$t · ${propertyName ?? propertyId}';
    if (isWaitingList) return '$t · Waiting list';
    return '$t · Belum tentukan kavling';
  }

  Map<String, dynamic> toApiJson() => {
        'township_id': townshipId,
        'company_id': companyId, 
        'cluster_id': clusterId,
        'product_id': productId,
        'property_id': propertyId,
        'is_waiting_list': isWaitingList,
      };
}
