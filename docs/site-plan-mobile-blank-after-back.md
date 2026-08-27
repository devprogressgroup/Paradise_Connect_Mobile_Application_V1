# Site Plan Mobile: Map Jadi Blank Setelah Kembali dari Detail Unit

**Tanggal:** 2026-08-12
**Area:** `lib/features/site-plan/presentation/site-plan-page/index_mobile.dart`

## Masalah

User lapor: setelah klik pin → "Lihat Selengkapnya" → lihat `SitePlanBlank` → tekan back →
halaman Site Plan (peta) jadi **putih/kosong**. Terlihat juga cluster yang tampil di dropdown
BERUBAH (balik ke cluster pertama di daftar, bukan yang terakhir dipilih user) — mengindikasikan
halaman Site Plan **dibuat ulang dari nol**, bukan sekadar "terlihat kosong sebentar".

Bug ini **HANYA ada di mobile** (`index_mobile.dart`) — versi web (`index_web.dart`) tidak
kena, sudah benar dari awal.

## Root Cause #1 — `initState()` Selalu Reset & Fetch Ulang

```dart
// SEBELUM (bug):
WidgetsBinding.instance.addPostFrameCallback((_) {
  setState(() { _selectedSite = null; _sites = []; });   // selalu reset
  context.read<SiteplanBloc>().add(LoadSiteplanEvent()); // selalu fetch ulang
});
```
Setiap kali widget `SitePlanPage` dibuat ulang (termasuk saat kembali dari route yang ditumpuk
di atasnya — `/site-plan/blank` didaftarkan DI LUAR `ShellRoute`, lihat
`Paradise-Connect-1.0/docs/site-plan-mobile-pwa.md` §16.3 repo backend untuk alasan desainnya),
`initState()` MEMAKSA reset ke kondisi awal + fetch ulang daftar site plan dari server —
otomatis pilih `sites.first` lagi (bukan yang user pilih sebelumnya), dan `WebViewController`
baru dibuat lalu `loadRequest()` dari nol (network round-trip ~3-4 detik, lihat riwayat
performa di `site-plan-mobile-pwa.md` §12 repo backend).

**Fix**: cek dulu state `SiteplanBloc` — kalau SUDAH `SiteplanLoaded` (data sudah ada), pakai
langsung (`_initFromSites`), JANGAN reset+fetch ulang. Pola disamakan dengan
[`index_web.dart`](../lib/features/site-plan/presentation/site-plan-page/index_web.dart) yang
sudah benar dari awal.

## Root Cause #2 — WebView Platform View Blank Setelah Ditumpuk Route Lain

Setelah fix #1, network fetch tidak lagi terjadi, TAPI map masih sempat kelihatan blank.
Ini bug **umum di `webview_flutter` (Android)**: WebView pakai platform view/texture native —
begitu ada halaman FULL-SCREEN lain ditumpuk di atasnya (push) lalu ditutup (pop), texture-nya
kadang berhenti repaint sendiri, walau `WebViewController` & isinya SEBENARNYA masih hidup di
memori (bukan kehilangan data — cuma berhenti "digambar").

**Fix**: pakai `RouteObserver` yang SUDAH ADA di app ini
([`route_observer.dart`](../lib/core/utils/route_observer.dart), `appRouteObserver` — pola yang
sama dipakai [`home/index.dart`](../lib/features/home/presentation/pages/home/index.dart)).
`_SitePlanPageState` sekarang `with RouteAware`, subscribe di `didChangeDependencies()`,
unsubscribe di `dispose()`. `didPopNext()` (dipanggil FRAMEWORK begitu halaman ini kembali
terlihat setelah route di atasnya di-pop) cuma panggil `setState(() {})` KOSONG — bukan reload
apa pun — supaya Flutter paksa rebuild widget tree, yang bikin platform view WebView ikut
di-re-attach & repaint sendiri.

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final route = ModalRoute.of(context);
  if (route is PageRoute) appRouteObserver.subscribe(this, route);
}

@override
void dispose() {
  appRouteObserver.unsubscribe(this);
  super.dispose();
}

@override
void didPopNext() {
  if (mounted) setState(() {});
}
```

## Yang BELUM Diselesaikan

- **Cluster yang tampil masih bisa balik ke default** (`sites.first`), BUKAN yang terakhir
  dipilih user via dropdown — fix #1 di atas cuma hindarkan FETCH ULANG (jauh lebih cepat), tapi
  `_selectedSite` sendiri adalah variable LOKAL widget yang tetap reset ke `null` kalau widget-nya
  benar-benar dibuat ulang (initState tetap jalan sekali per instance baru, cuma tidak lagi
  fetch-nya yang mahal). Kalau mau BENAR-BENAR pertahankan pilihan cluster terakhir, perlu
  simpan "site yang dipilih" di tempat yang tahan terhadap widget rebuild (mis. jadi bagian
  `SiteplanState`/Bloc itu sendiri, bukan local state) — BELUM dikerjakan, ditunggu konfirmasi
  apakah perlu.
- **Belum dites end-to-end sungguhan di device** — fix #2 (RouteAware + setState kosong) adalah
  solusi UMUM yang dikenal untuk kelas bug ini, tapi belum diverifikasi langsung di device
  bahwa `setState()` kosong SAJA cukup memicu WebView repaint (kadang perlu tambahan trik JS
  resize-event kalau `setState()` polos belum cukup) — perlu dicoba dulu sebelum dianggap final.

## Verifikasi

`flutter analyze lib/features/site-plan/presentation/site-plan-page/index_mobile.dart` → 0 issue
baru (1 warning pre-existing, tombol preview mata yang sudah dinonaktifkan sebelumnya, tidak
terkait perubahan ini).
