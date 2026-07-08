part of 'index.dart';

mixin AttendanceLocationMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  String? _address;
  bool _isProcessing = false;
  bool _inOfficeRadius = false;
  bool _inPameranRadius = false;
  bool _locationResolved = false;
  DateTime? _lastGeocodeTime;
  final double radiusMeter = 1050;

  void _trySetInitialTab();

 

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





  Future<bool> _handleLocationPermission({bool fromUserGesture = false}) async {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('GPS tidak aktif. Aktifkan GPS untuk melanjutkan.'),
            backgroundColor: Color(orangeAccentColor),
            action: SnackBarAction(
              label: 'Aktifkan',
              textColor: Color(whiteColor),
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
              if (!fromUserGesture && kIsWeb) {
              return false;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Izinkan lokasi di browser untuk melanjutkan.'),
              backgroundColor: Color(orangeAccentColor),
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
              backgroundColor: Color(redAccentColor),
            ),
          );
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    return true;
  }

  Future<void> _initLocation() async {
    
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
            }
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
            } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      if (kIsWeb) {
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
      if (_currentPosition != null) return _currentPosition;

      try {
      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),            );
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      return null;
    }
  }


}
