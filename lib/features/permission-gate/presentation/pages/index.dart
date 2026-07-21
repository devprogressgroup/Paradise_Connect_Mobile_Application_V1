import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/device_permission_gate.dart';

class PermissionGatePage extends StatefulWidget {
  /// Called instead of the default `context.go('/splash')` redirect once every
  /// required permission is granted. Pass this when pushing the page on top of
  /// an existing flow (e.g. mid-session from the update screen) so granting
  /// permission resumes that flow instead of jumping away to splash.
  final VoidCallback? onAllGranted;

  const PermissionGatePage({super.key, this.onAllGranted});

  @override
  State<PermissionGatePage> createState() => _PermissionGatePageState();
}

class _PermissionGatePageState extends State<PermissionGatePage> with WidgetsBindingObserver {
  final _items = DevicePermissionGate.requiredItems();
  final Map<DevicePermissionType, bool> _granted = {};
  final Map<DevicePermissionType, bool> _permanentlyDenied = {};

  bool _loading = true;
  bool _requesting = false;
  bool _locationServiceEnabled = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  bool get _allGranted =>
      _locationServiceEnabled && _items.every((i) => _granted[i.type] == true);

  Future<void> _refresh() async {
    _locationServiceEnabled = await DevicePermissionGate.isLocationServiceEnabled();
    for (final item in _items) {
      _granted[item.type] = await DevicePermissionGate.isGranted(item.type);
      _permanentlyDenied[item.type] = await DevicePermissionGate.isPermanentlyDenied(item.type);
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (_allGranted && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.onAllGranted != null) {
          widget.onAllGranted!();
        } else {
          context.go('/splash');
        }
      });
    }
  }

  bool get _hasPermanentlyDenied => _permanentlyDenied.values.any((v) => v);

  /// Browser (beda dengan native) tidak punya API untuk membuka halaman pengaturan
  /// app dari JS — begitu user klik "Block" di dialog izin, satu-satunya cara adalah
  /// user sendiri yang ubah manual lewat site settings browser lalu refresh halaman.
  void _showWebPermissionBlockedDialog() {
    final blockedLabels = _items
        .where((i) => _permanentlyDenied[i.type] == true)
        .map((i) => i.label)
        .join(', ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Diblokir Browser'),
        content: Text(
          'Browser memblokir izin berikut untuk halaman ini: $blockedLabels.\n\n'
          'Cara mengaktifkan:\n'
          '1. Klik ikon 🔒 atau ⓘ di address bar\n'
          '2. Pilih "Site settings"\n'
          '3. Ubah izin yang diblokir jadi "Allow"\n'
          '4. Refresh halaman',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }

  Future<void> _openSettingsForBlockedPermission() async {
    if (kIsWeb) {
      _showWebPermissionBlockedDialog();
      return;
    }
    await DevicePermissionGate.openAppSettings();
  }

  Future<void> _onPrimaryButtonTap() async {
    if (!_locationServiceEnabled) {
      await DevicePermissionGate.openLocationServiceSettings();
      return;
    }
    if (_hasPermanentlyDenied) {
      await _openSettingsForBlockedPermission();
      return;
    }

    setState(() => _requesting = true);
    // Request permission wajib (lokasi/notifikasi) dulu selagi masih dalam jendela user
    // gesture dari tap tombol ini — primeWebCamera() (getUserMedia, bisa nunggu s/d 10 detik)
    // taruh paling akhir supaya tidak menghabiskan jendela gesture itu di browser yang ketat.
    for (final item in _items) {
      if (_granted[item.type] != true) {
        await DevicePermissionGate.request(item.type);
      }
    }
    await DevicePermissionGate.primeWebCamera();
    if (!mounted) return;
    setState(() => _requesting = false);
    await _refresh();
  }

  IconData _iconFor(DevicePermissionType type) {
    switch (type) {
      case DevicePermissionType.camera:
        return Icons.camera_alt_rounded;
      case DevicePermissionType.gallery:
        return Icons.photo_library_rounded;
      case DevicePermissionType.location:
        return Icons.location_on_rounded;
      case DevicePermissionType.contacts:
        return Icons.contacts_rounded;
      case DevicePermissionType.notification:
        return Icons.notifications_rounded;
      case DevicePermissionType.installPackages:
        return Icons.system_update_rounded;
    }
  }

  Future<void> _onPermissionTap(DevicePermissionType type) async{
    if(_requesting) return;
    if (type == DevicePermissionType.location && !_locationServiceEnabled) {
      await DevicePermissionGate.openLocationServiceSettings();
      return;
    }

    final permanentlyDenied = _permanentlyDenied[type] == true;
    if (permanentlyDenied) {
      await _openSettingsForBlockedPermission();
      return;
    }

    setState(() => _requesting = true);

    if (type == DevicePermissionType.camera) {
      await DevicePermissionGate.primeWebCamera();
    }

    await DevicePermissionGate.request(type);

    setState(() => _requesting = false);

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(whiteColor),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Image.asset(logoSplasShcreenGif, width: 140, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      Text(
                        'Izin Aplikasi Diperlukan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(blue2Color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        !_locationServiceEnabled
                            ? 'GPS perangkat kamu sedang mati. Aktifkan GPS untuk melanjutkan.'
                            : kIsWeb
                                ? 'Aplikasi ini butuh izin berikut. Tap tombol "Izinkan" di tiap izin satu per satu untuk melanjutkan.'
                                : 'Aplikasi ini butuh izin berikut supaya semua fitur (absensi, kontak, foto, notifikasi) berjalan normal. Izinkan semua untuk melanjutkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(grey2Color)),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final granted = _granted[item.type] == true && _locationServiceEnabled;
                            final permanentlyDenied = _permanentlyDenied[item.type] == true;
                            return InkWell(
                              onTap: (kIsWeb || granted) ? null : () => _onPermissionTap(item.type),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(grey11Color),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Color(grey9Color)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (granted ? Color(successColor) : Color(primaryColor)).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _iconFor(item.type),
                                        color: granted ? Color(successColor) : Color(primaryColor),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.label,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description,
                                            style: TextStyle(fontSize: 12, color: Color(grey4Color)),
                                          ),
                                          if (permanentlyDenied) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ditolak permanen — buka Pengaturan untuk mengaktifkan',
                                              style: TextStyle(fontSize: 11, color: Color(redAccentColor)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (granted)
                                      Icon(Icons.check_circle_rounded, color: Color(successColor))
                                    else if (kIsWeb)
                                      OutlinedButton(
                                        onPressed: _requesting ? null : () => _onPermissionTap(item.type),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Color(primaryColor),
                                          side: BorderSide(color: Color(primaryColor)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          permanentlyDenied ? 'Pengaturan' : 'Izinkan',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      )
                                    else
                                      Icon(Icons.cancel_rounded, color: Color(grey6Color)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Web: tiap izin punya tombol "Izinkan" sendiri di atas (lihat tile),
                      // supaya tiap request punya user-gesture-nya sendiri-sendiri — browser
                      // bisa gagal munculin dialog kalau beberapa permission diminta berurutan
                      // dalam satu gesture yang sama. Tombol bulk cuma tampil untuk kasus
                      // "buka pengaturan" (satu aksi, aman) atau di native (OS handle sendiri).
                      if (kIsWeb && _locationServiceEnabled && !_hasPermanentlyDenied)
                        Text(
                          'Halaman ini otomatis lanjut setelah semua izin di atas diizinkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(grey4Color), fontStyle: FontStyle.italic),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requesting ? null : _onPrimaryButtonTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(primaryColor),
                              foregroundColor: Color(whiteColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _requesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    !_locationServiceEnabled
                                        ? 'Aktifkan GPS'
                                        : _hasPermanentlyDenied
                                            ? 'Buka Pengaturan Aplikasi'
                                            : 'Izinkan Semua',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
