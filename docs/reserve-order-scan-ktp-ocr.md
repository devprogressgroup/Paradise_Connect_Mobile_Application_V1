# Reserve Order — Step Scan KTP (OCR) & Form Data Pembeli

## Ringkasan

Item **Reserve** di halaman Reserve Order sekarang bisa diklik dan membuka flow 2 step sesuai
mockup:

1. **Reserve Order** — layar scan KTP: ilustrasi kartu, teks "Dengan scan KTP maka beberapa data
   anda akan terisi otomatis.", tombol **Scan KTP** (buka bottom sheet **Camera** / **Upload**),
   dan link **Isi manual**.
2. **Data Pembeli** — form 13 field (Nama, NIK, Tempat Lahir, Tgl Lahir, Jenis Kelamin, Marital
   Status, Agama, Kategori Pekerjaan, Pekerjaan, Alamat, Kecamatan, Kabupaten, Pendidikan) +
   tombol **Next**.

Judul di step bar ikut ganti per step ("Reserve Order" → "Data Pembeli"), seperti di mockup.

## Kenapa OCR-nya di server

App ini jalan sebagai PWA di web **dan** sebagai app mobile. `google_mlkit_text_recognition`
tidak punya implementasi web, `tesseract.js` cuma jalan di browser, dan API key OCR pihak ketiga
kalau dipanggil langsung dari Flutter web akan ikut ke-bundle di JS. Jadi satu-satunya jalur yang
sama untuk kedua platform: kirim foto ke backend.

Server-nya **sudah dibuat** di repo Laravel (`E:\WorkProject\php\Paradise-Connect-1.0`, branch
`reserve-order-mobile`): `POST /api/reserve/ktp-ocr`, engine Tesseract (gratis, tanpa billing,
foto tidak keluar server; Cloud Vision tersedia sebagai alternatif lewat `.env`). Lihat
bagian "Sisi server" di bawah.

Foto dikirim sebagai **bytes**, bukan path — di web `PickedFileResult.path` selalu null,
sedangkan `bytes` selalu terisi di kedua platform.

## Perubahan

### 1. Layer data OCR

- [ktp_ocr_model.dart](lib/features/contact/data/models/ktp/ktp_ocr_model.dart) — `KtpOcrModel`,
  semua field nullable (OCR bisa gagal baca sebagian baris). Kunci utama `fromJson` adalah
  `cust_*` — sama dengan kolom `m_customer_reserve` / body `POST /api/reserve` — plus alias
  Indonesia/Inggris sebagai jaring-jaring. `cust_gender_is_male` (boolean dari server) diubah
  jadi teks "Laki-laki"/"Perempuan" untuk dropdown. `isEmpty` dipakai untuk bedakan "sukses tapi
  tidak kebaca apa pun".
- [ktp_ocr_remote_datasource.dart:19](lib/features/contact/data/datasources/ktp_ocr_remote_datasource.dart#L19) —
  `POST /reserve/ktp-ocr`, multipart field `file`.
  [Baris 39](lib/features/contact/data/datasources/ktp_ocr_remote_datasource.dart#L39): server
  memisahkan `data.fields` (kolom siap kirim balik) dari `data.ktp` (kecamatan, kel/desa, RT/RW,
  dll yang tidak punya kolom) — keduanya digabung jadi satu peta datar untuk model.
  Status 404/405/501 (backend belum di-deploy) jadi pesan "Scan OCR KTP belum tersedia di
  server. Silakan isi data manual."; 503 dari server sudah punya pesan sendiri dan dipakai apa adanya.
- [ktp_ocr_cubit.dart](lib/features/contact/presentation/state/ktp_ocr/ktp_ocr_cubit.dart) +
  [ktp_ocr_state.dart](lib/features/contact/presentation/state/ktp_ocr/ktp_ocr_state.dart) —
  pola sama seperti `PipelineCubit` (datasource langsung, tanpa layer usecase/repository).
  State `loading` dipakai untuk overlay "Membaca data KTP...".
- [main.dart:431](lib/main.dart#L431) + [main.dart:532](lib/main.dart#L532) — datasource & provider
  didaftarkan mengikuti pola `PipelineCubit`.

### 2. Halaman flow

- [reserve.dart](lib/features/contact/presentation/pages/reserve-order/reserve.dart) — `ReservePage`.
  - [reserve.dart:123](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L123)
    `_pickAndScan()` — ambil foto → kompres → OCR → autofill. Berhasil atau gagal, user tetap
    dibawa ke form: kalau OCR gagal tinggal isi manual, tidak mentok di layar scan.
  - [reserve.dart:133](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L133)
    kompresi **wajib**, bukan sekadar penghematan — lihat bagian "Batas ukuran foto" di bawah.
    Yang disimpan untuk preview adalah versi yang dikirim, jadi bytes foto asli tidak ikut
    ditahan di state.
  - [reserve.dart:168](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L168)
    `_applyOcr()` — hanya menimpa field yang ada isinya; sisanya dibiarkan apa adanya.
  - [reserve.dart:186](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L186)
    `_parseOcrDate()` — server mengirim `yyyy-MM-dd`, tapi format cetak KTP (`dd-MM-yyyy`) &
    `dd/MM/yyyy` juga dicoba supaya tidak bergantung satu sumber OCR. Gagal semua → kosong.
  - [reserve.dart:200](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L200)
    `_matchOption()` — hasil OCR huruf besar semua ("LAKI-LAKI", "BELUM KAWIN") dicocokkan ke item
    dropdown tanpa memedulikan huruf besar/kecil, spasi, dan tanda hubung.
  - [reserve.dart:474](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L474)
    preview foto KTP + link "Scan ulang" di atas form, pakai `FilePreviewWidget` yang sudah ada.
  - Nilai awal form diambil dari kontak (`fullName`, `noKtp`, `ktpAddress`) supaya tidak mulai dari
    kosong; hasil OCR menimpanya kalau ada.
  - Tombol back & back tombol sistem (`PopScope`) dari step Data Pembeli balik ke step scan dulu,
    bukan langsung keluar halaman.

### 3. Reuse picker

- [custom_file_picker.dart:52-148](lib/core/utils/widget/custom_file_picker.dart#L52-L148) —
  `_pickCamera`/`_pickGallery`/`_pickDocument` dipindah dari `_FilePickerSheet` ke
  `CustomFilePicker` sebagai `pickCamera()`/`pickGallery()`/`pickDocument()` (static, public).
  Sheet lama tetap jalan lewat fungsi yang sama, jadi logika web-vs-mobile-nya cuma ada satu
  tempat dan sheet Camera/Upload versi mockup bisa memakainya.

### 4. Batas ukuran foto & kompresi

Semua request app masuk lewat gateway terenkripsi `POST /api/px`, yang membungkus file jadi
**base64 di dalam body JSON** (lihat [dio_client.dart:117](lib/core/network/dio_client.dart#L117)).
Dua konsekuensinya yang bikin kompresi jadi wajib:

- Yang mengikat adalah `post_max_size` server (8M), **bukan** `upload_max_filesize` — dan base64
  menambah ~33%. Server membatasi foto 4 MB (`KTP_OCR_MAX_KB`).
- Gateway menolak request yang umurnya **> 30 detik** (`MAX_AGE_MS`), dihitung dari saat client
  membuat request. Foto kamera 4–8 MB di jaringan lambat gampang kena.

Foto dikecilkan pakai helper yang sudah ada, dengan satu penambahan:

- [image_compress_helper.dart](lib/core/utils/helpers/image_compress_helper.dart) —
  `compressImageBytes()` sekarang punya parameter opsional `maxSide` (default `0` = perilaku
  lama, jadi pemanggil yang sudah ada di contact-add tidak berubah).
- [image_compress_web.dart](lib/core/utils/helpers/image_compress_web.dart) — di web, `maxSide`
  membatasi sisi terpanjang lewat canvas sebelum di-encode JPEG q0.8. Sebelumnya resolusi asli
  dipertahankan, jadi foto 12MP tetap besar walau sudah di-JPEG-kan.
- [image_compress_impl.dart](lib/core/utils/helpers/image_compress_impl.dart) — di mobile,
  `compressImageBytes()` dengan `maxSide` memakai `compressWithList`; tanpa `maxSide` tetap
  no-op seperti sebelumnya. Jalur mobile KTP sendiri pakai `compressImageFile()` yang sudah ada
  (min 1280x720, target ≤300 KB).

KTP dikirim dengan `maxSide: 1600` di web — masih di atas ukuran yang dipakai server untuk OCR
(server sendiri menskalakan ke ~2000px), dan hasilnya normalnya jauh di bawah 1 MB.

### 5. Menu & route

- [reserve-order/index.dart:44](lib/features/contact/presentation/pages/reserve-order/index.dart#L44) —
  item "Reserve" dapat `onTap`; `_buildItem` sekarang menerima `onTap` opsional dan menampilkan
  chevron hanya untuk item yang bisa diklik. **Topup** dan **RB** dibiarkan pasif karena
  tujuannya belum ditentukan.
- [router.dart:336-345](lib/app/router.dart#L336-L345) — route `reserveOrderReserve`
  (`/contact/reserve-order/reserve`) sebagai child dari `reserveOrder`.

## Sisi server

Sudah dibuat **dan sudah diuji jalan** di repo Laravel `E:\WorkProject\php\Paradise-Connect-1.0`
(branch `reserve-order-mobile`): `POST /api/reserve/ktp-ocr`.

Engine-nya **Tesseract di server** (bukan Cloud Vision): gratis tanpa billing, dan foto KTP tidak
pernah keluar dari server sendiri. Cloud Vision tetap ada sebagai alternatif satu baris `.env`
(`KTP_OCR_DRIVER=vision`) kalau nanti akurasinya dirasa kurang — API-nya sudah di-enable, tinggal
billing project yang belum aktif.

Hasil uji end-to-end (Tesseract 5.4 + `ind.traineddata`, gambar KTP sintetis): **11 field terbaca
benar** — nama, NIK, tempat & tanggal lahir, jenis kelamin, status perkawinan, agama, pekerjaan,
alamat, RT/RW + kel/desa + kecamatan, kabupaten. Endpoint balas HTTP 200; foto bukan KTP → 422;
tanpa file / format salah → 422; Tesseract belum terinstall → 503 dengan pesan cara installnya.

Detail lengkap (install, konfigurasi, bentuk response, tabel error) ada di
`docs/api/reserve/post-reserve-ktp-ocr.md` di repo backend.

## Yang belum jalan / perlu diputuskan

1. **Tesseract perlu diinstall di server** sebelum fitur ini hidup di dev/production:
   `sudo apt install tesseract-ocr tesseract-ocr-ind` (di Linux tidak perlu setting `.env` apa
   pun — binary-nya sudah di PATH). Selama belum ada, endpoint membalas 503 dengan pesan yang
   menyebut perintah installnya dan app langsung mengarahkan user ke isi manual — bukan error 500.
2. **Tombol Next** — validasi Nama wajib & NIK 16 digit sudah jalan, tapi step setelah Data
   Pembeli belum ada di mockup, jadi Next baru menampilkan pesan "Step berikutnya belum
   tersedia" ([reserve.dart:210](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L210)).
   Data form belum dikirim ke `POST /api/reserve` — nama field hasil OCR sudah disiapkan 1:1
   dengan body endpoint itu, jadi tinggal disambung.
3. **Isi dropdown** — Jenis Kelamin, Marital Status, Kategori Pekerjaan, Pendidikan masih list
   hardcode di [reserve.dart:57-60](lib/features/contact/presentation/pages/reserve-order/reserve.dart#L57-L60).
   Di sisi DB pun kolomnya string bebas (tidak ada tabel master), jadi kalau mau dibakukan perlu
   keputusan bisnis dulu.
4. **Akurasi di foto asli belum diukur.** Uji di atas memakai gambar sintetis yang bersih.
   Tesseract lebih sensitif ke kualitas foto dibanding Vision, jadi setelah dipakai di lapangan
   mungkin perlu penyetelan: `TESSERACT_PSM` 6 → 4, atau pindah ke driver `vision`.
5. **Camera di PWA desktop** — `ImagePicker` dengan `ImageSource.camera` di browser desktop
   membuka dialog file, bukan kamera; di browser HP baru benar-benar membuka kamera. Ini perilaku
   `image_picker` di web, sama seperti fitur lain yang sudah ada di app ini.
