# Menu "Reserve Order" di Sidebar (List Transaksi)

Sumber desain: [reserve-order-sales-final_12.html](reserve-order-sales-final_12.html) **Bagian 3 —
Menu "Reserve Order" (List Transaksi)** (mockup ada di root repo). Bagian 1 (titik masuk dari
Contact Detail) sudah dikerjakan di [contact-detail-reserve-order-menu.md](docs/contact-detail-reserve-order-menu.md),
Bagian 2 (flow pengajuan) di [reserve-order-scan-ktp-ocr.md](docs/reserve-order-scan-ktp-ocr.md).

## Ringkasan

Item **Reserve Order** (badge **BARU**) ditambahkan ke drawer, tepat di bawah *Contacts*, membuka
`/reserve-order` — daftar transaksi milik sales yang login. Isinya lima layar dari Bagian 3:

1. **List** — judul + "N transaksi", kotak cari "Cari nama / unit…", lalu kartu per transaksi
   berisi nama, badge tahap, unit + lokasi, sales, nilai, dan tanggal.
2. **Detail** — header pembeli, baris nomor HP + "Profil & Riwayat Lengkap ›", kotak status, dan 4
   tab: **Perjalanan** (timeline L1–L10 + chip gembok/tujuan akhir + catatan per tahap),
   **Data Pembeli**, **Attachment**, **Catatan** (dengan kotak tulis catatan di bawah).
3. **Top Up Pembayaran** — ringkasan status & total dibayar, upload bukti transfer, nominal,
   catatan, tombol **Ajukan Top Up**.
4. **Top Up Diajukan** — layar sukses + "Total setelah top up" berbadge **Menunggu**.
5. **Perbaiki Reserve Order** — untuk transaksi yang ditolak kasir: banner merah, dokumen identitas
   & bukti bayar (yang ditolak diunggah ulang), nominal + peringatan kekurangan, catatan, tombol
   **Submit Ulang**.

> Menu drawer ini **beda** dari `/contact/reserve-order` yang sudah ada. Yang lama itu menu
> per-kontak (Reserve / Topup / RB) yang dibuka dari bottom sheet Log Activity; yang baru ini daftar
> semua transaksi, dipakai tanpa harus lewat kontak dulu.

## List sudah tersambung ke `GET /api/reserve`

Query yang dikirim: `search`, `status_reserve_id` (dipisah koma), `sort=created_desc`, `page`,
`per_page=15`. Server membalas bentuk paginasi Laravel standar (`data.data[]` + `current_page` /
`next_page_url` / `total`).

**Yang masih menunggu keputusan Anda — chip filter dimatikan dulu:**

- Chip **Semua / Reserve / RBA / RBB / SP / Proses Bank / Akad** di mockup mengirim
  `status_reserve_id` ke server, tapi mapping id → nama tahapnya belum ada (Anda akan kirim
  endpoint master status reserve menyusul). Sampai itu ada, `_buildFilters` di
  [list.dart](lib/features/contact/presentation/pages/reserve-order/list.dart) sengaja
  mengembalikan `SizedBox.shrink()` — baris chip tidak digambar sama sekali, ketimbang menampilkan
  chip yang mengirim id tebakan yang salah.
- Begitu endpoint master-nya ada, tinggal isi `ReserveOrderListState.statusIds` dari situ dan
  gambar ulang baris chip; `ReserveOrderListCubit.load(statusIds: …)` sudah siap menerimanya.

**Badge status di kartu & kotak status detail** untuk sementara diturunkan dari tanggal yang ada di
response (bukan dari `status_reserve_id`, karena mapping-nya juga belum ada):

| Kondisi | Badge |
|---|---|
| `kasir_rejected_datetime`/`kasir_rejected_reason` **atau** `sa_rejected_*` terisi | **Ditolak** |
| `sp_date` terisi | **SP** |
| `rb_date` terisi (tapi belum SP) | **R/BR** — response tidak membedakan RBA/RBB, jadi ditulis netral |
| Selain itu | **Diproses** |

Ini di `ReserveOrder.fromJson()` — [reserve_order_model.dart:263](lib/features/contact/data/models/reserve/reserve_order_model.dart#L263).
Begitu ada mapping `status_reserve_id`, badge-nya tinggal dialihkan untuk pakai nama status asli
(termasuk membedakan RBA vs RBB) — field `statusReserveId` sudah disimpan di model, tinggal dipetakan.

## Yang belum ada di response list → detail sebagian kosong

Response `/api/reserve` cuma punya data ringkas. Field yang **tidak ada** di sana diisi seadanya di
`fromJson()` supaya halamannya tidak error, sampai endpoint detailnya (yang sudah Anda janjikan)
tersambung:

| Bagian | Sumbernya sekarang |
|---|---|
| Timeline L1–L3, L5–L10 | Ditandai "belum sampai tahap ini" / chip gembok; hanya L4 (Reserve) yang punya keterangan dari `created_datetime` + `amount_rp` |
| Tab **Data Pembeli** | Cuma nama & no. HP dari baris list |
| Tab **Attachment** | Kosong ("Belum ada dokumen.") |
| Tab **Catatan** | Diisi `reserve_note` sebagai satu catatan, kalau ada |
| `unitLabel` | `property_name` → `deal_blok_no` → "Unit belum ditentukan" (ketiganya sering null di response contoh) |

**Waktu endpoint detailnya siap:** ganti pemanggilan di
[detail.dart](lib/features/contact/presentation/pages/reserve-order/detail.dart) supaya mengambil
data lengkap berbekal `order.id`, lalu isi ulang `journey` / `buyer` / `docs` / `notes` dari situ.
Kartu di list tidak perlu berubah — datanya memang cukup dari `/api/reserve`.

## Link "Profil & Riwayat Lengkap ›" sudah jalan

`contact_id` & `deal_id` dari response dipakai untuk membuka `ContactDetailPage` (route
`detailContact`) — [detail.dart:541](lib/features/contact/presentation/pages/reserve-order/detail.dart#L541).
`ContactEntity` yang dikirim cuma diisi seadanya (nama, HP, id); halaman Contact Detail sendiri yang
memuat ulang detail & riwayat lengkapnya dari server begitu dibuka.

## Perubahan

### 1. Sidebar

- [main_layout.dart:457](lib/app/main_layout.dart#L457) — item drawer "Reserve Order"
  (`Icons.local_offer_rounded`, badge `BARU`, index 10), dipagari `PermissionsHelper.canAccessContacts`
  karena belum ada permission khusus reserve order.
- [main_layout.dart:537](lib/app/main_layout.dart#L537) — `_buildDrawerItem` dapat parameter baru
  `String? badge`; item lain tidak berubah karena parameternya opsional.
- [main_layout.dart:187](lib/app/main_layout.dart#L187) — `_currentIndex` mengenali `/reserve-order`
  (index 10). Dicek **sebelum** `/contact` supaya tidak ketukar prefix.
- [main_layout.dart:70](lib/app/main_layout.dart#L70) — event analytics
  `main_layout_drawer_nav_reserve_order`.

### 2. Route

- [router.dart:379](lib/app/router.dart#L379) — `/reserve-order` (`reserveOrderList`) di dalam
  `ShellRoute`, dengan turunan `detail` → `top-up` & `revise`.
- Tiap turunan punya `redirect` yang mengembalikan ke `/reserve-order` kalau `state.extra` bukan
  `ReserveOrder`. Ini untuk kasus PWA: URL yang di-reload langsung kehilangan `extra`, dan tanpa
  penjaga ini castingnya bakal crash.

### 3. Data

- [reserve_order_remote_datasource.dart](lib/features/contact/data/datasources/reserve_order_remote_datasource.dart) —
  `ReserveOrderRemoteDataSource.getReserveOrders()`, `GET /reserve` + `ReserveOrdersPage`
  (items, page, hasMore dari `next_page_url`, total).
- [reserve_order_list_cubit.dart](lib/features/contact/presentation/state/reserve_order_list/reserve_order_list_cubit.dart) —
  `ReserveOrderListCubit`, pola sama seperti `ReserveUnitCubit` (datasource langsung, tanpa
  usecase/repository): `load()` untuk halaman pertama + ganti pencarian/filter, `loadMore()` untuk
  infinite scroll, `refresh()` untuk pull-to-refresh.
- [reserve_order_list_state.dart](lib/features/contact/presentation/state/reserve_order_list/reserve_order_list_state.dart) —
  `ReserveOrderListState`.
- [main.dart:438](lib/main.dart#L438) + [main.dart:542](lib/main.dart#L542) — datasource &
  provider.

### 4. Model

- [reserve_order_model.dart](lib/features/contact/data/models/reserve/reserve_order_model.dart) —
  `ReserveOrder.fromJson()` memetakan satu baris response (lihat dua section di atas untuk
  aturannya), plus `ReserveOrderStatus` / `ReserveOrderStep` / `ReserveOrderDoc` / `ReserveOrderNote`
  / `ReserveOrderField` dan helper `buildReserveJourney()` yang menyusun 10 tahap timeline dari satu
  angka "sudah sampai tahap ke-berapa" (dipakai `fromJson` dan siap dipakai ulang saat endpoint
  detail tersambung).
  Warna badge SP memakai konstanta status unit yang sudah dipakai site plan (`spColor`), sisanya
  warna semantik.

Sebagian field sengaja **tidak** final (`status`, `statusText`, `rejectReason`, `ReserveOrderStep.sub`,
`docs`, `notes`) karena "Submit Ulang" dan "Ajukan Top Up" memang mengubah transaksinya secara lokal
selagi endpoint aksinya belum ada.

### 5. Halaman

- [list.dart](lib/features/contact/presentation/pages/reserve-order/list.dart) — `ReserveOrderListPage`.
  Pencarian didebounce 400 ms lalu dikirim ke server (bukan disaring di aplikasi); scroll mendekati
  bawah memicu `loadMore()`; shimmer (`buildContactListShimmer`) dipakai saat memuat, dan ada
  tombol "Coba lagi" saat gagal.
- [detail.dart](lib/features/contact/presentation/pages/reserve-order/detail.dart) —
  `ReserveOrderDetailPage` beserta timeline, keempat tab, dan kotak tulis catatan.
- [top_up.dart](lib/features/contact/presentation/pages/reserve-order/top_up.dart) —
  `ReserveOrderTopUpPage`, sekaligus layar suksesnya.
- [revise.dart](lib/features/contact/presentation/pages/reserve-order/revise.dart) —
  `ReserveOrderRevisePage`.
- [widgets.dart](lib/features/contact/presentation/pages/reserve-order/widgets.dart) — potongan UI
  yang dipakai berulang: app bar, avatar, badge status (`roStatusBadge(label, color)` — label &
  warnanya dikirim terpisah karena badge kini bisa lebih spesifik dari `ReserveOrderStatus`), label,
  input, chip, baris dokumen, banner tolak, baris ringkasan, footer, dan `roPrimaryButton` (tombol
  utama dengan status loading).

### 6. Formatter ribuan dipindah jadi milik bersama

- [thousands_input_formatter.dart](lib/core/utils/widget/thousands_input_formatter.dart) —
  `ThousandsInputFormatter`, sebelumnya class privat `_ThousandsFormatter` di dalam `reserve.dart`.
  Sekarang dipakai bertiga: flow Reserve, Top Up, dan Ajukan Ulang.
- [reserve.dart:720](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L720) —
  ikut memakai versi bersama; class privatnya dihapus.

## Aturan yang dipakai

| Bagian | Aturan |
|---|---|
| Chip gembok di timeline | Hanya muncul mulai tahap berjalan ke atas; tahap yang sudah lewat tidak diberi gembok |
| Tombol "+ Top Up Pembayaran" | Hanya untuk transaksi yang belum SP dan belum ditolak (`canTopUp`) |
| Tab "Data Pembeli" | Read-only; tanda panah cuma muncul kalau transaksinya ditolak, karena satu-satunya jalur edit adalah "Edit & Ajukan Ulang" |
| Nominal di Ajukan Ulang | Peringatan "Kurang Rp …" dihitung dari harga unit dan ikut berubah saat diketik; **tidak** memblokir submit — sesuai mockup, kekurangan boleh dijelaskan lewat catatan |
| Total dibayar | Nominal top up **belum** menambah total sampai kasir memverifikasi; di layar sukses ditampilkan sebagai "Rp A + Rp B" berbadge Menunggu |

Validasi (semua muncul sebagai snackbar, tidak memindahkan halaman):

| Layar | Syarat |
|---|---|
| Top Up | Bukti transfer wajib; nominal > 0 |
| Ajukan Ulang | Dokumen yang ditolak wajib diunggah ulang; nominal > 0 |
| Catatan | Teks tidak boleh kosong |

## Test

[test/reserve_order_menu_smoke_test.dart](test/reserve_order_menu_smoke_test.dart) — 5 kasus:

1. List memetakan JSON mentah (bentuk asli response Anda) ke kartu, dan kata kunci pencarian benar
   sampai ke datasource (bukan disaring di aplikasi).
2. Gagal memuat menampilkan pesan + tombol "Coba lagi", dan menekannya memuat ulang.
3. Detail: timeline L1–L10 & keempat tab, termasuk tab yang kosong karena responsnya belum lengkap,
   link "Profil & Riwayat Lengkap ›" membuka Contact Detail dengan `contact_id` yang benar, dan
   tambah catatan.
4. Top up sampai layar sukses beserta jejaknya di timeline.
5. Flow tolak → perbaiki → balik ke Diproses.

Analyzer tidak menangkap error layout (overflow / unbounded height), jadi test ini yang menjaganya.

## Belum dikerjakan / menunggu Anda

1. **Master status reserve** — endpoint yang memetakan `status_reserve_id` ke nama tahap (Reserve /
   RBA / RBB / SP / Proses Bank / Akad). Begitu ada, chip filter di list bisa dinyalakan lagi dan
   badge status bisa memakai nama asli alih-alih tebakan dari tanggal.
2. **Endpoint detail reserve order** — sudah Anda janjikan menyusul. Begitu ada, `detail.dart`
   disambungkan supaya timeline lengkap L1–L10, tab Data Pembeli, Attachment, dan Catatan terisi
   dari sana, bukan dari field seadanya di response list.
3. **Aksi Top Up & Ajukan Ulang belum mengirim apa pun ke server** — keduanya masih mengubah
   `ReserveOrder` di memori saja, sama seperti submit reserve order (lihat "Yang belum jalan" di
   [reserve-order-scan-ktp-ocr.md](docs/reserve-order-scan-ktp-ocr.md)). Menunggu endpoint aksinya.
