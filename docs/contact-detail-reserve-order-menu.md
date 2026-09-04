# Menu "Reserve Order" di Bottom Sheet Log Activity

## Ringkasan

Menambah entri **Reserve Order** di bottom sheet "Log Activity" pada halaman Contact Detail.
Untuk sekarang menu ini membuka **halaman blank** (`ReserveOrderPage`) — placeholder, form/isinya
menyusul.

Posisi menu: setelah **Visit**, sebelum **Update Status Prospect**.

## Perubahan

### 1. Konstanta ikon

- [assets.dart:21](lib/core/constants/assets.dart#L21) — `icContactDetailReserveOrder`
  → `assets/img/ic-contact-detail-reserve-order.png`

> **Belum ada file gambarnya.** Simpan PNG ikon reserve order ke
> `assets/img/ic-contact-detail-reserve-order.png`. Folder `assets/img/` sudah terdaftar di
> [pubspec.yaml:62](pubspec.yaml#L62), jadi tidak perlu edit pubspec.
> Selama file belum ada, `BgIcon` jatuh ke `errorBuilder` dan menampilkan ikon fallback
> (`Icons.more_vert`) — lihat [custom_bg_icon.dart:33-40](lib/core/utils/widget/custom_bg_icon.dart#L33-L40).

### 2. Halaman blank

- [reserve-order/index.dart](lib/features/contact/presentation/pages/reserve-order/index.dart) —
  `ReserveOrderPage`, `StatefulWidget` yang terima `ContactDetailArgs`.
  Isinya cuma `customHeader` (judul dari `args.namePage`, tombol back) + body kosong.
  `AnalyticsService.logScreenView('reserve_order')` dipanggil di `initState` mengikuti pola
  halaman lain.

Data kontak sudah ikut dikirim lewat `args.dataContact`, jadi waktu form-nya dibuat nanti tidak
perlu ubah pemanggilnya.

### 3. Route

- [router.dart:328-335](lib/app/router.dart#L328-L335) — `GoRoute` baru `name: 'reserveOrder'`,
  `path: 'reserve-order'`, sebagai child dari `/contact` (satu level dengan `addContact`).
- [router.dart:24](lib/app/router.dart#L24) — import halaman baru.

### 4. Menu + navigasi di Contact Detail

- [contact-detail/index.dart:149-151](lib/features/contact/presentation/pages/contact-detail/index.dart#L149-L151) —
  `_navigateToReserveOrder()`. Berbeda dari `_navigateToAddContact()`, helper ini **tidak**
  refresh activity/contact detail setelah kembali, karena halamannya belum menyimpan apa pun.
  Tambahkan `_getActivity()` / `_getContactDetail()` di sini kalau nanti form-nya sudah submit data.
- [contact-detail/index.dart:562-576](lib/features/contact/presentation/pages/contact-detail/index.dart#L562-L576) —
  entri `ContactOptionsSheet.buildIconLink` untuk "Reserve Order" di `_buildContentBSAdd()`.

## Catatan

`page` di `ContactDetailArgs` dibiarkan default (`0`) karena `ReserveOrderPage` tidak memakainya —
mapping `page` (0=Call, 1=WhatsApp, 2=Meeting, 3=Reminder/Task, 4=Visit, 5=Attachment,
6=Update Status Prospect, 7=Edit Attachment) itu khusus `ContactAddPage`, dan Reserve Order
sekarang punya route sendiri.

Kalau nanti Reserve Order ternyata harus jadi form status prospect (group `reserve` →
[`_buildFormReserved()`](lib/features/contact/presentation/pages/contact-add/index.dart#L1238))
atau WebView ke modul backend, tinggal ganti isi `ReserveOrderPage` atau alihkan
`_navigateToReserveOrder()` — menu dan route-nya sudah siap.
