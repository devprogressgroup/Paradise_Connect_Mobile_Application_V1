# Contact Filter Sheet — Redesign, Perf Fix, dan Pagination (2026-08-25)

## Ringkas
`ContactFilterSheet` ([contact_filter_sheet.dart](../lib/features/contact/presentation/widgets/contact_filter_sheet.dart))
dirombak visual, dibenerin beberapa bug data, dan sekarang grup filter yang datanya besar
(Sales Channel Detail, Owner/Executive/Supervisor/Manager/GM/Team) dedicated paginated
endpoint sendiri — bukan dimuat penuh di depan / diturunkan dari data profile.

## 1. Redesign tampilan
Accordion dikelompokkan jadi kartu per section (Data Kontak / Sales / Tanggal) dengan
ikon kategori, chip pilihan custom (bukan `ChoiceChip` default Material), dan search field
filled-style — lihat `_sectionCard`, `_accordionTitle`, `_pillChip` di
[contact_filter_sheet.dart](../lib/features/contact/presentation/widgets/contact_filter_sheet.dart).
Tidak ada lagi teks hasil pilihan atau badge angka di sebelah label accordion (collapsed
state) — cuma nama filternya, karena bisa kepanjangan kalau pilihannya banyak.

## 2. Bug fix: filter Project cuma bisa pilih satu
`_stagedProject` awalnya `String?` (single-select) padahal opsinya (`kContactProjectOptions`)
harusnya bisa dipilih lebih dari satu (mis. "Paradise Serpong City" + "Paradise Serpong City
2" sekaligus). Diganti jadi `Set<String> _stagedProjects`, digabung koma saat dikirim ke
`ContactFilterResult.project` (parameter `last_project` di backend tetap `String?` tunggal —
lihat [contact_filter_result.dart](../lib/features/contact/data/models/dropdown/contact_filter_result.dart)).
**Catatan:** backend `last_project` belum dikonfirmasi mendukung multi-value dipisah koma —
perlu dites langsung, sama seperti filter `user_id`/`type` lain yang sudah pakai pola ini.

## 3. Bug fix: Sales Channel Detail kadang kosong
Root cause: `InfoSourceBloc` pakai SATU field `status` dipakai bareng dua fetch berbeda
(`FetchInfoSourcesEvent(type:1)` dan fetch sales-channel-detail), plus hasil sales-channel-
detail sempat ditulis ke `sourcesMap[2]` — key yang SAMA dipakai `contact-form` untuk
`FetchInfoSourcesEvent(type:2, salesChannel:...)` (subset ter-filter per channel). Race
condition + key collision bikin filter sheet kadang kebuka dengan data kosong/salah.
**Fix final** (setelah pagination masuk): Sales Channel Detail dilepas total dari
`InfoSourceBloc` — sekarang lewat `SalesHierarchyService.channelDetail()` langsung, di-fetch
lazy oleh accordion-nya sendiri saat dibuka (lihat §5), jadi race condition ini otomatis
hilang (tidak ada lagi prefetch-dan-tunggu di `initState`).

## 4. Perf fix: expand accordion nge-lag
Dua penyebab:
- **Render 600+ `CheckboxListTile` sekaligus** saat accordion expand (non-lazy). Fix: item
  list dibatasi tinggi (`SizedBox` max 320px) + `ListView.builder` (lazy).
- **Blurred `BoxShadow`** di kartu section + tidak ada `RepaintBoundary` — tiap frame animasi
  expand/collapse, SEMUA kartu (termasuk yang tidak berubah, cuma ikut geser posisi) ikut
  di-rasterisasi ulang; shadow blur terutama berat di Flutter Web (CanvasKit). Fix: shadow
  diganti border tipis, `RepaintBoundary` ditambah per kartu section dan per accordion
  (`_sectionCard`, `_accordion` di [contact_filter_sheet.dart](../lib/features/contact/presentation/widgets/contact_filter_sheet.dart)).

## 5. Pagination + dedicated endpoint (perubahan utama)
Sebelumnya Owner/Sales Executive/Supervisor/Manager/GM/Team diturunkan dari
`ProfileBloc.state.profile` (jalan-jalan hierarki `subordinates`/`salesTeamHierarchy` di
client) — bukan API filter sendiri, dan otomatis ke-scope ke downline user karena datanya
memang dari situ. Sekarang:

- **Backend**: endpoint dedicated sudah ada sebagian (`sales/owners`, `/executives`,
  `/supervisors`, `/managers` — sudah paginated+search dari awal), ditambah
  `sales/general-managers` (baru) dan pagination+search di `sales/teams` +
  `master-data/sales-channel-detail`. Detail lengkap di sisi backend:
  `docs/api/sales/sales-dropdown-endpoints-pagination.md` (repo Paradise-Connect-1.0).
- **Flutter data layer** (baru):
  - [`DropdownOption`](../lib/features/contact/domain/entities/dropdown_option.dart) — entity
    kecil `{id, name, subtitle}`, dipakai generik buat semua dropdown paginated ini (bukan
    `InfoSource`, yang semantiknya beda).
  - `ContactRemoteDataSource` — 6 method baru (`getSalesOwners`, `getSalesExecutives`, dst,
    `getSalesTeamsPaginated`) + `getSalesChannelDetails` diubah jadi paginated (return raw
    map, bukan `List<InfoSourceModel>` lagi).
  - `ContactRepository`/`Impl` — method sepadan, semua return
    `Either<String, ({List<DropdownOption> data, int lastPage, int total})>`.
  - Usecase per endpoint di `lib/features/contact/domain/usecases/sales_hierarchy/`.
  - [`SalesHierarchyService`](../lib/features/contact/presentation/state/sales_hierarchy/sales_hierarchy_service.dart) —
    facade cubit (tidak pernah emit state) yang menyatukan usecase-usecase itu, di-provide di
    `main.dart`. Ini yang dipanggil dari `contact-page/index.dart` saat menyusun
    `paginatedGroups` untuk `ContactFilterSheet` — **terpisah dari `ProfileBloc`/endpoint
    profile**, sesuai concern awal supaya filter tidak "dicampur" dengan data profile.
- **`InfoSourceBloc`**: disederhanakan balik ke bentuk semula (cuma `FetchInfoSourcesEvent` +
  `ResetInfoSourcesEvent`) — semua state/handler `salesChannelDetails*` yang sempat
  ditambahkan buat fix di §3 dilepas lagi karena sudah tidak dipakai (channel detail pindah
  ke `SalesHierarchyService`).
- **UI**: `ContactFilterSheet` dapat parameter baru `paginatedGroups:
  List<PaginatedCheckGroup>` ([contact_filter_result.dart](../lib/features/contact/data/models/dropdown/contact_filter_result.dart)).
  Widget baru `_PaginatedGroupBody` (di `contact_filter_sheet.dart`) urus scroll-to-load-more,
  search dengan debounce 400ms yang men-trigger fetch baru ke server (bukan filter list
  lokal), dan state loading/error/empty sendiri. Accordion Owner/dst tidak lagi punya tombol
  "Pilih Semua" (tidak semua data ke-load ke client), tapi "Hapus" tetap ada.
  Data di-fetch lazy: `_PaginatedGroupBody.initState()` baru manggil halaman 1 saat
  accordion-nya benar-benar dibuka (`ExpansionTile` melepas `children` saat collapsed, jadi
  state otomatis reset kalau ditutup-buka lagi).

## Yang SENGAJA tidak ikut dipaginate
- **Status Prospek**, **Sales Channel** (level 1, dari `/sumber-informasi?type=1`) — tetap
  dimuat penuh di depan seperti semula. Dataset-nya kecil (puluhan item), tidak ada laporan
  lag, dan Sales Channel dipakai bareng `contact-form` (mengubahnya berisiko mempengaruhi
  flow lain yang tidak diminta untuk disentuh).
