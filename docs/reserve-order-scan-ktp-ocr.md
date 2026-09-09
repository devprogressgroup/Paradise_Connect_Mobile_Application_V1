# Reserve Order — Flow Sales (Data Pembeli → Dokumen → Unit → Review → Sukses)

Sumber desain: [reserve-order-sales-final_12.html](reserve-order-sales-final_12.html) **Bagian 2 —
Proses Reserve/Booking Reserve** (file mockup ada di root repo). Dokumen ini mencatat implementasi
Flutter-nya + endpoint pendukung di backend.

## Ringkasan

Item **Reserve** di halaman menu Reserve Order membuka satu halaman
([reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)) berisi 4 step
+ layar sukses, dengan stepper di atas yang menandai step berjalan (hijau = selesai, biru =
sekarang):

1. **1/4 Pembeli** — tombol **Scan KTP** (OCR mengisi field di bawahnya otomatis), lalu Nama
   Lengkap, No. KTP, "Tempat, Tanggal Lahir", Alamat sesuai KTP, Status Pernikahan (sheet
   pilihan), Pekerjaan, Cara Pembayaran (sheet pilihan). Tombol **Lanjut ke Dokumen**.
2. **2/4 Dokumen** — bagian *Dokumen Identitas* (KTP wajib, NPWP opsional) dan *Bukti Bayar*
   (bisa lebih dari satu lewat **+ Tambah Bukti Bayar Lain**), lalu **Jenis Transaksi**
   (chip: Reserve / Booking Reserve (langsung)), **Nominal Pembayaran**, dan **Catatan**.
   Tombol **Lanjut ke Pilih Unit**.
3. **3/4 Unit** — daftar kavling dengan kotak pencarian "Cari blok / no. unit…", checkbox
   **multi-pilih**, dan badge status. Footer menampilkan "N unit dipilih" + **Lanjut ke Review**.
4. **4/4 Review** — ringkasan (Kontak, Data Pembeli, Dokumen, Jenis Transaksi, Nominal & Catatan)
   + kartu per unit terpilih. Tombol **Submit Reserve Order**.
5. **Sukses** — ikon centang, "Reserve Order Berhasil Diajukan", kartu unit + badge **Diproses**,
   tombol **Lihat di Reserve Order** dan **Kembali ke Kontak**.

Judul app bar mengikuti mockup: step 1-2 "Reserve Order — <nama kontak>" + nomor HP di bawahnya,
step 3 "Pilih Unit", step 4 "Review Reserve Order". Tombol back (header maupun tombol back sistem)
mundur **satu** step; di layar sukses tidak ada jalan mundur.

## Validasi tiap step

| Step | Syarat lanjut |
|---|---|
| Pembeli | Nama lengkap terisi; No. KTP tepat 16 digit |
| Dokumen | Lampiran KTP ada; minimal 1 bukti bayar; nominal > 0 |
| Unit | Minimal 1 unit dipilih |
| Review | — (langsung submit) |

NPWP & catatan opsional. Semua pesan gagal keluar sebagai snackbar, tidak memindahkan step.

## OCR KTP

Tombol **Scan KTP** membuka sheet **Camera / Upload**, lalu fotonya dikirim ke
`POST /api/reserve/ktp-ocr` (server-side OCR). Detail engine, konfigurasi, dan bentuk response ada
di `docs/api/reserve/post-reserve-ktp-ocr.md` pada repo backend.

Kenapa OCR di server: app ini jalan sebagai PWA web **dan** mobile —
`google_mlkit_text_recognition` tidak punya implementasi web, `tesseract.js` cuma jalan di
browser, dan API key OCR pihak ketiga kalau dipanggil dari Flutter web akan ikut ke-bundle di JS.
Engine di server: **Tesseract** (gratis, tanpa billing, foto tidak keluar server); Cloud Vision
tersedia sebagai alternatif satu baris `.env`.

Perlakuan hasilnya:

- Field yang tampil di form diisi langsung; yang kosong dibiarkan supaya user melengkapi manual.
- "Tempat, Tanggal Lahir" tampil sebagai **satu** field teks (mengikuti mockup), tapi nilai
  terpisahnya tetap disimpan (`_birthPlace`, `_birthDate`) supaya tidak perlu diurai ulang saat
  submit ke `POST /api/reserve` nanti.
- Status pernikahan dicocokkan ke daftar pilihan tanpa memedulikan huruf besar/kecil & tanda
  hubung ("BELUM KAWIN" → "Belum Kawin").
- Field hasil OCR yang **tidak** ada di form ini (agama, jenis kelamin, kecamatan, kabupaten)
  ikut dibawa keluar flow lewat `ReserveResult.ktpOcr` supaya tidak hilang.
- Foto KTP-nya sekaligus dipakai sebagai lampiran dokumen KTP di step 2 — tidak perlu unggah dua
  kali.

## Daftar unit (step 3) — `GET /api/reserve/unit-status`

Daftar kavling di step ini adalah unit (satu baris per **deal**) milik kontak yang sedang dibuatkan
Reserve Order-nya — dicari & dipaginasi di server: `GET /api/reserve/unit-status?contact_id=&search=
&sort=created_desc&page=&per_page=`. Sebelumnya step ini sempat memakai snapshot lokal
(`ContactEntity.units`, ikut terbawa sekali saat contact detail dibuka) sebelum endpoint ini ada.

Sisi Flutter:

- `SelectedUnit.fromUnitStatusJson()` —
  [unit_hierarchy_model.dart](lib/features/contact/data/models/unit/unit_hierarchy_model.dart) —
  mapping field respons (`deal_id`, `cluster_id`/`product_id`/`property_id` yang bisa null
  sekaligus untuk deal yang belum ditentukan kavlingnya, `is_waiting_list`/`is_tipe_hoek` bool-atau-1,
  `status_name`, `deal_value`, `is_property_sellable`).
- [reserve_unit_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart)
  + [reserve_unit_cubit.dart](lib/features/reserve-order/presentation/state/reserve_unit/reserve_unit_cubit.dart)
  — **retarget** dari cubit yang sebelumnya dibuat buat endpoint lain
  (`GET /api/property/units/hierarchy?flat=1`, item-nya `UnitOption`) tapi ternyata tidak pernah
  dipakai halaman manapun (dead code, hanya ke-wire di provider `main.dart`). Karena sudah tidak ada
  konsumen lain, cubit ini langsung disesuaikan ke endpoint contact-scoped di atas alih-alih bikin
  cubit baru terpisah — item-nya sekarang `SelectedUnit` langsung (bukan `UnitOption`), jadi
  `_contactUnitRow`/`_unitRowTitle`/`_unitRowSubtitle` di `reserve.dart` tidak perlu layer mapping
  tambahan. `UnitOption`/`UnitOptionsPage` (`unit_option_model.dart`) dihapus karena jadi tidak
  terpakai sama sekali.
  - Pencarian di-debounce 300ms (`_onSearchChanged` di `reserve.dart`, Timer yang sama dipakai
    sebelumnya) lalu panggil `ReserveUnitCubit.setSearch()`.
  - Load-more dipicu scroll mendekati bawah (`_onUnitScroll`, threshold 240px — pola sama persis
    dengan `list.dart` punya `ReserveOrderListCubit`). Bentuk paginasinya paginator Laravel standar
    (sama seperti `GET /api/reserve`, **bukan** `units`/`page`/`has_more` custom seperti endpoint
    hierarchy unit yang lama) — array unit-nya ada di `data.data` (bukan `data.units`!), dan
    `hasMore`/`page` dibaca dari `data.next_page_url`/`data.current_page`.
  - **Cubit ini singleton** (satu instance dibagi lintas halaman lewat provider `main.dart`, sama
    seperti `ReserveOrderListCubit`) — begitu Reserve Order dibuka untuk `contact_id` yang **beda**
    dari sesi sebelumnya, `ReserveUnitCubit.load()` me-reset total state-nya (bukan `copyWith`)
    supaya unit kontak lama tidak nyangkut kelihatan sebentar di kontak baru.
- [main.dart:437](lib/main.dart#L437) + [main.dart:540](lib/main.dart#L540) — datasource & provider
  (tidak berubah tempatnya, cuma target endpoint & item-nya yang beda sekarang).
- **`key` pembeda unit** (`SelectedUnit.key`, dipakai `_selectedUnits` Map) sekarang mengutamakan
  `deal_id` kalau ada (`'deal:$dealId'`) — satu kontak bisa punya lebih dari satu deal yang
  cluster/product/property-nya sama-sama null (belum ditentukan kavlingnya), yang tanpa `dealId`
  bakal tabrakan jadi satu key yang sama. Sumber `SelectedUnit` lain (`fromContactJson`, unit
  picker contact-add) tidak punya `dealId` — key-nya tetap seperti sebelumnya, tidak ada perubahan
  perilaku di situ.
- Unit yang **tidak sellable** (`is_property_sellable: false` — mis. sudah SP/akad di kontak lain)
  tetap tampil tapi pudar (`Opacity` 0.5 pada seluruh baris) dan tidak bisa dicentang (`onTap: null`
  saat tidak sellable).
- Badge status (mis. "Available"/"Hold"/"Reserve") pakai
  [UnitStatusBadge](lib/core/utils/widget/unit_status_badge.dart) yang sudah ada — warna latar per
  nama status sudah ditentukan di widget itu sendiri (sama seperti dipakai
  `site-plan/unit-detail`), jadi tidak ada mapping warna baru yang dibuat di sini. Yang ditambahkan
  cuma `textColor` gelap khusus untuk "Available" (#00FF0C) dan "Reserve" (#EAFF00) — dua warna
  latar paling terang yang bikin teks putih default nyaris tak terbaca (`_statusBadgeTextColor` di
  `reserve.dart`); status lain tetap teks putih.
- **Harga sekarang tampil** (`deal_value`, field `dealValue` di `SelectedUnit`) di baris kedua kartu
  unit, mis. "PAR2 · Ecoscape · Rp 450.000.000" — beda dari sebelumnya (lihat versi lama dokumen ini
  di git history: harga sempat tidak bisa ditampilkan karena tidak ada di database inventory
  `m_property_lot`/`m_sellable_unit`; endpoint `unit-status` yang deal-scoped ini rupanya sudah
  membawa nominalnya sendiri lewat `deal_value`).

## Nominal pembayaran

Field nominal memakai prefix "Rp " + formatter pemisah ribuan
([`ThousandsInputFormatter`](lib/core/utils/widget/thousands_input_formatter.dart)):
mengetik `2000000` tampil `2.000.000`, dan nilai numeriknya diambil ulang dari digit-nya saja.
Kursor selalu ditaruh di akhir — menghitung ulang posisinya setelah titik disisipkan membuat
kursor melompat, sementara field ini praktis selalu diisi dari belakang.

Nominal ini juga yang menjawab pertanyaan sebelumnya soal angka di kartu menu: sumbernya step
**Dokumen & Bukti Bayar**, bukan input di step Unit atau harga unit.

## Baris customer dibuat lewat `POST /api/reserve` (begitu lepas dari step Dokumen)

Begitu tombol **Lanjut ke Pilih Unit** (step Dokumen) ditekan dan lolos validasi, langkah
berikutnya bikin baris `m_customer_reserve` lewat `POST /api/reserve` — **bukan** menunggu sampai
Submit di Review lagi. Alasannya: step Pilih Unit butuh `customer_id` buat menautkan unit yang
dipilih lewat `POST /api/reserve-unit` (section di bawah), jadi baris customer-nya harus sudah ada
sebelum step itu dibuka. Gagal di sini menahan user di step Dokumen dengan pesan errornya, dan
tidak lanjut ke Pilih Unit.

`createReserve()` mengembalikan `CreateReserveResult` (`reserveOrderId` + `customerId`, dari
`data.reserve_order.reserve_order_id`/`customer_id`) — disimpan sebagai `_reserveOrderId`/
`_customerId` di [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart),
dipakai lagi oleh `_onNextUnit` (`saveReserveUnit`) dan `_onSubmit` (`submitDocPayment`). Kalau
user mundur dari Unit ke Dokumen lalu maju lagi, `_onNextDokumen` **tidak** bikin baris baru lagi
selama `_reserveOrderId`/`_customerId` sudah ada — cukup lanjut ke Unit dengan id yang sama.

Payload-nya (`CreateReserveParams.toJson()` —
[reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart)):

| Field JSON | Sumbernya di form |
|---|---|
| `contact_id` | `ContactEntity.contactId` (wajib — kalau null, submit ditahan sebelum ini) |
| `cust_name` | Nama Lengkap |
| `cust_ktp` | No. KTP |
| `cust_birth_place` / `cust_birth_date` | "Tempat, Tanggal Lahir" — lihat catatan parsing di bawah |
| `cust_gender_is_male` | `KtpOcrModel.jenisKelamin` hasil scan ("Laki-laki"/"Perempuan" → bool). **Belum ada input manual** — null kalau belum pernah scan KTP |
| `cust_marital_status` | Status Pernikahan, di-`toUpperCase()` (mis. "Kawin" → "KAWIN") |
| `cust_religion` | `KtpOcrModel.agama` hasil scan. **Belum ada input manual**, sama seperti jenis kelamin |
| `cust_occupation` | Pekerjaan |
| `cust_address1` | Alamat sesuai KTP |
| `cara_bayar_id` | Cara Pembayaran — **id-nya** yang dikirim (dari `GET /api/reserve/cara-bayar`), bukan nama; lihat "Cara Pembayaran" di bawah |
| `cust_telp_mobile1` | `ContactEntity.primaryPhone` |

Field yang null/kosong tidak ikut dikirim (`toJson()` menyaringnya) ketimbang mengirim string kosong
atau `null` literal.

**Parsing "Tempat, Tanggal Lahir":** field ini teks bebas (bisa diisi manual maupun otomatis dari
OCR). Kalau OCR pernah jalan, `cust_birth_place`/`cust_birth_date` diambil langsung dari hasil
OCR-nya (`_birthPlace`/`_birthDate`, disimpan terpisah dari teks yang tampil). Kalau usernya isi
manual tanpa pernah scan, `_resolvedBirth()` di
[reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) mem-parse-balik teks
field-nya sesuai format hint-nya persis: `"<tempat>, dd MMMM yyyy"` (mis. "Jakarta, 09 Januari
1990"). Format lain gagal parse tanggalnya dan `cust_birth_date` dikirim kosong (tempatnya tetap
terkirim kalau ada koma).

## Unit ditautkan ke customer lewat `POST /api/reserve-unit` (begitu lepas dari step Pilih Unit)

Begitu tombol **Lanjut ke Review** (step Unit) ditekan dan minimal 1 unit terpilih, tiap unit yang
dicentang ditautkan ke customer yang barusan dibuat (section di atas) lewat `POST
/api/reserve-unit` — satu request per unit, payload `{ "deal_id": …, "customer_id": … }`.
`deal_id`-nya dari `SelectedUnit.dealId` (field ini yang membedakan satu baris deal di
`GET /api/reserve/unit-status`, lihat "Daftar unit (step 3)" di atas); unit yang tidak punya
`dealId` (mis. kalau suatu saat `SelectedUnit` dibuat dari sumber lain) dilewati begitu saja — tidak
ada deal yang bisa ditautkan.

Gagal di sini menahan user di step Unit dengan pesan errornya (baris customer-nya **tetap**
tersimpan — cuma penautan unitnya yang perlu dicoba ulang), dan tidak lanjut ke Review.

Kode: `saveReserveUnit()` — [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart).
[reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) `_onNextUnit()` yang
mengirim satu-per-satu (bukan `Future.wait` paralel) — kalau ada yang gagal di tengah, sisanya tidak
usah dilanjutkan.

## Dokumen & rincian pembayaran dikirim ke `POST /api/reserve/doc-payment` (saat Submit)

`POST /api/reserve/doc-payment` — endpoint khusus reserve order (bukan attachment kontak lagi) yang
menyimpan KTP/NPWP/bukti transfer **dan** rincian pembayaran (jenis transaksi, nominal, catatan)
sebagai baris `t_reserve_order_tts` milik order itu, pakai `reserve_order_id` dari `createReserve()`
(section di atas — sudah didapat lebih awal, begitu lepas dari step Dokumen).

**Kapan:** sekali di akhir, waktu tombol **Submit Reserve Order** ditekan — bukan saat file dipilih.
Selama 3 step pertama berkasnya ditahan di memori halaman, jadi kalau flow-nya ditinggal di tengah
jalan tidak ada dokumen/pembayaran nyangkut di reserve order manapun (baris customer & unitnya
sendiri sudah kadung tersimpan lebih awal — lihat dua section di atas). Gagal di `doc-payment`
menahan di Review dengan pesan errornya; `reserve_order_id`-nya tetap ada di server, cuma
dokumennya yang perlu dicoba ulang.

**Bentuk request** (`FormData`, bukan JSON) — field-nya disamakan persis dengan koleksi Postman yang
dipakai backend buat uji endpoint ini:

| Field | Sumbernya di form | Catatan |
|---|---|---|
| `reserve_order_id` | Hasil `createReserve()` | Wajib |
| `status_reserve_id` | Chip **Jenis Transaksi** — id-nya dicari dari `GET /api/reserve-filter` (`_statusReserveIdOf`, sama master yang dipakai isi chip-nya) | Wajib; kalau id-nya tidak ketemu (lagi pakai fallback lokal), submit ditahan dengan pesan "Jenis transaksi tidak dikenali" |
| `tts_amount_rp` | Nominal Pembayaran | Wajib |
| `note` | Catatan | Opsional, tidak dikirim kalau kosong |
| `ktp[]` | Slot **Dokumen Identitas → KTP** | Array (key-nya pakai kurung), tapi form ini baru punya 1 slot jadi selalu terkirim 1 elemen |
| `npwp` | Slot **Dokumen Identitas → NPWP** | Opsional, tidak dikirim kalau tidak diisi. **Bukan array**, tidak ada kurung |
| `bukti_transfer` | Semua proof di **Bukti Bayar** (bisa >1 lewat "+ Tambah Bukti Bayar Lain") | Boleh >1 file, tapi key-nya **TETAP tanpa kurung** — beda dari `ktp[]`. Dio mengirim beberapa part bernama persis `bukti_transfer` (bukan `bukti_transfer[]`) untuk tiap file-nya |

Kode: [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart)
— `DocPaymentParams` + `ReserveOrderRemoteDataSourceImpl.submitDocPayment()`.
[reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) `_onSubmit()` merangkai
kedua panggilan (`createReserve` → `submitDocPayment`).

**Kenapa `FormData`, bukan base64-JSON seperti upload attachment kontak:** proxy `/px`
([dio_client.dart](lib/core/network/dio_client.dart)) sudah bisa mengonversi `FormData` (fields +
files) jadi JSON terenkripsi secara generik — dipakai juga oleh `createContact`/`ktp-ocr`. Satu
perbaikan dibutuhkan di situ: konversinya tadinya nyimpan file per `MultipartFile.key` di sebuah
`Map`, jadi kalau ada >1 file dengan key yang sama (`ktp[]`) entri berikutnya menimpa yang sebelumnya
— sekarang entri dengan key yang sama diakumulasi jadi `List` supaya array file beneran terkirim
semuanya.

> **Gotcha `Dio.FormData.fromMap` + key array file:** sempat salah menaruh nilai `List<MultipartFile>`
> di key **`'ktp'`** (tanpa kurung), berharap Dio otomatis menambahkan `[]` seperti halnya nested
> `Map`/`List` biasa. Ternyata **tidak** — `encodeMap` (`dio/src/utils.dart`) cuma menambahkan
> `[index]` untuk item yang `is Map`/`is List`; `MultipartFile` bukan keduanya, jadi path-nya
> (nama field) tetap sama persis dengan key yang diberikan untuk SETIAP elemen list-nya. Hasilnya:
> beberapa field literal bernama `ktp` (bukan `ktp[]`) — yang oleh Laravel **tidak** dianggap array
> (`$request->file('ktp')` cuma dapat file terakhir), persis bunyi error backend "The ktp field
> must be an array." Perbaikannya: pakai key literal **`'ktp[]'`** sendiri di map yang dikirim ke
> `FormData.fromMap()` (lihat `submitDocPayment` di
> [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart)),
> bukan mengandalkan Dio menambahkannya otomatis. `npwp` (selalu 1 file) tidak kena masalah ini.
> `bukti_transfer` juga sengaja dikirim sebagai `List<MultipartFile>` (boleh >1 file) tapi TANPA
> kurung di key-nya — mekanisme yang sama (beberapa part dengan nama field yang sama persis) di sini
> justru diminta: hasilnya beberapa field literal bernama `bukti_transfer`, bukan `bukti_transfer[]`.

**Loading state per step** (tombol berubah teks + spinner, tombol back ditahan supaya tidak ada
proses separuh jalan):

| Step | Tombol saat loading |
|---|---|
| Dokumen → Unit | "Membuat reserve order..." (`_creatingReserve`) |
| Unit → Review | "Menyimpan unit..." (`_savingUnit`) |
| Review → Sukses | "Mengunggah dokumen..." (`_submittingDocPayment`, tanpa progress N/M — cuma 1 request `doc-payment`) |

## Kembali ke halaman menu

Halaman flow mengembalikan
[`ReserveResult`](lib/features/reserve-order/presentation/pages/reserve.dart) (unit,
nominal, jenis transaksi, nama, hasil OCR) lewat `context.pop()`:

- **Lihat di Reserve Order** → pop ke halaman menu; kartu "Reserve" langsung menampilkan unit +
  "Rp …" dan centang hijau.
- **Kembali ke Kontak** → pop dua kali (keluar dari flow **dan** dari halaman menu). Router
  diambil sebelum pop pertama, karena setelah route dilepas `context`-nya sudah tidak sah.

Kartu di halaman menu: [reserve-order/index.dart](lib/features/reserve-order/presentation/pages/index.dart)
— judul, rincian (unit lalu nominal), kotak centang hijau saat selesai, dan ikon pensil di kanan.
**Topup** dan **RB** menampilkan pensil juga (mengikuti mockup) tapi menekannya memunculkan pesan
"… belum tersedia."

## Pengaman otomatis

[test/reserve_page_smoke_test.dart](test/reserve_page_smoke_test.dart) — 9 test widget di layar
390x844:

1. Kelima layar render tanpa error layout (overflow / unbounded height — **tidak** terdeteksi
   `flutter analyze`), sheet pilihan jalan, validasi tiap step menahan langkah, nominal diformat,
   unit bisa dicari, sampai layar sukses. Termasuk picker "Cara Pembayaran": isinya dari
   `_FakeReserveOrders.getCaraBayarOptions()` (mis. "Cash Bertahap 3X"), bukan daftar hardcode lama
   — yang tampil & dipilih di sheet tetap `name`.
2. Submit mengirim KTP, **dua** bukti bayar (buktiin `bukti_transfer` boleh >1 file, terkirim
   semuanya bukan cuma yang pertama), dan rincian pembayaran ke `POST /api/reserve/doc-payment`
   dengan `reserve_order_id` dari response `createReserve()`, `status_reserve_id` hasil pencarian
   dari "Jenis Transaksi" terpilih, `tts_amount_rp`, `ktp[]`/`bukti_transfer` yang benar. NPWP yang
   tidak dilampirkan tidak ikut dikirim.
3. `doc-payment` yang gagal menahan user di step Review beserta pesan errornya.
4. Flow penuh dari halaman menu → submit → **Lihat di Reserve Order**, memastikan kartu menu dapat
   unit + "Rp 2.000.000" + centang.
5. "Jenis Transaksi" render dari `_FakeReserveOrders.getReserveFilters()` (bukan daftar hardcode),
   dan `ReservePage` yang dibuka dua kali dengan `ReserveOrderListCubit` yang sama cuma memanggil
   `getReserveFilters()` sekali (`filterCalls == 1`) — buktiin cache-nya kepakai. Dibuka "dua kali"
   di test-nya sengaja pump `SizedBox.shrink()` dulu sebelum `MaterialApp` yang baru, supaya
   elemen `ReservePage` sebelumnya benar-benar di-dispose (tree berbentuk sama + tanpa key cuma
   di-rebuild oleh `pumpWidget`, bukan mount ulang — kalau tidak dipaksa lepas, `_step` dkk kebawa
   dari sesi sebelumnya).
6. `POST /api/reserve` (`_FakeReserveOrders.createReserve()`) terkirim begitu lepas dari step
   Dokumen (**bukan** menunggu Submit di Review) — Tempat/Tanggal Lahir diisi manual ("Jakarta, 09
   Januari 1990", tanpa scan KTP) buat membuktikan parsing-balik `_resolvedBirth()` jalan, lalu tiap
   field payloadnya dicek satu-satu (`contact_id`, `cust_name`, `cust_ktp`,
   `cust_birth_place`/`cust_birth_date`, `cust_marital_status` yang di-uppercase, `cust_occupation`,
   `cust_address1`, `cara_bayar_id` dari opsi yang dipilih, `cust_telp_mobile1`), termasuk
   `toJson()`-nya (`cust_birth_date` jadi string `"1990-01-09"`). `cust_gender_is_male`/
   `cust_religion` dicek null karena belum pernah scan KTP. `POST /api/reserve-unit`
   (`saveReserveUnit()`) lalu dicek terkirim begitu lepas dari step Unit, dengan `deal_id` unit yang
   dipilih + `customer_id` dari `createReserve()`. Terakhir, Submit di Review cuma menambah
   `docPaymentCalls` (bukan `createCalls` — tidak dipanggil ulang), pakai `reserve_order_id` yang
   sama dari `createReserve()` tadi.
7. `POST /api/reserve` yang gagal (`failCreate = true`) menahan user di step **Dokumen** (tidak
   lanjut ke Pilih Unit) dengan pesan errornya; `saveReserveUnit`/`doc-payment` **tidak** ikut
   dipanggil.
8. `POST /api/reserve-unit` yang gagal (`failSaveUnit = true`) menahan user di step **Unit** (tidak
   lanjut ke Review) dengan pesan errornya — baris customer-nya (`createCalls`) tetap sudah dibuat
   sebelumnya, cuma penautan unitnya yang gagal; `doc-payment` **tidak** ikut dipanggil.
9. Unit yang `is_property_sellable: false` tetap tampil (pudar) tapi tidak bertambah ke "N unit
   dipilih" saat ditap, sementara unit sellable di sebelahnya tetap bisa; harga (`deal_value`) dan
   badge status (`status_name`, mis. "Available"/"Reserve") ikut tampil di kartunya.

Daftar unit di step 3 dimuat dari `_FakeReserveUnits` (`ReserveUnitRemoteDataSource` palsu,
menyediakan `SelectedUnit` langsung — meniru `GET /api/reserve/unit-status`), bukan lagi dari
`ContactEntity.units` lokal. Filter pencarian di fake ini meniru cara filter lama (client-side)
persis supaya test pencarian yang sudah ada ("Pencarian menyaring daftar" di test #1) tetap berlaku
sama walau sumber datanya sekarang server.

Jalankan: `flutter test`. Menu Reserve Order (Bagian 3) punya test terpisah, lihat
[reserve-order-menu-list.md](docs/reserve-order-menu-list.md).

## Yang belum jalan / perlu diputuskan

1. **Tesseract perlu diinstall di server** sebelum OCR hidup:
   `sudo apt install tesseract-ocr tesseract-ocr-ind`. Selama belum ada, endpoint membalas 503
   dengan pesan cara installnya dan user diarahkan mengisi manual — bukan error 500.
2. **Isi pilihan masih hardcode** — Status Pernikahan. Di DB kolomnya string bebas (tidak ada
   tabel master), jadi kalau mau dibakukan perlu keputusan bisnis. Istilahnya memakai versi KTP
   ("Kawin", bukan "Menikah" seperti di mockup) supaya hasil OCR bisa dicocokkan otomatis.
   - **Jenis Transaksi** sudah tidak hardcode lagi — pakai master status reserve yang sama dengan
     chip filter di menu List (`GET /api/reserve-filter`), lewat
     `ReserveOrderListCubit.ensureFilters()` (di-cache di cubit, lihat
     [reserve-order-menu-list.md](docs/reserve-order-menu-list.md) bagian "Chip filter tersambung
     ke `GET /api/reserve-filter`") — [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)
     `_loadTransactionTypes()`. Fallback `['Reserve', 'Booking Reserve (langsung)']` dipakai kalau
     fetch-nya gagal/kosong, supaya form tetap bisa disubmit.
   - **Cara Pembayaran** juga sudah tidak hardcode — `GET /api/reserve/cara-bayar`
     (`{cara_bayar_id, name}`), lewat `ReserveOrderListCubit.ensureCaraBayarOptions()` (cache
     terpisah dari `filters`, pola sama persis). `name` yang tampil di picker/sheet-nya
     (`_caraPembayaran`), tapi yang **dikirim ke `POST /api/reserve`** adalah `cara_bayar_id`
     (`_caraBayarId`, dicari lewat `_caraBayarIdOf(name)` di
     [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) — lihat "Baris
     customer dibuat lewat `POST /api/reserve`" di atas). Fallback
     `['KPR', 'Cash', 'Cash Bertahap', 'Inhouse']` (tanpa id, jadi `cara_bayar_id` tidak terkirim)
     dipakai kalau fetch-nya gagal/kosong.
3. **Bagian 3 sudah dikerjakan** di menu drawer terpisah — lihat
   [reserve-order-menu-list.md](docs/reserve-order-menu-list.md). Halaman menu per-kontak
   (`/contact/reserve-order`) tetap versi kartu Reserve/Topup/RB yang lama.
4. **Camera di PWA desktop** — `ImagePicker` dengan `ImageSource.camera` di browser desktop
   membuka dialog file, bukan kamera; di browser HP baru membuka kamera. Perilaku `image_picker`
   di web, sama seperti fitur lain di app ini.
