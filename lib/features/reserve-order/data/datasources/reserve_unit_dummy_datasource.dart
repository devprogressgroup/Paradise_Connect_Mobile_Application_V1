import '../models/reserve_unit_option.dart';

/// Sumber data project & unit untuk step "Pilih Unit" di wizard Create Reserve Order.
///
/// Masih dummy — belum ada API reserve-order di branch ini (lihat catatan di
/// `presentation/pages/create/index.dart`). Sengaja dipisah ke sini (bukan inline di halaman)
/// supaya nanti tinggal ganti isi class ini dengan implementasi yang manggil API sungguhan,
/// tanpa perlu ubah UI-nya.
class ReserveUnitDummyDataSource {
  const ReserveUnitDummyDataSource();

  /// Unit yang sudah "dikenal" lewat riwayat Contact customer — ditampilkan di tab "Unit dari
  /// Contact".
  List<ReserveUnitOption> getContactUnits(String project) => _contactUnitsByProject[project] ?? const [];

  /// Semua cluster/tipe/kavling di project ini — ditampilkan di tab "Pilih Unit Lain".
  List<ReserveUnitGroup> getOtherUnitGroups(String project) => _otherUnitsByProject[project] ?? const [];
}

const Map<String, List<ReserveUnitOption>> _contactUnitsByProject = {
  'Paradise Serpong City 2': [
    ReserveUnitOption(id: 'ct1', name: 'Blok E1 No. 19', context: 'PAR2 · Ecoscape', price: 450000000, available: true),
    ReserveUnitOption(id: 'ct2', name: 'Blok E1 No. 21', context: 'PAR2 · Ecoscape', price: 450000000, available: true),
    ReserveUnitOption(id: 'ct3', name: 'Blok E1 No. 20', context: 'PAR2 · Ecoscape', price: 465000000, available: false),
  ],
};

const Map<String, List<ReserveUnitGroup>> _otherUnitsByProject = {
  'Paradise Serpong City': [
    ReserveUnitGroup(cluster: 'Rosewood', tipe: 'Rosewood - Tipe 45', tipeSub: 'LB 90m²', kavlings: [
      ReserveUnitOption(id: 'special-psc-belum', name: 'Belum menentukan kavling', special: true),
      ReserveUnitOption(id: 'special-psc-waiting', name: 'Waiting list', special: true),
      ReserveUnitOption(id: 'psc1', name: 'A2-08', price: 520000000, available: true),
      ReserveUnitOption(id: 'psc2', name: 'A2-09', price: 525000000, available: true),
    ]),
  ],
  'Paradise Serpong City 2': [
    ReserveUnitGroup(cluster: 'Arwood', tipe: 'Arwood - Tipe 60', tipeSub: 'LB 120m²', kavlings: [
      ReserveUnitOption(id: 'special-psc2-belum', name: 'Belum menentukan kavling', special: true),
      ReserveUnitOption(id: 'special-psc2-waiting', name: 'Waiting list', special: true),
      ReserveUnitOption(id: 'psc2a', name: 'F3-05', price: 610000000, available: true),
      ReserveUnitOption(id: 'psc2b', name: 'F3-06', price: 615000000, available: true),
      ReserveUnitOption(id: 'psc2c', name: 'F3-07', price: 615000000, available: false),
    ]),
  ],
  'Paradise Resort City': [
    ReserveUnitGroup(cluster: 'THE BAY', tipe: 'THE BAY - BAHAMAS', tipeSub: 'LB 150m²', kavlings: [
      ReserveUnitOption(id: 'special-prc1-belum', name: 'Belum menentukan kavling', special: true),
      ReserveUnitOption(id: 'special-prc1-waiting', name: 'Waiting list', special: true),
      ReserveUnitOption(id: 'prc-c519', name: 'C5-19', price: 730000000, available: true),
      ReserveUnitOption(id: 'prc-c520', name: 'C5-20', price: 730000000, available: true),
      ReserveUnitOption(id: 'prc-c521', name: 'C5-21', price: 735000000, available: false),
    ]),
    ReserveUnitGroup(cluster: 'THE BAY', tipe: 'THE BAY - MALIBU', tipeSub: 'LB 180m²', kavlings: [
      ReserveUnitOption(id: 'special-prc2-belum', name: 'Belum menentukan kavling', special: true),
      ReserveUnitOption(id: 'special-prc2-waiting', name: 'Waiting list', special: true),
      ReserveUnitOption(id: 'prc-c602', name: 'C6-02', price: 855000000, available: true),
    ]),
  ],
};
