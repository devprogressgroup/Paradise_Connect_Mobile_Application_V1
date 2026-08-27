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

## Update — Cuma PDF & gambar yang didownload, selain itu share link biasa
Awalnya cuma video yang dikecualikan dari download (pakai `isVideo`). Setelah didiskusikan lagi, keputusan akhirnya dibalik jadi **whitelist**: cuma PDF & gambar yang didownload lalu di-share sebagai file. Semua tipe lain (video, dokumen, zip, dll — apa pun yang bukan PDF/gambar) langsung `Share.share(widget.url, ...)` (link mentah, tanpa dipersingkat/di-custom — sempat didiskusikan pakai shortlink seperti Bitly/TinyURL tapi diputuskan pakai link biasa dulu untuk saat ini).

- `bool get isImage` ditambahkan di `WebViewPage` (gantikan `isVideo` yang sebelumnya dipakai untuk guard ini — sekarang tidak diperlukan lagi karena logikanya sudah whitelist `isPdf`/`isImage`):
  - [lib/core/utils/widget/webview_page_mobile.dart:28-31](../lib/core/utils/widget/webview_page_mobile.dart#L28-L31)
  - [lib/core/utils/widget/webview_page_web.dart:26-29](../lib/core/utils/widget/webview_page_web.dart#L26-L29)
- Guard di awal `_shareUrl()` — kalau **bukan** `isPdf` dan **bukan** `isImage`, langsung `Share.share(...)` dan `return`, tidak masuk ke alur download:
  - [lib/core/utils/widget/webview_page_mobile.dart:46-51](../lib/core/utils/widget/webview_page_mobile.dart#L46-L51)
  - [lib/core/utils/widget/webview_page_web.dart:180-185](../lib/core/utils/widget/webview_page_web.dart#L180-L185)

Jadi ringkasan akhir: **PDF & gambar** → download lalu share sebagai file. **Selain itu (termasuk video/YouTube)** → share link biasa.

## Fix — File hasil share jadi ".bin" / tanpa ekstensi
**Masalah:** banyak URL sumber (misal Google Drive `uc?export=download&id=...`) tidak punya ekstensi di path-nya. Kode awal cuma nebak ekstensi dari potongan terakhir URL — kalau tidak ketemu, nama file jadi tanpa ekstensi dan `XFile`/share sheet default ke `application/octet-stream`, yang oleh banyak OS/aplikasi penerima ditampilkan sebagai file `.bin`.

**Perbaikan:** tambah helper [lib/core/utils/helpers/file_extension_helper.dart](../lib/core/utils/helpers/file_extension_helper.dart) buat resolve ekstensi secara berlapis:
1. `extensionFromUrl()` — dari path URL (cuma dipakai kalau ekstensinya dikenali di daftar mime yang didukung).
2. `extensionFromContentDisposition()` — parse header `Content-Disposition: ...filename=...` dari response.
3. `extensionFromContentType()` — mapping header `Content-Type` (mis. `application/pdf` → `.pdf`) ke ekstensi.
4. Fallback terakhir: `.pdf` kalau `widget.isPdf`, atau `.bin` kalau benar-benar tidak diketahui.

- **Mobile** — download tetap sekali jalan (`Dio().download`); kalau URL tidak punya ekstensi, ekstensi final di-resolve dari header response yang sama, lalu file di-*rename* sebelum di-share: [lib/core/utils/widget/webview_page_mobile.dart:50-77](../lib/core/utils/widget/webview_page_mobile.dart#L50-L77)
- **Web** — ekstensi + `mimeType` di-resolve dari response yang sama (satu request `Dio().get(bytes)`, tidak ada request tambahan), lalu dipakai di `XFile.fromData(bytes, name: ..., mimeType: ...)`: [lib/core/utils/widget/webview_page_web.dart:187-210](../lib/core/utils/widget/webview_page_web.dart#L187-L210)

Hasilnya file yang di-share sekarang konsisten punya ekstensi & mimeType yang benar (`.pdf`, `.jpg`, dst), cuma jatuh ke `.bin` kalau memang tipe filenya di luar daftar yang dikenali helper.

## Catatan risiko
Di web, fetch file dari domain lain (misal Google Drive) bisa kena **CORS** kalau server sumbernya tidak mengizinkan cross-origin request dari browser — kalau itu terjadi, otomatis fallback ke share link (tidak ada crash), tapi user tidak dapat file-nya. Perlu ditest langsung ke masing-masing sumber file (Price List/Brochure/dll) untuk pastikan tidak semuanya kena CORS.
