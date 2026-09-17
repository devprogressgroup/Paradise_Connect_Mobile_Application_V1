


class UnitCluster {
  final int projectId;
  final int companyId;
  final int townshipId;

  /// Dari `township_name` — cuma dikirim `GET /api/reserve/unit-all?contact_id=…` (katalog seluruh
  /// township kontak tersebut sekaligus, bisa beda-beda per cluster). Null di
  /// `GET /property/units/hierarchy?township_id=…` punya fitur contact, karena di situ township-nya
  /// sudah ditentukan lebih dulu oleh pemanggil ([UnitPickerScreen.townshipName]).
  final String? townshipName;
  final String projectName;
  final List<UnitProduct> products;

  const UnitCluster({
    required this.projectId,
    this.companyId = 0,
    this.townshipId = 0,
    this.townshipName,
    required this.projectName,
    this.products = const [],
  });

  factory UnitCluster.fromJson(Map<String, dynamic> j) => UnitCluster(
        projectId: j['project_id'] ?? 0,
        companyId: j['company_id'] ?? 0,
        townshipId: j['township_id'] ?? 0,
        townshipName: j['township_name']?.toString(),
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

  /// Dari `status_name` — cuma dikirim `GET /api/reserve/unit-all?product_id=…` (mis. "Ordered"),
  /// tidak ada di `GET /property/units/hierarchy?product_id=…` punya fitur contact. Null di situ.
  final String? statusName;

  const UnitLot({
    required this.propertyId,
    required this.propertyName,
    this.propTotalArea,
    this.isTipeHoek = false,
    this.isTipeKhusus = false,
    this.statusId,
    this.statusName,
  });

  factory UnitLot.fromJson(Map<String, dynamic> j) => UnitLot(
        propertyId: j['property_id'] ?? 0,
        propertyName: (j['property_name'] ?? '').toString(),
        propTotalArea: j['prop_total_area'] is num ? (j['prop_total_area'] as num).toDouble() : null,
        isTipeHoek: j['is_tipe_hoek'] == true || j['is_tipe_hoek'] == 1,
        isTipeKhusus: j['is_tipe_khusus'] == true || j['is_tipe_khusus'] == 1,
        statusId: j['status_id'],
        statusName: j['status_name']?.toString(),
      );
}


class SelectedUnit {
  final int townshipId;

  /// Dari `UnitCluster.townshipName` (katalog `unit-all`). [fromProductSelectJson] (`GET
  /// /api/reserve/product-select`) TIDAK mengirim field ini sama sekali (dikonfirmasi dari response
  /// asli) — buat unit "sudah ada" itu, `ReservePage._enrichExistingUnit` yang mengisinya belakangan
  /// dengan mencocokkan `clusterId` ke katalog tree (`state.clusters`) yang sudah dimuat bareng.
  final String? townshipName;
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
    this.townshipName,
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

  /// Id deal yang menghasilkan baris ini — cuma keisi dari [fromProductSelectJson] (`GET
  /// /api/reserve/product-select`) kalau produknya sudah py deal existing (`deal_id` tidak null).
  /// Null buat unit dari [fromContactJson] atau dari unit picker contact-add.
  final int? dealId;

  /// Nama status yang ditampilkan sebagai badge di step "Pilih Unit" lewat `UnitStatusBadge`. Dari
  /// `UnitLot.statusName` (katalog `unit-all?product_id=…`). [fromProductSelectJson] tidak
  /// mengirim status kavling sama sekali (cuma `status_prospect_id`, status PIPELINE deal, beda
  /// konsep dari status ketersediaan kavling) — buat unit "sudah ada" yang py `propertyId`,
  /// `ReservePage._enrichExistingUnit` mengisinya belakangan dengan mencocokkan `propertyId` ke
  /// `state.lotsByProduct` (baru terisi kalau produknya sudah pernah di-expand/lots-nya sudah
  /// dimuat). Null buat sumber lain ([fromContactJson], unit picker contact-add).
  final String? statusName;

  /// Nominal deal — dipakai sebagai harga di baris kedua kartu step "Pilih Unit". Null/0 tidak
  /// ditampilkan. `GET /api/reserve/product-select` ([fromProductSelectJson]) tidak mengirim field
  /// ini, jadi selalu null lewat sumber itu — baris harga otomatis tidak muncul.
  final num? dealValue;

  /// Dari `is_property_sellable` — kavling yang sudah tidak sellable (mis. sudah SP/akad kontak
  /// lain) tetap tampil tapi pudar & tidak bisa dicentang di step "Pilih Unit". Default true supaya
  /// sumber lain ([fromContactJson], unit picker contact-add) yang tidak punya field ini tetap bisa
  /// dipilih seperti sebelumnya.
  final bool isPropertySellable;


  factory SelectedUnit.fromContactJson(Map<String, dynamic> j) => SelectedUnit(
        townshipId: j['township_id'] ?? 0,
        townshipName: j['township_name']?.toString(),
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

  /// Satu deal/unit yang SUDAH ADA buat kontak ini, dari `GET /api/reserve/product-select?contact_id=…`
  /// (`data.units[]` — daftar rata, satu baris = satu deal, BUKAN dikelompokkan per proyek). Dipakai
  /// step "Pilih Unit" di form Reserve buat menampilkan & auto-centang unit yang sudah pernah dipilih
  /// sebelumnya, terpisah dari katalog unit yang bisa dipilih baru (`GET /api/reserve/unit-all`,
  /// lihat [UnitCluster.fromJson]/[UnitLot.fromJson]). [dealId] selalu terisi dari sumber ini.
  factory SelectedUnit.fromProductSelectJson(Map<String, dynamic> j) => SelectedUnit(
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
        lostDate: j['lost_date']?.toString(),
        dealValue: j['deal_value'],
      );


  /// Cuma buat mengisi [townshipName]/[statusName] belakangan (lihat catatan di kedua field itu) —
  /// bukan copyWith umum, sengaja cuma dua field ini yang butuh di-backfill setelah konstruksi.
  SelectedUnit copyWith({String? townshipName, String? statusName}) => SelectedUnit(
        townshipId: townshipId,
        townshipName: townshipName ?? this.townshipName,
        companyId: companyId,
        clusterId: clusterId,
        clusterName: clusterName,
        productId: productId,
        productName: productName,
        propertyId: propertyId,
        propertyName: propertyName,
        isWaitingList: isWaitingList,
        isTipeHoek: isTipeHoek,
        statusProspectId: statusProspectId,
        lostDate: lostDate,
        dealId: dealId,
        statusName: statusName ?? this.statusName,
        dealValue: dealValue,
        isPropertySellable: isPropertySellable,
      );

  bool get isLost => lostDate != null && lostDate!.isNotEmpty;

  /// [dealId] dipakai duluan kalau ada (dari [fromProductSelectJson]) — satu kontak bisa punya lebih
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
