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

## Chip filter tersambung ke `GET /api/reserve-filter`

Chip di atas list (Semua + satu chip per status) sekarang dari master status reserve, bukan
kategori hardcode di app lagi:

- [reserve_order_model.dart](lib/features/reserve-order/data/models/reserve_order_model.dart) —
  `ReserveFilterOption` (`statusReserveId`, `name` dari `status_reserve_name`, `isActive`)
  menggantikan enum `ReserveOrderFilter` lama.
- [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart) —
  `getReserveFilters()`, `GET /reserve-filter`; baris dengan `is_active` 0 disaring keluar sebelum
  sampai ke UI.
- [reserve_order_list_cubit.dart](lib/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart) —
  `loadFresh()` memuat filter & halaman pertama sekaligus lewat `Future.wait`; gagal memuat
  filter cukup dibiarkan (chip tidak tampil), tidak menghalangi daftar transaksinya.
  - **Di-cache di `state.filters`** — `_loadFilters()` langsung `return` kalau `state.filters`
    sudah terisi, jadi `GET /reserve-filter` cuma dipanggil **sekali** per sesi app (cubit-nya
    singleton, provider bersama di `main.dart`), bukan tiap kali halaman List / form Reserve
    dibuka. `ensureFilters()` — method publik buat dipakai dari luar (lihat "Jenis Transaksi" di
    [reserve-order-scan-ktp-ocr.md](reserve-order-scan-ktp-ocr.md)) — pola aksesnya sama: kalau
    sudah ada cache-nya, langsung dikembalikan tanpa fetch ulang; gagal fetch berarti
    `state.filters` tetap kosong, jadi percobaan berikutnya otomatis coba lagi.
  - Pola cache yang sama dipakai lagi buat `state.caraBayarOptions` /
    `ensureCaraBayarOptions()` — master "Cara Pembayaran" di form Reserve
    (`GET /api/reserve/cara-bayar`), lihat "Isi pilihan masih hardcode" di
    [reserve-order-scan-ktp-ocr.md](reserve-order-scan-ktp-ocr.md).
- [list.dart](lib/features/reserve-order/presentation/pages/list.dart) — `_buildFilters()`
  membangun chip dari `state.filters` (plus "Semua" buat reset). Tap chip memanggil
  `cubit.load(statusIds: [id])` — **filternya jalan di server** (`status_reserve_id` beneran
  dikirim), bukan disaring di app seperti sebelumnya, jadi total di header ikut berubah sesuai
  hasil filter.

Chip badge di kartu (`ReserveOrderStatus`/`badgeLabel`) **belum** ikut dialihkan ke
`status_reserve_id` — masih diturunkan dari tanggal seperti sebelumnya (lihat section di bawah).
Filter chip & badge kartu jadi dua sumbu independen buat sementara: chip menyaring by
`status_reserve_id` asli dari server, badge masih tebakan dari tanggal.

**Badge status di kartu & kotak status detail** untuk sementara masih diturunkan dari tanggal yang
ada di response `/api/reserve`, bukan dari `status_reserve_id` — mapping id → namanya sekarang
sudah ada (`GET /api/reserve-filter`, dipakai chip filter di atas), tapi badge kartu belum
dialihkan (lihat "Belum dikerjakan" di bawah):

| Kondisi | Badge |
|---|---|
| `kasir_rejected_datetime`/`kasir_rejected_reason` **atau** `sa_rejected_*` terisi | **Ditolak** |
| `sp_date` terisi | **SP** |
| `rb_date` terisi (tapi belum SP) | **R/BR** — response tidak membedakan RBA/RBB, jadi ditulis netral |
| Selain itu | **Diproses** |

Ini di `ReserveOrder.fromJson()` — [reserve_order_model.dart:263](lib/features/reserve-order/data/models/reserve_order_model.dart#L263).
Begitu ada mapping `status_reserve_id`, badge-nya tinggal dialihkan untuk pakai nama status asli
(termasuk membedakan RBA vs RBB) — field `statusReserveId` sudah disimpan di model, tinggal dipetakan.

## Yang belum ada di response list → detail sebagian kosong

Response `/api/reserve` cuma punya data ringkas. Field yang **tidak ada** di sana diisi seadanya di
`fromJson()` supaya halamannya tidak error, sampai endpoint detailnya (yang sudah Anda janjikan)
tersambung:

| Bagian | Sumbernya sekarang |
|---|---|
| Timeline L1–L3, L5–L10 | Ditandai "belum sampai tahap ini" / chip gembok; hanya L4 (Reserve) yang punya keterangan dari `created_datetime` + `amount_rp` |
| Tab **Data Pembeli** | Sudah tersambung ke `GET /api/reserve/customer` — lihat section "Tab Data Pembeli tersambung ke `GET /api/reserve/customer`" di bawah |
| Tab **Attachment** | Sudah tersambung ke `GET /api/reserve/attachment` — tapi cuma untuk reserve order yang `reserve_order_tts_id`-nya diketahui (lihat section "Tab Attachment tersambung ke `GET /api/reserve/attachment`" di bawah); selain itu tampil "Dokumen transaksi ini belum bisa ditampilkan di sini." |
| Tab **Catatan** | Diisi `reserve_note` sebagai satu catatan, kalau ada |
| `unitLabel` | `property_name` → `deal_blok_no` → "Unit belum ditentukan" (ketiganya sering null di response contoh) |

**Waktu endpoint detailnya siap:** ganti pemanggilan di
[detail.dart](lib/features/reserve-order/presentation/pages/detail.dart) supaya mengambil
timeline lengkap berbekal `order.id`, lalu isi ulang `journey` / `docs` / `notes` dari situ (`buyer`
sudah duluan, lihat section di bawah). Kartu di list tidak perlu berubah — datanya memang cukup
dari `/api/reserve`.

## Tab Data Pembeli tersambung ke `GET /api/reserve/customer`

`GET /api/reserve/customer?reserve_order_id=…` membalas `data.reserve_order` + `data.customer` —
dipanggil dari `ReserveOrderDetailPage.initState` (bukan dari list, supaya list tetap ringan), lalu
dipetakan ke 5 baris tab **Data Pembeli**:

| Baris | Sumbernya |
|---|---|
| Nama Lengkap (sesuai KTP) | `customer.cust_name` |
| No. KTP | `customer.cust_ktp` |
| Alamat sesuai KTP | `customer.cust_address1` |
| Status Pernikahan | `customer.cust_marital_status` (ditulis apa adanya, tidak diubah kapitalisasinya) |
| Cara Pembayaran | `reserve_order.cara_bayar_id` dipetakan ke nama lewat master `GET /api/reserve/cara-bayar` (`ReserveOrderListCubit.ensureCaraBayarOptions()`, sudah di-cache) |

Field yang null tetap ditulis "-", sama seperti sebelum endpoint ini ada. Gagal fetch (koneksi
putus dkk.) juga cuma dibiarkan — tab tetap tampil field "-" bawaan `ReserveOrder.fromJson()`
daripada memblokir seluruh halaman detail.

- [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart) —
  `ReserveOrderRemoteDataSource.getReserveCustomer(reserveOrderId)`, `GET /reserve/customer`.
- [reserve_order_model.dart](lib/features/reserve-order/data/models/reserve_order_model.dart) —
  `ReserveCustomerDetail.fromJson()` memetakan responsnya; `ReserveOrder.applyCustomerDetail()`
  menulis ulang isi `buyer` (field ini sekarang selalu list baru yang bisa di-`clear()`/`addAll()`,
  bukan `const []` bawaan konstruktor lagi).
- [detail.dart](lib/features/reserve-order/presentation/pages/detail.dart) —
  `_loadBuyerDetail()` dipanggil di `initState`, pakai `context.read<ReserveOrderListCubit>()`
  buat akses `dataSource` + `ensureCaraBayarOptions()` (pola yang sama dengan `reserve.dart`, cubit
  yang sama dipakai bareng, tanpa cubit baru khusus detail). Tab-nya tampil `CircularProgressIndicator`
  kecil selama fetch berjalan.

## Tab Attachment tersambung ke `GET /api/reserve/attachment` — tapi cuma untuk reserve order yang baru disubmit di sesi ini

`GET /api/reserve/attachment?reserve_order_id=…&reserve_order_tts_id=…` membalas array dokumen
(KTP/NPWP/bukti transfer) yang tersimpan lewat `POST /api/reserve/doc-payment` — lihat
[reserve-order-scan-ktp-ocr.md](reserve-order-scan-ktp-ocr.md) bagian "Dokumen & rincian pembayaran
dikirim ke `POST /api/reserve/doc-payment`".

**Kendalanya:** `GET /api/reserve` (list, sumber `ReserveOrder` yang dipakai halaman ini) **sama
sekali tidak membawa `reserve_order_tts_id`**, dan satu reserve order bisa punya lebih dari satu TTS
(tiap kali `doc-payment` dipanggil, TTS baru dibuat). Jadi halaman Detail tidak bisa tahu
`reserve_order_tts_id` mana yang mau diambil dokumennya hanya dari `order.id` saja.

**Solusi sementara:** `submitDocPayment()` (dipanggil dari `reserve.dart` `_onSubmit`) sekarang
mengembalikan `reserve_order_tts_id` dari response-nya (`data.tts.reserve_order_tts_id`), langsung
disimpan ke cache di memori lewat `ReserveOrderListCubit.rememberTtsId(reserveOrderId,
reserveOrderTtsId)` — cubit ini singleton (provider bersama `main.dart`, dipakai juga oleh
`list.dart`/`detail.dart`), jadi cache-nya kebawa begitu user pindah dari layar sukses form Reserve
ke menu list lalu buka detailnya. **Cuma menutupi reserve order yang doc-payment-nya dikirim lewat
app ini di sesi app yang sama** — reserve order lama, atau yang di-refresh/dibuka lagi setelah app
di-restart, `ttsIdFor()`-nya `null` dan tab-nya tampil "Dokumen transaksi ini belum bisa ditampilkan
di sini." (beda pesannya dari "Belum ada dokumen." — biar jelas ini keterbatasan sistem, bukan
memang belum ada dokumen). Perbaikan permanennya butuh salah satu dari: endpoint attachment yang
menerima `reserve_order_id` saja (tanpa `reserve_order_tts_id`, ambil semua TTS sekaligus), atau
endpoint buat menelusuri daftar TTS milik satu `reserve_order_id`.

- [reserve_order_model.dart](lib/features/reserve-order/data/models/reserve_order_model.dart) —
  `ReserveOrderAttachment.fromJson()` (row `contact_attachments` yang sama dengan attachment kontak
  biasa, tapi field-nya beda — ada `verification_status`/`create_user_name`/dll — jadi model
  terpisah, bukan reuse `ContactAttachment` dari fitur contact).
- [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart) —
  `getReserveAttachments({reserveOrderId, reserveOrderTtsId})`, `GET /reserve/attachment`.
- [reserve_order_list_cubit.dart](lib/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart) —
  `rememberTtsId()`/`ttsIdFor()`, cache `Map<int, int>` di memori (bukan bagian dari
  `ReserveOrderListState` yang Equatable — tidak perlu memicu rebuild).
- [detail.dart](lib/features/reserve-order/presentation/pages/detail.dart) — `_loadAttachments()`
  dipanggil di `initState` bareng `_loadBuyerDetail()`, pola yang sama (silent-fail, spinner kecil
  selama fetch). Tiap `ReserveOrderAttachment` dibungkus jadi `ReserveOrderDoc` (`_docFrom()`) supaya
  bisa dirender pakai `roDocTile()` yang sudah ada — tidak ada tile baru dibuat khusus untuk ini.
  Tap kartunya buka `context.pushNamed('attachmentWebView', extra: attachment.attachmentUrl)` —
  route yang sama persis dipakai attachment kontak (`contact-detail/index.dart`), bukan webview baru.

## Link "Profil & Riwayat Lengkap ›" sudah jalan

`contact_id` & `deal_id` dari response dipakai untuk membuka `ContactDetailPage` (route
`detailContact`) — [detail.dart:541](lib/features/reserve-order/presentation/pages/detail.dart#L541).
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

- [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart) —
  `ReserveOrderRemoteDataSource.getReserveOrders()`, `GET /reserve` + `ReserveOrdersPage`
  (items, page, hasMore dari `next_page_url`, total).
- [reserve_order_list_cubit.dart](lib/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart) —
  `ReserveOrderListCubit`, pola sama seperti `ReserveUnitCubit` (datasource langsung, tanpa
  usecase/repository): `load()` untuk halaman pertama + ganti pencarian/filter, `loadMore()` untuk
  infinite scroll, `refresh()` untuk pull-to-refresh.
- [reserve_order_list_state.dart](lib/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_state.dart) —
  `ReserveOrderListState`.
- [main.dart:438](lib/main.dart#L438) + [main.dart:542](lib/main.dart#L542) — datasource &
  provider.

### 4. Model

- [reserve_order_model.dart](lib/features/reserve-order/data/models/reserve_order_model.dart) —
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

- [list.dart](lib/features/reserve-order/presentation/pages/list.dart) — `ReserveOrderListPage`.
  Pencarian didebounce 400 ms lalu dikirim ke server (bukan disaring di aplikasi); scroll mendekati
  bawah memicu `loadMore()`; shimmer (`buildContactListShimmer`) dipakai saat memuat, dan ada
  tombol "Coba lagi" saat gagal.
- [detail.dart](lib/features/reserve-order/presentation/pages/detail.dart) —
  `ReserveOrderDetailPage` beserta timeline, keempat tab, dan kotak tulis catatan.
- [top_up.dart](lib/features/reserve-order/presentation/pages/top_up.dart) —
  `ReserveOrderTopUpPage`, sekaligus layar suksesnya.
- [revise.dart](lib/features/reserve-order/presentation/pages/revise.dart) —
  `ReserveOrderRevisePage`.
- [widgets.dart](lib/features/reserve-order/presentation/pages/widgets.dart) — potongan UI
  yang dipakai berulang: app bar, avatar, badge status (`roStatusBadge(label, color)` — label &
  warnanya dikirim terpisah karena badge kini bisa lebih spesifik dari `ReserveOrderStatus`), label,
  input, chip, baris dokumen, banner tolak, baris ringkasan, footer, dan `roPrimaryButton` (tombol
  utama dengan status loading).

### 6. Perbaikan: baris tab "Data Pembeli" tidak disembunyikan lagi

- [reserve_order_model.dart:364](lib/features/reserve-order/data/models/reserve_order_model.dart#L364) —
  `buyer` sekarang selalu berisi 5 baris tetap (Nama Lengkap, No. KTP, Alamat sesuai KTP, Status
  Pernikahan, Cara Pembayaran) sesuai mockup; yang datanya belum ada dari `/api/reserve` ditulis
  "-", bukan dihapus dari list. Sebelumnya "No. HP" ikut nongol di tab ini kalau ada isinya —
  dihapus karena sudah ada di baris kontak cepat atas tab (duplikat) dan memang tidak ada di mockup.

### 7. Dipakai juga sebagai daftar transaksi per-kontak

`ReserveOrderListPage` sekarang juga dibuka dari "Reserve Order" di bottom sheet Log Activity
kontak (gantinya `ReserveOrderPage` blank) — detail lengkapnya di
[contact-detail-reserve-order-menu.md](contact-detail-reserve-order-menu.md) bagian "Dialihkan ke
daftar transaksi per-kontak". Ringkas: `contactArgs` (opsional) mengisi query `contact_id` ke
`GET /api/reserve`, dan kontak yang belum punya transaksi sama sekali ditawari "+ Buat Reserve
Baru" alih-alih pesan kosong polos.

### 8. Pindah jadi feature module sendiri (`lib/features/reserve-order/`)

Sebelumnya file data & state-nya menumpang di `lib/features/contact/` (datasources, models, state)
sementara halamannya sempat lepas di `lib/features/reserve-order/` tanpa struktur — sekarang
disatukan jadi satu feature module dengan pola `data/` + `presentation/{pages,state}/` yang sama
seperti `contact/` (tanpa `domain/`, karena slice ini sengaja tanpa layer usecase/repository — lihat
catatan di `ReserveOrderListCubit`):

```
lib/features/reserve-order/
  data/
    datasources/   reserve_order_remote_datasource.dart, reserve_unit_remote_datasource.dart,
                    ktp_ocr_remote_datasource.dart
    models/        reserve_order_model.dart, ktp_ocr_model.dart
  presentation/
    pages/          detail.dart, index.dart, list.dart, reserve.dart, revise.dart, top_up.dart,
                    widgets.dart
    state/          reserve_order_list/, reserve_unit/, reserve_attachment/, ktp_ocr/
```

Model unit (`unit_hierarchy_model.dart`/`unit_option_model.dart`) **tidak** ikut pindah — dipakai
bersama `contact-add`/`contact-form`/`unit-picker` juga, jadi tetap di
`lib/features/contact/data/models/unit/`. `reserve_attachment_cubit.dart` juga tetap mengimpor
usecase attachment dari `contact/domain/` (dipakai bersama, bukan reserve-order-spesifik).

### 9. Formatter ribuan dipindah jadi milik bersama

- [thousands_input_formatter.dart](lib/core/utils/widget/thousands_input_formatter.dart) —
  `ThousandsInputFormatter`, sebelumnya class privat `_ThousandsFormatter` di dalam `reserve.dart`.
  Sekarang dipakai bertiga: flow Reserve, Top Up, dan Ajukan Ulang.
- [reserve.dart:720](lib/features/reserve-order/presentation/pages/reserve.dart#L720) —
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

[test/reserve_order_menu_smoke_test.dart](test/reserve_order_menu_smoke_test.dart) — 7 kasus:

1. List memetakan JSON mentah (bentuk asli response Anda) ke kartu, dan kata kunci pencarian benar
   sampai ke datasource (bukan disaring di aplikasi).
2. Chip filter dari `GET /api/reserve-filter`: status `is_active: 0` tidak tampil jadi chip, tap
   chip mengirim `status_reserve_id` yang benar ke `getReserveOrders()` (bukan disaring di app),
   dan "Semua" mereset ke daftar penuh.
3. Gagal memuat menampilkan pesan + tombol "Coba lagi", dan menekannya memuat ulang.
4. Detail: timeline L1–L10 & keempat tab, termasuk tab Attachment yang tampil "belum bisa
   ditampilkan" karena `reserve_order_tts_id`-nya tidak diketahui (lihat kasus #5), link
   "Profil & Riwayat Lengkap ›" membuka Contact Detail dengan `contact_id` yang benar, dan tambah
   catatan.
5. Tab Attachment **dengan** `reserve_order_tts_id` yang sudah di-`rememberTtsId()` duluan (meniru
   reserve order yang doc-payment-nya baru disubmit di sesi app yang sama) — dokumennya tampil
   (nama tipe + "Diunggah <nama> · <tanggal>"), dan tap kartunya membuka route `attachmentWebView`
   bawa `attachment_url`-nya. `_pumpMenu()` dapat parameter opsional `cubit` khusus test ini, supaya
   `rememberTtsId()` bisa dipanggil di cubit yang sama sebelum widget-nya dibangun.
6. Top up sampai layar sukses beserta jejaknya di timeline.
7. Flow tolak → perbaiki → balik ke Diproses.

Test chip filter & test pertama sengaja memakai viewport yang dilebarkan (`_pumpMenu(tester,
width: 900)`) supaya semua chip kebangun tanpa gulir horizontal — drag scroll ke item yang di luar
cache extent rapuh di widget test (`ensureVisible` butuh elemennya sudah kebangun; kalaupun pakai
`scrollUntilVisible`, arah drag yang tetap bikin gagal begitu targetnya ada di belakang posisi
scroll saat ini).

Analyzer tidak menangkap error layout (overflow / unbounded height), jadi test ini yang menjaganya.

## Belum dikerjakan / menunggu Anda

1. **Badge status kartu & detail belum pakai `status_reserve_id`** — chip filter di atas list
   sudah (lihat "Chip filter tersambung ke `GET /api/reserve-filter`" di atas), tapi
   `ReserveOrder.fromJson()` masih menurunkan `ReserveOrderStatus`/`badgeLabel` dari tanggal
   (`sp_date`/`rb_date`/status ditolak), bukan dari `status_reserve_id` baris itu sendiri. Begitu
   diputuskan bagaimana memetakan tiap id master (RBB/Reserve/RKB/Reserve Batal/Waitinglist/SP/
   RBA/SP Batal) ke `ReserveOrderStatus` & warnanya, badge bisa memakai nama asli alih-alih
   tebakan dari tanggal.
2. **Endpoint detail reserve order** — tab **Data Pembeli** sudah tersambung
   (`GET /api/reserve/customer`, lihat section di atas), tab **Attachment** juga sudah
   (`GET /api/reserve/attachment`, lihat section "Tab Attachment tersambung ke
   `GET /api/reserve/attachment`" di atas) tapi terbatas ke reserve order yang
   `reserve_order_tts_id`-nya diketahui (baru disubmit di sesi app yang sama). Timeline L1–L10
   lengkap & Catatan masih menunggu endpoint detailnya menyusul.
3. **Aksi Top Up & Ajukan Ulang belum mengirim apa pun ke server** — keduanya masih mengubah
   `ReserveOrder` di memori saja, sama seperti submit reserve order (lihat "Yang belum jalan" di
   [reserve-order-scan-ktp-ocr.md](docs/reserve-order-scan-ktp-ocr.md)). Menunggu endpoint aksinya.
