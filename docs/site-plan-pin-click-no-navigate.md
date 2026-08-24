# Site Plan: Klik Pin Tidak Boleh Navigasi (PDWeb)

**Tanggal:** 2026-08-24
**Lokasi fix:** BUKAN di repo ini — ada di server vendor PDWeb (Paradise Dynamics Web2):

```
\\192.168.8.21\d$\xampp\htdocs\PD2\apps\views\apps\siteplan_mobile.php
```

## Masalah

Dulu alurnya: klik pin → popup mini muncul → klik tombol "Lihat Selengkapnya" → itu yang
navigasi. Sekarang tombolnya sudah dihapus dari `siteplan_mobile.php` (lihat komentar baris
236-253 di file itu: *"Tidak ada popup lagi di tengah - tap pin langsung generate link +
navigasi"*) — klik pin LANGSUNG navigasi pakai `window.location.href`. Di PWA (web), ini bikin
`<iframe>` peta beneran pindah halaman (blank/reload), karena browser tidak punya cara mencegah
navigasi iframe dari luar (beda dari WebView native mobile yang bisa dicegat via
`onNavigationRequest`, lihat [index_mobile.dart](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart)).

## Kode Sebelum (baris ±255-277 `siteplan_mobile.php`)

```js
$("#mapplic").on("click touchend", ".mapplic-pin", function(e) {
    e.preventDefault();
    e.stopPropagation();
    var locId = $(this).attr("data-location");
    var loc = findLocationById(locId);
    if (!loc) return;

    $(".mapplic-pin").removeClass("ud-pin-active");
    $(this).addClass("ud-pin-active");
    $(this).appendTo($(this).parent());

    var url = devconnectAppUrl
        + "?siteplan_id=" + encodeURIComponent(siteplanId)
        + "&company_id=" + encodeURIComponent(companyId)
        + "&product_id=" + encodeURIComponent(loc.product_id)
        + "&property_id=" + encodeURIComponent(loc.property_id);

    window.location.href = url;   // <-- BIKIN NAVIGASI, INI SUMBER MASALAHNYA
});
```

## Fix: `fetch(url)`, bukan `window.location.href = url`

```js
    fetch(url);
```

Ganti SATU baris itu saja (`window.location.href = url;` → `fetch(url);`), sisanya persis sama.

## Kenapa `fetch(url)` Cukup (Tidak Perlu `postMessage` Manual)

Halaman `siteplan_mobile.php` ini TIDAK PERNAH diakses langsung oleh Flutter — selalu lewat
proxy Laravel `GET /property/siteplan-proxy` (`PropertyController::forwardToSiteplan()` →
`patchContent()`). `patchContent()` menyisipkan `siteplanBridgeScript()` sebelum `</body>` —
script itu **override `window.fetch` GLOBAL** di halaman ini, jadi setiap kode di
`siteplan_mobile.php` yang manggil `fetch(...)` sebenarnya manggil versi yang sudah "dibajak"
bridge tersebut, bukan `fetch` asli browser.

Isi hook-nya (ringkas, lihat `siteplanBridgeScript()` di branch `siteplan`,
`PropertyController.php`):

```js
function tryRelayPlainUnitParams(url) {
    var params = new URLSearchParams(url.split('?')[1] || '');
    if (params.has('siteplan_id') && params.has('company_id')
        && params.has('product_id') && params.has('property_id')) {
        relayToFlutter('unitDetailPlainParams', { ...4 param di atas... });
        return true;
    }
    return false;
}

window.fetch = function (input, init) {
    var url = typeof input === 'string' ? input : (input && input.url);
    var p = _fetch.apply(this, arguments);
    tryRelayPlainUnitParams(url);   // <-- cek query string, relay KALAU cocok
    return p;
};
```

Jadi begitu `fetch(url)` dipanggil dengan `url` yang sudah bawa ke-4 param
(`siteplan_id`/`company_id`/`product_id`/`property_id`) — persis bentuk `url` yang dulu dipakai
`window.location.href` — `tryRelayPlainUnitParams()` otomatis mengenali & memanggil
`relayToFlutter('unitDetailPlainParams', payload)`, yang kirim ke:
- `window.parent.postMessage(...)` → ditangkap Flutter web di
  [`index_web.dart::_listenSiteplanBridge()`](../lib/features/site-plan/presentation/site-plan-page/index_web.dart#L69-L146),
  type `unitDetailPlainParams`.
- `window.SiteplanBridge.postMessage(...)` → ditangkap Flutter mobile di
  [`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart#L217-L256)
  (JS channel `SiteplanBridge`), type sama.

Response `fetch(url)`-nya sendiri (isi `index.html` app Flutter, karena `devconnectAppUrl`
adalah domain app kita) **tidak dipakai** — cukup dibuang. Yang penting cuma efek samping hook
di atas, yang sudah kejadian SEBELUM response-nya kembali (`tryRelayPlainUnitParams` dipanggil
sinkron, bukan di dalam `.then()`).

Karena hook ini ada di script yang SAMA yang dimuat kedua platform (proxy Laravel inject sekali,
dipakai baik `<iframe>` web maupun `WebViewController` mobile), `fetch(url)` otomatis benar untuk
KEDUA platform — tidak perlu percabangan `window.parent`/`window.SiteplanBridge` manual di
`siteplan_mobile.php`.

## Prasyarat

Bridge script (`siteplanBridgeScript()` + `tryRelayPlainUnitParams()` + `allow_redirects: false`
di `forwardToSiteplan()`) ada di branch **`siteplan`** repo backend
(`E:\WorkProject\php\Paradise-Connect-1.0`), BUKAN di `module-reserve-order`/`main`. Fix
`fetch(url)` ini HANYA berlaku kalau server yang mem-proxy siteplan sedang jalan di branch yang
punya bridge script tsb (dicek `git branch --show-current` di repo backend). Migrasi DB
tambahan branch `siteplan` (`m_bank`, `m_bank_promo`, `m_price_scheme`, `m_status_property_lot`,
`h_bank_promo`) sudah "Ran" di DB dev per 2026-08-24 — lihat `php artisan migrate:status`.

## File Terkait

| File | Peran |
|---|---|
| `\\192.168.8.21\d$\xampp\htdocs\PD2\apps\views\apps\siteplan_mobile.php` | Handler klik pin (vendor PDWeb) — **fix ada di sini** |
| `Paradise-Connect-1.0/app/Http/Controllers/Api/PropertyController.php` (branch `siteplan`) | `forwardToSiteplan()`, `patchContent()`, `siteplanBridgeScript()` |
| [`index_web.dart`](../lib/features/site-plan/presentation/site-plan-page/index_web.dart) | Listener `postMessage` (PWA) |
| [`index_mobile.dart`](../lib/features/site-plan/presentation/site-plan-page/index_mobile.dart) | Listener JS channel `SiteplanBridge` (mobile) |
| [`site-plan-data-contract.md`](site-plan-data-contract.md) | Kontrak data site plan → detail unit secara keseluruhan |
