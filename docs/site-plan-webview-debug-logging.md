# Site Plan – Hapus Local Proxy, Debug Logging URL WebView

**Tanggal:** 2026-08-07
**Area:** `lib/features/site-plan/presentation/site-plan-page/index_mobile.dart`

## Masalah

1. Saat memilih cluster di halaman Site Plan (mobile/native webview), sulit memastikan URL apa yang sebenarnya diminta ke server — terutama saat menyelidiki kasus `net::ERR_HTTP_RESPONSE_CODE_FAILURE`. Investigasi menunjukkan `SITEPLAN_MOBILE_URL` di settings API Development masih berisi value lama (`http://192.168.8.56/Paradise-Dynamics-Web-2.0-v1/...`), beda dari Production (`https://dynamics.paradise.id/paradise_api/siteplan_mobile`) — bukan bug kode, tapi beda data setting per environment.
2. Kode sebelumnya menjalankan `_LocalProxy` (HTTP server lokal di `127.0.0.1`) untuk menyisipkan header (`X-App-Token`) ke request, lalu me-rewrite URL asli jadi `http://127.0.0.1:<port>/...` sebelum di-load ke WebView. Ini membuat URL asli tidak terlihat langsung dan menambah lapisan yang tidak perlu.

## Perubahan

- Hapus class `_LocalProxy` dan field `_proxy` beserta lifecycle-nya (`stop()` di `dispose()`) — sudah tidak dipakai.
- `_loadSite` sekarang langsung memanggil `WebViewController.loadRequest(uri, headers: site.headers)` bawaan `webview_flutter`, tanpa rewrite host/port ke localhost: [index_mobile.dart:85-92](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart#L85-L92)
- Tambah `debugPrint` untuk `site.url` dan `site.headers` setiap kali site dipilih, supaya URL yang benar-benar dipakai (persis dari `SITEPLAN_MOBILE_URL` setting, tanpa rewrite apa pun) mudah diverifikasi lewat debug console.

## Catatan

Tidak ada URL yang di-hardcode di kode Flutter — URL selalu diambil dari setting `SITEPLAN_MOBILE_URL` lewat `ApiConstants.siteplanBaseUrl` ([api_constants.dart:125](../lib/core/network/api_constants.dart#L125)), berbeda nilainya sesuai environment (Development/Production) yang aktif di app.

## Hasil

Log muncul di console setiap kali user memilih site plan, dan URL yang dimuat WebView sekarang identik dengan value `SITEPLAN_MOBILE_URL` dari settings API (plus header `X-App-Token` yang dikirim native oleh WebView, bukan lewat proxy lokal).
