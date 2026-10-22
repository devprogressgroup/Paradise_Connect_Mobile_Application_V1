# Update Aplikasi — Google Play, App Store/TestFlight, dan APK

- **Tanggal:** 22 Oktober 2026
- **Branch:** `ios-app2` (diambil dari commit `4f6ca92` di `marketing-feed` / `new-reserve-order`)
- **Area:** version check, layar update, push notification `app_update`

## Masalah

- App punya mekanisme update sendiri: download APK dari `appDownloadUrl` (OTA). Untuk app yang di-install dari **Google Play**, cara ini selalu gagal. Play menandatangani app dengan key *Play App Signing*, sedangkan APK hasil build sendiri memakai key lain, sehingga Android menolak install-nya (signature beda). User Play bisa terjebak di layar update yang tidak pernah berhasil.
- Di `main`, perbaikannya belum ada. Baru tersedia di branch `marketing-feed` dan `new-reserve-order`.

## Perubahan

- Service baru untuk update lewat **Play In-App Updates** (package `in_app_update`, mode *immediate*). App dianggap berasal dari Play kalau installer-nya `com.android.vending`: [play_update_service.dart:15](../lib/core/services/play_update_service.dart#L15)
- Layar update khusus app dari Play. Tombol update membuka layar update resmi milik Play, dengan fallback membuka halaman app di Play Store: [play_update_screen.dart:11](../lib/core/screens/play_update_screen.dart#L11)
- Version check: untuk app dari Play, acuannya adalah Play (ada versi lebih baru atau tidak), bukan `LAST_VERSION` dari settings: [version_check_service.dart:58](../lib/core/services/version_check_service.dart#L58)
- Banner update OTA APK tidak ditampilkan untuk app dari Play: [push_notification_service.dart:76](../lib/core/services/push_notification_service.dart#L76)
- Push notification `app_update` untuk app dari Play diarahkan ke pengecekan Play, bukan ke layar download APK: [main.dart:317](../lib/main.dart#L317)
- Overlay update memilih `PlayUpdateScreen` atau `UpdateScreen` (APK) sesuai sumber install: [main.dart:618](../lib/main.dart#L618)
- Dependency `in_app_update: ^4.2.5` (hanya untuk Android): [pubspec.yaml](../pubspec.yaml)

Yang **tidak** diambil dari commit `4f6ca92`:
- Background halaman login yang diubah jadi merah. Ini kelihatannya perubahan untuk tes, bukan bagian dari fitur update.
- Fungsi `_onSettingsChanged` di `main.dart`. Itu milik fitur lain (settings yang dimuat setelah frame pertama) dan di `main` tidak dipakai.
- Perbaikan iOS di commit yang sama (permission gate, kamera, version check iOS) sudah lebih dulu masuk lewat `b4c3e52`. Lihat [ios-app-review-compliance.md](ios-app-review-compliance.md).

## Hasil (per cara install)

- **Android, install dari Google Play:** saat ada versi baru di Play, app langsung menampilkan layar update dan update dijalankan lewat Play. Selain itu Play juga meng-update otomatis sesuai setting auto-update di HP user.
- **Android, install dari APK langsung:** tetap memakai mekanisme lama, yaitu download APK dari `appDownloadUrl` kalau `LAST_VERSION` lebih baru.
- **iOS (App Store / TestFlight):** tidak ada pengecekan update di dalam app. Update dilakukan iOS sendiri:
  - App Store: otomatis kalau *Settings → App Store → App Updates* menyala (default menyala). Waktunya tidak langsung, biasanya dalam hitungan jam sampai sekitar satu hari.
  - TestFlight: tester mendapat notifikasi build baru. Update otomatis bisa dinyalakan per app di aplikasi TestFlight.
- **Web (PWA):** tidak berubah.

## Catatan

- Supaya update dari Play terdeteksi, versi baru harus sudah **dirilis** di track tempat user meng-install (internal / closed testing / production), dan nomor build-nya (angka setelah `+`) lebih besar.
- Play In-App Updates hanya jalan untuk app yang benar-benar di-install dari Play Store. Install lewat `flutter run` atau APK manual tidak akan pernah mendeteksi update dari Play.
