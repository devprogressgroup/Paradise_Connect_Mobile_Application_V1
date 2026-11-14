UPDATE MARKETING FEEDNYA TAPI UNTUK PENYIMPANAN MEDIA MASIH PAKAI MINIO AISTOR RAPTOR
# Prompt Implementasi: Marketing Feed (Admin Web + API + Mobile)

> Dokumen ini adalah instruksi lengkap untuk membangun backend (API), Admin Web, dan integrasi Mobile untuk Marketing Feed.
> Sumber kebenaran perilaku: `Marketing Feed Prototype.html` (tab Aplikasi HP, Panel Admin, Database) dan `docs/marketing-feed-erd.md`.
> Jika ada pertentangan antara dokumen ini dan prototype, ikuti dokumen ini dan catat perbedaannya.

---

## 1. Tujuan

Membangun feed konten untuk sales di Home aplikasi, dengan fitur:

1. Moderator membuat post (post, poll, link) dari Admin Web, lalu menayangkan, menjadwalkan, atau menyimpan draft.
2. Sales mengajukan momen dari mobile. Momen masuk antrean review dan tidak langsung tayang.
3. Moderator menyetujui atau menolak momen. Penolakan wajib menyertakan alasan.
4. Sales melihat feed, memberi reaksi dan komentar, serta menyematkan kirimannya di profil.
5. Wall of Fame: juara per program dan kategori, diisi manual oleh user yang punya izin.
6. Algoritma: urutan kiriman di Home per global atau per sales, dengan mode Pintar, Terbaru dulu, Acak, dan Custom, serta pin kiriman dan Wall of Fame.

---

## 2. Aktor dan izin

| Aktor | Cara masuk | Izin | Bisa apa |
|---|---|---|---|
| **Sales** | Mobile | login biasa | Lihat feed, reaksi, komentar, vote poll, ajukan momen (review), simpan draft pribadi, kelola Kiriman Saya, sematkan profil (maks. 3) |
| **Moderator** | Mobile (tombol +) dan Admin Web | `marketing-feed.moderate` | Buat post, poll, link. Tayang, jadwalkan, draft, sematkan feed, setujui atau tolak momen |
| **Pengelola Wall of Fame** | Admin Web | `marketing-feed.fame.edit`, cakupan opsional (`all`, `program`, `tim`) | Buat program dan juara, unggah media, tayang, jadwalkan, hapus |
| **Pengelola Algoritma** | Admin Web | `marketing-feed.algorithm.edit` (usulan, lihat bagian 14) | Atur global dan per sales: mode, bobot custom, pin |
| **Scheduler** | Internal, tiap menit | - | Ubah `scheduled` ke `published` saat waktunya tiba, lepas sematan yang sudah lewat |

Aturan izin:
- Setiap endpoint admin memeriksa izin di server, bukan hanya di UI.
- Permission tidak boleh diberikan dari sisi klien. Pemberian izin hanya lewat `t_feed_fame_perm` (untuk Wall of Fame) dan sistem izin yang sudah ada untuk moderator.
- Tidak ada tahap persetujuan kedua untuk Wall of Fame. Pengelola yang punya izin bisa menyimpan draft, menjadwalkan, atau menayangkan langsung.

---

## 3. Alur data (end to end)

```
Mobile (sales/moderator)          Admin Web (moderator)           Scheduler (tiap menit)
        │                                  │                               │
        ▼                                  ▼                               ▼
   ┌──────────────────────────────────────────────────────────────────────────┐
   │                         API (REST, JSON, auth token)                       │
   │  /marketing-feed/...   /admin/marketing-feed/...   /admin/wall-of-fame/... │
   └──────────────────────────────────────────────────────────────────────────┘
        │                                  │                               │
        ▼                                  ▼                               ▼
   Service layer: validasi, izin, transaksi, pencatatan perubahan status
        │
        ▼
   Database: t_feed_post, d_feed_post_media, d_feed_poll*, d_feed_link,
             t_feed_reaction, t_feed_comment*, t_feed_fame_*, t_feed_setting,
             t_global_notifications, app_m_user, m_project
        │
        ▼
   Notifikasi (push + t_global_notifications) dan storage media (menyusul)
```

Prinsip:
- Semua tulisan yang mengubah status berjalan dalam satu transaksi, termasuk notifikasi.
- Counter (`like_count`, `dislike_count`, `comment_count`, `vote_count`, `total_voters`) diupdate dalam transaksi yang sama dengan insert atau delete interaksinya.
- Setiap respons error memakai format yang sama (lihat bagian 12).
- Media disimpan di storage yang belum ditentukan. Database hanya menyimpan `file_path` (path atau key). Bagian ini menyusul dan jangan diasumsikan Google Drive.

---

## 4. Model data

### 4.1 Status post (`t_feed_post.status`)

`draft`, `review`, `rejected`, `scheduled`, `published`. Soft delete lewat `deleted_at`.

| Dari | Aksi | Ke | Oleh |
|---|---|---|---|
| (baru) | Simpan draft, autosave editor | `draft` | Moderator |
| (baru) | Publikasikan | `published` | Moderator |
| (baru) | Jadwalkan | `scheduled` | Moderator |
| (baru) | Bagikan Momen | `review` | Sales |
| (baru) | Simpan draft pribadi (Momen) | `draft` | Sales |
| `draft` | Tayangkan | `published` | Moderator |
| `draft` | Jadwalkan | `scheduled` | Moderator |
| `scheduled` | Waktu tayang tiba | `published` | Scheduler |
| `scheduled` | Tayangkan sekarang | `published` | Moderator |
| `scheduled` | Batalkan jadwal | `draft` | Moderator |
| `published` | Tarik ke draft | `draft` | Moderator (juga lepas sematan) |
| `review` | Setujui dan tayangkan | `published` | Moderator |
| `review` | Setujui dan jadwalkan | `scheduled` | Moderator |
| `review` | Tolak (alasan wajib) | `rejected` | Moderator |
| `rejected` | Kirim ulang | `review` | Sales (pemilik) |
| `rejected` | Pindah ke draft | `draft` | Sales (pemilik) |
| `draft`, `rejected` | Hapus | soft delete | Pemilik atau Moderator |

Aturan umum:
- Setiap perubahan ke `published` mengisi `published_at` (dan `publish_at` jika kosong). Untuk yang tayang dari jadwal, `publish_at` tetap waktu jadwalnya.
- Sematan (`pinned_at`, `pin_user_id`, `pin_until`) hanya berlaku saat `published`. Keluar dari `published` berarti sematan dilepas.
- Setiap transisi dicatat. Lihat bagian 11.

### 4.2 Kolom penting `t_feed_post`

`feed_post_id`, `post_type` (`post` | `poll` | `link`), `status`, `text`, `project_id` (NULL = semua project), `create_user_id` (penulis), `publish_at`, `published_at`, `review_user_id`, `review_date`, `reject_reason`, `pinned_at`, `pin_user_id`, `pin_until`, `profile_pin_at`, `allow_like`, `allow_dislike`, `allow_comment`, `allow_reply`, `allow_share`, `like_count`, `dislike_count`, `comment_count`, `source` (`mobile` | `admin`), `created_at`, `updated_at`, `deleted_at`.

### 4.3 Tabel lain

- `d_feed_post_media`: foto/video carousel (maks. 10 per post), gambar poll, thumbnail link. JPG/PNG/MP4, maks. 20 MB per file. Simpan `file_path`, `file_name`, `mime_type`, `size_bytes`, `sort_order`.
- `d_feed_poll`, `d_feed_poll_option`, `t_feed_poll_vote`: poll. Opsi minimal 2. Vote final. Pilihan tunggal: maks. 1 baris per (`feed_post_id`, `user_id`).
- `d_feed_link`: `url`, `platform` (diisi otomatis dari domain: youtube/youtu.be→youtube, instagram.com→instagram, tiktok.com→tiktok, facebook.com/fb.watch→facebook, linkedin.com→linkedin, x.com/twitter.com→x, lainnya→web), `title`, `description`. Backend menghitung ulang saat simpan.
- `t_feed_reaction`: 1 baris per user per post. Ganti like ke dislike = update. Batal = delete.
- `t_feed_comment`: `parent_comment_id` (NULL untuk komentar utama). Balasan maksimal 1 tingkat. `hidden` untuk moderasi.
- `t_feed_comment_like`: 1 baris per user per komentar.
- `t_feed_fame_program`, `t_feed_fame`, `d_feed_fame_media`, `t_feed_fame_perm`, `t_feed_fame_log`: Wall of Fame (lihat bagian 8).
- `t_feed_setting`: pengaturan algoritma (lihat bagian 9).
- `t_global_notifications`: riwayat notifikasi (`title`, `description`, `target_type` = `all` | `user`, `target_user_ids`, `link_url`).

---

## 5. API

Semua endpoint memakai token login. Format tanggal ISO 8601 dalam UTC, ditampilkan di klien sebagai waktu lokal.

### 5.1 Feed untuk mobile (sales dan moderator)

| Metode | Path | Fungsi | Catatan |
|---|---|---|---|
| GET | `/marketing-feed/home?cursor=` | Data Home: Wall of Fame, kiriman pin Global, kiriman sendiri yang `review`/`rejected`, sematan, dan feed | Urutan dijelaskan di bagian 7. Paginasi dengan cursor. |
| GET | `/marketing-feed/posts/{id}` | Detail satu post | Hanya `published` (kecuali pemilik dan moderator). |
| PUT | `/marketing-feed/posts/{id}/reaction` | Body `{value: "like" \| "dislike" \| "none"}` | Ganti dan batal. Counter ikut berubah. |
| POST | `/marketing-feed/posts/{id}/vote` | Body `{option_ids: []}` | Ditolak jika sudah vote (pilihan tunggal atau semua poll). |
| GET | `/marketing-feed/posts/{id}/comments` | Komentar dan balasan | Komentar `hidden` tidak tampil. |
| POST | `/marketing-feed/posts/{id}/comments` | Body `{text, parent_comment_id?}` | Balasan hanya untuk komentar utama. Butuh `allow_comment` (dan `allow_reply` untuk balasan). |
| PUT | `/marketing-feed/comments/{id}/like` | Suka atau batal | Idempoten. |
| POST | `/marketing-feed/momen` | Sales mengajukan momen. Body `{text, media_ids[], post_type, link?, poll?, submit: "review" \| "draft"}` | `review` masuk antrean moderator. `draft` hanya untuk pemilik. Lihat bagian 6. |
| POST | `/marketing-feed/media` | Unggah foto atau video | Mengembalikan `media_id` dan `file_path` sementara. Validasi jenis dan ukuran di server. |
| GET | `/marketing-feed/me/posts?status=draft,review,rejected,published` | Kiriman Saya | Hanya milik sendiri. Folder Draf dan Ditolak dipisah dari grid. |
| PUT | `/marketing-feed/me/posts/{id}` | Ubah draft atau kiriman ditolak | Status `review` tidak bisa diubah. |
| POST | `/marketing-feed/me/posts/{id}/resubmit` | Body `{to: "review" \| "draft"}` | Dari `rejected`. Lihat bagian 6.3. |
| DELETE | `/marketing-feed/me/posts/{id}` | Hapus draft atau kiriman ditolak | Soft delete. |
| PUT | `/marketing-feed/me/posts/{id}/profile-pin` | Sematkan di profil. Maks. 3 per sales, hanya status `published` | Lepas dengan `DELETE`. |
| GET | `/wall-of-fame` | Kartu Wall of Fame yang tayang | Hanya entri `published` dengan `publish_at <= now`. |

### 5.2 Moderasi dan admin (Admin Web)

| Metode | Path | Fungsi |
|---|---|---|
| GET | `/admin/marketing-feed/posts?status=&q=&project=` | Daftar konten dengan hitungan per status. Termasuk `review`. |
| POST | `/admin/marketing-feed/posts` | Buat post, poll, atau link. Body `{post_type, text, media_ids[], poll?, link?, project_id?, interaksi, action: "draft" \| "publish" \| "schedule", publish_at?}`. |
| PUT | `/admin/marketing-feed/posts/{id}` | Ubah isi. Post yang sudah tayang langsung berlaku di app. `post_type` tidak boleh diganti. |
| POST | `/admin/marketing-feed/posts/{id}/publish` | Tayangkan sekarang. Dari `draft` atau `scheduled`. |
| POST | `/admin/marketing-feed/posts/{id}/schedule` | Body `{publish_at}`. Dari `draft` atau `review` (lihat bagian 6.2). |
| POST | `/admin/marketing-feed/posts/{id}/unschedule` | `scheduled` ke `draft`. |
| POST | `/admin/marketing-feed/posts/{id}/unpublish` | `published` ke `draft`. Lepas sematan. |
| DELETE | `/admin/marketing-feed/posts/{id}` | Soft delete. |
| PUT | `/admin/marketing-feed/posts/{id}/pin` | Body `{until: null \| "1d" \| "3d" \| "7d"}`. Hanya `published`. Maks. 3 sekaligus. |
| DELETE | `/admin/marketing-feed/posts/{id}/pin` | Lepas sematan. |
| GET | `/admin/marketing-feed/reviews` | Antrean kiriman sales (`status = review`), urut terbaru. |
| POST | `/admin/marketing-feed/reviews/{id}/approve` | Body `{action: "publish" \| "schedule", publish_at?}`. Lihat bagian 6.2. |
| POST | `/admin/marketing-feed/reviews/{id}/reject` | Body `{reason}` wajib. Lihat bagian 6.2. |

### 5.3 Pengaturan algoritma

| Metode | Path | Fungsi |
|---|---|---|
| GET | `/admin/marketing-feed/settings/feed` | Daftar pengaturan global dan per sales yang punya baris. |
| GET | `/admin/marketing-feed/settings/feed/effective?user_id=` | Pengaturan yang berlaku untuk satu sales, hasil gabungan global dan user. |
| PUT | `/admin/marketing-feed/settings/feed/global` | Simpan global. Body `{mode, bobot?, pin_post?, pin_fame?}`. Upsert. |
| PUT | `/admin/marketing-feed/settings/feed/users/{user_id}` | Simpan per sales. Field yang tidak dikirim ikut global. |
| DELETE | `/admin/marketing-feed/settings/feed/users/{user_id}` | Hapus pengaturan sales. Sales kembali ikut global. |

### 5.4 Wall of Fame

| Metode | Path | Fungsi |
|---|---|---|
| GET | `/admin/wall-of-fame/programs` | Daftar program dan periodenya. |
| POST | `/admin/wall-of-fame/programs` | Buat program. Body `{nama_program, periode_label, periode_mulai?, periode_selesai?}`. |
| POST | `/admin/wall-of-fame/programs/{id}/entries` | Tambah juara. Body `{kategori, ranking, user_id, posisi_label?, caption, status, publish_at?}`. |
| PUT | `/admin/wall-of-fame/entries/{id}` | Ubah juara. |
| POST | `/admin/wall-of-fame/entries/{id}/status` | Body `{status: "draft" \| "scheduled" \| "published", publish_at?}`. |
| POST / DELETE | `/admin/wall-of-fame/entries/{id}/media` | Unggah atau hapus foto/video khusus (maks. 1 per entri). |
| DELETE | `/admin/wall-of-fame/entries/{id}` | Soft delete. Media ikut dihapus. |
| GET / POST / DELETE | `/admin/wall-of-fame/permissions` | Kelola `t_feed_fame_perm`. Hanya pemberi izin yang berhak. |

### 5.5 Respons error

```json
{ "error": { "code": "FEED_STATUS_CONFLICT", "message": "Kiriman sudah diproses moderator lain.", "field": null } }
```

Kode yang wajib ada:
- `FORBIDDEN`: tidak punya izin atau di luar cakupan.
- `NOT_FOUND`
- `VALIDATION_FAILED` (dengan `field`).
- `FEED_STATUS_CONFLICT`: status sudah berubah (misalnya dua moderator menyetujui bersamaan). Balas 409.
- `PIN_LIMIT_REACHED`: sudah 3 sematan.
- `MEDIA_TOO_LARGE`, `MEDIA_TYPE_NOT_ALLOWED`, `MEDIA_LIMIT_REACHED`.
- `REJECT_REASON_REQUIRED`.

---

## 6. Alur pengajuan dan persetujuan

### 6.1 Sales mengajukan momen dari mobile

1. Sales menekan tombol + lalu **Bagikan Momen**. Form berisi teks, foto atau video, dan opsional link.
2. Setiap foto atau video diunggah dulu lewat `POST /marketing-feed/media`. Server memeriksa jenis (JPG, PNG, MP4) dan ukuran (maks. 20 MB), serta jumlah (maks. 10 per post). Respons memberi `media_id`.
3. Sales memilih **Kirim untuk ditinjau** atau **Simpan draft**.
4. `POST /marketing-feed/momen` membuat post dengan `source = mobile`, `create_user_id = sales`, dan `project_id` sesuai proyek sales.
   - `submit = review`: `status = review`, `publish_at` kosong, dan tidak tampil di feed.
   - `submit = draft`: `status = draft`, hanya terlihat oleh pemilik di Kiriman Saya > Draf.
5. Notifikasi ke moderator: **satu notifikasi ringkas** dibuat saat momen masuk antrean review (jika kebijakan notifikasi mengizinkan). Belum ada notifikasi untuk draft.
6. Di Kiriman Saya, kiriman `review` ditandai **Menunggu persetujuan Tim Marketing**. Sales tidak bisa mengubahnya selama masih `review`.

Yang tidak boleh terjadi:
- Momen dari sales tidak pernah langsung `published`. Ini aturan keras, dicek di server.
- Sales tidak bisa melihat kiriman sales lain yang masih `review`.

### 6.2 Moderator menyetujui kiriman (approve)

Input: `POST /admin/marketing-feed/reviews/{id}/approve` dengan `action` dan opsional `publish_at`.

Langkah dalam satu transaksi:
1. Kunci baris post. Jika `status != review`, balas 409 `FEED_STATUS_CONFLICT`.
2. Jika `action = publish`:
   - `status = published`, `published_at = now`, `publish_at = now`.
3. Jika `action = schedule`:
   - `publish_at` wajib dan harus di masa depan. Jika tidak, balas 422.
   - `status = scheduled`.
4. Isi `review_user_id = moderator`, `review_date = now`. Kosongkan `reject_reason`.
5. Catat transisi di log (bagian 11).
6. Insert notifikasi `t_global_notifications` dengan `target_type = user` dan `target_user_ids = [sales]`. Judul: "Kirimanmu sudah tayang" (untuk publish) atau "Kirimanmu sudah dijadwalkan" (untuk schedule). `link_url` menunjuk post.
7. Jika `publish`, post langsung muncul di feed. Notifikasi ke semua sales hanya jika kebijakan konten mengizinkan (pertanyaan terbuka).

Hasil di Home:
- Kiriman muncul di feed sesuai aturan visibilitas (bagian 7) dan menjadi kiriman pengirim di Kiriman Saya > kiriman tayang.

### 6.3 Moderator menolak kiriman (reject)

Input: `POST /admin/marketing-feed/reviews/{id}/reject` dengan `reason`.

Langkah dalam satu transaksi:
1. Kunci baris. `status` harus `review`, jika tidak balas 409.
2. `reason` wajib dan tidak boleh kosong (`REJECT_REASON_REQUIRED`). Alasan cepat (misalnya "Foto kurang jelas") boleh dipakai sebagai isi.
3. `status = rejected`, `reject_reason = reason`, `review_user_id = moderator`, `review_date = now`.
4. Catat transisi di log.
5. Insert notifikasi ke pengirim dengan judul "Kirimanmu belum bisa tayang" dan isi berisi alasan. `link_url` menunjuk post.

Hasil di app:
- Kiriman tidak tampil di feed. Hanya pengirim yang melihatnya, di Kiriman Saya > Ditolak, bersama alasannya. Tanda merah menunjukkan perlu diperbaiki.
- Badge merah di ikon menu hanya untuk kiriman `rejected`. Kiriman `review` tidak memberi badge.

### 6.4 Pengirim memperbaiki dan mengirim ulang

1. Sales membuka kiriman di Ditolak dan menekan **Perbaiki & kirim ulang** atau **Pindah ke draft**.
2. `PUT /marketing-feed/me/posts/{id}` mengubah isi dan media. Media lama yang dihapus ikut dihapus dari storage.
3. `POST /marketing-feed/me/posts/{id}/resubmit` dengan `to = review`:
   - `status = review`. Kosongkan `reject_reason`, `review_user_id`, dan `review_date`.
   - Buat antrean baru dan notifikasi ringkas ke moderator.
4. `to = draft`: `status = draft`, sama seperti pindah ke draft pribadi.

Kiriman `rejected` tidak pernah langsung kembali ke feed tanpa persetujuan.

### 6.5 Pengajuan dari moderator di mobile

Moderator memakai tombol + dengan opsi **Post baru**, **Poll baru**, dan **Link**, dengan aksi Tayangkan, Jadwalkan, atau Simpan draft. Ini memakai endpoint `POST /admin/marketing-feed/posts` dengan `source = mobile` dan izin moderator. Tidak ada antrean review untuk moderator.

---

## 7. Feed Home: urutan dan visibilitas

### 7.1 Visibilitas

Post tampil di feed jika:
- `status = published`
- `deleted_at IS NULL`
- `project_id IS NULL` atau sama dengan project user

Di halaman 1, kiriman milik user sendiri yang berstatus `review` atau `rejected` ditampilkan paling atas.

### 7.2 Urutan Home

Urutan dihitung dengan urutan berikut:
1. Kiriman yang dipin Global, atau pin per sales jika terisi (maks. 3), sesuai urutan pin.
2. Kartu Wall of Fame. Juara yang dipin tampil dulu, lalu sisanya.
3. Kiriman sendiri `review` dan `rejected` (hanya pemilik).
4. Kiriman yang disematkan moderator (`pinned_at` dan `pin_until` belum lewat), terbaru disematkan dulu.
5. Feed biasa sesuai **mode** berikut.

### 7.3 Mode feed

Pengaturan efektif untuk sales = pengaturan user, dengan kunci kosong diisi dari global.

| Mode | Cara | Sinyal yang dibutuhkan |
|---|---|---|
| `otomatis` (Pintar) | Skor dengan bobot standar. Bobot tidak dibaca dari config. | Ya |
| `terbaru` | `published_at` terbaru di atas | Tidak |
| `acak` | Diacak dengan seed = `user_id` + tanggal hari ini, sehingga urutan tetap sepanjang hari | Tidak |
| `custom` | Skor dengan bobot dari `config.bobot`. Kunci kosong ikut global. | Ya |

Bobot standar: `rel` 3, `minat` 2, `engage` 2, `baru` 2, `proyek` 1. Skala setiap bobot 0 sampai 5, langkah 0,5.

Definisi sinyal, dihitung hanya dari data viewer:
- `rel` (hubungan dengan pembuat): +2 untuk setiap like dari viewer ke post pembuat, -1 untuk dislike, +3 untuk setiap komentar viewer di post pembuat. Dinormalisasi ke rentang -1 sampai 1 dengan batas 6.
- `minat` (topik): jumlah like viewer per `pillar` (topik), dibatasi 1 pada skala 5.
- `engage`: `log10(1 + likes + 2 * komentar) / 2`, dibatasi 1.
- `baru`: `exp(-hari / 3)`.
- `proyek`: 1 jika `project_id` sama dengan project viewer atau `project_id` kosong (semua project), selain itu 0.

Skor = jumlah bobot × sinyal. Urutan: skor tertinggi, lalu `published_at` terbaru.

Skor tidak disimpan. Hitung saat feed diambil, dan batasi jumlah kandidat (misalnya 200 post terbaru) agar query tetap ringan.

---

## 8. Wall of Fame

### 8.1 Aturan

- Program, kategori, dan peringkat diisi manual oleh pengelola yang punya izin. Tidak ada daftar kategori tetap dan tidak ada level tetap di kode.
- `kategori` teks bebas (misalnya "TOP SE"). Peringkat boleh seri, yaitu lebih dari satu baris dengan nilai `ranking` yang sama.
- Setiap juara adalah satu kartu per orang.
- Status: `draft` tidak tampil, `scheduled` menjadi `published` saat `publish_at` lewat (oleh scheduler), `published` tampil.
- Foto khusus: maks. 1 file per entri, JPG, PNG, atau MP4, maks. 20 MB. Jika tidak ada, kartu memakai foto profil `app_m_user.photo`, lalu inisial nama.
- Pin Wall of Fame: maks. 3, hanya entri yang `published`. Pin Global dan pin per sales ada di `t_feed_setting.config`.

### 8.2 Izin

- Izin `marketing-feed.fame.edit` diberikan lewat `t_feed_fame_perm`.
- `scope_type = all` berarti semua program. `program` atau `tim` membatasi cakupan.
- Pengelola bisa membuat, mengubah, menayangkan, dan menjadwalkan sesuai cakupannya.
- Setiap perubahan dicatat di `t_feed_fame_log`.

### 8.3 Yang tidak boleh terjadi

- Juara tidak boleh tayang berdasarkan perhitungan otomatis dari data SP. Penayangan hanya lewat tindakan pengelola.
- Entri yang dihapus tidak boleh tampil di Home, dan pin yang mengarah ke entri itu diabaikan.

---

## 9. Algoritma (pengaturan)

### 9.1 Data

`t_feed_setting` berisi satu baris per tingkat:
- `setting_key = feed`
- `scope_type = global` (`scope_value` kosong) atau `user` (`scope_value` = `user_id`)
- `config` JSON:

```json
{ "mode": "otomatis", "bobot": {"rel":3,"minat":2,"engage":2,"baru":2,"proyek":1}, "pin_post": [12], "pin_fame": [3] }
```

Aturan:
- Pengaturan user menimpa global per kunci. Kunci yang kosong ikut global.
- `bobot` hanya dipakai saat mode `custom`.
- `pin_post` maks. 3 dan hanya kiriman `published`. Kiriman yang kemudian ditarik ke draft dilepas dari pin.
- `pin_fame` maks. 3 dan hanya entri Wall of Fame `published`.

### 9.2 Alur simpan (Admin Web)

- Tombol **Simpan** melakukan upsert satu baris sesuai tingkat yang dibuka (Global atau sales yang dipilih). Perubahan belum berlaku sebelum disimpan.
- **Batal** membuang draf di layar.
- Tombol **Hapus** di tabel sales menghapus baris user (`DELETE`), sehingga sales kembali ikut global. Tombol ini meminta konfirmasi.
- Setelah simpan, `renderFeed` dan cache feed untuk tingkat yang terpengaruh harus dihapus. Gunakan versi pengaturan (`version`) agar klien tahu kapan harus membaca ulang.

### 9.3 Pratinjau

Admin Web menampilkan contoh 5 kiriman teratas untuk sales yang dipilih, memakai pengaturan draf (belum tersimpan). Riwayat interaksi hanya tersedia untuk akun yang sedang login, jadi pratinjau untuk sales lain hanya memakai sinyal non-personal dan harus diberi keterangan jelas di UI.

---

## 10. Scheduler (tiap menit)

Jalankan dalam satu transaksi per batch:
1. `UPDATE t_feed_post SET status='published', published_at=now WHERE status='scheduled' AND publish_at <= now()`. Untuk setiap baris, insert notifikasi ke pembuat ("Kirimanmu sudah tayang").
2. Lepas sematan yang sudah lewat: `pin_until <= now()` maka kosongkan `pinned_at`, `pin_user_id`, `pin_until`.
3. `UPDATE t_feed_fame SET status='published', published_at=now WHERE status='scheduled' AND publish_at <= now()`. Catat di `t_feed_fame_log`.
4. Hapus pin dari `t_feed_setting` yang menunjuk post atau entri yang sudah tidak `published`.

Scheduler harus idempoten: menjalankan dua kali tidak boleh menghasilkan dua notifikasi.

---

## 11. Pencatatan perubahan

- Setiap transisi status post dicatat: `post_id`, `from_status`, `to_status`, `action`, `user_id`, `reason` (jika ada), `created_at`. Tabel ini perlu dibuat (`t_feed_post_log`, usulan).
- Setiap perubahan Wall of Fame dicatat di `t_feed_fame_log`.
- Perubahan pengaturan algoritma dicatat dengan `update_user_id` dan `updated_at`. Riwayat lengkap bisa ditambahkan nanti.

---

## 12. Validasi (ringkasan)

| Aturan | Nilai |
|---|---|
| Media per post | maks. 10 |
| Jenis media | JPG, PNG, MP4 |
| Ukuran media | maks. 20 MB per file |
| Poll | minimal 2 opsi. Vote final |
| Link | platform dihitung ulang dari domain |
| Komentar | balasan maks. 1 tingkat |
| Pin Global dan per sales | maks. 3 |
| Sematan moderator | maks. 3 sekaligus |
| Sematan profil sales | maks. 3 per sales |
| Wall of Fame media | maks. 1 per entri |
| Penolakan | alasan wajib |
| Jadwal | `publish_at` harus di masa depan |

---

## 13. Kriteria penerimaan

Setiap skenario di bawah harus lolos uji otomatis.

1. **Momen dari mobile:** sales mengirim momen dengan submit `review`. Status `review`, tidak muncul di feed, muncul di antrean moderator.
2. **Momen tidak bisa langsung tayang:** request sales dengan `status: published` ditolak atau diabaikan di server.
3. **Approve publish:** moderator menyetujui. Status `published`, `review_user_id` terisi, notifikasi ke pengirim dibuat, post muncul di feed.
4. **Approve schedule:** dengan `publish_at` di masa depan, status `scheduled`. Di waktu yang ditentukan, scheduler menerbitkan dan membuat notifikasi.
5. **Approve dengan `publish_at` di masa lalu:** ditolak (422).
6. **Reject tanpa alasan:** ditolak (422 `REJECT_REASON_REQUIRED`).
7. **Reject:** status `rejected`, alasan tersimpan, notifikasi berisi alasan dibuat, post tidak muncul di feed, pengirim melihat di Ditolak.
8. **Kirim ulang:** dari `rejected` ke `review` mengosongkan `reject_reason`. Antrean moderator menerima kembali.
9. **Konflik:** dua moderator menyetujui bersamaan, hanya satu yang berhasil. Yang lain mendapat 409.
10. **Pin melebihi batas:** pin keempat ditolak dengan `PIN_LIMIT_REACHED`.
11. **Urutan Home:** pin Global tampil paling atas. Pin per sales menggantikan Global untuk sales itu saja.
12. **Mode terbaru:** urutan sama dengan `published_at` desc, tanpa sinyal.
13. **Mode acak:** urutan sama untuk satu user pada satu hari, dan berubah pada hari berikutnya.
14. **Mode custom:** bobot dari config dipakai. Untuk mode lain, bobot tidak mempengaruhi urutan.
15. **Hapus pengaturan sales:** sales kembali mengikuti global tanpa perlu restart klien.
16. **Wall of Fame draft:** tidak tampil. Setelah `scheduled` dan waktunya lewat, tampil.
17. **Wall of Fame izin:** pengelola dengan cakupan `program` tidak bisa mengubah program lain (403 `FORBIDDEN`).

---

## 14. Keputusan yang masih terbuka

1. Izin untuk mengubah algoritma: usulan `marketing-feed.algorithm.edit`, atau cukup `marketing-feed.moderate`.
2. Penyimpanan media (belum ditentukan). Database hanya menyimpan `file_path`. Jangan asumsikan Google Drive.
3. Apakah sematan dibatasi per project atau global.
4. Masa berlaku draft sales: disimpan sampai dihapus, atau dihapus otomatis setelah beberapa hari.
5. Apakah juara Wall of Fame yang tampil harus selalu sama dengan juara yang dibayar. Jika tidak, perlu kolom catatan selisih.
6. Kebijakan notifikasi: apakah moderator mendapat notifikasi per momen atau dikumpulkan.
7. Pengguna lain yang belum punya riwayat interaksi: sinyal personal untuk mereka bagaimana. Usulan: hanya sinyal non-personal.

---

## 15. Di luar cakupan (untuk tahap ini)

- Kalender publikasi dan tampilan analitik.
- Persetujuan berlapis (dua orang) untuk Wall of Fame.
- Pemindahan media ke storage final.
- Cache skor feed tingkat produksi. Dicatat sebagai pekerjaan lanjutan jika datanya sudah besar.

---

## 16. Hubungan dengan prototype

| Di prototype | Yang harus dibangun |
|---|---|
| Panel Admin > Konten (tab Terjadwal, Draf, Menunggu Review) | `GET /admin/marketing-feed/posts` dan `GET /admin/marketing-feed/reviews` |
| Persetujuan Kiriman Sales (setujui, jadwalkan, tolak) | `approve` dan `reject` (bagian 6.2 dan 6.3) |
| Kiriman Saya (Draf, Ditolak, kiriman tayang, sematan profil) | `GET /marketing-feed/me/posts`, `resubmit`, `profile-pin` |
| Wall of Fame (admin) | bagian 5.4 dan 8 |
| Algoritma (tab Global dan Per sales, pin, mode, bobot custom) | bagian 5.3 dan 9 |
| Home sales (urutan dan kartu Wall of Fame) | bagian 7 dan 8 |
| Tab Database | bagian 4 dan 5, serta lampiran tabel di `docs/marketing-feed-erd.md` |

Prototype memakai data dummy dan penyimpanan di memori. Semua perilaku di atas harus diganti dengan API dan database sungguhan.