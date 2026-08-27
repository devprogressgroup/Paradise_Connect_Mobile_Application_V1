# Home — Prospect Status: Navigasi ke Contact Tidak Lagi Paksa Default Tanggal

**Tanggal:** 2026-08-05
**Area:** `features/home` (section Prospect Status)

## Masalah
Saat filter "Create Date" di section Prospect Status (Home) di-clear (`_prospectStartDate`/`_prospectEndDate` jadi `null`), klik salah satu item status tetap mengirim `startDate`/`endDate` default (1 tahun ke belakang s/d hari ini) ke halaman Contact. Akibatnya kondisi "sudah di-clear" di Home tidak konsisten dengan tampilan filter tanggal di Contact (selalu tampak ada filter aktif).

## Perubahan
Hapus fallback `defaultStart`/`defaultEnd`, kirim `_prospectStartDate`/`_prospectEndDate` apa adanya (boleh `null`).

- [lib/features/home/presentation/pages/home/index.dart:679-684](../lib/features/home/presentation/pages/home/index.dart#L679-L684)

```dart
onTap: () {
  context.go('/contact', extra: {
    'statusIds': [item.prospectStatusId],
    'startDate': _prospectStartDate,
    'endDate': _prospectEndDate,
  });
},
```

## Hasil
Kalau filter tanggal di Home kosong/di-clear, Contact page ikut terbuka tanpa filter tanggal aktif (bukan default 1 tahun terakhir lagi). Lihat juga perubahan serupa di [home-sales-channel-filter.md](home-sales-channel-filter.md).
