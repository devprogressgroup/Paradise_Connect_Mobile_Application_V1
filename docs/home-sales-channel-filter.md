# Home — Sales Channel: Navigasi ke Contact Tidak Lagi Paksa Default Tanggal

**Tanggal:** 2026-08-05
**Area:** `features/home` (section Sales Channel)

## Masalah
Sama seperti [home-prospect-status-filter.md](home-prospect-status-filter.md): saat filter "Create Date" di section Sales Channel (Home) di-clear (`_salesChannelStartDate`/`_salesChannelEndDate` jadi `null`), klik salah satu channel tetap mengirim `startDate`/`endDate` default (1 tahun ke belakang s/d hari ini) ke halaman Contact.

## Perubahan
Hapus fallback `defaultStart`/`defaultEnd`, kirim `_salesChannelStartDate`/`_salesChannelEndDate` apa adanya (boleh `null`).

- [lib/features/home/presentation/pages/home/index.dart:903-908](../lib/features/home/presentation/pages/home/index.dart#L903-L908)

```dart
onTap: () {
  context.go('/contact', extra: {
    'salesChannelIds': [item.salesChannelId],
    'startDate': _salesChannelStartDate,
    'endDate': _salesChannelEndDate,
  });
},
```

> Catatan: kode lama (dengan fallback default) masih tersisa dalam bentuk comment di [lib/features/home/presentation/pages/home/index.dart:891-902](../lib/features/home/presentation/pages/home/index.dart#L891-L902), belum dibersihkan.

## Hasil
Kalau filter tanggal di Home kosong/di-clear, Contact page ikut terbuka tanpa filter tanggal aktif (bukan default 1 tahun terakhir lagi).
