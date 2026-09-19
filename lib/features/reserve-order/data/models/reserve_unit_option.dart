/// Unit/kavling yang bisa dipilih di step "Pilih Unit" pada wizard Create Reserve Order.
class ReserveUnitOption {
  final String id;
  final String name;
  final String context;
  final double? price;
  final bool available;
  final bool special;

  const ReserveUnitOption({
    required this.id,
    required this.name,
    this.context = '',
    this.price,
    this.available = true,
    this.special = false,
  });

  ReserveUnitOption copyWith({String? context}) => ReserveUnitOption(
        id: id,
        name: name,
        context: context ?? this.context,
        price: price,
        available: available,
        special: special,
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
