# applicationId terpisah untuk branch dev (Development-1.0.4)

## Masalah

Sebelumnya semua branch (Main maupun dev) pakai applicationId yang sama:
`id.co.progressgroup.connect`. Akibatnya build dari branch dev nggak bisa
diinstall berdampingan dengan app production di HP yang sama — install APK
dev bakal nimpa/uninstall app production (atau ditolak install kalau
signature beda), jadi susah testing tanpa ganggu app yang lagi dipakai sales.

## Perubahan

Branch `Development-1.0.4` sekarang pakai applicationId placeholder Flutter
default: [android/app/build.gradle.kts:45](../android/app/build.gradle.kts#L45)
```kotlin
applicationId = "com.example.progress_group"
```
sedangkan Main tetap `id.co.progressgroup.connect` (applicationId produksi).

`namespace` di [build.gradle.kts:30](../android/app/build.gradle.kts#L30) **tidak
diubah** — itu cuma dipakai buat resolusi package Kotlin/Java, bukan identity
APK yang keinstall, jadi aman dibiarkan beda dari applicationId.

Firebase (`google-services.json`) nggak perlu diubah karena filenya sudah
punya entry client untuk kedua package name (`com.example.progress_group`
dan `id.co.progressgroup.connect`) sekaligus.

Perubahan ini cuma di branch `Development-1.0.4`, belum dipush ke remote dan
belum diterapkan ke branch dev lain (Devlopment-1.0.1, Development-1.0.3,
staging, dll).

Catatan penting: hook identity-guard yang dijelaskan di
[main-branch-identity-protection.md](main-branch-identity-protection.md)
(`.githooks/_identity-guard.sh`) cuma ada di branch `Development-1.0.4`,
**belum di-port ke Main**. Branch `Main` masih pakai hook lama
(`.githooks/post-merge` versi Main) yang cuma melindungi
`lib/core/network/api_constants.dart` — applicationId **belum
terproteksi** kalau branch ini di-merge ke Main. Detail di
[dev-branch-app-name-suffix.md](dev-branch-app-name-suffix.md#status-proteksi-ke-main--penting-belum-aktif).

## Cara cek applicationId app yang sudah terinstall di HP

Lewat ADB (device harus kekoneksi & USB debugging aktif):

```bash
# semua package yang keinstall, filter nama app
adb shell pm list packages | grep progress

# applicationId dari app yang lagi kebuka/fokus di layar
adb shell dumpsys window | grep mCurrentFocus
```

Contoh hasil `mCurrentFocus`:
```
mCurrentFocus=Window{... id.co.progressgroup.connect/id.co.progressgroup.connect.MainActivity}
```
Bagian sebelum `/` itu applicationId-nya. Kalau build dev yang lagi dibuka,
harusnya muncul `com.example.progress_group` di situ — dan dua-duanya bisa
sekaligus muncul di `pm list packages` kalau kedua APK (prod + dev)
terinstall bareng di HP yang sama.
