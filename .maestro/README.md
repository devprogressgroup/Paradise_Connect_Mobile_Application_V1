# 🧪 Maestro UI Tests — Paradise Connect (Attendance)

Folder ini berisi flow test Maestro untuk fitur **Attendance** di aplikasi Paradise Connect.

## 📋 Daftar Flow Test

| File | Deskripsi |
|------|-----------|
| `01_login.yaml` | Login ke aplikasi |
| `02_attendance_tabs.yaml` | Navigasi tab Activity & Attendance Log |
| `03_clock_in.yaml` | Proses Clock In (sampai kamera terbuka) |
| `04_filter_attendance_log.yaml` | Filter tanggal di Attendance Log |
| `05_download_excel.yaml` | Download Excel kehadiran |
| `06_pull_to_refresh.yaml` | Pull-to-refresh di halaman Attendance |

---

## 🚀 Setup & Instalasi

### 1. Install Maestro (Windows PowerShell)
```powershell
iex "& { $(iwr 'https://get.maestro.mobile.dev') }"
```

Setelah install, verifikasi:
```powershell
maestro --version
```

### 2. Build & Install APK ke Device/Emulator
```bash
# Build debug (lebih cepat untuk testing)
flutter build apk --debug

# Install ke device/emulator yang terhubung
flutter install
```

> ⚠️ Untuk Maestro, gunakan **debug build** (bukan release) agar lebih stabil saat testing.

---

## ▶️ Cara Menjalankan Test

### Jalankan satu flow:
```bash
maestro test .maestro/02_attendance_tabs.yaml
```

### Jalankan semua flow sekaligus:
```bash
maestro test .maestro/
```

### Jalankan dengan video recording:
```bash
maestro test .maestro/02_attendance_tabs.yaml --format junit --output report.xml
```

### Mode interaktif (debug live):
```bash
maestro studio
```

---

## ⚠️ Catatan Penting per Flow

### `03_clock_in.yaml` — Clock In
- Memerlukan **GPS aktif** di emulator
- Set mock location di emulator: Android Studio → Device Manager → titik tiga → Edit → Location
- Kamera harus diizinkan
- Flow **tidak bisa auto-foto** — hanya test sampai kamera terbuka

### `01_login.yaml` — Login
- Sesuaikan `email` dan `password` dengan akun test yang valid
- Jika ada splash screen, tambahkan `waitForAnimationToEnd` di awal

---

## 🔑 Menyesuaikan Selector

Jika ada elemen yang tidak terdeteksi, tambahkan **Semantics Label** di Flutter:

```dart
// Contoh: beri label pada tombol download
Semantics(
  label: 'btn_download_excel',
  child: IconButton(
    icon: Icon(Icons.download),
    onPressed: _showPdfDatePickerDialog,
  ),
)
```

Lalu di Maestro gunakan:
```yaml
- tapOn:
    id: "btn_download_excel"
```

---

## 🐛 Tips Debugging

```bash
# Lihat semua elemen yang terdeteksi di layar saat ini
maestro hierarchy

# Screenshot layar saat ini
maestro screenshot output.png

# Mode interaktif step-by-step
maestro studio
```
