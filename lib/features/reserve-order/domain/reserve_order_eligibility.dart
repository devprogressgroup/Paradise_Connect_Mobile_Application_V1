import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';

/// Grup status prospek (`m_prospect_status.group_name`, field `group` di `GET /sales/statuses`) yang
/// jadi patokan boleh Reserve Order.
const reserveStatusGroup = 'reserve';

/// Status prospek yang BOLEH dibuatkan Reserve Order — dari daftar `GET /sales/statuses`:
///  - semua status grup [reserveStatusGroup] (10A, 10B, 30, 31, 32), DAN
///  - semua status lain yang `status_value`-nya LEBIH TINGGI dari `status_value` tertinggi di grup itu
///    (saat ini > 32: 50 - SP, dan juga grup lost 40A–40Z, 41, 41A, 42A–42C, 43, 45).
/// Patokan dihitung dari data, jadi ikut berubah kalau `group_name` di master diubah.
///
/// Dipakai tombol Reserve Order di Detail Contact & daftar contact di Pilih Contact — keduanya harus
/// sama. Urutan mengikuti [statuses]. Grup reserve kosong → tidak ada yang boleh.
List<ProspectStatusEntity> reserveEligibleStatuses(
  List<ProspectStatusEntity> statuses,
) {
  (int, String)? highest;
  for (final s in statuses) {
    if (s.group != reserveStatusGroup) continue;
    final key = _statusValueKey(s.statusValue);
    if (key != null && (highest == null || _compareKey(key, highest) > 0)) {
      highest = key;
    }
  }
  if (highest == null) {
    return statuses.where((s) => s.group == reserveStatusGroup).toList();
  }

  return statuses.where((s) {
    if (s.group == reserveStatusGroup) return true;
    final key = _statusValueKey(s.statusValue);
    return key != null && _compareKey(key, highest!) > 0;
  }).toList();
}

/// `status_value` → (angka depan, huruf belakang) supaya "40A" > "32" dan "10B" > "10A" > "10".
/// Tanpa angka di depan → null (tidak pernah dianggap lebih tinggi).
(int, String)? _statusValueKey(String value) {
  final match = RegExp(r'^\s*(\d+)\s*([A-Za-z]*)').firstMatch(value);
  if (match == null) return null;
  return (int.parse(match.group(1)!), match.group(2)!.toUpperCase());
}

int _compareKey((int, String) a, (int, String) b) =>
    a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);
