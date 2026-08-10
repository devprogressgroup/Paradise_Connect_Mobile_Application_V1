# Site Plan – Halaman Detail Unit (Blank) + Decrypt Payload `/siteplan-key`

**Tanggal:** 2026-08-10
**Area:** `lib/features/site-plan/presentation/blank/siteplan-blank.dart`, `lib/features/site-plan/domain/entities/unit_detail.dart`, `lib/features/site-plan/presentation/site-plan-page/index_web.dart`, `lib/features/site-plan/presentation/site-plan-page/index_mobile.dart`, `lib/app/router.dart`

## Masalah

1. `SitePlanBlank` sebelumnya cuma placeholder kosong (`return const Center();`) — belum ada tampilan native untuk detail unit.
2. Backend siteplan mengirim data unit dalam bentuk terenkripsi (AES-256-CBC) lewat query param url `/siteplan-key?=<ivBase64>:<ciphertextBase64>` (contoh cara decrypt-nya ada di `test_crypto.html` di root project), jadi perlu didecrypt dulu di sisi app sebelum bisa ditampilkan.

## Perubahan

1. **Model data** — `UnitDetail`, `UnitSpec`, `PriceScheme`, `Installment` dibuat di [unit_detail.dart](../lib/features/site-plan/domain/entities/unit_detail.dart) untuk parsing JSON unit (`projects`, `cluster`, `product`, `blok_unit`, `status`, `is_sold`, `spec`, `price_schemes`).
2. **UI halaman detail** — [siteplan-blank.dart](../lib/features/site-plan/presentation/blank/siteplan-blank.dart) dibangun lengkap: judul unit + badge status, section "Informasi Unit" (grid 2 kolom, bisa expand/collapse), "Harga dan Simulasi Pembayaran" (kartu per skema harga, scroll horizontal, promo/strikethrough), dan "Spesifikasi Unit" (grid ikon). Tema warnanya disamakan dengan app (header `primaryColor`, background `grey11Color`, card putih border `grey9Color`) — tidak pakai warna ad-hoc.
3. **Empty state harga** — [_buildHargaSimulasi](../lib/features/site-plan/presentation/blank/siteplan-blank.dart#L242-L280): kalau `status == "SP"` atau `is_sold == true` → tampil pesan **"Unit Sudah Terjual"**; kalau `price_schemes` kosong (belum terjual) → **"Harga Belum Tersedia"**. Keduanya pakai empty-state card dengan ikon bulat + judul + deskripsi ([_buildPaymentEmptyState](../lib/features/site-plan/presentation/blank/siteplan-blank.dart#L282)), bukan section yang hilang begitu saja.
4. **Helper decrypt** — [UnitDetail.fromEncryptedKeyUrl](../lib/features/site-plan/domain/entities/unit_detail.dart#L50) dan [decryptKeyUrlToJson](../lib/features/site-plan/domain/entities/unit_detail.dart#L57): ambil bagian setelah `?=` di url, decrypt lewat `ProxyCipher.decryptString` (`lib/core/network/proxy_cipher.dart`, key AES sama dengan yang dipakai `test_crypto.html`), lalu `jsonDecode` hasilnya. Sengaja reuse `ProxyCipher` yang sudah ada, bukan tulis ulang logic AES.
5. **Routing (buka dari dalam app)** — `site_plan_blank` di [router.dart:317-329](../lib/app/router.dart#L317-L329) menerima `state.extra` sebagai `data` ke `SitePlanBlank`.
6. **Tombol akses** — ikon mata di header halaman Site Plan ([index_web.dart:109](../lib/features/site-plan/presentation/site-plan-page/index_web.dart#L109), [index_mobile.dart:117](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart#L117)) sekarang decrypt `sampleEncryptedSiteplanKeyUrl` lalu push ke `SitePlanBlank` dengan data hasil decrypt (bukan cuma buka halaman kosong).
7. **Routing (buka dari App Link `/link/{hash}`)** — payload unit terenkripsi ikut nebeng di query string link asli (`...?=<ivBase64>:<ciphertextBase64>`), BUKAN dari endpoint resolve (endpoint itu sengaja cuma balikin nama target halaman, lihat komentar di [_resolveAppLinkHash](../lib/app/router.dart#L67)). Redirect di [router.dart:119-133](../lib/app/router.dart#L119-L133) meneruskan query itu apa adanya ke path internal; builder `site_plan_blank` ([router.dart:317-329](../lib/app/router.dart#L317-L329)) baca `state.uri.query` dan decrypt lewat [UnitDetail.decryptPayload](../lib/features/site-plan/domain/entities/unit_detail.dart#L58) kalau tidak ada `extra`.
8. **Fix PWA/web** — Flutter web defaultnya pakai hash URL strategy (`/#/link/{hash}`), jadi kalau link `https://devconnect.paradise.id/link/{hash}` dibuka langsung di browser, path aslinya tidak pernah kebaca router (selalu keliatan `/` polos). Ditambahkan `usePathUrlStrategy()` di [main.dart](../lib/main.dart) (paket `flutter_web_plugins`, ditambah di `pubspec.yaml`) supaya web pakai clean path URL yang sama persis dengan yang dicek regex `_appLinkHashPattern`.
9. **Prioritas app > PWA > web** — [web/manifest.json:11](../web/manifest.json#L11) ditambah `"capture_links": "existing-client-navigate"`, supaya di Android, kalau PWA sudah ter-install, link `devconnect.paradise.id/link/...` otomatis kebuka di window PWA (bukan tab browser baru) alih-alih cuma jadi website biasa.

## Status deteksi app/PWA/web per platform

Prioritas "app terinstall → app, PWA terinstall → PWA, tidak ada → web" itu **bukan logika yang bisa ditulis manual di Dart** — sepenuhnya ditentukan OS/browser:

- **Android**: sudah lengkap. App Links terverifikasi ([AndroidManifest.xml:64-69](../android/app/src/main/AndroidManifest.xml#L64-L69), `autoVerify="true"`) → native app otomatis kebuka kalau terinstall, request tidak pernah sampai ke browser/PWA sama sekali. Kalau app tidak terinstall tapi PWA sudah, `capture_links` (poin 9 di atas) yang ambil alih. Kalau tidak ada keduanya, baru jatuh ke browser biasa (jalur yang sudah kita bangun).
- **iOS**: **belum ada Universal Links** (associated domains + `apple-app-site-association`) — project sudah punya bundle ID (`id.co.progressgroup.connect`) tapi belum di-setup. **Sengaja belum dikerjakan** (dikonfirmasi ke user 2026-08-10) karena butuh Apple Developer Team ID + file `apple-app-site-association` yang harus di-deploy tim backend di luar repo ini. Efeknya: di iPhone, link ini SELALU jatuh ke Safari/PWA, tidak akan pernah otomatis buka native app. `capture_links` juga tidak didukung Safari sama sekali. Kalau nanti mau diaktifkan, tinggal lanjutkan dari sini.

## Catatan

- Galeri gambar unit **tidak dibuat** — JSON data unit yang ada belum menyediakan field gambar/foto sama sekali.
- `sampleEncryptedSiteplanKeyUrl` ([unit_detail.dart:7](../lib/features/site-plan/domain/entities/unit_detail.dart#L7)) masih **hardcode** (contoh response API yang diberikan saat development), belum ada pemanggilan endpoint `/siteplan-key` yang sesungguhnya dari app. Begitu endpoint aslinya siap dipanggil (mis. lewat `SiteplanRemoteDataSource`), tinggal ganti sumber string terenkripsi itu di `_openSitePlanBlank()` — helper decrypt-nya sudah generic dan siap pakai untuk data asli.
- Belum ada jembatan (JS bridge/`postMessage`) dari WebView/iframe site plan yang otomatis memicu halaman ini saat user tap unit di peta — tombol mata di header sekarang murni jalur preview manual.
- `usePathUrlStrategy()` cuma membereskan sisi Flutter. Server yang serve `devconnect.paradise.id` (di luar repo ini) tetap harus punya SPA fallback (rewrite path yang tidak dikenal ke `index.html`) supaya request langsung ke `/link/{hash}` tidak 404 sebelum Flutter sempat jalan — sama seperti requirement standar SPA routing di web mana pun.

## Hasil

- `flutter analyze` bersih di semua file yang diubah (cuma 1 info `deprecated_member_use` untuk `dart:html` yang sudah ada sebelumnya, tidak terkait perubahan ini).
- Hasil decrypt sudah diverifikasi cocok 100% dengan payload asli lewat skrip Dart sementara (dijalankan lalu dihapus lagi, tidak masuk repo).
