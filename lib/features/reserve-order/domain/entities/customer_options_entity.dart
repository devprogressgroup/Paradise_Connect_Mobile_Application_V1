import 'package:equatable/equatable.dart';

/// 1 pilihan dropdown "Data Customer" — [value] yang disimpan ke backend, [label] yang tampil.
class CustomerOptionEntity extends Equatable {
  final String value;
  final String label;

  const CustomerOptionEntity({required this.value, required this.label});

  @override
  List<Object?> get props => [value, label];
}

/// Opsi semua dropdown "Data Customer" dari GET /reserve-order/customer-options — sumbernya SAMA
/// dgn dropdown web admin (backend CustomerReserveFields::dropdownOptions()), jadi tidak ada daftar
/// opsi tetap di app.
class CustomerOptionsEntity extends Equatable {
  /// Kolom → nama daftar opsi (mis. `cust_area` → `location`, dipakai 8 kolom Wilayah Area).
  final Map<String, String> fields;

  /// Nama daftar → opsinya.
  final Map<String, List<CustomerOptionEntity>> lists;

  /// Nilai pilihan yang memunculkan isian bebas ("Lainnya"); kosong = belum dimuat.
  final String other;

  const CustomerOptionsEntity({
    this.fields = const {},
    this.lists = const {},
    this.other = '',
  });

  /// Opsi dropdown kolom [key] — kosong = bukan dropdown / belum dimuat.
  List<CustomerOptionEntity> optionsFor(String key) =>
      lists[fields[key]] ?? const [];

  /// Dropdown [key] punya pilihan "Lainnya" (isian bebas).
  bool hasOther(String key) =>
      other.isNotEmpty && optionsFor(key).any((o) => o.value == other);

  /// Opsi yang cocok dgn nilai tersimpan [value] — sama persis, beda huruf besar/kecil ("ISLAM" =
  /// "Islam"), cocok labelnya, atau angka yang sama ("7000000.0" = "7000000"). Sama dgn backend
  /// CustomerReserveFields::optionKey(). null = tidak ada yang cocok.
  CustomerOptionEntity? match(String key, Object? value) {
    final text = value == null ? '' : '$value'.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    final number = num.tryParse(text);
    for (final option in optionsFor(key)) {
      if (option.value.toLowerCase() == lower ||
          option.label.toLowerCase() == lower) {
        return option;
      }
      final optionNumber = num.tryParse(option.value);
      if (number != null && optionNumber != null && number == optionNumber) {
        return option;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [fields, lists, other];
}
