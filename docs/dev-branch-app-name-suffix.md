# Nama app "Dev" di branch Development-1.0.4

## Masalah

Sama seperti applicationId (lihat [dev-branch-applicationid-separation.md](dev-branch-applicationid-separation.md)),
nama app yang ditampilkan di bawah ikon HP Android harus beda antara build dev
dan build production, supaya gampang dibedain pas dua-duanya keinstall
bareng di HP yang sama.

## Perubahan

Branch `Development-1.0.4`: [AndroidManifest.xml:18](../android/app/src/main/AndroidManifest.xml#L18)
```xml
android:label="Paradise Connect Dev"
```
Main tetap `"Paradise Connect"`.

Cakupan cuma Android untuk sekarang — iOS (`Info.plist` CFBundleDisplayName/
CFBundleName) dan web/PWA (`web/manifest.json` name/short_name) sengaja
belum disentuh.

## Status proteksi ke Main — PENTING, belum aktif

`android/app/src/main/AndroidManifest.xml` sudah ditambahkan ke daftar
`protected` di [`.githooks/_identity-guard.sh`](../.githooks/_identity-guard.sh)
(sama kayak `build.gradle.kts`), tapi ini **belum berlaku di Main**.

Alasan: hook di-baca dari isi `.githooks/` pada branch yang lagi di-checkout
saat hook jalan — bukan dari branch yang di-merge. Branch `Main` saat ini
masih pakai hook lama (`.githooks/post-merge` versi Main) yang **cuma
melindungi `lib/core/network/api_constants.dart`**, belum pakai
`_identity-guard.sh` yang lebih lengkap ini sama sekali. Jadi:

- `applicationId` (`build.gradle.kts`) — **belum terproteksi** kalau
  Development-1.0.4 di-merge ke Main.
- `android:label` (nama app) — **belum terproteksi** juga, dengan alasan sama.

Sebelum merge Development-1.0.4 ke Main, cek manual dulu applicationId &
nama app di Main gak ikut kebawa jadi versi dev — atau port dulu sistem
`_identity-guard.sh` yang lengkap ini ke branch Main (ganti hook lama-nya)
supaya proteksinya beneran aktif. Belum dilakukan atas permintaan eksplisit
(sengaja belum menyentuh Main).
