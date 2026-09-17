# Reserve Order — Flow Sales (Data Pembeli → Unit → Dokumen → Review → Sukses)

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
   pilihan), Pekerjaan, Cara Pembayaran (sheet pilihan). Tombol **Lanjut ke Pilih Unit**.
2. **2/4 Unit** — daftar kavling dengan kotak pencarian "Cari blok / no. unit…", checkbox
   **multi-pilih**, dan badge status. Footer menampilkan "N unit dipilih" + **Lanjut ke Dokumen**.
3. **3/4 Dokumen** — bagian *Dokumen Identitas* (KTP wajib, NPWP opsional) dan *Bukti Bayar*
   (bisa lebih dari satu lewat **+ Tambah Bukti Bayar Lain**), lalu **Jenis Transaksi**
   (chip: Reserve / Booking Reserve (langsung)), **Nominal Pembayaran**, dan **Catatan**.
   Tombol **Lanjut ke Tinjau**.
4. **4/4 Review** — ringkasan (Customer, Dokumen, Jenis Transaksi, Nominal & Catatan) + kartu per
   unit terpilih. Tombol **Submit Reserve Order**.
5. **Sukses** — ikon centang, "Reserve Order Berhasil Diajukan", kartu unit + badge **Diproses**,
   tombol **Lihat di Reserve Order** dan **Kembali ke Kontak**.

Judul app bar mengikuti mockup: step 1 & 3 "Reserve Order — <nama kontak>" + nomor HP di bawahnya,
step 2 "Pilih Unit", step 4 "Review Reserve Order". Tombol back (header maupun tombol back sistem)
mundur **satu** step; di layar sukses tidak ada jalan mundur.

## Validasi tiap step

| Step | Syarat lanjut |
|---|---|
| Pembeli | Nama lengkap terisi; No. KTP tepat 16 digit |
| Unit | Minimal 1 unit dipilih |
| Dokumen | Lampiran KTP ada; minimal 1 bukti bayar; nominal > 0 |
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
- Field hasil OCR yang **tidak** ada di form ini (kecamatan, kabupaten)
  ikut dibawa keluar flow lewat `ReserveResult.ktpOcr` supaya tidak hilang.
- Foto KTP-nya sekaligus dipakai sebagai lampiran dokumen KTP di step 3 — tidak perlu unggah dua
  kali.

## Daftar unit (step 2) — dua sumber terpisah

Awalnya step ini fetch `GET /api/reserve/product-select?contact_id=…`, di-parsing seolah
dikelompokkan per proyek (`data.data[].products[]`, meniru bentuk `GET /property/units/hierarchy`).
**Itu salah** — response asli endpoint ini (dikonfirmasi langsung dari API) berbentuk flat:

```json
{"status": true, "data": {"contact_id": 112885, "units": [ {"deal_id": 113789, "cluster_id": 255,
"cluster_name": "Cluster EcoArdence", "product_id": 51, "product_name": "…", "property_id": null,
"property_name": null, "is_tipe_hoek": false, "is_waiting_list": 1, "deal_value": 0, … } ], … }}
```

Datasource-nya mencari `data.data[]` (key yang salah) sehingga `groups` selalu kosong — inilah
sebab step "Pilih Unit" tampil **"Tidak ada unit tersedia untuk kontak ini"** walau kontaknya
sebenarnya sudah punya beberapa deal. Selain key-nya salah, setiap baris `data.units[]` ternyata
SELALU punya `deal_id` — artinya endpoint ini cuma daftar **deal yang sudah ada** buat kontak
tersebut (dibuat dari CRM/pipeline lain), BUKAN katalog produk yang bisa dipilih baru.

Untuk bisa memilih unit yang **belum pernah** jadi deal, dipakai endpoint terpisah,
`GET /api/reserve/unit-all` (dua bentuk panggilan tergantung param, sama polanya dengan
`GET /property/units/hierarchy` di fitur contact):

- `?contact_id=…&search=…` → katalog cluster > produk (`data.data[]`, tanpa properti/kavling).
- `?product_id=…&township_id=…&company_id=…&contact_id=…` (dipanggil pas satu produk di-expand)
  → daftar kavling produk itu (`data.lots[]`, asumsi sama seperti field `UnitLot` yang sudah ada —
  belum ada contoh response asli buat panggilan ini, jadi kalau ternyata field-nya beda, kegagalan
  tampil sebagai baris "Gagal memuat kavling · Coba lagi" inline di bawah produknya (lihat
  `_unitProductTile` di [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)),
  bukan salah diam-diam.

Sisi Flutter — [reserve_unit_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart)
sekarang punya 3 method:

- `getUnitTree({contactId, search})` — `GET /reserve/unit-all?contact_id=…` → `List<UnitCluster>`
  (model yang sama dipakai `UnitPickerScreen` di fitur contact,
  [unit_hierarchy_model.dart](lib/features/contact/data/models/unit/unit_hierarchy_model.dart)).
- `getUnitLots({productId, townshipId, companyId, contactId})` — `GET /reserve/unit-all?product_id=…`
  → `List<UnitLot>`.
- `getSelectedUnits({contactId})` — `GET /reserve/product-select?contact_id=…`, parsing **diperbaiki**
  jadi `data.units[]` (bukan `data.data[].products[]`) → `List<SelectedUnit>`, lewat
  `SelectedUnit.fromProductSelectJson()` yang field mapping-nya juga dibetulkan sesuai response asli
  (`cluster_id`/`cluster_name`, `property_id`, `is_tipe_hoek`, `deal_value` — bukan
  `project_id`/`project_name`/`display_name`/`status_property_name`/`is_property_sellable`/
  `is_selected` seperti asumsi lama, yang semuanya tidak ada di response sungguhan).

`SelectedUnit.spec` & `SelectedUnit.isSelected` dihapus dari model — dua-duanya tidak pernah terisi
oleh sumber manapun lagi sesudah perbaikan ini (dead field).

**`township_name`/status kavling buat unit "sudah ada":** response `product-select` (dikonfirmasi
dari contoh response asli) sama sekali tidak mengirim nama township maupun status kavling — cuma id
(`township_id`) dan `status_prospect_id` (status PIPELINE deal, beda konsep dari status ketersediaan
kavling di `UnitLot.statusName`). `ReservePage._enrichExistingUnit`
([reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)) melengkapinya belakangan
dengan mencocokkan manual: nama township dari cluster yang `clusterId`-nya sama di katalog tree
(`state.clusters`, sudah dimuat bareng), status kavling dari lot yang `propertyId`-nya sama di
`state.lotsByProduct` (baru terisi setelah produknya di-expand lewat `expandProductFor` — dipanggil
otomatis oleh `_autoSelectAlreadyChosenUnits` begitu unit "sudah ada" ke-auto-select). Karena lots-nya
dimuat async, `_autoSelectAlreadyChosenUnits` dipanggil ulang tiap `ReserveUnitState` berubah dan
me-refresh entri yang statusnya baru kepenuhan — bukan cuma sekali di awal.

### `ReserveUnitCubit`/`ReserveUnitState` — tree + daftar existing terpisah

Ditulis ulang total mengikuti pola `UnitPickerCubit`/`UnitPickerState` (fitur contact):
`clusters`/`expandedClusters`/`expandedProducts`/`lotsByProduct`/`loadingProductIds` buat katalog
(fetch bertahap: tree dulu, lots per produk pas di-expand), ditambah `existingUnits` (dari
`getSelectedUnits`, di-fetch sekali bareng tree, TERPISAH — gagalnya `existingUnits`
(`existingUnitsError`) tidak menyembunyikan katalog yang sudah berhasil dimuat). Tidak ada
paginasi/`loadMore` lagi (`unit-all` & `product-select` sama-sama mengembalikan semuanya sekaligus,
bukan Laravel paginator) — `_unitScroll`/`_onUnitScroll` di `reserve.dart` dihapus.

### Tampilan step 2 — [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)

Dua seksi dalam satu `ListView`, sama seperti desain [UnitPickerScreen](lib/features/contact/presentation/pages/unit-picker/index.dart):

1. **"Unit yang Sudah Dipilih Sebelumnya"** — daftar `state.existingUnits` apa adanya (pakai
   `_contactUnitRow` yang sudah ada, tanpa perubahan tampilan), auto-tercentang begitu dimuat
   (`_autoSelectAlreadyChosenUnits`, dipanggil dari `listener` `BlocConsumer`). **Semua** baris di
   sini otomatis dianggap terpilih (selalu punya `deal_id`) — beda dari desain lama yang menyaring
   pakai field `is_selected` yang ternyata tidak pernah ada di response.
   - `_autoSelectedUnitKeys` (`Set<String>` isinya `SelectedUnit.key`, key-nya `'deal:$dealId'`
     buat baris ini) tetap dipakai supaya uncheck manual user tidak balik tercentang tiap ada
     `setState` lain — pola sama seperti sebelumnya, cuma sumbernya sekarang `state.existingUnits`.
   - Kalau `existingUnitsError` terisi, ditampilkan sekali lewat `showSnackbar` (`_existingUnitsErrorShown`
     mencegah snackbar berulang tiap rebuild).
2. **"Tambah Unit Baru"** — tree Cluster > Produk dari `state.clusters`, expand produk menampilkan
   dua baris statis "Belum menentukan kavling"/"Waiting list" (sama seperti `UnitPickerScreen`) lalu
   daftar kavling asli (`state.lotsByProduct`, fetch on-demand pas expand). Ketiganya dirender lewat
   `_contactUnitRow` yang SAMA dengan seksi pertama (satu widget generik buat semua bentuk
   `SelectedUnit`), jadi visualnya (checkbox, badge Hoek, dst.) konsisten otomatis.

**Keterbatasan yang disengaja, ditunda:** unit yang dipilih dari seksi "Tambah Unit Baru" belum
punya `deal_id` (belum pernah jadi deal), sementara `POST /api/reserve-unit` ([`_onSubmit` di
reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)) cuma bisa
`{deal_id, customer_id}` — jadi unit BARU yang dicentang di sini **masih ikut dihitung** di "N unit
dipilih" tapi **belum benar-benar tersimpan ke server** (loop di `_onSubmit` tetap skip unit tanpa
`deal_id`). Ini disengaja atas arahan: fitur pilih-unit-baru menunggu perubahan endpoint
`reserve-unit` (atau endpoint baru) yang bisa menerima `product_id`/`property_id`/`is_waiting_list`
tanpa `deal_id` — bukan sesuatu yang bisa ditebak dari sisi Flutter.

## Nominal pembayaran

Field nominal memakai prefix "Rp " + formatter pemisah ribuan
([`ThousandsInputFormatter`](lib/core/utils/widget/thousands_input_formatter.dart)):
mengetik `2000000` tampil `2.000.000`, dan nilai numeriknya diambil ulang dari digit-nya saja.
Kursor selalu ditaruh di akhir — menghitung ulang posisinya setelah titik disisipkan membuat
kursor melompat, sementara field ini praktis selalu diisi dari belakang.

Nominal ini juga yang menjawab pertanyaan sebelumnya soal angka di kartu menu: sumbernya step
**Dokumen & Bukti Bayar**, bukan input di step Unit atau harga unit.

## Baris customer dibuat lewat `POST /api/reserve` (begitu lepas dari step Pembeli)

Begitu tombol **Lanjut ke Pilih Unit** (step Pembeli) ditekan dan lolos validasi, langkah
berikutnya bikin baris `m_customer_reserve` lewat `POST /api/reserve` — **bukan** menunggu sampai
Submit di Review lagi. Alasannya: step Pilih Unit butuh `customer_id` buat menautkan unit yang
dipilih lewat `POST /api/reserve-unit` (section di bawah), jadi baris customer-nya harus sudah ada
sebelum step itu dibuka. Gagal di sini menahan user di step Pembeli dengan pesan errornya, dan
tidak lanjut ke Pilih Unit.

`createReserve()` mengembalikan `CreateReserveResult` (`reserveOrderId` + `customerId`, dari
`data.reserve_order.reserve_order_id`/`customer_id`) — disimpan sebagai `_reserveOrderId`/
`_customerId` di [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart),
dipakai lagi oleh `_onNextUnit` (`saveReserveUnit`) dan `_onSubmit` (`submitDocPayment`). Kalau
user mundur dari Unit ke Pembeli lalu maju lagi, `_onNextPembeli` **tidak** bikin baris baru lagi
selama `_reserveOrderId`/`_customerId` sudah ada — cukup lanjut ke Unit dengan id yang sama.

Payload-nya (`CreateReserveParams.toJson()` —
[reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart)):

| Field JSON | Sumbernya di form |
|---|---|
| `contact_id` | `ContactEntity.contactId` (wajib — kalau null, submit ditahan sebelum ini) |
| `cust_name` | Nama Lengkap |
| `cust_ktp` | No. KTP |
| `cust_birth_place` / `cust_birth_date` | "Tempat, Tanggal Lahir" — lihat catatan parsing di bawah |
| `cust_gender_is_male` | Jenis Kelamin — dropdown `roGenderItems` ([reserve_order_model.dart:99](lib/features/reserve-order/data/models/reserve_order_model.dart#L99)) ("Laki-laki"/"Perempuan" → bool → dikirim sebagai `1`/`0`, `FormData` tidak bisa bawa literal bool), auto-terisi dari `KtpOcrModel.jenisKelamin` hasil scan tapi bisa diganti manual; null kalau belum pernah scan KTP maupun dipilih manual |
| `cust_marital_status` | Status Pernikahan, di-`toUpperCase()` (mis. "Kawin" → "KAWIN") |
| `cust_religion` | Agama — dropdown `roReligionItems` ([reserve_order_model.dart:103](lib/features/reserve-order/data/models/reserve_order_model.dart#L103)), auto-terisi dari `KtpOcrModel.agama` hasil scan kalau cocok salah satu opsi, tapi bisa diganti manual di [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) |
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

Begitu tombol **Lanjut ke Dokumen** (step Unit) ditekan dan minimal 1 unit terpilih, tiap unit yang
dicentang ditautkan ke customer yang barusan dibuat (section di atas) lewat `POST
/api/reserve-unit` — satu request per unit, payload `{ "deal_id": …, "customer_id": … }`.
`deal_id`-nya dari `SelectedUnit.dealId` (lihat "Daftar unit (step 2)" di atas — dari
`GET /api/reserve/product-select`, banyak produk katalog yang `dealId`-nya null karena belum pernah
dipilih buat kontak ini); unit yang tidak punya `dealId` dilewati begitu saja — tidak ada deal yang
bisa ditautkan.

Gagal di sini menahan user di step Unit dengan pesan errornya (baris customer-nya **tetap**
tersimpan — cuma penautan unitnya yang perlu dicoba ulang), dan tidak lanjut ke Dokumen.

Kode: `saveReserveUnit()` — [reserve_order_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart).
[reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart) `_onNextUnit()` yang
mengirim satu-per-satu (bukan `Future.wait` paralel) — kalau ada yang gagal di tengah, sisanya tidak
usah dilanjutkan.

## Dokumen & rincian pembayaran dikirim ke `POST /api/reserve/doc-payment` (saat Submit)

`POST /api/reserve/doc-payment` — endpoint khusus reserve order (bukan attachment kontak lagi) yang
menyimpan KTP/NPWP/bukti transfer **dan** rincian pembayaran (jenis transaksi, nominal, catatan)
sebagai baris `t_reserve_order_tts` milik order itu, pakai `reserve_order_id` dari `createReserve()`
(section di atas — sudah didapat lebih awal, begitu lepas dari step Pembeli).

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
| Pembeli → Unit | "Membuat reserve order..." (`_creatingReserve`) |
| Unit → Dokumen | "Menyimpan unit..." (`_savingUnit`) |
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
   dipanggil dengan `excludeBatal: true` (`lastFilterExcludeBatal == true`), dan `ReservePage` yang
   dibuka dua kali dengan `ReserveOrderListCubit` yang sama cuma memanggil `getReserveFilters()`
   sekali (`filterCalls == 1`) — buktiin cache-nya kepakai. Dibuka "dua kali" di test-nya sengaja
   pump `SizedBox.shrink()` dulu sebelum `MaterialApp` yang baru, supaya elemen `ReservePage`
   sebelumnya benar-benar di-dispose (tree berbentuk sama + tanpa key cuma di-rebuild oleh
   `pumpWidget`, bukan mount ulang — kalau tidak dipaksa lepas, `_step` dkk kebawa dari sesi
   sebelumnya).
6. `POST /api/reserve` (`_FakeReserveOrders.createReserve()`) terkirim begitu lepas dari step
   Pembeli (**bukan** menunggu Submit di Review) — Tempat/Tanggal Lahir diisi manual ("Jakarta, 09
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
7. `POST /api/reserve` yang gagal (`failCreate = true`) menahan user di step **Pembeli** (tidak
   lanjut ke Pilih Unit) dengan pesan errornya; `saveReserveUnit`/`doc-payment` **tidak** ikut
   dipanggil.
8. `POST /api/reserve-unit` yang gagal (`failSaveUnit = true`) menahan user di step **Unit** (tidak
   lanjut ke Dokumen) dengan pesan errornya — baris customer-nya (`createCalls`) tetap sudah dibuat
   sebelumnya, cuma penautan unitnya yang gagal; `doc-payment` **tidak** ikut dipanggil.
9. Unit yang `is_property_sellable: false` tetap tampil pudar (`Opacity` 0.5) tapi **tetap**
   bertambah ke "N unit dipilih" saat ditap, sama seperti unit sellable di sebelahnya; harga
   (`deal_value`) dan badge status (`status_name`, mis. "Available"/"Reserve") ikut tampil di
   kartunya.

Daftar unit di step 2 dimuat dari `_FakeReserveUnits` (`ReserveUnitRemoteDataSource` palsu,
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
   - **Jenis Transaksi** sudah tidak hardcode lagi — pakai master status reserve
     `GET /api/reserve-filter?exclude_batal=1` (**beda** dari chip filter di menu List yang minta
     semua status termasuk "Batal", lihat
     [reserve-order-menu-list.md](docs/reserve-order-menu-list.md) bagian "Chip filter tersambung
     ke `GET /api/reserve-filter`") — status "Batal" sengaja tidak ditawarkan sebagai jenis
     transaksi buat reserve order baru. Lewat `ReserveOrderListCubit.ensureTransactionTypeFilters()`
     (cache terpisah dari `ensureFilters()`, `ReserveOrderListState.transactionTypeFilters`) —
     [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)
     `_loadTransactionTypes()`. TIDAK ada fallback lokal — kalau fetch-nya gagal/kosong, chip-nya
     diganti pesan error asli dari API (`ReserveOrderListState.transactionTypeFiltersError`) plus
     tombol "Coba lagi" yang manggil `_loadTransactionTypes()` ulang (lihat [reserve.dart:1006-1024](lib/features/reserve-order/presentation/pages/reserve.dart#L1006-L1024)).
   - **Cara Pembayaran** (field "Cara Pembarayan" di form) juga sudah tidak hardcode —
     `GET /api/reserve/cara-bayar` (`{cara_bayar_id, name}`), lewat
     `ReserveOrderListCubit.ensureCaraBayarOptions()` (cache terpisah dari `filters`, pola sama
     persis). `name` yang tampil di picker/sheet-nya (`_caraPembayaran`), tapi yang **dikirim ke
     `POST /api/reserve`** adalah `cara_bayar_id` (`_caraBayarId`, dicari lewat
     `_caraBayarIdOf(name)` di [reserve.dart](lib/features/reserve-order/presentation/pages/reserve.dart)
     — lihat "Baris customer dibuat lewat `POST /api/reserve`" di atas). Sama seperti Jenis
     Transaksi, TIDAK ada fallback lokal — gagal/kosong tampil sebagai pesan error API +
     tombol "Coba lagi" (`ReserveOrderListState.caraBayarOptionsError`).
3. **Bagian 3 sudah dikerjakan** di menu drawer terpisah — lihat
   [reserve-order-menu-list.md](docs/reserve-order-menu-list.md). Halaman menu per-kontak
   (`/contact/reserve-order`) tetap versi kartu Reserve/Topup/RB yang lama.
4. **Camera di PWA desktop** — `ImagePicker` dengan `ImageSource.camera` di browser desktop
   membuka dialog file, bukan kamera; di browser HP baru membuka kamera. Perilaku `image_picker`
   di web, sama seperti fitur lain di app ini.
5. **Produk katalog tanpa `deal_id` belum benar-benar bisa direserve** — sejak step Unit pindah ke
   `GET /api/reserve/product-select` (lihat "Daftar unit (step 2)" di atas), produk yang dicentang
   tapi belum py deal existing tetap lolos jadi "N unit dipilih" & lanjut ke step berikutnya, tapi
   `saveReserveUnit()` melewatinya diam-diam saat submit karena belum ada endpoint buat bikin deal
   baru dari produk katalog. Perlu diputuskan: endpoint baru buat "pilih produk jadi deal", atau
   validasi yang menahan user kalau unit yang dicentang tidak py deal.
