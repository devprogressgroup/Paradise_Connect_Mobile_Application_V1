# iOS — Penyesuaian untuk App Review Apple

- **Tanggal:** 22 Oktober 2026
- **Branch:** `ios-app2` (dari `origin/main`), versi `1.0.6+8`
- **Area:** auth (login, aktivasi akun), permission gate, version check / OTA update, kamera absensi

## Masalah

Versi 1.0 di App Store Connect ditolak dengan status *Guideline 2.1 – Information Needed*. Waktu kode `main` diperiksa, ada beberapa hal yang akan membuat app ditolak lagi di review berikutnya:

- Halaman permission gate mewajibkan semua izin (kamera, galeri, lokasi, kontak, notifikasi) sebelum app bisa dipakai. Ini melanggar Guideline 5.1.1: izin harus diminta saat fiturnya dipakai.
- Version check membuka layar update OTA (APK). Di iOS layar itu tidak jalan dan user tertahan di "Mempersiapkan..." selamanya.
- Tombol "Sign Up" di login membuat Apple menganggap app mendukung pembuatan akun, sehingga fitur hapus akun jadi wajib (Guideline 5.1.1(v)). Padahal akun dibuat oleh HRD, dan alur di app hanya aktivasi (set password lewat OTP WhatsApp).
- Tap judul "Sign In" membuka pilihan server development. Ini fitur tersembunyi (Guideline 2.3.1), dan reviewer bisa nyasar ke server dev sehingga akun demo gagal login.

## Perubahan

Diambil dari commit `b4c3e52` (branch `ios-app` lama; hanya perbaikan kode, tanpa perubahan bundle ID):

- Permission gate tidak men-gate izin apa pun di iOS: [device_permission_gate.dart:93](../lib/core/utils/helpers/device_permission_gate.dart#L93)
- GPS yang mati tidak menahan user di permission gate kalau tidak ada izin yang di-gate: [permission-gate/presentation/pages/index.dart:56](../lib/features/permission-gate/presentation/pages/index.dart#L56)
- Kamera absensi meminta izin sendiri di iOS. Kalau ditolak, user diarahkan ke Pengaturan: [camera/index_mobile.dart:126](../lib/features/attandance/presentation/pages/camera/index_mobile.dart#L126)
- Version check di iOS selalu menganggap tidak perlu update (update hanya lewat App Store): [version_check_service.dart:46](../lib/core/services/version_check_service.dart#L46)
- Banner update dan notifikasi `app_update` (OTA APK) diabaikan di iOS: [push_notification_service.dart:76](../lib/core/services/push_notification_service.dart#L76), [push_notification_service.dart:591](../lib/core/services/push_notification_service.dart#L591)
- "Don't have an account? Sign Up" diganti jadi "New employee? Activate Account": [login/index.dart:560](../lib/features/auth/presentation/pages/login/index.dart#L560), [login/index.dart:566](../lib/features/auth/presentation/pages/login/index.dart#L566)
- Judul halaman aktivasi diganti jadi "Activate Employee Account": [forgot-password/index.dart:413](../lib/features/auth/presentation/pages/forgot-password/index.dart#L413)

Perubahan baru:

- Pilihan server dev (tap judul "Sign In") dimatikan di build release iOS. Android, web, dan build debug tidak berubah: [login/index.dart:217](../lib/features/auth/presentation/pages/login/index.dart#L217)

## Hasil

- Di iOS, user langsung masuk ke login/home tanpa halaman izin. Izin kamera dan lokasi diminta saat absensi, kontak saat import kontak, notifikasi saat app pertama dibuka.
- Di iOS tidak ada lagi layar update APK, jadi app tidak macet di "Mempersiapkan...".
- Login menampilkan "New employee? Activate Account" dan tidak ada istilah pendaftaran akun publik.
- Di build release iOS, tap "Sign In" tidak membuka pilihan server, jadi reviewer selalu memakai server production.

## Yang masih harus disiapkan di luar kode

- Akun demo di server production berisi data contoh. Clock-in absensi harus bisa dilakukan dari lokasi mana pun.
- Ajukan *Unlisted App Distribution* (app khusus karyawan, Guideline 3.2): https://developer.apple.com/support/unlisted/request/
- Rekaman layar dari iPhone asli dengan iOS terbaru (build TestFlight 1.0.6 (8)), dimulai dari membuka app.
- Balasan untuk App Review, diisi juga di App Review Information → Notes, lengkap dengan kredensial akun demo.
- Screenshot App Store harus menampilkan isi app saat dipakai, bukan halaman login atau splash.
