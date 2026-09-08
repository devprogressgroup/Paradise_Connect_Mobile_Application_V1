# Menu "Reserve Order" di Bottom Sheet Log Activity

## Ringkasan

Menambah entri **Reserve Order** di bottom sheet "Log Activity" pada halaman Contact Detail.

Posisi menu: setelah **Visit**, sebelum **Update Status Prospect**.

> **Update:** menu ini sekarang membuka `ReserveOrderListPage` (daftar transaksi menu drawer, lihat
> [reserve-order-menu-list.md](reserve-order-menu-list.md)) yang disaring `contact_id`, bukan lagi
> `ReserveOrderPage` blank di bawah ini — lihat section "Dialihkan ke daftar transaksi per-kontak"
> di bagian bawah dokumen ini. Sisa dokumen ini dibiarkan sebagai riwayat implementasi awal.

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

- [reserve-order/index.dart](lib/features/reserve-order/presentation/pages/index.dart) —
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

## Dialihkan ke daftar transaksi per-kontak

Bottom sheet-nya sekarang membuka `ReserveOrderListPage` (halaman yang sama dengan menu drawer
"Reserve Order" — lihat [reserve-order-menu-list.md](reserve-order-menu-list.md)), disaring supaya
cuma menampilkan transaksi kontak yang sedang dibuka. Halaman blank `ReserveOrderPage` (tile
Reserve/Topup/RB) masih ada di codebase tapi sudah tidak ada pintu masuknya dari UI, kecuali sebagai
parent route `reserveOrderReserve` (form buat reserve baru — lihat di bawah).

- [contact_options_sheet.dart:32-38](lib/features/contact/presentation/widgets/contact_options_sheet.dart#L32-L38) —
  `buildIconLink` dapat parameter opsional `IconData? icon`, dipakai lewat `BgIcon.fallbackIcon`
  saat `asset` kosong. Ikon "Reserve Order" di bottom sheet disamakan dengan drawer
  (`Icons.local_offer_rounded`, bukan `icContactDetailReserveOrder` lagi) —
  [contact-detail/index.dart:580-593](lib/features/contact/presentation/pages/contact-detail/index.dart#L580-L593).
- [contact-detail/index.dart:149-153](lib/features/contact/presentation/pages/contact-detail/index.dart#L149-L153) —
  `_navigateToReserveOrder()` sekarang `pushNamed('reserveOrderList', ...)`, bukan `'reserveOrder'`.
- [router.dart:378-384](lib/app/router.dart#L378-L384) — builder `reserveOrderList` membaca
  `state.extra` sebagai `ContactDetailArgs?`; diteruskan ke `ReserveOrderListPage.contactArgs`.
- [list.dart](lib/features/reserve-order/presentation/pages/list.dart) —
  `ReserveOrderListPage` dapat field `contactArgs`; `contactId`-nya (dari
  `contactArgs.dataContact.contactId`) dikirim ke `GET /api/reserve?...&contact_id=…` supaya daftar
  cuma berisi transaksi kontak itu.
  - Kontak yang responsnya kosong (`total: 0`) ditawari **"+ Buat Reserve Baru"** — membuka
    `ReservePage` (`reserveOrderReserve`) dengan data kontak terisi, gantinya tile "Reserve" di
    `ReserveOrderPage` lama.
- [reserve_order_list_cubit.dart](lib/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart) —
  method baru `loadFresh({contactId})`: reset `ReserveOrderListState` dari nol sebelum `load()`,
  supaya `contactId` (dan pencarian/filter) dari kunjungan sebelumnya tidak kebawa — cubit-nya satu
  instance dipakai bersama drawer & daftar per-kontak (`main.dart`).
- [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart) —
  `getReserveOrders()` dapat parameter `contactId`, dikirim sebagai query `contact_id` kalau diisi.
