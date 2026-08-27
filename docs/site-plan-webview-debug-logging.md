# Site Plan – Local Proxy & Header Injection di WebView

**Area:** `lib/features/site-plan/presentation/site-plan-page/index_mobile.dart`,
`lib/features/site-plan/domain/repositories/site_plan_repository_impl.dart`,
`lib/features/site-plan/domain/entities/project_site.dart`, `lib/core/network/api_constants.dart`

> **Catatan penting**: bagian "Iterasi 1" di bawah (2026-08-07) mengklaim `_LocalProxy` sudah
> dihapus — tapi menurut `git log -S "_LocalProxy" -- .../index_mobile.dart`, **tidak pernah ada
> commit yang menghapus class itu** sejak pertama kali dibuat (28 Mei 2026, commit `a165a06`).
> Artinya perubahan yang diklaim Iterasi 1 kemungkinan besar tidak pernah sempat ke-commit (atau
> ke-revert sebelum commit) — faktanya, `_LocalProxy` MASIH ADA di kode sampai Iterasi 2 (di bawah)
> beneran menghapusnya. Isi Iterasi 1 dibiarkan sebagai riwayat, bukan dihapus, supaya jelas kalau
> klaimnya sempat tidak sinkron dengan kode sungguhan.

## Iterasi 1 (2026-08-07, klaim — tidak tervalidasi di git history)

**Masalah yang diangkat saat itu:**
1. Saat memilih cluster di halaman Site Plan (mobile/native webview), sulit memastikan URL apa yang sebenarnya diminta ke server — terutama saat menyelidiki kasus `net::ERR_HTTP_RESPONSE_CODE_FAILURE`. Investigasi menunjukkan `SITEPLAN_MOBILE_URL` di settings API Development masih berisi value lama (`http://192.168.8.56/Paradise-Dynamics-Web-2.0-v1/...`), beda dari Production (`https://dynamics.paradise.id/paradise_api/siteplan_mobile`) — bukan bug kode, tapi beda data setting per environment.
2. Kode saat itu menjalankan `_LocalProxy` (HTTP server lokal di `127.0.0.1`) untuk menyisipkan header (`X-App-Token`) ke request, lalu me-rewrite URL asli jadi `http://127.0.0.1:<port>/...` sebelum di-load ke WebView. Ini membuat URL asli tidak terlihat langsung dan menambah lapisan yang tidak perlu.

**Perubahan yang diklaim** (lihat catatan di atas — tidak ketemu di git history):
- Hapus class `_LocalProxy` dan field `_proxy` beserta lifecycle-nya (`stop()` di `dispose()`).
- `_loadSite` langsung memanggil `WebViewController.loadRequest(uri, headers: site.headers)`
  bawaan `webview_flutter`, tanpa rewrite host/port ke localhost.
- Tambah `debugPrint` untuk `site.url` dan `site.headers` setiap kali site dipilih.

## Iterasi 2 (2026-08-10) — `_LocalProxy` Benar-Benar Dihapus, Sekaligus Disatukan dengan PWA

**Konteks berbeda dari Iterasi 1**: bukan lagi soal "native headers vs local proxy" (dua-duanya
sama-sama masih connect LANGSUNG ke server siteplan asli, `dynamics.paradise.id`/dst). Perubahan
ini datang dari sisi backend Laravel (`Paradise-Connect-1.0`, lihat
`docs/site-plan-mobile-pwa.md` §9 di repo itu): permintaan user adalah proxy + header custom
**jangan di Flutter sama sekali** — backend yang urus, PERSIS seperti jalur PWA/web
(`index_web.dart`) yang dari awal memang sudah lewat proxy Laravel (`/property/siteplan-proxy`).
Backend juga sudah dipastikan TIDAK hardcode (baca `app_m_setting` secara dinamis) sebelum
perubahan sisi Flutter ini dikerjakan.

**Perubahan:**
- [`site_plan_repository_impl.dart`](../lib/features/site-plan/domain/repositories/site_plan_repository_impl.dart):
  cabang `if (kIsWeb) {...} else {...}` dihapus — mobile & web SEKARANG SELALU bangun URL yang
  sama: `$backendBase/property/siteplan-proxy?company_id=...&siteplan_id=...`, TANPA header
  custom (backend yang menyisipkan `X-App-Token` + query param `pdkey`, lihat
  `PropertyController::forwardToSiteplan()` di repo Laravel). Query param `pdkey=hoaxprogress`
  yang SEBELUMNYA hardcode literal di sini juga dihapus — backend yang isi otomatis.
- [`project_site.dart`](../lib/features/site-plan/domain/entities/project_site.dart): field
  `headers` dihapus dari `ProjectSite` — tidak ada lagi yang butuh.
- [`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart):
  class `_LocalProxy` **benar-benar dihapus** kali ini (beserta field `_proxy`,
  `dispose()` override yang cuma isinya `_proxy?.stop()`). `_loadSite()` jadi 1 baris:
  `_controller.loadRequest(Uri.parse(site.url))` — tidak ada lagi cek `site.headers.isNotEmpty`
  atau bikin `HttpServer`/`HttpClient` lokal sama sekali. `debugPrint('[SitePlan] loading url:
  ...')` dipertahankan; `debugPrint('[SitePlan] proxied url: ...')` (yang sebelumnya nge-print
  `$localUri` hasil rewrite ke `127.0.0.1`) ikut terhapus karena bagian kodenya sendiri sudah
  tidak ada.
- [`api_constants.dart`](../lib/core/network/api_constants.dart): field `_siteplanBaseUrl`/
  `_siteplanToken` dan getter `siteplanBaseUrl`/`siteplanWebviewHeaders` dihapus (dicek dulu lewat
  grep — sudah tidak dipakai di manapun setelah perubahan di atas). Case
  `'SITEPLAN_MOBILE_URL'`/`'X-App-Token SitePlan'` di `applySettings()` juga dihapus — setting itu
  tetap ada di `app_m_setting`/`GET /api/settings`, cuma sisi Flutter sudah tidak baca/simpan lagi
  (tidak dipakai buat connect WebView lagi).

**Yang SENGAJA tidak disatukan**: `index_mobile.dart` (WebView native, `webview_flutter`) &
`index_web.dart` (iframe browser, `dart:html`) tetap 2 file terpisah — rendering-nya genuinely
beda (widget, error handling, reset-zoom mechanism), bukan soal proxy/header lagi. Yang disamakan
cuma cara dapat URL-nya (`site_plan_repository_impl.dart`).

**Dampak samping**: mobile jadi lebih ringan — tidak ada lagi `HttpServer`/`HttpClient` yang
dibuka/ditutup tiap kali pindah site plan (biaya CPU/memory kecil tapi nyata, apalagi kalau user
sering ganti-ganti site plan).

## Iterasi 3 (2026-08-11) — Log URL Navigasi Dalam WebView (`onNavigationRequest`)

**Konteks:** popup marker unit di Site Plan (mis. klik pin → muncul info unit + tombol
"Lihat Selengkapnya") itu di-render oleh konten HTML dari server siteplan (via proxy Laravel),
bukan widget Flutter. Sebelum perubahan ini, `WebViewController` di
[`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart)
tidak punya `onNavigationRequest`, jadi tiap kali tombol semacam itu di-tap, WebView langsung
navigasi sendiri di dalam dirinya tanpa ada jejak URL tujuan yang bisa dilihat dari sisi Flutter.

**Perubahan:**
- [`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart#L71-L78):
  tambah `onNavigationRequest` di `NavigationDelegate` — `debugPrint` + `web_debug.logDebugInfo`
  URL request-nya, lalu selalu `NavigationDecision.navigate` (murni observasi, tidak mengubah
  perilaku navigasi).
- **Fix spam log**: awalnya log tercetak terus-menerus dengan `url` kosong — ternyata konten
  siteplan pakai iframe internal yang juga memicu `onNavigationRequest` berkali-kali (bukan cuma
  navigasi utama). Ditambah filter `request.isMainFrame && request.url.isNotEmpty` sebelum log,
  supaya cuma navigasi frame utama dengan URL valid yang dicatat.

**Yang SENGAJA belum dikerjakan:** tidak ada intercept/`NavigationDecision.prevent` atau redirect
ke halaman native (`/site-plan/blank` + `UnitDetail`) — baru sebatas lihat dulu URL-nya berisi apa.
Kalau nanti perlu buka detail unit secara native dari tombol ini, baru ditambah logic parsing URL
+ prevent di titik yang sama.

## Status/Verifikasi

`flutter analyze lib/features/site-plan lib/core/network/api_constants.dart` → 0 error (1 info
pre-existing soal `dart:html` deprecated di `index_web.dart`, tidak terkait perubahan ini).
**Belum dites jalan sungguhan di emulator/device** — perlu dicoba buka Site Plan di app mobile
untuk konfirmasi WebView berhasil load lewat proxy backend (origin siteplan yang di-hit backend
sempat butuh ~46 detik buat respons saat dites, lihat `docs/site-plan-mobile-pwa.md` §9.3 di repo
Laravel — WebView mobile juga akan kena delay yang sama, belum dicek apakah ada timeout sisi
Flutter yang bisa motong lebih cepat dari itu).
