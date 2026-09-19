/// Unit/kavling yang bisa dipilih di step "Pilih Unit" pada wizard Create Reserve Order.
///
/// `id` cuma dipakai buat identitas UI (checklist terpilih/tidak) — untuk submit ke
/// `POST /reserve-order/create`, pakai field id ASLI di bawah (`propertyId`/`productId`/dst),
/// yang diisi dari `SelectUnitEntity` (tab "Unit dari Contact") atau `UnitCluster`/`UnitProduct`/
/// `UnitLot` (tab "Pilih Unit Lain") — lihat `_toReserveUnitOption`/`_otherProductTiles` di
/// `create/index.dart`.
class ReserveUnitOption {
  final String id;
  final String name;
  final String context;
  final double? price;
  final bool available;
  final bool special;

  final int? dealId;
  final int? townshipId;
  final int? companyId;
  final int? clusterId;
  final int? productId;
  final int? propertyId;
  final bool isWaitingList;

  const ReserveUnitOption({
    required this.id,
    required this.name,
    this.context = '',
    this.price,
    this.available = true,
    this.special = false,
    this.dealId,
    this.townshipId,
    this.companyId,
    this.clusterId,
    this.productId,
    this.propertyId,
    this.isWaitingList = false,
  });

  ReserveUnitOption copyWith({String? context}) => ReserveUnitOption(
        id: id,
        name: name,
        context: context ?? this.context,
        price: price,
        available: available,
        special: special,
        dealId: dealId,
        townshipId: townshipId,
        companyId: companyId,
        clusterId: clusterId,
        productId: productId,
        propertyId: propertyId,
        isWaitingList: isWaitingList,
      );
}

/// Grup cluster + tipe unit (dipakai tab "Pilih Unit Lain") yang berisi beberapa [kavlings].
class ReserveUnitGroup {
  final String cluster;
  final String tipe;
  final String tipeSub;
  final List<ReserveUnitOption> kavlings;

  const ReserveUnitGroup({required this.cluster, required this.tipe, required this.tipeSub, required this.kavlings});
}
