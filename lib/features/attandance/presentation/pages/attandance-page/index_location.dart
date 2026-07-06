// Geolocation mixin for AttandancePage — part of the same library as index.dart
// so private identifiers (_xxx) are shared across the two files.
// Imports are inherited from index.dart (part files don't declare their own imports).
part of 'index.dart';

mixin AttendanceLocationMixin<T extends StatefulWidget> on State<T> {
  // ── State ────────────────────────────────────────────────────────────────────
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  String? _address;
  bool _isProcessing = false;
  // Dicek independen per tipe — user bisa berada di dalam radius Office
  // DAN Pameran sekaligus (radius overlap), jadi keduanya harus dievaluasi
  // sendiri-sendiri terhadap izinnya masing-masing, bukan cuma ambil satu
  // lokasi "pemenang" lalu cek izin tipe itu doang.
  bool _inOfficeRadius = false;
  bool _inPameranRadius = false;
  bool _locationResolved = false;
  DateTime? _lastGeocodeTime;
  final double radiusMeter = 1050;

  // ── Abstract — implemented by _AttandancePageState ────────────────────────────
  void _trySetInitialTab();

  // ── Shared ────────────────────────────────────────────────────────────────────
 

  void _computeNearestLocation(Position position) {
    if (!mounted) return;
    final officeLocations = context.read<OfficeLocationCubit>().state;
    if (officeLocations.isEmpty) {
      if (mounted) {
        setState(() {
          _inOfficeRadius = false;
          _inPameranRadius = false;
          _locationResolved = true;
        });
        _trySetInitialTab();
      }
      return;
    }

    bool inOfficeRadius = false;
    bool inPameranRadius = false;

    for (var office in officeLocations) {
      final lat = double.tryParse(office.latitude ?? '');
      final lng = double.tryParse(office.longitude ?? '');
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween( lat, lng, position.latitude, position.longitude);
      final radius = office.radius?.toDouble() ?? radiusMeter;
      if (d <= radius) {
        if (office.typeLocationId == 2) {
          inPameranRadius = true;
        } else {
          inOfficeRadius = true;
        }
      }
    }

    if (mounted) {
      setState(() {
        _inOfficeRadius = inOfficeRadius;
        _inPameranRadius = inPameranRadius;
        _locationResolved = true;
      });
      _trySetInitialTab();
    }
  }

  bool _isClockButtonDisabled(int flagParam) {
    if (flagParam != 0 && flagParam != 1) return false;
    if (!_locationResolved) return false;

    final bool officeAllowed = _inOfficeRadius &&
        (flagParam == 0
            ? PermissionsHelper.canClockInOffice
            : PermissionsHelper.canClockOutOffice);
    final bool pameranAllowed = _inPameranRadius &&
        (flagParam == 0
            ? PermissionsHelper.canClockInPameran
            : PermissionsHelper.canClockOutPameran);
    // Luar Lokasi = override total: berlaku di mana pun user berada, tidak
    // disyaratkan harus benar-benar di luar radius Office/Pameran dulu.
    final bool luarLokasiAllowed = flagParam == 0
        ? (PermissionsHelper.canClockInLuarLokasi ||
            PermissionsHelper.canClockInLuarLokasiRequestApprove)
        : (PermissionsHelper.canClockOutLuarLokasi ||
            PermissionsHelper.canClockOutLuarLokasiRequestApprove);

    final bool allowed = officeAllowed || pameranAllowed || luarLokasiAllowed;
    debugPrint('[_isClockButtonDisabled] flag=$flagParam -> ${allowed ? "ENABLED" : "DISABLED"} '
        '(officeAllowed=$officeAllowed pameranAllowed=$pameranAllowed luarLokasiAllowed=$luarLokasiAllowed '
        'inOffice=$_inOfficeRadius inPameran=$_inPameranRadius)');
    return !allowed;
  }

  // ── Permission ────────────────────────────────────────────────────────────────
  // Future<bool> _handleLocationPermission({bool fromUserGesture = false}) async {
  //   try {
  //     return await _checkLocationPermission(fromUserGesture: fromUserGesture);
  //   } catch (e) {
  //     // Package geolocator/geolocator_web pernah melempar "Null check operator
  //     // used on a null value" secara internal di WebKit lama (iPhone 6s, iOS 15)
  //     // saat query navigator.permissions — di luar kendali kita untuk benerin
  //     // langsung tanpa fork package. Daripada blokir user total, anggap lolos
  //     // dan biarkan _getCurrentLocationOnce() (yang sudah aman/ada try-catch)
  //     // jadi penentu akhir apakah lokasi benar-benar bisa diambil.
  //     web_debug.logDebugError('_handleLocationPermission gagal (package error, dilewati): $e');
  //     return true;
  //   }
  // }

  // Future<bool> _checkLocationPermission({bool fromUserGesture = false}) async {
  //   final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: const Text('GPS tidak aktif. Aktifkan GPS untuk melanjutkan.'),
  //         backgroundColor: Colors.orange,
  //         action: SnackBarAction(
  //           label: 'Aktifkan',
  //           textColor: Colors.white,
  //           onPressed: () => Geolocator.openLocationSettings(),
  //         ),
  //       ));
  //     }
  //     return false;
  //   }

  //   LocationPermission permission = await Geolocator.checkPermission();

  //   if (permission == LocationPermission.denied) {
  //     // Web: browser tidak munculkan dialog izin kecuali dipicu user gesture
  //     if (!fromUserGesture && kIsWeb) return false;
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text('Izin lokasi ditolak. Izinkan lokasi di pengaturan.'),
  //           backgroundColor: Colors.orange,
  //         ));
  //       }
  //       return false;
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     if (mounted) {
  //       if (kIsWeb) {
  //         showDialog(
  //           context: context,
  //           builder: (ctx) => AlertDialog(
  //             title: const Text('Izin Lokasi Diblokir'),
  //             content: const Text(
  //               'Browser memblokir akses lokasi untuk halaman ini.\n\n'
  //               'Cara mengaktifkan:\n'
  //               '1. Klik ikon 🔒 atau ⓘ di address bar\n'
  //               '2. Pilih "Site settings"\n'
  //               '3. Ubah "Location" ke "Allow"\n'
  //               '4. Refresh halaman',
  //             ),
  //             actions: [
  //               TextButton(
  //                   onPressed: () => Navigator.pop(ctx),
  //                   child: const Text('Mengerti')),
  //             ],
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text(
  //               'Izin lokasi ditolak permanen. Buka settings untuk mengaktifkan.'),
  //           backgroundColor: Colors.red,
  //         ));
  //         await Geolocator.openAppSettings();
  //       }
  //     }
  //     return false;
  //   }

  //   return true;
  // }

  Future<bool> _handleLocationPermission({bool fromUserGesture = false}) async {
    // Di web, isLocationServiceEnabled hanya cek apakah browser support geolocation
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('GPS tidak aktif. Aktifkan GPS untuk melanjutkan.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Aktifkan',
              textColor: Colors.white,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Di web, requestPermission() hanya muncul jika dipanggil saat user gesture.
      // Kalau dipanggil saat init (bukan gesture), Chrome bisa suppress dialog.
      if (!fromUserGesture && kIsWeb) {
        // Jangan request saat init di web — tunggu user klik dulu
        return false;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Izinkan lokasi di browser untuk melanjutkan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        if (kIsWeb) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Izin Lokasi Diblokir'),
              content: const Text(
                'Chrome memblokir akses lokasi untuk halaman ini.\n\n'
                'Cara mengaktifkan:\n'
                '1. Klik ikon 🔒 atau ⓘ di address bar\n'
                '2. Pilih "Site settings"\n'
                '3. Ubah "Location" ke "Allow"\n'
                '4. Refresh halaman',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mengerti'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak permanen. Buka settings untuk mengaktifkan.'),
              backgroundColor: Colors.red,
            ),
          );
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    return true;
  }

  // ── Location stream ───────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    // fromUserGesture: false — saat init, di web kita hanya cek kalau sudah granted
    // Chrome tidak akan munculkan dialog izin kecuali dipicu user gesture

    debugPrint('[PermissionsHelper] canClockInOffice                    : ${PermissionsHelper.canClockInOffice} radius : $_inOfficeRadius');
    debugPrint('[PermissionsHelper] canClockInPameran                   : ${PermissionsHelper.canClockInPameran} radius : $_inPameranRadius');
    debugPrint('[PermissionsHelper] canClockInLuarLokasi                : ${PermissionsHelper.canClockInLuarLokasi}');
    debugPrint('[PermissionsHelper] canClockInLuarLokasiRequestApprove  : ${PermissionsHelper.canClockInLuarLokasiRequestApprove}');
    debugPrint('[PermissionsHelper] canClockOutOffice                   : ${PermissionsHelper.canClockOutOffice} radius : $_inOfficeRadius');
    debugPrint('[PermissionsHelper] canClockOutPameran                  : ${PermissionsHelper.canClockOutPameran} radius : $_inPameranRadius');
    debugPrint('[PermissionsHelper] canClockOutLuarLokasi               : ${PermissionsHelper.canClockOutLuarLokasi}');
    debugPrint('[PermissionsHelper] canClockOutLuarLokasiRequestApprove : ${PermissionsHelper.canClockOutLuarLokasiRequestApprove}');


    final hasPermission = await _handleLocationPermission(fromUserGesture: false);
    if (!hasPermission) {
      if (mounted) {
        setState(() => _locationResolved = true);
        _trySetInitialTab();
      }
      return;
    }

    if (kIsWeb) {
      // Web: browser geolocation API tidak mendukung distanceFilter via stream dengan baik,
      // gunakan getCurrentPosition sekali saat init, lalu stream tanpa filter.
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: WebSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          ),
        );
        if (!mounted) return;
        _currentPosition = position;
        _computeNearestLocation(position);
        await _getAddressFromLatLng(position);
      } catch (e) {
        // ignore
      }
      // Tetap pasang stream untuk update posisi berikutnya di web
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).listen((Position position) async {
        _currentPosition = position;
        _computeNearestLocation(position);
        if (_isProcessing) return;
        _isProcessing = true;
        try {
          if (!mounted) return;
          if (_lastGeocodeTime == null ||
              DateTime.now().difference(_lastGeocodeTime!) > const Duration(seconds: 30)) {
            _lastGeocodeTime = DateTime.now();
            await _getAddressFromLatLng(position);
          }
        } catch (e) {
          // ignore
        } finally {
          _isProcessing = false;
        }
      });
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      _currentPosition = position;
      _computeNearestLocation(position);

      if (_isProcessing) return;
      _isProcessing = true;

      try {
        if (!mounted) return;

        if (_lastGeocodeTime == null ||
            DateTime.now().difference(_lastGeocodeTime!) > const Duration(seconds: 10)) {
          _lastGeocodeTime = DateTime.now();
          await _getAddressFromLatLng(position);
        }
      } catch (e) {
        // ignore
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      if (kIsWeb) {
        // geocoding package tidak support web — pakai Nominatim (OpenStreetMap)
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'lat': position.latitude,
            'lon': position.longitude,
            'format': 'json',
          },
          options: Options(headers: {'Accept-Language': 'id'}),
        );
        final display = response.data['display_name'] as String?;
        if (display != null && mounted) {
          setState(() => _address = display);
        }
        return;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      setState(() {
        _address =
            "${place.street}, ${place.subLocality}, ${place.locality}, "
            "${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        _address = "Alamat tidak ditemukan";
      });
    }
  }

  Future<Position?> _getCurrentLocationOnce() async {
    // Gunakan posisi dari stream jika sudah tersedia — langsung, tanpa delay
    if (_currentPosition != null) return _currentPosition;

    // Fallback: minta sekali. Web pakai WebSettings (timeLimit), mobile pakai LocationSettings.
    try {
      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15), // Tambahkan timeLimit agar tidak loading forever
            );
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      return null;
    }
  }


}
