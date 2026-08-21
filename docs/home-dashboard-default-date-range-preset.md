# Home Dashboard — Default Date Range dari Setting Backend

**Tanggal:** 2026-08-21
**Area:** `features/home` (section Prospect Status & Sales Channel)

## Masalah
Default range tanggal untuk section **Prospect Status** dan **Sales Channel** di Home hardcode "Last 1 Year" (1 tahun ke belakang s/d hari ini), tidak bisa diatur dari backend. Admin ingin bisa mengganti default ini (mis. jadi "This Month" atau "Today") lewat setting `PROSPECT_STATUS_DEFAULT_RANGE_PRESET` di `GET {{base_url}}/api/settings`, tanpa perlu update aplikasi.

Nilai valid setting ini: `""` (no default/all time), `today`, `this_week`, `last_week`, `this_month`, `last_month`, `last_1_year`.

## Perubahan

### 1. Baca setting baru di `ApiConstants`
Setting diterapkan lewat mekanisme yang sudah ada (`ApiConstants.applySettings`, dipanggil dari `main.dart` saat cold-start & setelah profile loaded). Ditambahkan field/getter untuk `PROSPECT_STATUS_DEFAULT_RANGE_PRESET`, plus `settingsVersion` (`ValueNotifier`) yang naik setiap kali `applySettings` jalan — supaya widget bisa tahu kapan settings baru datang (settings di-fetch async, bisa selesai setelah widget lain sudah mount).

- [lib/core/network/api_constants.dart:120-121](../lib/core/network/api_constants.dart#L120-L121) — field `_prospectStatusDefaultRangePreset` + `settingsVersion`
- [lib/core/network/api_constants.dart:134](../lib/core/network/api_constants.dart#L134) — getter `prospectStatusDefaultRangePreset`
- [lib/core/network/api_constants.dart:164-165](../lib/core/network/api_constants.dart#L164-L165) — `case 'PROSPECT_STATUS_DEFAULT_RANGE_PRESET'` di `applySettings`
- [lib/core/network/api_constants.dart:168](../lib/core/network/api_constants.dart#L168) — `settingsVersion.value++` di akhir `applySettings`

### 2. Resolver preset → tanggal
String preset dari backend (`today`, `this_month`, dst.) dikonversi ke `DateTime` start/end + label tampilan, mirror dari preset yang sudah ada di halaman filter tanggal Contact (`date-selection/index.dart`), tapi keyed pakai string snake_case dari backend.

- [lib/core/utils/helpers/date_helper.dart:51-77](../lib/core/utils/helpers/date_helper.dart#L51) — `DateHelper.resolveRangePreset(String? preset)`, return `null` kalau preset kosong/tidak dikenal (artinya "no default / all time").

### 3. Pakai default preset di Home
Kedua section (Prospect Status & Sales Channel) pakai setting **yang sama** (`PROSPECT_STATUS_DEFAULT_RANGE_PRESET`) untuk default range-nya.

- [lib/features/home/presentation/pages/home/index.dart:84-99](../lib/features/home/presentation/pages/home/index.dart#L84-L99) — `_applyDefaultDateRangePreset()`: resolve preset, isi `_prospectStartDate`/`_prospectEndDate`/`_prospectDateLabel` dan `_salesChannel*` yang senama, **kecuali** user sudah pernah pilih/clear filter itu sendiri (dilacak lewat flag `_prospectFilterUserSet`/`_salesChannelFilterUserSet`, di-set `true` di handler pilih & clear filter, contoh: [index.dart:634](../lib/features/home/presentation/pages/home/index.dart#L634), [index.dart:868](../lib/features/home/presentation/pages/home/index.dart#L868)).
- [lib/features/home/presentation/pages/home/index.dart:182-186](../lib/features/home/presentation/pages/home/index.dart#L182-L186) — `_loadData()` selalu memanggil ulang `_applyDefaultDateRangePreset()` di awal, jadi setiap refresh (pull-to-refresh, tombol retry, balik ke halaman via `didPopNext`) ikut menyegarkan default kalau filter belum pernah diubah manual oleh user.

### 4. Race condition: settings datang setelah Home sudah mount
Setting di-fetch async dan bisa baru selesai *setelah* `HomePage.initState()` jalan (mis. tepat setelah login, sebelum fetch kedua di `main.dart` selesai). Supaya default tetap ke-apply meski telat, `HomePage` subscribe ke `ApiConstants.settingsVersion`:

- [lib/features/home/presentation/pages/home/index.dart:80](../lib/features/home/presentation/pages/home/index.dart#L80) — `ApiConstants.settingsVersion.addListener(_onSettingsUpdated)` di `initState` (didaftarkan sekali saja).
- [lib/features/home/presentation/pages/home/index.dart:101-104](../lib/features/home/presentation/pages/home/index.dart#L101-L104) — `_onSettingsUpdated()`: kalau kedua filter belum pernah di-set manual user, panggil `_loadData(force: true)` lagi (yang otomatis re-apply default & refetch data).
- [lib/features/home/presentation/pages/home/index.dart:118](../lib/features/home/presentation/pages/home/index.dart#L118) — listener dilepas di `dispose()`.

### 5. Klik status/channel row tidak lagi paksa default "Last 1 Year"
Sebelumnya, tap salah satu status prospect atau sales channel di Home selalu jatuh balik ke fallback hardcoded `defaultStart`/`defaultEnd` (last 1 year) kalau `_prospectStartDate`/`_salesChannelStartDate` `null` — jadi walau filter "Create Date" di Home lagi kosong (all time, sesuai preset kosong dari poin 1-4 di atas atau habis di-clear), Contact page tetap dibuka dengan filter tanggal 1 tahun terakhir. Ini sama dengan masalah yang sudah diperbaiki di branch `Development-1.0.4` untuk kasus tanpa group ([home-prospect-status-filter.md](home-prospect-status-filter.md), [home-sales-channel-filter.md](home-sales-channel-filter.md)); di sini fallback yang sama juga dihapus untuk versi Das yang sudah pakai per-group date field (`apptStartDate`, `spStartDate`, dst.).

- [lib/features/home/presentation/pages/home/index.dart:707-726](../lib/features/home/presentation/pages/home/index.dart#L707-L726) — Prospect Status: fallback `defaultStart`/`defaultEnd` dihapus, `_prospectStartDate`/`_prospectEndDate` (boleh `null`) dikirim langsung ke `startDate`/`endDate` atau `${dateField}StartDate`/`${dateField}EndDate` sesuai `item.group` (mis. group `sp` → `spStartDate`/`spEndDate`).
- [lib/features/home/presentation/pages/home/index.dart:934-940](../lib/features/home/presentation/pages/home/index.dart#L934-L940) — Sales Channel: fallback yang sama dihapus, `_salesChannelStartDate`/`_salesChannelEndDate` dikirim apa adanya.

## Hasil
- Default range Prospect Status & Sales Channel di Home sekarang ikut nilai `PROSPECT_STATUS_DEFAULT_RANGE_PRESET` dari `/api/settings` (bisa `today`, `this_month`, dll), bukan hardcode "Last 1 Year" lagi.
- Kalau preset di-set kosong (`""`), default-nya "no filter" (all time) — konsisten dengan behavior tombol "Clear" yang sudah ada.
- Default ikut menyesuaikan tiap refresh (pull-to-refresh, retry, balik ke Home), tapi tidak akan menimpa filter yang sudah dipilih/di-clear manual oleh user.
- Aman dari race condition kalau settings baru selesai di-fetch setelah Home sudah tampil (mis. tepat setelah login).
- Klik status/channel row di Home tidak lagi paksa filter tanggal 1 tahun terakhir kalau filter "Create Date" lagi kosong/all-time — Contact page ikut terbuka tanpa filter tanggal aktif untuk group terkait (mis. `spStartDate`/`spEndDate` kosong untuk status group `sp`).
