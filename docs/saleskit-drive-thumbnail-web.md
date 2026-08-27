# SalesKit — Thumbnail Google Drive Tidak Muncul di PWA (Web)

**Tanggal:** 2026-08-06
**Area:** `core/utils/widget/drive_image/drive_image_web.dart` (dipakai oleh SalesKit media list — YouTube & Website group)

## Masalah
Thumbnail media di SalesKit (format API: `thumbnail: "https://drive.google.com/thumbnail?id=<ID>&sz=w1000"`) tampil normal di mobile (native app), tapi **tidak muncul sama sekali di PWA** — sebagian nyangkut loading terus (kotak abu-abu), sebagian lagi eksplisit jadi ikon broken-image.

## Investigasi
- URL & CORS-nya sendiri sudah dicek langsung (curl, termasuk simulasi header `Sec-Fetch-Mode`/`Sec-Fetch-Dest` yang dipakai browser) — **selalu sukses & `Access-Control-Allow-Origin: *`**, baik di response redirect (`drive.google.com/thumbnail`) maupun response final (`lh3.googleusercontent.com`). Jadi resource-nya sendiri valid, bukan link mati.
- Dibandingkan dengan pola di halaman Attendance (`features/attandance`) yang juga pakai `DriveImage` dan Google Drive, ternyata komponennya **sama persis** — bedanya di format URL yang dikirim backend. Attendance biasa dapat link gaya `https://drive.google.com/file/d/<ID>/view` (path style), sedangkan SalesKit dapat `https://drive.google.com/thumbnail?id=<ID>&sz=...` (query-param style).
- Root cause: `_toCdnUrl()` di `drive_image_web.dart` cuma extract ID dari pola path `/d/<ID>/`. Untuk format `?id=<ID>` (SalesKit), regex ini tidak match → fallback `return url` → gambar di-load **lewat `drive.google.com/thumbnail` dulu (kena redirect 302 ke `lh3.googleusercontent.com`)**. Redirect cross-origin inilah yang bermasalah khusus di Flutter Web (CanvasKit/Skwasm fetch pixel-decode), sementara format Attendance (`/file/d/<ID>/view`) langsung ke-convert ke URL final `lh3.googleusercontent.com` TANPA redirect sama sekali — makanya Attendance selalu mulus di web, SalesKit tidak.

## Perbaikan
`_toCdnUrl()` sekarang extract ID dari **kedua pola** (path `/d/<ID>/` ATAUPUN query param `?id=<ID>`), sehingga apa pun format URL Drive-nya, hasil akhirnya selalu langsung ke `lh3.googleusercontent.com` — tidak pernah lagi lewat redirect `drive.google.com`.

- [lib/core/utils/widget/drive_image/drive_image_web.dart:58-65](../lib/core/utils/widget/drive_image/drive_image_web.dart#L58-L65)

```dart
String _toCdnUrl(String url) {
  try {
    final id = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1) ??
        Uri.parse(url).queryParameters['id'];
    if (id == null) return url;
    final baseUrl = 'https://lh3.googleusercontent.com/d/$id';
    ...
  } catch (_) {
    return url;
  }
}
```

Sudah diverifikasi: request langsung ke `lh3.googleusercontent.com/d/<ID>=w...` (pakai ID hasil extract dari `?id=`) sukses 200 OK dengan CORS terbuka.

## Catatan
Versi mobile (`drive_image_mobile.dart` / `convertDriveUrl` di [image_url.dart](../lib/core/utils/helpers/image_url.dart)) sengaja **tidak diubah** — mobile tidak kena masalah redirect ini sama sekali (native HTTP client tidak punya batasan CORS/fetch-mode seperti browser), jadi tidak ada yang perlu diperbaiki di sisi itu.
