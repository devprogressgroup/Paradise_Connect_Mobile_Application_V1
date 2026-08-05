# WebView — Share Button Download File Dulu, Bukan Share Link Mentah

**Tanggal:** 2026-08-05
**Area:** `core/utils/widget/webview_page_mobile.dart` & `webview_page_web.dart` (dipakai oleh SalesKit — Price List, E-Brochure, Product Knowledge, Promotion Kit, media item)

## Masalah
Tombol share (ikon share di header `WebViewPage`) sebelumnya cuma `Share.share(widget.url, subject: widget.title)` — yang dibagikan lewat share sheet OS cuma **teks link mentah**, bukan file-nya. Penerima harus buka link itu sendiri, tidak langsung dapat filenya.

## Perubahan
`_shareUrl()` sekarang men-download file dulu ke memory/temp, baru dibagikan sebagai file lewat `Share.shareXFiles`. Kalau download gagal (misal file besar/timeout/CORS di web), fallback otomatis ke share link mentah seperti sebelumnya supaya fitur tidak rusak total.

**Mobile** — download ke temp directory pakai `Dio().download()`, lalu `Share.shareXFiles([XFile(filePath)])`:
- [lib/core/utils/widget/webview_page_mobile.dart:34-63](../lib/core/utils/widget/webview_page_mobile.dart#L34-L63)

**Web** — fetch file sebagai bytes pakai `Dio().get(... responseType: ResponseType.bytes)`, lalu `Share.shareXFiles([XFile.fromData(bytes, name: ...)])` (pakai Web Share API kalau didukung browser):
- [lib/core/utils/widget/webview_page_web.dart:172-198](../lib/core/utils/widget/webview_page_web.dart#L172-L198)

## Hasil
- Share sheet sekarang menampilkan file asli (PDF/gambar/dll), bukan cuma teks link.
- Ada guard `_isSharing` supaya tombol tidak bisa di-tap dobel saat proses download berlangsung.
- Kalau download gagal, muncul snackbar "Gagal mengunduh file, membagikan link saja" lalu tetap fallback share link — tidak ada skenario tombol jadi tidak berfungsi sama sekali.

## Update — Video tetap share link, bukan download
Video (ekstensi `.mp4/.mov/.avi/.mkv/.webm` atau link YouTube) sengaja **tidak** didownload — file video biasanya besar (lambat/boros kuota) dan YouTube bukan file yang bisa didownload langsung. Untuk kasus ini, share tetap pakai `Share.share(widget.url, ...)` (link mentah), sama seperti behavior sebelum perubahan ini.

- `bool get isVideo` pada `WebViewPage` — cek ekstensi video atau `isYoutubeUrl()` ([lib/core/utils/helpers/youtube_helper.dart](../lib/core/utils/helpers/youtube_helper.dart)):
  - [lib/core/utils/widget/webview_page_mobile.dart:24-28](../lib/core/utils/widget/webview_page_mobile.dart#L24-L28)
  - [lib/core/utils/widget/webview_page_web.dart:24-28](../lib/core/utils/widget/webview_page_web.dart#L24-L28)
- Guard di awal `_shareUrl()` — kalau `widget.isVideo`, langsung `Share.share(...)` dan `return`, tidak masuk ke alur download:
  - [lib/core/utils/widget/webview_page_mobile.dart:43-48](../lib/core/utils/widget/webview_page_mobile.dart#L43-L48)
  - [lib/core/utils/widget/webview_page_web.dart:188-192](../lib/core/utils/widget/webview_page_web.dart#L188-L192)

Jadi ringkasan akhir: **PDF & gambar** → download lalu share sebagai file. **Video** (termasuk YouTube) → tetap share link.

## Catatan risiko
Di web, fetch file dari domain lain (misal Google Drive) bisa kena **CORS** kalau server sumbernya tidak mengizinkan cross-origin request dari browser — kalau itu terjadi, otomatis fallback ke share link (tidak ada crash), tapi user tidak dapat file-nya. Perlu ditest langsung ke masing-masing sumber file (Price List/Brochure/dll) untuk pastikan tidak semuanya kena CORS.
