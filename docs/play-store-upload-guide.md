# Panduan Upload App ke Play Store (Terbatas / Belum Publik)

**Tanggal:** 2026-08-10
**Area:** `android/app` (signing, package name, Play Console)

## Ringkasan
Dokumen ini mencatat proses **Android developer verification** (verifikasi kepemilikan package name) dan cara upload build ke Play Store lewat **testing track** supaya app bisa diakses tester tertentu tanpa publish ke publik.

## Info Kunci Project
- **Package name / applicationId:** `id.co.progressgroup.connect` — lihat [android/app/build.gradle.kts:30](../android/app/build.gradle.kts#L30) (namespace) & [android/app/build.gradle.kts:45](../android/app/build.gradle.kts#L45) (applicationId).
- **Keystore release:** `android/app/upload-keystore.jks`, alias `upload`. Kredensial ada di [android/key.properties](../android/key.properties) (jangan commit ke git kalau belum di-gitignore, cek dulu).
- **SHA-256 fingerprint keystore ini:** `8F:B1:23:62:2B:B7:C5:C6:7D:73:A3:E7:6B:50:5B:41:3D:71:B3:A2:7C:55:1C:1D:FD:BF:76:81:82:48:3F:EE` — sudah dicocokkan dan **match** dengan yang diminta Google Play Console.

## 1. Android Developer Verification (Bukti Kepemilikan Package Name)
Proses ini terpisah dari publish app — cuma buat membuktikan kamu pemilik package name & private key-nya. APK yang di-upload di sini **tidak didistribusikan ke user**, jadi bisa dilakukan kapan saja meski app masih dalam tahap develop.

Langkah:
1. Snippet unik dari Play Console sudah di-paste ke [android/app/src/main/assets/adi-registration.properties](../android/app/src/main/assets/adi-registration.properties).
2. Build APK release (pakai keystore `upload-keystore.jks` yang sudah match fingerprint-nya):
   ```
   flutter build apk --release
   ```
   Hasil ada di `build/app/outputs/flutter-apk/app-release.apk`.
3. Upload APK tersebut ke halaman verifikasi di Play Console (Manage → Android developer verification → Upload APK).
4. Tunggu status berubah dari **Draft** → **Verified**.

## 2. Upload ke Play Store Tanpa Publish ke Publik
Supaya app cuma bisa diakses user tertentu (bukan publik), pakai **testing track**, bukan Production:

- **Internal testing** — max 100 tester, via email undangan. Cocok untuk tim internal/QA.
- **Closed testing** — email list atau Google Group, bisa lebih dari 100 orang. Cocok untuk sales/klien tertentu, tetap private.
- **Open testing** — publik lewat link. ❌ Bukan pilihan kalau mau restricted.

Langkah upload ke Internal/Closed testing:
1. Build **App Bundle** (disarankan Google daripada APK):
   ```
   flutter build appbundle --release
   ```
   Hasil ada di `build/app/outputs/bundle/release/app-release.aab`.
2. Di Play Console: **Testing → Internal testing** (atau **Closed testing**) → **Create new release**.
3. Upload file `.aab`, isi release notes, **Save** → **Review release** → **Start rollout**.
4. Di tab **Testers**, tambahkan daftar email tester (Internal testing) atau Google Group (Closed testing).
5. Tester dapat **link opt-in** dari Play Console — mereka harus klik link itu dan join dulu sebelum bisa install lewat Play Store.

Track ini tidak masuk listing Production, jadi tidak akan muncul di pencarian Play Store publik.

## Catatan
- Verifikasi developer (bagian 1) dan upload testing track (bagian 2) adalah dua proses independen — bisa dikerjakan di urutan mana saja.
- Kalau nanti keystore diganti (misal migrasi ke Play App Signing), verifikasi developer perlu diulang karena fingerprint-nya berubah.
