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
  int? _nearestTypeLocationId;
  bool _nearestIsInRadius = false;
  bool _locationResolved = false;
  DateTime? _lastGeocodeTime;
  final double radiusMeter = 1050;

  // ── Abstract — implemented by _AttandancePageState ────────────────────────────
  void _trySetInitialTab();

  // ── Shared ────────────────────────────────────────────────────────────────────
  bool _isClockButtonDisabled(int flagParam) {
    if (flagParam != 0 && flagParam != 1) return false;
    if (!_locationResolved) return false;
    if (!_nearestIsInRadius) {
      return flagParam == 0
          ? !(PermissionsHelper.canClockInLuarLokasi ||
              PermissionsHelper.canClockInLuarLokasiRequestApprove)
          : !(PermissionsHelper.canClockOutLuarLokasi ||
              PermissionsHelper.canClockOutLuarLokasiRequestApprove);
    }
    if (_nearestTypeLocationId == 2) {
      return flagParam == 0
          ? !PermissionsHelper.canClockInPameran
          : !PermissionsHelper.canClockOutPameran;
    }
    return flagParam == 0
        ? !PermissionsHelper.canClockInOffice
        : !PermissionsHelper.canClockOutOffice;
  }

  void _computeNearestLocation(Position position) {
    if (!mounted) return;
    final officeLocations = context.read<OfficeLocationCubit>().state;
    if (officeLocations.isEmpty) {
      if (mounted) {
        setState(() {
          _nearestTypeLocationId = null;
          _nearestIsInRadius = false;
          _locationResolved = true;
        });
        _trySetInitialTab();
      }
      return;
    }

    double? nearestDistance;
    int? typeId;
    bool inRadius = false;

    for (var office in officeLocations) {
      final lat = double.tryParse(office.latitude ?? '');
      final lng = double.tryParse(office.longitude ?? '');
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(
          lat, lng, position.latitude, position.longitude);
      if (nearestDistance == null || d < nearestDistance) {
        nearestDistance = d;
        typeId = office.typeLocationId;
        final radius = office.radius?.toDouble() ?? radiusMeter;
        inRadius = d <= radius;
      }
    }

    if (mounted) {
      setState(() {
        _nearestTypeLocationId = inRadius ? typeId : null;
        _nearestIsInRadius = inRadius;
        _locationResolved = true;
      });
      _trySetInitialTab();
    }
  }

  // ── Permission ────────────────────────────────────────────────────────────────
  Future<bool> _handleLocationPermission({bool fromUserGesture = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('GPS tidak aktif. Aktifkan GPS untuk melanjutkan.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Aktifkan',
            textColor: Colors.white,
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ));
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Web: browser tidak munculkan dialog izin kecuali dipicu user gesture
      if (!fromUserGesture && kIsWeb) return false;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Izin lokasi ditolak. Izinkan lokasi di pengaturan.'),
            backgroundColor: Colors.orange,
          ));
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
                'Browser memblokir akses lokasi untuk halaman ini.\n\n'
                'Cara mengaktifkan:\n'
                '1. Klik ikon 🔒 atau ⓘ di address bar\n'
                '2. Pilih "Site settings"\n'
                '3. Ubah "Location" ke "Allow"\n'
                '4. Refresh halaman',
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Mengerti')),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Izin lokasi ditolak permanen. Buka settings untuk mengaktifkan.'),
            backgroundColor: Colors.red,
          ));
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    return true;
  }

  // ── Location stream ───────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    final hasPermission = await _handleLocationPermission(fromUserGesture: false);
    if (!hasPermission) {
      if (mounted) {
        setState(() => _locationResolved = true);
        _trySetInitialTab();
      }
      return;
    }

    if (kIsWeb) {
      // Web: satu kali getCurrentPosition, lalu stream tanpa distanceFilter
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
        debugPrint('[Attendance] web _initLocation: $e');
        web_debug.logDebugError('web _initLocation: $e');
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).listen((Position position) async {
        _currentPosition = position;
        _computeNearestLocation(position);
        if (_isProcessing) return;
        _isProcessing = true;
        try {
          if (!mounted) return;
          if (_lastGeocodeTime == null ||
              DateTime.now().difference(_lastGeocodeTime!) >
                  const Duration(seconds: 30)) {
            _lastGeocodeTime = DateTime.now();
            await _getAddressFromLatLng(position);
          }
        } catch (e) {
          debugPrint('[Attendance] web positionStream: $e');
          web_debug.logDebugError('web positionStream: $e');
        } finally {
          _isProcessing = false;
        }
      }, onError: (e) {
        debugPrint('[Attendance] web positionStream error: $e');
      }, cancelOnError: false);
      return;
    }

    // Mobile: stream dengan distanceFilter
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
            DateTime.now().difference(_lastGeocodeTime!) >
                const Duration(seconds: 10)) {
          _lastGeocodeTime = DateTime.now();
          await _getAddressFromLatLng(position);
        }
      } catch (e) {
        debugPrint('[Attendance] mobile positionStream: $e');
        web_debug.logDebugError('mobile positionStream: $e');
      } finally {
        _isProcessing = false;
      }
    }, onError: (e) {
      debugPrint('[Attendance] mobile positionStream error: $e');
    }, cancelOnError: false);
  }

  // ── Reverse geocode ───────────────────────────────────────────────────────────
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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.first;
      if (mounted) {
        setState(() {
          _address =
              '${place.street}, ${place.subLocality}, ${place.locality}, '
              '${place.subAdministrativeArea}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Alamat tidak ditemukan');
    }
  }

  // ── One-shot position ─────────────────────────────────────────────────────────
  Future<Position?> _getCurrentLocationOnce() async {
    if (_currentPosition != null) return _currentPosition;
    try {
      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            );
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      return null;
    }
  }
}
