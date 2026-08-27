# Attendance — Perjelas Copy Tombol "Check In"

**Tanggal:** 2026-08-05
**Area:** `features/attandance` (Attendance page, tab "Check In")

## Masalah
Tab bar attendance punya 3 tab: "Clock In", "Check In", "Clock Out". Karena disandingkan dengan "Clock In"/"Clock Out" yang jelas-jelas absensi, user bisa salah kira "Check In" juga bagian dari absensi — padahal ini cuma dokumentasi foto aktivitas harian (tidak mempengaruhi jam kerja).

## Perubahan
Label tab & tombol besar tetap "Check In" (tidak diganti nama). Yang diubah cuma teks bantuan di bawah tombol, khusus untuk tab ini (`flagParam == 6`), supaya tujuannya lebih jelas tanpa mengubah nama fitur.

- [lib/features/attandance/presentation/pages/attandance-page/index.dart:2618-2621](../lib/features/attandance/presentation/pages/attandance-page/index.dart#L2618-L2621)

```dart
Text(
  flagParam == 6 ? "Ambil foto aktivitas hari ini" : "Please $title!",
  style: TextStyle(fontSize: 12, color: Color(grey6Color)),
),
```

## Hasil
Tab "Clock In"/"Clock Out" tetap tampil "Please Clock In!"/"Please Clock Out!". Tab "Check In" sekarang tampil "Ambil foto aktivitas hari ini" di bawah tombolnya.

## Belum diterapkan (opsional, didiskusikan tapi belum disetujui user)
- Rename label tab/tombol dari "Check In" → "Aktivitas" (ditolak user — nama tetap "Check In")
- Caption tambahan di bawah tab bar ("Dokumentasi kegiatan lapangan, bukan absensi")
