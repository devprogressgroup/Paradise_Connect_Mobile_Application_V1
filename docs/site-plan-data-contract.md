# Kontrak Data Site Plan → Detail Unit (Flutter Side)

Dokumen referensi: bagaimana Flutter MENGONSUMSI data dari backend Laravel di fitur Site Plan
(daftar → peta → detail unit), dan file mana yang berperan di tiap tahap. Pasangan dokumen ini
ada di repo backend: [`Paradise-Connect-1.0/docs/site-plan-data-contract.md`](../../Paradise-Connect-1.0/docs/site-plan-data-contract.md)
(bentuk data dari SISI backend). Riwayat lengkap kenapa arsitekturnya begini (bug/perbaikan per
sesi) ada di `docs/site-plan-mobile-pwa.md` **repo backend** (bukan di repo Flutter ini).

## 1. Ringkasan Alur (dari sudut pandang Flutter)

```
SiteplanBloc.add(LoadSiteplanEvent)
  → SitePlanRepository.getAvailableSites()
      → SiteplanRemoteDataSource.getSiteplanSettings()   [GET /property/siteplan-settings]
      → susun List<ProjectSite> (url proxy DIBANGUN DI SINI, bukan dari backend)
  → SitePlanPage (index_web.dart / index_mobile.dart, split platform)
      → load ProjectSite.url ke <iframe> (web) / WebViewController (mobile)
      → user tap pin, klik "Lihat Selengkapnya" (DI DALAM konten webview, bukan widget Flutter)
      → backend cegat redirect, relay balik lewat:
          - postMessage (web)      → index_web.dart::_listenSiteplanBridge()
          - onNavigationRequest (mobile) → index_mobile.dart, intersep LANGSUNG (bukan lewat channel)
      → UnitDetail.decryptPayload(...) — DECRYPT TERJADI DI SINI, key AES di proxy_cipher.dart
      → context.pushNamed('site_plan_blank', extra: <Map hasil decrypt>)
  → SitePlanBlank(data: ...) — render halaman detail unit
```

## 2. Tahap 1 — Daftar Site Plan

**Sumber**: `GET /property/siteplan-settings` (lihat dokumen backend §2 untuk bentuk JSON
lengkap dari server).

**File**: [`siteplan_remote_datasource.dart`](../lib/features/site-plan/data/datasources/siteplan_remote_datasource.dart) —
`getSiteplanSettings()` cuma unwrap `{status, message, data}`, balikin `data` mentah
(`Map<String, dynamic>`) ke repository.

**File**: [`site_plan_repository_impl.dart`](../lib/features/site-plan/domain/repositories/site_plan_repository_impl.dart) —
`getAvailableSites()` iterasi `data['townships'][].clusters[]`, filter `show_on_mobile == 1`,
lalu **SUSUN SENDIRI URL proxy-nya**:
```dart
final url = '$backendBase/property/siteplan-proxy?company_id=$companyId&siteplan_id=$siteplanId';
```
(`backendBase` dari [`ApiConstants.baseUrl`](../lib/core/network/api_constants.dart) — Flutter
TIDAK PERNAH tahu/kirim token/pdkey vendor, itu disisipkan backend, lihat dokumen backend §3).

**Entity hasil**: [`ProjectSite`](../lib/features/site-plan/domain/entities/project_site.dart)
— cuma 3 field: `groupName` (nama township), `unitName` (nama siteplan/cluster), `url` (proxy
URL di atas). SEMUA field lain dari response backend (`image_name`, `cluster_id`, dst) **DIBUANG**
di titik ini, tidak ikut ke widget.

**State**: [`siteplan_bloc.dart`](../lib/features/site-plan/presentation/state/siteplan_bloc.dart) —
`LoadSiteplanEvent` → `SiteplanLoading` → `SiteplanLoaded(List<ProjectSite>)` /
`SiteplanError(String)`.

## 3. Tahap 2 — Peta Site Plan (WebView/iframe)

Flutter **TIDAK parsing** apa pun di tahap ini — `ProjectSite.url` langsung dipasang sebagai
`src` iframe (web) / target `loadRequest()` WebView (mobile). Isinya HTML dari backend (proxy
ke vendor, lihat dokumen backend §3) — dianggap konten OPAQUE oleh Flutter.

**File platform-split** (`index.dart` cuma conditional export):
- [`index_web.dart`](../lib/features/site-plan/presentation/site-plan-page/index_web.dart) —
  `html.IFrameElement`, `_listenSiteplanBridge()` (listener `postMessage`, dipakai Tahap 4 juga).
- [`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart) —
  `WebViewController`, `addJavaScriptChannel('SiteplanBridge', ...)` + `onNavigationRequest`
  (dipakai Tahap 4).

## 4. Tahap 4 — Detail Unit ("Lihat Selengkapnya")

Ini bagian yang PALING BEDA antara web & mobile, karena keterbatasan platform (iframe web tidak
bisa dicegat navigasinya dari luar; WebView native bisa) — TAPI hasil akhirnya (data yang sampai
ke `SitePlanBlank`) SAMA PERSIS bentuknya.

### Web (`index_web.dart`)
`_listenSiteplanBridge()` dengar `window.onMessage`, filter `data['source'] == 'paradiseSiteplan'`:
- `type == 'unitDetailRedirect'` → `payload.query` (String, MASIH terenkripsi, format
  `=<ivBase64>:<ciphertextBase64>`) → `UnitDetail.decryptPayload(query.substring(1))` →
  `context.pushNamed('site_plan_blank', extra: unitData)`.
- `type == 'unitDetailFromBlank'` → fallback jaga-jaga (kalau PWA sempat boot nested di iframe,
  jarang terjadi setelah fix backend) — `payload` String JSON (BUKAN Map JS langsung, alasan:
  hindari masalah tipe nested-map dari structured-clone `postMessage`), `jsonDecode()` dulu.

### Mobile (`index_mobile.dart`)
`onNavigationRequest` cek `Uri.parse(request.url).path == '/siteplan-key'` — kalau cocok:
`NavigationDecision.prevent` (navigasi WebView DIBATALKAN) →
`UnitDetail.decryptKeyUrlToJson(request.url)` (fungsi ini cari marker `?=` di URL, beda dari
`decryptPayload` yang butuh string SUDAH tanpa `?=`/`=` di depan) →
`context.pushNamed('site_plan_blank', extra: unitData)`.

### Entity hasil decrypt: [`UnitDetail`](../lib/features/site-plan/domain/entities/unit_detail.dart)
```dart
class UnitDetail {
  String? projectName;      // json['projects']
  String? clusterName;      // json['cluster']
  String? productName;      // json['product']
  String? blokUnit;         // json['blok_unit']
  String? status;           // json['status']
  bool isSold;              // json['is_sold']
  UnitSpec spec;             // json['spec'] → {luasTanah, luasBangunan, kelebihanTanah,
                             //                 jumlahLantai, kamarTidur, kamarMandi}
  List<PriceScheme> priceSchemes; // json['price_schemes'] — SELALU [] saat ini,
                                   // lihat dokumen backend §4 kenapa
}
```
2 titik masuk decrypt yang PENTING dibedakan (jangan tertukar):
- `UnitDetail.decryptPayload(rawIvCiphertext)` — input SUDAH bersih (`iv:ciphertext`, tanpa
  prefix apa pun). Dipakai: web bridge, DAN fallback query-string `/site-plan/blank` (§5).
- `UnitDetail.decryptKeyUrlToJson(url)` — input URL LENGKAP, fungsi ini cari `?=` sendiri lalu
  panggil `decryptPayload()` untuk sisanya. Dipakai: mobile `onNavigationRequest`, DAN tombol
  preview mata (👁) di `index_web.dart`/`index_mobile.dart` (`_openSitePlanBlank()`, pakai
  `sampleEncryptedSiteplanKeyUrl` — data contoh, BUKAN dari server, cuma buat testing UI).

**Key AES** ada di [`proxy_cipher.dart`](../lib/core/network/proxy_cipher.dart)
(`ProxyCipher._keyStr`, AES-256-CBC) — **HANYA ADA DI SINI**, backend Laravel TIDAK PERNAH punya
akses ke key ini (dikonfirmasi lewat riwayat perbaikan — semua desain proxy backend SENGAJA
menghindari perlu tahu isi data unit, cuma relay bytes terenkripsi apa adanya).

## 5. Halaman Tujuan: [`SitePlanBlank`](../lib/features/site-plan/presentation/blank/siteplan-blank.dart)

Route: `GoRoute(path: '/site-plan/blank', name: 'site_plan_blank')` di
[`router.dart`](../lib/app/router.dart) — **DI LUAR** `ShellRoute` (tanpa `MainLayout`/bottom-nav)
& dikecualikan dari gate login (`redirect()` top-level, cek `location.startsWith('/site-plan/blank')`)
— supaya link share ke orang yang belum login tetap bisa dibuka.

Builder-nya terima data dari **2 sumber berbeda** tergantung cara masuk:
```dart
final extra = state.extra as Map<String, dynamic>?;         // dari context.pushNamed(extra: ...)
final query = state.uri.query;                               // dari URL langsung (App Link/share)
final data = extra ?? (query.isEmpty ? null
    : UnitDetail.decryptPayload(query.startsWith('=') ? query.substring(1) : query));
return SitePlanBlank(data: data);
```
`data` (Map, HASIL DECRYPT, bukan mentah) → `UnitDetail.fromJson(data)` → dirender jadi UI
(judul+status, grid info, kartu skema harga/"Unit Sudah Terjual", spesifikasi).

`_appLinkPathRoutes` (`router.dart`) juga daftarkan `/siteplan-key` → `/site-plan/blank` (query
diteruskan apa adanya) — dipakai kalau redirect vendor SEMPAT lolos ke domain App Links tanpa
tercegat backend (kasus jarang setelah fix backend, jaga-jaga saja).

## 6. Bridge Helper (Web-only)

[`web_iframe_bridge.dart`](../lib/core/utils/web_iframe_bridge.dart) (+ `_stub.dart`/`_web.dart`,
pola conditional export sama seperti `web_debug_util.dart`) — `isInsideIframe` (deteksi
`window.parent != window`) & `postUnitDetailToParent(data)` (relay ke parent via `postMessage`,
`data` di-`jsonEncode()` dulu). Dipakai `SitePlanBlank.initState()` sebagai fallback §4
(`unitDetailFromBlank`) — di MOBILE, helper ini SELALU no-op (`isInsideIframe` konstan `false`
di variant stub).

## 7. File Terkait (Flutter)

| File | Peran |
|---|---|
| [`siteplan_remote_datasource.dart`](../lib/features/site-plan/data/datasources/siteplan_remote_datasource.dart) | Panggil `GET /property/siteplan-settings` |
| [`site_plan_repository.dart`](../lib/features/site-plan/domain/repositories/site_plan_repository.dart), [`site_plan_repository_impl.dart`](../lib/features/site-plan/domain/repositories/site_plan_repository_impl.dart) | Susun `List<ProjectSite>` + URL proxy |
| [`project_site.dart`](../lib/features/site-plan/domain/entities/project_site.dart) | Entity daftar site plan (Tahap 1) |
| [`unit_detail.dart`](../lib/features/site-plan/domain/entities/unit_detail.dart) | Entity detail unit + 2 fungsi decrypt (Tahap 4) |
| [`proxy_cipher.dart`](../lib/core/network/proxy_cipher.dart) | Key & implementasi AES-256-CBC |
| [`siteplan_bloc.dart`](../lib/features/site-plan/presentation/state/siteplan_bloc.dart), `siteplan_event.dart`, `siteplan_state.dart` | State management Tahap 1 |
| [`index.dart`](../lib/features/site-plan/presentation/site-plan-page/index.dart) (+ `index_web.dart`/`index_mobile.dart`) | Halaman utama Site Plan (Tahap 2-4) |
| [`project-list/index.dart`](../lib/features/site-plan/presentation/project-list/index.dart) | Pemilih township/cluster (dropdown) |
| [`siteplan-blank.dart`](../lib/features/site-plan/presentation/blank/siteplan-blank.dart) | Halaman detail unit (Tahap 5) |
| [`web_iframe_bridge.dart`](../lib/core/utils/web_iframe_bridge.dart) (+ `_stub.dart`/`_web.dart`) | Helper relay iframe→parent (web-only, Tahap 4 fallback) |
| [`router.dart`](../lib/app/router.dart) | Route `/site-plan`, `/site-plan/blank`, mapping `_appLinkPathRoutes['/siteplan-key']` |
| [`api_constants.dart`](../lib/core/network/api_constants.dart) | `ApiConstants.baseUrl` (dasar susun URL proxy) |
| [`docs/site-plan-blank.md`](site-plan-blank.md) | Dokumen lama khusus halaman `SitePlanBlank` (lebih detail UI-nya) |
