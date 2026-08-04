import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';

enum _GuidePlatform { safariIos, chromeAndroid }

class _GuideStep {
  final String image;
  final String caption;

  const _GuideStep(this.image, this.caption);
}

class LocationPermissionGuidePage extends StatefulWidget {
  const LocationPermissionGuidePage({super.key});

  @override
  State<LocationPermissionGuidePage> createState() => _LocationPermissionGuidePageState();
}

class _LocationPermissionGuidePageState extends State<LocationPermissionGuidePage> {
  _GuidePlatform _platform = _GuidePlatform.safariIos;

  static final List<_GuideStep> _locationServiceSteps = [
    _GuideStep(locationGuideSafariImages[0], 'Buka aplikasi Pengaturan (Settings) di iPhone'),
    _GuideStep(locationGuideSafariImages[1], 'Scroll ke bawah, lalu ketuk "Privasi & Keamanan"'),
    _GuideStep(locationGuideSafariImages[2], 'Ketuk "Layanan Lokasi", pastikan dalam posisi aktif'),
    _GuideStep(locationGuideSafariImages[3], 'Cari "Safari" pada daftar app'),
    _GuideStep(locationGuideSafariImages[4], 'Pilih "Saat App Aktif" dan aktifkan "Lokasi Tepat"'),
  ];

  static final List<_GuideStep> _safariWebsiteSteps = [
    _GuideStep(locationGuideSafariImages[5], 'Di halaman Pengaturan, scroll ke bawah lalu ketuk "App"'),
    _GuideStep(locationGuideSafariImages[6], 'Cari dan ketuk "Safari"'),
    _GuideStep(locationGuideSafariImages[7], 'Scroll ke bawah pada halaman Safari'),
    _GuideStep(locationGuideSafariImages[8], 'Pada bagian "Pengaturan untuk Situs Web", ketuk "Lokasi"'),
    _GuideStep(locationGuideSafariImages[9], 'Pilih "Izinkan"'),
  ];

  static final List<_GuideStep> _chromeAppPermissionSteps = [
    _GuideStep(locationGuideChromeImages[0], 'Buka Setelan (Settings) HP, lalu ketuk "Lokasi"'),
    _GuideStep(locationGuideChromeImages[1], 'Pastikan "Akses lokasi" dalam posisi aktif'),
    _GuideStep(locationGuideChromeImages[2], 'Kembali ke Setelan, lalu ketuk "Aplikasi"'),
    _GuideStep(locationGuideChromeImages[3], 'Ketuk "Kelola aplikasi"'),
    _GuideStep(locationGuideChromeImages[4], 'Cari dan ketuk "Chrome"'),
    _GuideStep(locationGuideChromeImages[5], 'Pada halaman Info apl, ketuk "Perizinan apl"'),
    _GuideStep(locationGuideChromeImages[6], 'Ketuk "Lokasi"'),
    _GuideStep(locationGuideChromeImages[7], 'Pilih "Izinkan saat aplikasi digunakan" dan aktifkan "Gunakan lokasi presisi"'),
  ];

  static final List<_GuideStep> _chromeSiteSteps = [
    _GuideStep(locationGuideChromeImages[8], 'Buka devconnect.paradise.id di Chrome, lalu ketuk ikon di sebelah kiri address bar'),
    _GuideStep(locationGuideChromeImages[9], 'Ketuk "Izin"'),
    _GuideStep(locationGuideChromeImages[10], 'Aktifkan toggle "Lokasi"'),
  ];

  void _selectPlatform(_GuidePlatform platform) {
    if (_platform == platform) return;
    setState(() => _platform = platform);
  }

  Widget _platformSelector() {
    return Row(
      children: [
        Expanded(child: _platformButton('Safari (iOS)', _GuidePlatform.safariIos)),
        const SizedBox(width: 10),
        Expanded(child: _platformButton('Chrome (Android)', _GuidePlatform.chromeAndroid)),
      ],
    );
  }

  Widget _platformButton(String label, _GuidePlatform platform) {
    final bool selected = _platform == platform;
    return GestureDetector(
      onTap: () => _selectPlatform(platform),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Color(primaryColor) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Color(primaryColor) : Color(grey7Color)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _stepList(List<_GuideStep> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(primaryColor),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(step.caption, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(grey7Color)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(step.image, height: 350, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _guideContent() {
    if (_platform == _GuidePlatform.safariIos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Langkah 1: Aktifkan Layanan Lokasi untuk Safari'),
          const SizedBox(height: 12),
          _stepList(_locationServiceSteps),
          const SizedBox(height: 8),
          _sectionTitle('Langkah 2: Izinkan akses lokasi di Safari'),
          const SizedBox(height: 12),
          _stepList(_safariWebsiteSteps),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Langkah 1: Izinkan akses lokasi untuk aplikasi Chrome'),
        const SizedBox(height: 12),
        _stepList(_chromeAppPermissionSteps),
        const SizedBox(height: 8),
        _sectionTitle('Langkah 2: Izinkan akses lokasi untuk situs web'),
        const SizedBox(height: 12),
        _stepList(_chromeSiteSteps),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Color(backgroundColor),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: customHeader(
              context,
              'Panduan Izin Lokasi',
              isBack: true,
              colorTitle: Color(blackColor),
              colorBack: Color(primaryColor),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(redColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_off_outlined, color: Color(whiteColor)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Akses lokasi belum diizinkan. Aktifkan izin lokasi pada browser Anda terlebih dahulu agar proses Clock In, Check In dan Clock Out dapat berjalan dengan lancar.',
                            style: const TextStyle(fontSize: 14, color: Color(whiteColor)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _platformSelector(),
                  const SizedBox(height: 24),
                  _guideContent(),
                  const SizedBox(height: 4),
                  const Text(
                    'Setelah semua langkah selesai, tutup dan buka kembali halaman ini.',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Mengerti'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
