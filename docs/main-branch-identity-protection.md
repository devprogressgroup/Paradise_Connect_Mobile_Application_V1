# Proteksi identity file di branch main/Main

## Masalah

Branch `main`/`Main` pakai applicationId produksi (`id.co.progressgroup.connect`,
lihat [build.gradle.kts:45](../android/app/build.gradle.kts#L45)) yang sudah beredar
di HP sales. Kalau merge atau cherry-pick dari branch dev membawa perubahan appId/bundle
id/signing/Firebase client config secara gak sengaja, main bisa ketiban identity yang
salah — device yang sudah install APK produksi bakal gagal update in-place (signature/
package name berubah) atau malah nyasar ke Firebase project yang salah.

## Mekanisme

Dua lapis:

1. **`.gitattributes`** — `merge=ours` untuk file-file identity. Ini cuma nolong kasus
   konflik asli (main DAN branch lain sama-sama ubah file yang sama). **Gak nolong kasus
   paling umum** (main diem, branch lain yang ubah) — sudah dites, di kasus itu git ambil
   versi mereka tanpa manggil driver `ours` sama sekali.
2. **Git hooks (`post-commit` + `post-merge`)** — [`.githooks/_identity-guard.sh`](../.githooks/_identity-guard.sh)
   yang jalan tiap ada commit baru di branch `main`/`Main`. Kalau file yang dikunci beda
   dari commit sebelumnya (`HEAD@{1}`), otomatis di-restore + bikin commit tambahan
   `chore: restore app identity files on <branch> [allow-identity]`. Ini yang benar-benar
   nolong buat merge (fast-forward maupun bukan) dan cherry-pick — sudah dites eksplisit
   untuk ketiga skenario itu di clone terpisah.

File yang dikunci (murni identity, jarang berubah di luar itu):
- [android/app/build.gradle.kts](../android/app/build.gradle.kts) — applicationId, namespace, signingConfig
- [android/app/google-services.json](../android/app/google-services.json)
- [ios/Runner/GoogleService-Info.plist](../ios/Runner/GoogleService-Info.plist)
- [firebase.json](../firebase.json)
- [lib/firebase_options.dart](../lib/firebase_options.dart)

**Sengaja TIDAK dikunci**: `lib/core/network/api_constants.dart` (banyak logic aktif
selain base URL environment, kalau dikunci nambah fitur baru di file itu gak akan pernah
lewat merge/cherry-pick ke main) dan `ios/Runner.xcodeproj/project.pbxproj` (file generated
raksasa, bundle id cuma sebagian kecil isinya, locking bisa nge-block perubahan Xcode
project yang legit).

## Setup (sekali per clone/laptop/CI)

```bash
git config core.hooksPath .githooks
git config merge.ours.driver true
```

Dua config ini disimpan di `.git/config` lokal, bukan ke-commit ke repo (git sengaja
gak ngizinin driver command otomatis jalan dari file yang di-clone, demi keamanan).

## Kalau memang mau sengaja ubah identity di main

Tambahkan tag `[allow-identity]` di commit message — hook bakal skip, perubahan masuk
seperti biasa.
