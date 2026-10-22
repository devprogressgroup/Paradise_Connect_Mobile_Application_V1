# Panduan Build iOS di Codemagic & Upload ke App Store Connect

**Tanggal:** 2026-10-22
**Area:** `ios/` (bundle ID, signing), `pubspec.yaml` (versi), Codemagic (Workflow Editor), Apple Developer & App Store Connect

## Ringkasan
Dokumen ini mencatat setup build iOS lewat **Codemagic** sampai `.ipa` terupload ke **App Store Connect / TestFlight**. Setup ini sudah dipakai dan berhasil build pada 22 Oktober 2026. Ada juga catatan error yang sempat muncul beserta solusinya.

Untuk penyesuaian kode supaya lolos App Review (izin, update OTA, aktivasi akun, dll.), lihat [ios-app-review-compliance.md](ios-app-review-compliance.md).

## Info Kunci Project
- **Bundle ID iOS:** `id.co.progressgroup.connect`, **dua "s"**, sama dengan Android. Lokasinya:
  - [ios/Runner.xcodeproj/project.pbxproj:375](../ios/Runner.xcodeproj/project.pbxproj#L375) (juga baris 554 & 576)
  - [lib/firebase_options.dart:39](../lib/firebase_options.dart#L39)
  - [ios/Runner/GoogleService-Info.plist:12](../ios/Runner/GoogleService-Info.plist#L12)
- **Team Apple:** PT SUPER KAPITA PROPERTINDO, Team ID `ARQB3FNSRL`.
- **App di App Store Connect:** "Paradise Connect Mobile", Apple ID `6820334471`, SKU `APP001`.
- **Branch untuk build iOS:** `ios-app2`, dibuat dari `origin/main`.
- **Versi & nomor build:** diambil dari [pubspec.yaml:4](../pubspec.yaml#L4) (`version: 1.0.6+8`). `Info.plist` membacanya lewat `$(FLUTTER_BUILD_NAME)` dan `$(FLUTTER_BUILD_NUMBER)`: [ios/Runner/Info.plist:24](../ios/Runner/Info.plist#L24), [ios/Runner/Info.plist:28](../ios/Runner/Info.plist#L28).

## ⚠️ Jangan pakai branch `ios-app`
- Branch `origin/ios-app` mengganti bundle ID iOS menjadi `id.co.progresgroup.connect` (**satu "s"**). Itu **salah**: tidak cocok dengan App ID di Apple Developer maupun app di App Store Connect, sehingga build gagal di tahap signing.
- Perbaikan kode iOS dari branch itu (commit `b4c3e52`) sudah dipindah ke `ios-app2` **tanpa** perubahan bundle ID.
- Di Windows, nama branch `main` dan `Main` dianggap sama. Kalau di lokal masih ada branch lama `Main`, `git checkout main` bisa nyasar ke `Main` yang lama. Untuk membuat branch dari main terbaru, pakai `origin/main` langsung:
  ```
  git fetch origin
  git checkout -b <nama-branch> origin/main
  ```

## 1. Setup di Apple Developer (developer.apple.com)
Semua ini **sudah ada**. Langkah di bawah hanya untuk referensi kalau perlu dibuat ulang.

1. **Identifiers:** App ID `id.co.progressgroup.connect` (explicit), deskripsi "Paradise Connect".
2. **Certificates:** satu sertifikat **Distribution** yang dibuat Codemagic lewat API key. Berlaku sampai **22 Oktober 2027**. Apple membatasi jumlah sertifikat distribusi, jadi jangan generate baru kalau yang lama masih berlaku.
3. **Profiles:** profile **App Store Connect** (Distribution) untuk App ID di atas, memakai sertifikat Distribution tersebut. Nama profile di Apple: `Paradise Connect ios_app_store 1791428341`.
   - Kalau sertifikat diganti, profile harus di-**Edit** dan diarahkan ke sertifikat baru, lalu di-fetch ulang di Codemagic.

## 2. API Key App Store Connect
Dipakai Codemagic untuk signing dan upload.

1. Buka App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys**.
2. Key yang dipakai sekarang: Key ID **`Z97WSUSK25`**, file `AuthKey_Z97WSUSK25.p8`.
3. File `.p8` **hanya bisa didownload sekali**, saat key dibuat. Simpan di tempat aman dan **jangan** di-commit, di-paste ke chat, atau dikirim lewat pesan.
4. **Issuer ID** ada di atas tabel Team Keys. Ambil dari halaman ini, **bukan** dari URL browser App Store Connect (ID di URL itu ID team).
5. Ada key kedua (`7879D7R644`) di folder Downloads. Cek di tabel Team Keys apakah masih dipakai. Kalau tidak, revoke.
6. **To-do keamanan:** isi key `Z97WSUSK25` sempat ter-share di luar Codemagic. Disarankan buat key baru, ganti di integration Codemagic, baru revoke `Z97WSUSK25`. Urutannya penting: kalau di-revoke duluan, signing dan upload langsung gagal.

## 3. Setup di Codemagic (codemagic.io)
Semua setup ada di **Personal Account**, bukan Team. App, API key, sertifikat, dan profile harus berada di akun yang sama.

### 3a. Integration Developer Portal
- **Settings** → **Integrations** → **Developer Portal** → Manage keys.
- Nama key: **`code magic paradise connect`**. Isi Issuer ID, Key ID, dan upload `.p8`.

### 3b. Code signing identities
**Settings** → **Code signing identities**:
- **iOS certificates:** sertifikat Distribution di atas, reference name `paradise_connect_certificate`. Ada entri dobel `paradise connect certificate` yang isinya sama, boleh dihapus salah satu.
- **iOS provisioning profiles:** klik **Fetch profiles**, pilih profile App Store untuk `id.co.progressgroup.connect`, reference name `paradise_connect_profile`.
- **Reference name** hanya label bebas. Dipakai kalau memanggil sertifikat atau profile dari `codemagic.yaml`.

### 3c. Workflow Editor (app `Paradise_Connect_Mobile_Application_V1`)
Mode yang dipakai: **Workflow Editor**, bukan `codemagic.yaml`. Workflow: **Default Workflow**.

- **Build for platforms:** centang **iOS saja**. Jangan centang Android: Kotlin di branch ini masih `2.1.21` ([android/settings.gradle.kts:26](../android/settings.gradle.kts#L26)), sedangkan Flutter Gradle Plugin butuh minimal `2.2.20`, jadi build Android akan gagal.
- **Run build on:** macOS M2 (Mac mini M2).
- **Max build duration:** 60 menit.
- **Environment variables:** kosong, tidak perlu.
- **Pre-build script:** kosong.
- **Build:**
  - Flutter version: channel Stable
  - Xcode: Latest
  - CocoaPods: default
  - Project path: `.`
  - Mode: Release
  - Format iOS: `.ipa`
  - **Build arguments: kosong.** Nomor build diambil dari pubspec.
- **Distribution → iOS code signing:** aktif.
  - Manual: certificate `paradise_connect_certificate` dan profile `paradise_connect_profile`.
  - Atau Automatic: key `code magic paradise connect`, tipe App Store, bundle ID `id.co.progressgroup.connect`.
- **Distribution → App Store Connect:** aktif, API key `code magic paradise connect`. *Submit to TestFlight* boleh dimatikan; build tetap terupload dan muncul di TestFlight.
- Setiap selesai mengubah setting, klik **Save changes** di bagian paling bawah. Kalau tidak, build tetap memakai setting lama.

## 4. Cara Build & Upload (setiap rilis)
1. Naikkan **nomor build** (angka setelah `+`) di [pubspec.yaml:4](../pubspec.yaml#L4). Contoh: `1.0.6+8` jadi `1.0.6+9`.
   - Nomor build **harus lebih besar** dari build terakhir yang pernah diupload ke App Store Connect, untuk versi apa pun.
   - Angka di depan (`1.0.6`) hanya dinaikkan kalau rilis versi baru.
2. Commit dan push ke `ios-app2`.
3. Di Codemagic: **Start new build** → branch `ios-app2` → Start.
4. Build sekitar 15–30 menit. Kalau sukses, `.ipa` otomatis terupload ke App Store Connect.
5. Tunggu Apple memproses build (biasanya 10–30 menit). Setelah itu build muncul di **TestFlight**.

## 5. TestFlight
- **Internal testing (`test-group`):** tambahkan build ke grup ini. Tester bisa langsung install, tanpa review Apple.
- **External testing (`test-external`):** tambahkan build ke grup, lalu **Submit for Review** (Beta App Review). Sebelum submit, isi **Test Information**: deskripsi, email feedback, dan **akun demo** untuk login.
- Build TestFlight kedaluwarsa **90 hari** setelah diupload.

## 6. Submit ke App Store
1. Di tab **Distribution**, **nomor versi App Store harus sama dengan versi build**. Contoh: versi `1.0` diubah jadi `1.0.6` supaya build `1.0.6 (8)` bisa dipilih.
2. Pilih build, lalu isi **App Review Information**:
   - **Sign-in information:** akun demo.
   - **Notes:** penjelasan app untuk reviewer.
3. App ini khusus karyawan, jadi ajukan **Unlisted App Distribution** (Guideline 3.2): https://developer.apple.com/support/unlisted/request/
4. Daftar yang perlu disiapkan untuk App Review ada di [ios-app-review-compliance.md](ios-app-review-compliance.md).

## 7. Error yang Pernah Muncul & Solusinya
- **`The bundle version must be higher than the previously uploaded version: '7'`** (tahap Publishing)
  - Penyebab: nomor build sama dengan build yang sudah ada di App Store Connect.
  - Solusi: naikkan angka setelah `+` di `pubspec.yaml`, commit, push, lalu build ulang. Build dan signing di run itu sebenarnya sudah sukses; yang gagal hanya upload-nya.
- **`No matching profiles found`** (tahap code signing)
  - Penyebab: bundle ID di project berbeda dengan profile (kasus branch `ios-app` yang memakai satu "s").
  - Solusi: pastikan bundle ID `id.co.progressgroup.connect` di semua lokasi pada "Info Kunci Project".
- **`Missing value PRIVATE_KEY`** atau **`Provided value is not a valid PEM encoded private key`** (Pre-build script)
  - Hanya muncul kalau memakai script yang menjalankan `app-store-connect` CLI, misalnya untuk nomor build otomatis. Setup sekarang tidak memakai script, jadi error ini tidak akan muncul.
  - Kalau suatu saat butuh nomor build otomatis:
    - Simpan isi `.p8` sebagai **base64** di environment variable `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` (Secure), lalu decode di awal script: `export APP_STORE_CONNECT_PRIVATE_KEY="$(echo "$APP_STORE_CONNECT_PRIVATE_KEY_BASE64" | base64 --decode)"`. Paste `.p8` langsung ke kolom value sering merusak baris-barisnya.
    - Isi juga `APP_STORE_CONNECT_ISSUER_ID` dan `APP_STORE_CONNECT_KEY_IDENTIFIER`.
    - Script di Workflow Editor yang sudah diubah harus di-**Save changes**. Cek lewat **Show command** di log apakah script yang jalan sudah versi terbaru.

## Catatan
- Opsi pindah ke `codemagic.yaml`: konfigurasi build tercatat di git, dan kredensial App Store Connect otomatis tersedia di script lewat `integrations: app_store_connect`, jadi tidak perlu environment variable base64. Syaratnya, file harus ada di setiap branch yang di-build. Kalau mau pindah, pasang dulu di `ios-app2`, tes sampai sukses, baru merge ke `main`.
- Push notification iOS belum aktif: belum ada file entitlements (Push Notifications capability) dan APNs key di Firebase. Build tetap jalan tanpa itu.
