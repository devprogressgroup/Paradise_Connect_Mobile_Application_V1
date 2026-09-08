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

## Daftar unit (step 3)

Butuh daftar kavling yang bisa dicari langsung, sedangkan unit picker yang sudah ada
(`UnitPickerScreen`) menelusuri cluster → tipe → kavling dan endpoint-nya mewajibkan `product_id`.
Karena itu backend dapat **mode baru**: `GET /api/property/units/hierarchy?township_id=X&flat=1`
— daftar kavling se-township + nama status dari master `m_status_property_lot`, ber-paginasi.
Dokumentasi endpoint: `docs/api/property/property-units-flat-mode.md` di repo backend.

Sisi Flutter:

- [unit_option_model.dart](lib/features/contact/data/models/unit/unit_option_model.dart) —
  `UnitOption` + `toSelectedUnit()` (dipakai saat unit dikirim keluar flow).
- [reserve_unit_remote_datasource.dart](lib/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart)
  + [reserve_unit_cubit.dart](lib/features/reserve-order/presentation/state/reserve_unit/reserve_unit_cubit.dart)
  — pola sama seperti `PipelineCubit` (datasource langsung, tanpa usecase/repository), dengan
  pencarian (debounce 400 ms) dan load-more saat daftar di-scroll mendekati bawah.
- [main.dart:434](lib/main.dart#L434) + [main.dart:536](lib/main.dart#L536) — datasource & provider.
- Unit non-`Available` (Reserve/Hold/SP) tetap tampil tapi pudar dan tidak bisa dicentang.
  Penilaian "boleh dipilih" datang dari server (`is_available`).
- Badge status memakai [UnitStatusBadge](lib/core/utils/widget/unit_status_badge.dart) yang sudah
  ada; widget itu dapat parameter **opsional** `textColor` karena latar "Available" (#00FF0C) dan
  "Reserve" (#EAFF00) sangat terang sehingga teks putih hampir tidak terbaca. Default-nya tetap
  putih, jadi tampilan layar lain tidak berubah.

### Harga unit tidak ditampilkan

Mockup menampilkan "Rp 450.000.000" di baris kedua tiap unit, tapi harga **tidak ada di database
inventory** (`m_property_lot`/`m_sellable_unit` tidak punya kolom harga — dicek langsung ke DB dev).
Sumbernya relay Paradise Dynamics Web2 via `POST /api/property-pricing`, **satu request per unit**,
jadi tidak masuk untuk daftar. Sementara ini baris kedua diisi "Cluster · Tipe · Luas m²". Kalau
harga wajib tampil, butuh endpoint harga massal dulu.

## Nominal pembayaran

Field nominal memakai prefix "Rp " + formatter pemisah ribuan
([`ThousandsInputFormatter`](lib/core/utils/widget/thousands_input_formatter.dart)):
mengetik `2000000` tampil `2.000.000`, dan nilai numeriknya diambil ulang dari digit-nya saja.
Kursor selalu ditaruh di akhir — menghitung ulang posisinya setelah titik disisipkan membuat
kursor melompat, sementara field ini praktis selalu diisi dari belakang.

Nominal ini juga yang menjawab pertanyaan sebelumnya soal angka di kartu menu: sumbernya step
**Dokumen & Bukti Bayar**, bukan input di step Unit atau harga unit.

## Baris customer dibuat lewat `POST /api/reserve` (saat Submit, sebelum dokumen)

Begitu **Submit Reserve Order** ditekan, langkah pertamanya bikin baris `m_customer_reserve` lewat
`POST /api/reserve` — baru kalau itu sukses, lanjut ke upload dokumen (section di bawah). Gagal di
sini menahan user di step Review dengan pesan errornya, dan dokumen **tidak** ikut diunggah.

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

## Dokumen dikirim ke attachment kontak (saat Submit)

KTP (termasuk foto hasil **Scan KTP**), NPWP, dan semua bukti bayar diunggah ke endpoint attachment
kontak yang sudah ada: `POST /api/contacts/{contact_id}/attachments`. Tidak ada endpoint baru.

**Kapan:** sekali di akhir, waktu tombol **Submit Reserve Order** ditekan — bukan saat file dipilih.
Selama 3 step pertama berkasnya ditahan di memori halaman, jadi kalau flow-nya ditinggal di tengah
jalan tidak ada attachment nyangkut di kontak.

**Pengelompokan:** satu request per attachment type, memakai bentuk `files[]` + `file_names[]` yang
sudah didukung datasource-nya
([contact_remote_datasource.dart:644](lib/features/contact/data/datasources/contact_remote_datasource.dart#L644)).
Jadi bukti bayar yang lebih dari satu tetap satu request. Kelompok yang berkasnya kosong dilewati —
NPWP opsional, jadi tidak dikirim kalau tidak diisi.

**`attachment_type_id` tidak di-hardcode.** Master-nya diambil dari
`GET /api/contacts/attachment-types`, lalu dicocokkan berdasarkan nama (case-insensitive,
`contains`):

| Dokumen | Kata kunci nama tipe (dicoba berurutan) |
|---|---|
| KTP | `ktp` |
| NPWP | `npwp` |
| Bukti Bayar | `bukti bayar` → `bukti transfer` → `bukti pembayaran` → `bukti` → `pembayaran` |

Urutannya dari yang paling spesifik supaya "Bukti Transfer" menang atas tipe umum yang cuma
bernama "Bukti". Kalau tidak ada satu pun yang cocok, submit **ditahan** dengan pesan
"Attachment type untuk KTP tidak ada di master data. Tambahkan dulu di CRM." — sengaja tidak
jatuh ke tipe "Lainnya", karena attachment yang salah kategori lebih susah dibereskan daripada
error yang jelas.

**`attachment_note`** diisi otomatis supaya di halaman Attachment kontak kelihatan dokumennya datang
dari transaksi mana, mis. `Reserve Order · Reserve · Blok E1 No. 19 · Rp 2.000.000`.
`deal_id` ikut dikirim dari `ContactEntity.dealId` kalau ada.

Kode:

- [reserve_attachment_cubit.dart](lib/features/reserve-order/presentation/state/reserve_attachment/reserve_attachment_cubit.dart)
  — `ReserveAttachmentCubit.submit()`, memakai `GetAttachmentTypesUseCase` &
  `UploadAttachmentUseCase` yang sudah ada. Master type di-cache di cubit.
- [main.dart:538](lib/main.dart#L538) — provider-nya.
- [reserve.dart:383](lib/features/reserve-order/presentation/pages/reserve.dart#L383) —
  `_onSubmit()`.

**Selama upload:** tombol Submit berubah jadi "Mengunggah dokumen 1/2..." dengan spinner dan tidak
bisa ditekan dua kali, dan tombol back ditahan supaya tidak ada upload separuh jalan
([reserve.dart:141](lib/features/reserve-order/presentation/pages/reserve.dart#L141)).
Kalau ada satu kelompok yang gagal, sisanya dihentikan, user tetap di step Review, dan pesannya
menyebut dokumen yang gagal ("Gagal mengunggah KTP: …") — jadi bisa langsung dicoba lagi.

> Kalau upload berhasil tapi user lalu menutup app di layar sukses, dokumennya **tetap** ada di
> attachment kontak. Itu memang disengaja: file-nya milik kontak, bukan milik order. Baris
> customer-nya sendiri (`POST /api/reserve`, section di atas) sudah tersimpan **sebelum** dokumen
> diunggah, jadi kasus "dokumen nyangkut tanpa baris customer" ini tidak berlaku lagi untuk baris
> customer-nya — yang belum ada baru tabel unit/pembayaran (`t_reserve_order`, lihat "Yang belum
> jalan" di bawah).

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

[test/reserve_page_smoke_test.dart](test/reserve_page_smoke_test.dart) — 7 test widget di layar
390x844:

1. Kelima layar render tanpa error layout (overflow / unbounded height — **tidak** terdeteksi
   `flutter analyze`), sheet pilihan jalan, validasi tiap step menahan langkah, nominal diformat,
   unit bisa dicari, sampai layar sukses. Termasuk picker "Cara Pembayaran": isinya dari
   `_FakeReserveOrders.getCaraBayarOptions()` (mis. "Cash Bertahap 3X"), bukan daftar hardcode lama
   — yang tampil & dipilih di sheet tetap `name`.
2. Submit mengirim KTP & bukti bayar ke `POST /contacts/1/attachments` dengan
   `attachment_type_id` hasil pencocokan nama, `file_names` yang benar, dan `deal_id` ikut terkirim.
   NPWP yang tidak dilampirkan tidak ikut dikirim.
3. Upload yang gagal menahan user di step Review beserta pesan "Gagal mengunggah KTP: …".
4. Flow penuh dari halaman menu → submit → **Lihat di Reserve Order**, memastikan kartu menu dapat
   unit + "Rp 2.000.000" + centang.
5. "Jenis Transaksi" render dari `_FakeReserveOrders.getReserveFilters()` (bukan daftar hardcode),
   dan `ReservePage` yang dibuka dua kali dengan `ReserveOrderListCubit` yang sama cuma memanggil
   `getReserveFilters()` sekali (`filterCalls == 1`) — buktiin cache-nya kepakai. Dibuka "dua kali"
   di test-nya sengaja pump `SizedBox.shrink()` dulu sebelum `MaterialApp` yang baru, supaya
   elemen `ReservePage` sebelumnya benar-benar di-dispose (tree berbentuk sama + tanpa key cuma
   di-rebuild oleh `pumpWidget`, bukan mount ulang — kalau tidak dipaksa lepas, `_step` dkk kebawa
   dari sesi sebelumnya).
6. Submit memanggil `POST /api/reserve` (`_FakeReserveOrders.createReserve()`) **sebelum**
   mengunggah dokumen — Tempat/Tanggal Lahir diisi manual ("Jakarta, 09 Januari 1990", tanpa scan
   KTP) buat membuktikan parsing-balik `_resolvedBirth()` jalan, lalu tiap field payloadnya dicek
   satu-satu (`contact_id`, `cust_name`, `cust_ktp`, `cust_birth_place`/`cust_birth_date`,
   `cust_marital_status` yang di-uppercase, `cust_occupation`, `cust_address1`, `cara_bayar_id` dari
   opsi yang dipilih, `cust_telp_mobile1`), termasuk `toJson()`-nya (`cust_birth_date` jadi string
   `"1990-01-09"`). `cust_gender_is_male`/`cust_religion` dicek null karena belum pernah scan KTP.
7. `POST /api/reserve` yang gagal (`failCreate = true`) menahan user di step Review dengan pesan
   errornya, dan dokumen **tidak** ikut diunggah (`repo.uploads` tetap kosong) — buktiin urutannya
   customer dulu baru dokumen, bukan paralel.

Daftar unit di step 3 sekarang diambil dari kavling yang sudah menempel di kontak
(`ContactEntity.units`), bukan dari pencarian ke server — test-nya menyediakan unit lewat
`_contact()`, bukan lewat datasource palsu.

Jalankan: `flutter test`. Menu Reserve Order (Bagian 3) punya test terpisah, lihat
[reserve-order-menu-list.md](docs/reserve-order-menu-list.md).

## Yang belum jalan / perlu diputuskan

1. **Rincian unit/pembayaran belum dikirim ke server** — data customer sudah jalan
   (`POST /api/reserve`, section "Baris customer dibuat lewat `POST /api/reserve`" di atas) dan
   dokumennya juga (lihat "Dokumen dikirim ke attachment kontak"). Yang **belum ada** endpoint-nya:
   unit yang dipilih & rincian pembayaran (jenis transaksi, nominal, catatan) → `t_reserve_order` /
   `t_reserve_order_tts`. Selama itu belum ada, unit/nominal/catatan cuma tersimpan di
   `ReserveResult` lokal (dipakai kartu di halaman menu), tidak ikut ke `POST /api/reserve`.
2. **Tesseract perlu diinstall di server** sebelum OCR hidup:
   `sudo apt install tesseract-ocr tesseract-ocr-ind`. Selama belum ada, endpoint membalas 503
   dengan pesan cara installnya dan user diarahkan mengisi manual — bukan error 500.
3. **Isi pilihan masih hardcode** — Status Pernikahan. Di DB kolomnya string bebas (tidak ada
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
4. **Harga unit** — lihat "Harga unit tidak ditampilkan" di atas.
5. **Bagian 3 sudah dikerjakan** di menu drawer terpisah — lihat
   [reserve-order-menu-list.md](docs/reserve-order-menu-list.md). Halaman menu per-kontak
   (`/contact/reserve-order`) tetap versi kartu Reserve/Topup/RB yang lama.
6. **Camera di PWA desktop** — `ImagePicker` dengan `ImageSource.camera` di browser desktop
   membuka dialog file, bukan kamera; di browser HP baru membuka kamera. Perilaku `image_picker`
   di web, sama seperti fitur lain di app ini.
