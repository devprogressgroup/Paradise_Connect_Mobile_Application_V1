import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

const String _defaultDriftMessage =
    'Tanggal/jam di HP kamu tidak sesuai dengan waktu server. '
    'Mohon matikan pengaturan tanggal & waktu manual, lalu gunakan '
    'waktu otomatis (network time) agar data absensi dan aktivitas '
    'tercatat dengan benar.';

const String certErrorMessage =
    'Gagal terhubung ke server karena keamanan koneksi (HTTPS) ditolak. '
    'Ini hampir selalu terjadi kalau tanggal/jam di HP kamu salah, sehingga '
    'fitur seperti Contact, Attendance, atau Inbox bisa kelihatan "tidak '
    'punya akses" padahal sebenarnya cuma gagal konek. Mohon aktifkan '
    '"Tanggal & waktu otomatis" di pengaturan HP, lalu buka ulang aplikasi.';

/// Peringatan saat jam/tanggal perangkat terdeteksi menyimpang jauh dari
/// waktu server, ATAU saat koneksi HTTPS ke server gagal karena sertifikat
/// ditolak (biasanya juga gara-gara jam perangkat salah — lihat
/// [certErrorMessage]). Tombol "Buka Pengaturan" tidak muncul di web karena
/// browser tidak punya jalan untuk membuka pengaturan tanggal & waktu OS.
void showDeviceTimeWarningDialog(BuildContext context, {String message = _defaultDriftMessage}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tanggal & Waktu Tidak Sesuai'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Nanti'),
        ),
        if (!kIsWeb)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              AppSettings.openAppSettings(type: AppSettingsType.date);
            },
            child: Text(
              'Buka Pengaturan',
              style: TextStyle(color: Color(primaryColor), fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );
}
