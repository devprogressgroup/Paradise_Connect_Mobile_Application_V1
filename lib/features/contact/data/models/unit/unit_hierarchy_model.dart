


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
    this.dealId,
    this.statusName,
    this.dealValue,
    this.isPropertySellable = true,
  });


  final int? statusProspectId;

  final String? lostDate;

  /// Id deal yang menghasilkan baris ini — cuma keisi dari [fromUnitStatusJson] (`GET
  /// /api/reserve/unit-status`, satu baris per deal). Null buat unit dari [fromContactJson] atau
  /// dari unit picker contact-add.
  final int? dealId;

  /// Nama status deal-nya (mis. "Hold") dari [fromUnitStatusJson] — dipakai badge di step "Pilih
  /// Unit" lewat `UnitStatusBadge`. Null buat sumber lain.
  final String? statusName;

  /// Nominal deal — dipakai sebagai harga di baris kedua kartu step "Pilih Unit". Null/0 tidak
  /// ditampilkan.
  final num? dealValue;

  /// Dari `is_property_sellable` — kavling yang sudah tidak sellable (mis. sudah SP/akad kontak
  /// lain) tetap tampil tapi pudar & tidak bisa dicentang di step "Pilih Unit". Default true supaya
  /// sumber lain ([fromContactJson], unit picker contact-add) yang tidak punya field ini tetap bisa
  /// dipilih seperti sebelumnya.
  final bool isPropertySellable;


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

  /// Satu baris (per deal) dari `GET /api/reserve/unit-status?contact_id=…` — step "Pilih Unit" di
  /// form Reserve. Beda dari [fromContactJson]: cluster/product/property-nya bisa null sekaligus
  /// (deal yang belum ditentukan kavlingnya), makanya di-`?? 0` sama seperti field lain yang
  /// nullable di sini.
  factory SelectedUnit.fromUnitStatusJson(Map<String, dynamic> j) => SelectedUnit(
        dealId: j['deal_id'],
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
        statusName: j['status_name']?.toString(),
        dealValue: j['deal_value'] is num ? j['deal_value'] as num : num.tryParse('${j['deal_value']}'),
        isPropertySellable: j['is_property_sellable'] == null
            ? true
            : (j['is_property_sellable'] == true || j['is_property_sellable'] == 1),
      );


  bool get isLost => lostDate != null && lostDate!.isNotEmpty;

  /// [dealId] dipakai duluan kalau ada (dari [fromUnitStatusJson]) — satu kontak bisa punya lebih
  /// dari satu deal tanpa kavling (cluster/product/property semuanya null), yang tanpa ini bakal
  /// tabrakan jadi satu key yang sama. Sumber lain ([fromContactJson], unit picker contact-add)
  /// tidak punya `dealId` — key-nya tetap seperti sebelumnya.
  String get key => dealId != null
      ? 'deal:$dealId'
      : '$clusterId|${productId ?? 0}|${propertyId ?? 0}|${isWaitingList ? 1 : 0}';

  
  String get label {
    final t = productName ?? '-';
    if (propertyId != null) return '$t · ${propertyName ?? propertyId}';
    if (isWaitingList) return '$t · Waiting list';
    return '$t · Belum tentukan kavling';
  }

  // Format tampilan "kavling produk cluster" (mis. "BB1-2 Grayson EcoArdence") — dipakai
  // form contact-add DAN step Pilih Unit di Reserve Order supaya bunyinya sama di keduanya.
  // Beda dari [label] yang pakai pemisah titik-tengah untuk daftar pilihan di unit picker.
  String get displayLabel {
    final tail = [productName, clusterName]
        .where((e) => (e ?? '').toString().trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(' ');
    if (propertyId != null && (propertyName ?? '').trim().isNotEmpty) {
      return [propertyName!.trim(), tail].where((e) => e.isNotEmpty).join(' ');
    }
    final status = isWaitingList ? 'Waiting list' : 'Belum tentukan kavling';
    return tail.isNotEmpty ? '$tail · $status' : status;
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
