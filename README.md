# progress_group

A new Flutter project.



#Tujuan utama:
** menutup celah keamanan di aplikasi mobile, di mana user non-sales (role "User") saat ini bisa melihat SEMUA Inbox WhatsApp & SEMUA Contact se-perusahaan, dengan menyelaraskan (menyamakan) cara mobile membatasi data dengan web — supaya non-sales hanya melihat data departemennya (Telesales lihat Telesales, dst.), sementara Sales tetap sama (hirarki jabatan).**




---


## 1. Masalah (kenapa harus diubah)


Mobile melayani **bukan hanya Sales** — departemen non-sales (Telesales, Customer Service, Finance Executive) juga login & pakai Inbox WhatsApp.


**Kondisi sekarang (BUG/over-privilege di mobile):**
- Scoping API mobile memakai `HierarchyService::getAllowedOwnerIds()`.
- Method itu mengembalikan `null` (= **FULL/lihat semua**) untuk **role 1 (Superadmin) DAN role 2 ("User")**.
- Semua user non-sales = **role 2 "User"**. Akibatnya **non-sales di mobile saat ini melihat SEMUA Inbox & SEMUA Contact se-perusahaan** — tidak ter-scope.
- Web sudah diperbaiki (non-sales ter-scope per departemen). **Mobile belum** → tidak konsisten & bocor.


**Target (samakan dengan web):**
| Viewer | Boleh lihat |
|---|---|
| Superadmin (role 1) / `permission_scope='everything'` | semua |
| Sales (punya `sales_person_id`) | subtree hirarki jabatan (SUDAH benar di mobile) |
| Non-sales + `permission_scope='team_only'` | departemen + sub-departemen (`app_m_group`) |
| Non-sales + `owned_only`/null | dirinya sendiri |


---


## 2. Pembagian kerja


| Bagian | Pemilik | Status |
|---|---|---|
| **A. Backend API (Laravel)** — ganti resolver scope | Tim backend/web | perlu dikerjakan |
| **B. Mobile client (Flutter)** — sumber daftar owner filter | Programmer mobile | perlu dikerjakan |
| **C. Test bersama** | Keduanya | — |


> Scoping data terjadi di **server (Laravel)**, jadi keamanan otomatis beres begitu Bagian A selesai (tanpa perlu rilis mobile). Bagian B hanya soal **UX filter** (agar dropdown "Owner" menampilkan rekan sedepartemen, bukan kosong).


---


## 3. Bagian A — Perubahan Backend API (kontrak baru)


Ganti scoping owner dari `HierarchyService::getAllowedOwnerIds()` → engine bersama **`HasRoleScope::getScopedUserIds()`** (sudah ada & teruji di web). Lokasi:
- `app/Http/Controllers/Api/WhatsappInboxApiController.php` (≈ baris 249, 346, 485)
- `app/Http/Controllers/Api/ContactController.php` (filter `owner_id`)


Pola tetap sama (`null` = tanpa filter):
```php
$allowedOwnerIds = $this->getScopedUserIds(); // ganti dari getAllowedOwnerIds()
if ($allowedOwnerIds !== null) {
    $query->whereIn('...owner_id / user_id', $allowedOwnerIds);
}
```
**Tidak ada perubahan parameter request.** Hasil: non-sales otomatis ter-scope; Sales tidak berubah (engine memakai hirarki yang sama untuk yang punya `sales_person_id`).


**Tambahan untuk filter di mobile — endpoint `/me`:**
Saat ini `/me` mengirim `subordinates` (pohon hirarki **sales**). Untuk non-sales pohon ini kosong → dropdown filter Owner di mobile akan kosong. Usulan kontrak:
- Tambah field **`accessible_owners`** di `/me` = hasil `getScopedUserIds()` yang sudah di-resolve jadi detail:
  ```json
  "accessible_owners": [
    { "user_id": 12, "full_name": "Budi", "subtitle": "Telesales" },
    { "user_id": 13, "full_name": "Siti", "subtitle": "Telesales" }
  ]
  ```
  - Untuk Sales = hirarki yang ter-flatten (boleh tetap kirim `subordinates` juga).
  - Untuk non-sales = anggota departemennya (dari `app_m_group`).
  - Untuk full-access (Superadmin/everything) = `null` atau daftar semua (sepakati).


---


## 4. Bagian B — Perubahan Mobile Client (Flutter)


1. **Dropdown filter "Owner" di Inbox** (dan Contact, jika ada) ambil dari **`accessible_owners`** (`/me`), BUKAN lagi semata dari `subordinates` (yang sales-only).
   - File terkait (referensi): `lib/features/inbox/presentation/pages/inbox-page/index.dart` (bagian build owner dropdown dari `user.subordinates`).
2. **Jangan berasumsi setiap user punya hirarki sales.** Untuk non-sales `subordinates` kosong — jangan crash / jangan tampil kosong; pakai `accessible_owners`.
3. **Handle self-only**: kalau `accessible_owners` hanya berisi dirinya, dropdown cukup tampil dirinya (atau sembunyikan filter).
4. **Param yang dikirim tetap** `sales_executive_id` (berisi `user_id` terpilih) — backend sudah meng-intersect dengan scope, jadi aman walau salah kirim.
5. Tidak perlu ubah menu/permission (lapis menu via `/permissions/me` tidak berubah).


---


## 5. Bagian C — Test bersama (skenario)


| Login sebagai | Harapan Inbox/Contact | Dropdown Owner |
|---|---|---|
| Superadmin | semua | semua / kosongkan (full) |
| Sales SM (punya bawahan) | tim-nya | dirinya + bawahan (seperti sekarang) |
| Sales SE (leaf) | dirinya | dirinya |
| **Telesales `team_only`** | **percakapan/kontak departemen Telesales** | **anggota Telesales** |
| **Telesales `owned_only`** | **hanya miliknya** | **dirinya** |
| User non-sales tanpa group | hanya miliknya | dirinya |


Fokus regресi: **sebelum** fix, login Telesales = lihat semua; **sesudah** fix = hanya departemen/diri. Sales harus tetap sama persis seperti sebelumnya.


---


## 6. Catatan teknis
- `permission_scope` (kolom `app_m_user`) jadi penentu untuk non-sales: `everything` / `team_only` / `owned_only`. Nilai diatur di menu **Group User** (web).
- Engine `getScopedUserIds()` memakai `auth()->user()` — sama seperti `getAllowedOwnerIds()` yang sudah jalan di API mobile, jadi kompatibel dengan guard JWT.
- Hasil di-cache 10 menit/user (`scoped_user_ids_{id}`). Perubahan assignment group/team berlaku ≤10 menit.


