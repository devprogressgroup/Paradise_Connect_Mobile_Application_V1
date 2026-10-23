# Import Kontak tanpa READ_CONTACTS (Kebijakan Contacts Permission Google Play)

- **Tanggal:** 23 Oktober 2026
- **Branch:** `ios-app2`
- **Area:** form kontak (import dari buku kontak), permission gate, AndroidManifest, MainActivity

## Masalah

Google Play mengumumkan kebijakan *Contacts Permission*. Mulai **27 Januari 2027**, app yang menargetkan Android 17+ (SDK 37+) dan memakai `READ_CONTACTS` wajib mengajukan declaration di Play Console. Declaration hanya disetujui kalau fungsi utama app memang butuh akses ke seluruh buku kontak. Kalau tidak, Google meminta `READ_CONTACTS` dihapus dan diganti contact picker.

Kondisi sebelumnya:
- `READ_CONTACTS` ada di `AndroidManifest.xml`.
- Di Android, permission gate mewajibkan izin kontak sejak app pertama dibuka. User tidak bisa masuk ke app kalau izin itu ditolak.
- Kontak hanya dipakai untuk satu hal: tombol import di form kontak, untuk mengisi nama dan nomor dari **satu** kontak. `flutter_contacts` butuh `READ_CONTACTS` di Android untuk membaca nomor telepon dari picker.
- targetSdk mengikuti `flutter.targetSdkVersion` (sekarang 36). Kalau Flutter di-upgrade, targetSdk bisa ikut naik ke 37 tanpa disadari.

## Perubahan

- Channel `com.example.progress_group/contact_picker` (method `pickPhone`) di MainActivity. Channel ini membuka picker nomor telepon bawaan Android (`ACTION_PICK` + `Phone.CONTENT_URI`). Android memberi izin baca sementara hanya untuk nomor yang dipilih, jadi tidak perlu `READ_CONTACTS`: [MainActivity.kt:21](../android/app/src/main/kotlin/id/co/progressgroup/connect/MainActivity.kt#L21), [MainActivity.kt:42](../android/app/src/main/kotlin/id/co/progressgroup/connect/MainActivity.kt#L42)
- Service baru `ContactPickerService.pickPhone()`. Android memakai channel di atas, iOS memakai `flutter_contacts` (`CNContactPickerViewController`, yang memang tidak butuh izin kontak). Hasilnya cuma nama dan satu nomor: [contact_picker_service.dart:23](../lib/core/services/contact_picker_service.dart#L23)
- Import kontak di form tidak lagi meminta izin kontak dan langsung membuka picker: [contact-form/index.dart:1436](../lib/features/contact/presentation/pages/contact-form/index.dart#L1436)
- Item **Kontak** dihapus dari permission gate, termasuk enum `DevicePermissionType.contacts` beserta semua case-nya: [device_permission_gate.dart:49](../lib/core/utils/helpers/device_permission_gate.dart#L49). Ikon kontak di halaman gate juga dihapus: [permission-gate/presentation/pages/index.dart](../lib/features/permission-gate/presentation/pages/index.dart)
- `READ_CONTACTS` dihapus dari [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)

## Hasil

- **Android:** tombol import membuka daftar nomor telepon bawaan Android. User memilih satu nomor, lalu nama dan nomornya terisi di form. Tidak ada dialog izin kontak, dan app tidak bisa membaca kontak lain.
- **Android:** permission gate tidak lagi meminta izin kontak. User yang sebelumnya menolak izin kontak tidak lagi tertahan di gate.
- **iOS:** tombol import langsung membuka picker kontak iOS tanpa dialog izin kontak.
- Permintaan izin kontak juga hilang dari iOS, jadi lebih aman untuk App Review (Guideline 5.1.1: minta izin hanya kalau perlu).
- `NSContactsUsageDescription` di `Info.plist` tetap dipertahankan, karena plugin `flutter_contacts` masih mereferensikan API Contacts.

## Yang perlu dilakukan di Play Console

- Rilis build tanpa `READ_CONTACTS` ke **semua track yang aktif** (production dan testing: internal/closed). Google memeriksa semua version code yang aktif.
- Setelah itu, di **Monitor and improve → Policy and programs → App content → Contacts Permission**, pastikan app tidak lagi dianggap memakai `READ_CONTACTS`. Tidak perlu mengajukan declaration.

## Catatan

- Branch lain (`main`, `marketing-feed`, `new-reserve-order`) masih memakai `READ_CONTACTS`. Perubahan ini perlu di-merge sebelum build Android dari branch tersebut dirilis ke Play.
- Kalau nanti ada fitur yang benar-benar butuh seluruh buku kontak (misalnya sinkron semua kontak), baru `READ_CONTACTS` dan declaration diperlukan lagi.
