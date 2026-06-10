import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/office_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_state.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_pdf/attendance_pdf_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_pdf/attendance_pdf_state.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/data/models/permissions_model.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/web_download.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../data/arguments/attandance_args.dart';

class AttandancePage extends StatefulWidget {
  final int? initialTab;
  const AttandancePage({super.key, this.initialTab});

  @override
  State<AttandancePage> createState() => _AttandancePageState();
}

class _AttandancePageState extends State<AttandancePage> {
  late PageController _pageController;
  final double officeLat =  -6.1416575;
  final double officeLng = 106.8659419;
  final double radiusMeter = 1050;

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  late ScrollController _scrollController;

  int selectedIndex = 0;
  String selectedMenu ='activity';
  String? _address;
  bool _isProcessing = false;
  bool _isCameraOpening = false;
  bool _attendanceLogLoaded = false;
  DateTime? _lastGeocodeTime;
  bool _hasSetInitialTab = false;
  bool _isButtonPinned = false;
  // Attendance Log filter
  List<int>? _attendanceOwnerIds;
  String? _attendanceStartDate;
  String? _attendanceEndDate;
  String? _attendanceDateLabel;

  // Activity Log filter
  List<int>? _activityOwnerIds;
  String? _activityStartDate;
  String? _activityEndDate;
  String? _activityDateLabel;


  @override
  void initState() {
    super.initState();

    if (widget.initialTab != null) {
      selectedIndex = widget.initialTab!;
      _hasSetInitialTab = true;
    }

    _pageController = PageController(initialPage: selectedIndex);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      _initLocation();

      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded) {
        final id = profileState.profile.salesPersonId;
        if (id != null) _attendanceOwnerIds = [id];
        if (const ['General Manager', 'Sales Manager']
            .contains(profileState.profile.positionName)) {
          context.read<AttendanceApprovalCubit>().loadBadge();
        }
      }
      _getLog();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final isPinned = _scrollController.position.pixels > 275;
    if (isPinned != _isButtonPinned) {
      setState(() => _isButtonPinned = isPinned);
    }

    final atBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300;
    if (!atBottom) return;

    if (selectedMenu == 'activity') {
      final activityState = context.read<AttendanceActivityBloc>().state;
      if (activityState is! AttendanceActivityLoaded) return;
      if (activityState.activityLoadingMore) return;
      if (activityState.activityPage >= activityState.activityLastPage) return;
      context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
        salesPersonIds: _activityOwnerIds,
        startDate: _activityStartDate,
        endDate: _activityEndDate,
        page: activityState.activityPage + 1,
        isLoadMore: true,
      ));
    } else if (selectedMenu == 'attendance') {
      final attendanceState = context.read<AttendanceBloc>().state;
      if (attendanceState is! AttendanceLoaded) return;
      if (attendanceState.attendanceLoadingMore) return;
      if (attendanceState.attendancePage >= attendanceState.attendanceLastPage) return;
      context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
        salesPersonIds: _attendanceOwnerIds,
        startDate: _attendanceStartDate,
        endDate: _attendanceEndDate,
        page: attendanceState.attendancePage + 1,
        isLoadMore: true,
      ));
    }
  }

  void _onTabChanged(int index) {
    setState(() => selectedIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isApprover(UserProfileEntity profile) {
    if (const ['General Manager', 'Sales Manager'].contains(profile.positionName)) return true;
    if (profile.positionName == 'Sales Supervisor') {
      return !profile.salesRoles.any((r) => const ['General Manager', 'Sales Manager'].contains(r.parent?.positionName));
    }
    return false;
  }

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

  Future<void> _initLocation() async {
    // fromUserGesture: false — saat init, di web kita hanya cek kalau sudah granted
    // Chrome tidak akan munculkan dialog izin kecuali dipicu user gesture
    final hasPermission = await _handleLocationPermission(fromUserGesture: false);
    if (!hasPermission) return;

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
          : const LocationSettings(accuracy: LocationAccuracy.high);
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      return null;
    }
  }


  Future<void> _handleMoveCamera(String title, int flagParam) async {
    if (!mounted || _isCameraOpening) return;
    setState(() => _isCameraOpening = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mohon tunggu, sedang mempersiapkan kamera...'),
        duration: Duration(seconds: 30),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      // Pastikan permission granted — ini dipicu user gesture, Chrome akan munculkan dialog
      final hasPermission = await _handleLocationPermission(fromUserGesture: true);
      if (!hasPermission) {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      // Ambil lokasi — web langsung proceed meski null (stream masih jalan di background)
      final position = await _getCurrentLocationOnce();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi belum terdeteksi, coba lagi"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final officeLocationCubit = context.read<OfficeLocationCubit>();
      await officeLocationCubit.load(force: true);
      if (!mounted) return;
      var officeLocations = officeLocationCubit.state;

      double? nearestDistance;
      double? activeRadius;
      String? nearestOfficeName;
      int? nearestOfficeId;
      String? nearestOfficeLat;
      String? nearestOfficeLng;

      if (officeLocations.isNotEmpty) {
        for (var office in officeLocations) {
          final lat = double.tryParse(office.latitude ?? '');
          final lng = double.tryParse(office.longitude ?? '');
          if (lat != null && lng != null) {
            final d = Geolocator.distanceBetween(
              lat, lng,
              position.latitude, position.longitude,
            );
            if (nearestDistance == null || d < nearestDistance) {
              nearestDistance = d;
              activeRadius = office.radius?.toDouble() ?? radiusMeter;
              nearestOfficeName = office.name;
              nearestOfficeId = office.id;
              nearestOfficeLat = office.latitude;
              nearestOfficeLng = office.longitude;
            }
          }
        }
      }

      final effectiveDistance = nearestDistance ?? Geolocator.distanceBetween(officeLat, officeLng, position.latitude, position.longitude);
      final effectiveRadius = activeRadius ?? radiusMeter;
      final isInRadius = effectiveDistance <= effectiveRadius;

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final result = await context.pushNamed('camera', extra: AttandanceArgs(flag: flagParam, type: title, location: isInRadius ? (nearestOfficeName ?? _address) : _address, time: DateHelper.formatTime(DateTime.now()), locationId: isInRadius ? nearestOfficeId : null, latitude: nearestOfficeLat, longitude: nearestOfficeLng, ), );

      if (result == true) {
        _getLog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: ${cleanErrorMessage(e)}. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCameraOpening = false);
    }
  }

  Future<void> _getLog() async {
    if (_attendanceLogLoaded) {
      context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
        salesPersonIds: _attendanceOwnerIds,
        startDate: _attendanceStartDate,
        endDate: _attendanceEndDate,
      ));
    } else {
      context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
    }
    context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
      salesPersonIds: _activityOwnerIds,
      startDate: _activityStartDate,
      endDate: _activityEndDate,
    ));
  }

  void _showImagePreview(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenSize.width - 20,
                      maxHeight: screenSize.height - 80,
                    ),
                    child: InteractiveViewer(
                      child: DriveImage(
                        url: imageUrls[currentIndex],
                        width: screenSize.width - 20,
                        height: screenSize.height - 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  /// Tombol kiri
                  if (currentIndex > 0)
                    Positioned(
                      left: 10,
                      child: IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          setState(() {
                            currentIndex--;
                          });
                        },
                      ),
                    ),

                  /// Tombol kanan
                  if (currentIndex < imageUrls.length - 1)
                    Positioned(
                      right: 10,
                      child: IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          setState(() {
                            currentIndex++;
                          });
                        },
                      ),
                    ),

                  /// Close
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),

                  /// Indicator
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${imageUrls.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPdfDatePickerDialog() async {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is! ProfileLoaded) return;
    final profile = profileState.profile;

    // Bangun daftar owner
    final List<OwnerDropdownItem> ownerItems = [];
    // Tambahkan diri sendiri hanya jika punya data kehadiran (salesPersonId atau nikNumber)
    if (profile.salesPersonId != null || profile.nikNumber != null) {
      ownerItems.add(OwnerDropdownItem(
        id: profile.salesPersonId,
        name: profile.fullName,
        subtitle: profile.positionName,
      ));
    }
    void addSubs(List<HierarchyNodeEntity> subs) {
      for (final s in subs) {
        ownerItems.add(OwnerDropdownItem(
          id: s.salesPersonId,
          name: s.fullName,
          subtitle: s.positionName,
        ));
        if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
      }
    }
    addSubs(profile.subordinates);

    if (ownerItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data karyawan yang dapat diunduh')),
        );
      }
      return;
    }

    if (ownerItems.length > 1) {
      ownerItems.insert(0, OwnerDropdownItem(id: null, name: 'Semua Karyawan', typeData: 'all'));
    }

    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, 1);
    DateTime endDate = DateTime(now.year, now.month + 1, 0);
    OwnerDropdownItem selectedOwner = ownerItems.first;
    final searchController = TextEditingController();
    String searchQuery = '';
    bool dropdownOpen = false;

    // Helper: compact date button
    Widget dateButton({required String label, required DateTime date, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(DateFormat('dd MMM yy', 'id_ID').format(date), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final filteredItems = searchQuery.isEmpty
              ? ownerItems
              : ownerItems.where((i) => i.name.toLowerCase().contains(searchQuery)).toList();

          return AlertDialog(
            backgroundColor: const Color(whiteColor),
            title: const Text('Download Excel Kehadiran'),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris atas: [filter] | [mulai] | [akhir]
                  Row(
                    children: [
                      if (ownerItems.length > 1) ...[
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => setStateDialog(() => dropdownOpen = !dropdownOpen),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Karyawan', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                        const SizedBox(height: 2),
                                        Text(selectedOwner.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    dropdownOpen ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        flex: 2,
                        child: dateButton(
                          label: 'Mulai',
                          date: startDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(now.year + 1, 12, 31),
                            );
                            if (picked != null) setStateDialog(() => startDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: dateButton(
                          label: 'Akhir',
                          date: endDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(now.year + 1, 12, 31),
                            );
                            if (picked != null) setStateDialog(() => endDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Dropdown list karyawan (expand saat dropdownOpen == true)
                  if (ownerItems.length > 1 && dropdownOpen) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari karyawan...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setStateDialog(() => searchQuery = v.toLowerCase()),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (_, i) {
                          final item = filteredItems[i];
                          final isSelected = selectedOwner.id == item.id && selectedOwner.name == item.name;
                          final color = Theme.of(ctx).colorScheme.primary;
                          return InkWell(
                            onTap: () => setStateDialog(() {
                              selectedOwner = item;
                              dropdownOpen = false;
                              searchController.clear();
                              searchQuery = '';
                            }),
                            child: Container(
                              color: isSelected ? color.withAlpha(25) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        if (item.subtitle != null)
                                          Text(item.subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) Icon(Icons.check, size: 16, color: color),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(whiteColor),
                  foregroundColor: const Color(primaryColor),
                  side: const BorderSide(color: Color(primaryColor)),
                ),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(primaryColor),
                  foregroundColor: const Color(whiteColor),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Download'),
              ),
            ],
          );
        },
      ),
    );

    searchController.dispose();

    if (result == true && mounted) {
      final start = DateFormat('yyyy-MM-dd').format(startDate);
      final end = DateFormat('yyyy-MM-dd').format(endDate);
      final isAll = selectedOwner.typeData == 'all';
      context.read<AttendancePdfCubit>().download(
        salesPersonId: isAll ? null : selectedOwner.id,
        nikNumber: isAll ? null : (selectedOwner.id == null ? profile.nikNumber : null),
        startDate: start,
        endDate: end,
      );
    }
  }

  void _showPdfOptions(BuildContext context, String filePath) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Excel Kehadiran berhasil diunduh',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Simpan ke Penyimpanan'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _savePdfToStorage(filePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Bagikan'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Share.shareXFiles([XFile(filePath)], text: 'Laporan Kehadiran');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPdfOptionsWeb(BuildContext context, Uint8List bytes, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Excel Kehadiran berhasil diunduh',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  downloadPdfOnWeb(bytes, fileName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Buka di Tab Baru'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  openPdfOnWeb(bytes);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePdfToStorage(String tempFilePath) async {
    try {
      final fileName = tempFilePath.split('/').last;
      String savedPath;

      if (Platform.isAndroid) {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        try {
          savedPath = '${publicDownloads.path}/$fileName';
          await File(tempFilePath).copy(savedPath);
        } catch (_) {
          final extDir = await getExternalStorageDirectory();
          if (extDir == null) throw Exception('Penyimpanan tidak tersedia');
          savedPath = '${extDir.path}/$fileName';
          await File(tempFilePath).copy(savedPath);
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savedPath = '${dir.path}/$fileName';
        await File(tempFilePath).copy(savedPath);
      } else {
        throw Exception('Platform tidak didukung');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel disimpan di: $savedPath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${cleanErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(grey11Color),
      body: BlocListener<AttendancePdfCubit, AttendancePdfState>(
        listener: (context, state) async {
          if (state is AttendancePdfLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Mengunduh Excel...'),
                  ],
                ),
                duration: Duration(seconds: 30),
              ),
            );
          } else if (state is AttendancePdfSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showPdfOptions(context, state.filePath);
            context.read<AttendancePdfCubit>().reset();
          } else if (state is AttendancePdfWebSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showPdfOptionsWeb(context, state.bytes, state.fileName);
            context.read<AttendancePdfCubit>().reset();
          } else if (state is AttendancePdfError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            debugPrint('AttendancePdfError: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mengunduh data kehadiran')),
            );
            context.read<AttendancePdfCubit>().reset();
          }
        },
        child: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceLoaded && !_hasSetInitialTab) {
            final now = DateTime.now();
            final today = state.todayData;

            int targetIndex = 0;
            if (now.hour >= 17) {
              targetIndex = 2; // Clock Out
            } else if (today == null || today.clockIn == null) {
              targetIndex = 0; // Clock In
            } else {
              targetIndex = 1; // Check In (Activity)
            }

            setState(() {
              _hasSetInitialTab = true;
            });
            _onTabChanged(targetIndex);
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final isAtasan = profileState is ProfileLoaded && _isApprover(profileState.profile);
                  return ValueListenableBuilder<bool>(
                    valueListenable: context.read<AttendanceApprovalCubit>().hasPendingApproval,
                    builder: (context, hasPending, _) {
                      return customHeader(
                        context,
                        'Attendance',
                        colorBg: Color(primaryColor),
                        colorBack: Color(whiteColor),
                        colorTitle: Color(whiteColor),
                        iconRight: Icons.arrow_back,
                        iconRightOnTap: () => context.go('/'),
                        colorIconRight: Color(whiteColor),
                        iconLeft: isAtasan ? Icons.checklist : null,
                        colorIconLeft: Color(whiteColor),
                        iconLeftOnTap: isAtasan ? () => context.pushNamed('approval') : null,
                        showBadgeLeft: isAtasan && hasPending,
                        iconLeft2: Icons.download,
                        colorIconLeft2: Color(whiteColor),
                        iconLeft2OnTap: _showPdfDatePickerDialog,
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildHeaderProfile(),
                    ),
                    RefreshIndicator(
                      onRefresh: _getLog,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 240,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildFloatingCard(),
                                ],
                              ),
                            ),
                          ),

                          /// BUTTON
                          SliverToBoxAdapter(child: const SizedBox(height: 35)),
                          SliverToBoxAdapter(
                            child: BlocBuilder<AttendanceBloc, AttendanceState>(
                              builder: (context, state) {
                                if (state is AttendanceLoading) {
                                  return buildAttendanceTabButtonShimmer();
                                }
                                return _buildButtonLog();
                              },
                            ),
                          ),
                          // SliverPersistentHeader(
                          //   key: const ValueKey('button_log'),
                          //   pinned: true,
                          //   delegate: _ButtonLogDelegate(_buildButtonLog(), isPinned: _isButtonPinned),
                          // ),
                          /// CONTENT
                          SliverToBoxAdapter(
                            child: selectedMenu == 'activity'
                                ? _buildActivityLog()
                                : _buildAttendanceLog(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    )));
  }

  Widget _buildButtonLog(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
        // MY ACTIVITY
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMenu = 'activity';
                  });
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedMenu == 'activity'
                        ? Colors.blue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedMenu != 'activity'
                        ? Colors.blue
                        : Colors.white,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedMenu == 'activity'
                          ? Colors.white
                          : Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ATTENDANCE LOG
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => selectedMenu = 'attendance');
                  if (!_attendanceLogLoaded) {
                    _attendanceLogLoaded = true;
                    context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
                      salesPersonIds: _attendanceOwnerIds,
                      startDate: _attendanceStartDate,
                      endDate: _attendanceEndDate,
                    ));
                  }
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedMenu == 'attendance'
                        ? Colors.blue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Attendance Log',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedMenu == 'attendance'
                          ? Colors.white
                          : Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
        
        
            
          ],
        ),
      ),
    );
  }

  Widget _filterOwner({bool isMultiSelect = true, String section = 'activity'}) {
    final isAttendance = section == 'attendance';

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final currentIds = isAttendance ? _attendanceOwnerIds : _activityOwnerIds;
        String label = 'Sales';
        final isSelected = currentIds != null && currentIds.isNotEmpty;

        if (isSelected && profileState is ProfileLoaded) {
          final user = profileState.profile;

          String? findName(int? id) {
            if (id == null) return null;
            if (user.salesPersonId == id) return user.fullName;
            HierarchyNodeEntity? found;
            void search(List<HierarchyNodeEntity> nodes) {
              for (var n in nodes) {
                if (n.salesPersonId == id) found = n;
                if (found == null && n.subordinates.isNotEmpty) search(n.subordinates);
              }
            }
            search(user.subordinates);
            return found?.fullName;
          }

          if (currentIds.length == 1) {
            label = findName(currentIds.first) ?? 'Filtered';
          } else {
            label = '${currentIds.length} Owners';
          }
        }

        return CustomFilterButton(
          label: label,
          isSelected: isSelected,
          maxWidth: 130,
          onTap: () async {
            if (profileState is ProfileLoaded) {
              final user = profileState.profile;
              final List<OwnerDropdownItem> ownerItems = [];

              ownerItems.add(OwnerDropdownItem(
                id: user.salesPersonId,
                name: user.fullName,
                subtitle: user.positionName,
              ));

              void addSubs(List<HierarchyNodeEntity> subs) {
                for (var s in subs) {
                  ownerItems.add(OwnerDropdownItem(
                    id: s.salesPersonId,
                    name: s.fullName,
                    subtitle: s.positionName,
                  ));
                  if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
                }
              }
              addSubs(user.subordinates);

              final currentIds = isAttendance ? _attendanceOwnerIds : _activityOwnerIds;
              final result = await context.pushNamed(
                'detailContactDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih Owner',
                  items: ownerItems,
                  selectedIds: isMultiSelect ? currentIds : null,
                  selectedId: !isMultiSelect ? currentIds?.firstOrNull : null,
                  isMultiSelect: isMultiSelect,
                  allowClear: !isMultiSelect,
                ),
              );

              if (result != null) {
                final List<OwnerDropdownItem> selected;
                if (result is List<OwnerDropdownItem>) {
                  selected = result;
                } else {
                  selected = [result as OwnerDropdownItem];
                }
                final newIds = selected.map((e) => e.id!).toList();
                final ids = newIds.isNotEmpty ? newIds : null;

                setState(() {
                  if (isAttendance) {
                    _attendanceOwnerIds = ids;
                  } else {
                    _activityOwnerIds = ids;
                  }
                });

                if (isAttendance) {
                  _attendanceLogLoaded = true;
                  context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
                    salesPersonIds: _attendanceOwnerIds,
                    startDate: _attendanceStartDate,
                    endDate: _attendanceEndDate,
                  ));
                } else {
                  context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
                    salesPersonIds: _activityOwnerIds,
                    startDate: _activityStartDate,
                    endDate: _activityEndDate,
                  ));
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _filterDate({String section = 'activity'}) {
    final isAttendance = section == 'attendance';
    final startDate = isAttendance ? _attendanceStartDate : _activityStartDate;
    final endDate = isAttendance ? _attendanceEndDate : _activityEndDate;
    final dateLabel = isAttendance ? _attendanceDateLabel : _activityDateLabel;

    final isSelected = startDate != null && endDate != null;
    String label = 'Date';
    if (isSelected) {
      if (dateLabel != null) {
        label = dateLabel;
      } else {
        final start = DateTime.tryParse(startDate);
        final end = DateTime.tryParse(endDate);
        if (start != null && end != null) {
          label = '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
        }
      }
    }

    return CustomFilterButton(
      label: label,
      isSelected: isSelected,
      onTap: () async {
        final result = await context.pushNamed<DateFilterResult>(
          'dateFilter',
          extra: {
            'label': dateLabel,
            'startDate': startDate,
            'endDate': endDate,
          },
        );

        if (result != null) {
          if (result.isClear) {
            setState(() {
              if (isAttendance) {
                _attendanceStartDate = null;
                _attendanceEndDate = null;
                _attendanceDateLabel = null;
              } else {
                _activityStartDate = null;
                _activityEndDate = null;
                _activityDateLabel = null;
              }
            });
          } else {
            setState(() {
              if (isAttendance) {
                _attendanceStartDate = result.startDate;
                _attendanceEndDate = result.endDate;
                _attendanceDateLabel = result.label;
              } else {
                _activityStartDate = result.startDate;
                _activityEndDate = result.endDate;
                _activityDateLabel = result.label;
              }
            });
          }
          if (isAttendance) {
            _attendanceLogLoaded = true;
            context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
              salesPersonIds: _attendanceOwnerIds,
              startDate: _attendanceStartDate,
              endDate: _attendanceEndDate,
            ));
          } else {
            context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
              salesPersonIds: _activityOwnerIds,
              startDate: _activityStartDate,
              endDate: _activityEndDate,
            ));
          }
        }
      },
    );
  }

  Widget _buildAttendanceLog() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLogHeaderShimmer(),
                const SizedBox(height: 5),
                buildAttendanceShimmer(),
              ],
            );
          }

          Widget content = const SizedBox();
          if (state is AttendanceLoaded) {
            final data = state.data;
            if (data.isEmpty) {
              content = Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "Tidak ada data attendance",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              );
            } else {
              content = Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: data.length,
                    itemBuilder: (_, i) => RepaintBoundary(child: _buildCardAttendance(data[i])),
                  ),
                  if (state.attendanceLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Attendance Log", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _filterOwner(isMultiSelect: false, section: 'attendance'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 5),
              content,
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityLog() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(grey11Color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AttendanceActivityBloc, AttendanceActivityState>(
            builder: (context, state) {
              if (state is AttendanceActivityLoading) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLogHeaderShimmer(),
                    const SizedBox(height: 5),
                    buildActivityLogShimmer(),
                  ],
                );
              }

              Widget content = const SizedBox();
              if (state is AttendanceActivityLoaded) {
                // Flatten each ActivityEntity into one entry per type
                final profileState = context.read<ProfileBloc>().state;
                final isAtasan = profileState is ProfileLoaded && _isApprover(profileState.profile);
                final currentSalesPersonId = profileState is ProfileLoaded ? profileState.profile.salesPersonId : null;

                final List<({String fullName, String? photoUrl, String date, String type, Color typeColor, String? datetime, String? location, String? contactName, String? note, List<String> images, int? statusValidasi, String? noteValidasi, int? logId, int salesPersonId})> entries = [];

                for (final item in state.activityLogs) {
                  if (item.clockInDate != null) {
                    entries.add((fullName: item.fullName, photoUrl: item.photoUrl, date: item.date, type: 'Clock In', typeColor: const Color(0xFF27AE60), datetime: item.clockInDate, location: item.clockInLocation, contactName: null, note: item.clockInNote, images: item.clockInAttachment ?? [], statusValidasi: null, noteValidasi: null, logId: null, salesPersonId: item.salesPersonId));
                  }
                  if (item.clockOutDate != null) {
                    entries.add((fullName: item.fullName, photoUrl: item.photoUrl, date: item.date, type: 'Clock Out', typeColor: const Color(0xFFE74C3C), datetime: item.clockOutDate, location: item.clockOutLocation, contactName: null, note: item.clockOutNote, images: item.clockOutAttachment ?? [], statusValidasi: null, noteValidasi: null, logId: null, salesPersonId: item.salesPersonId));
                  }
                  for (final c in item.checkIns) {
                    if (c.checkInDate != null) {
                      entries.add((fullName: item.fullName, photoUrl: item.photoUrl, date: item.date, type: 'Check In', typeColor: const Color(0xFF2980B9), datetime: c.checkInDate, location: c.checkInLocation, contactName: null, note: c.checkInNote, images: c.checkInAttachment ?? [], statusValidasi: c.statusValidasi, noteValidasi: c.noteValidasi, logId: c.logId, salesPersonId: item.salesPersonId));
                    }
                  }
                  for (final v in item.visits) {
                    if (v.datetime != null) {
                      entries.add((fullName: item.fullName, photoUrl: item.photoUrl, date: item.date, type: 'Visit', typeColor: const Color(0xFFE67E22), datetime: v.datetime, location: v.lastProject, contactName: v.contactName, note: v.note, images: v.attachment ?? [], statusValidasi: null, noteValidasi: null, logId: null, salesPersonId: item.salesPersonId));
                    }
                  }
                }

                entries.sort((a, b) {
                  final dateCmp = b.date.compareTo(a.date);
                  if (dateCmp != 0) return dateCmp;
                  final aDt = a.datetime != null ? DateTime.tryParse(a.datetime!) : null;
                  final bDt = b.datetime != null ? DateTime.tryParse(b.datetime!) : null;
                  if (aDt == null && bDt == null) return 0;
                  if (aDt == null) return 1;
                  if (bDt == null) return -1;
                  return bDt.compareTo(aDt);
                });

                if (entries.isEmpty) {
                  content = const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Tidak ada data aktivitas')),
                  );
                } else {
                  // Group by date
                  final Map<String, List<({String fullName, String? photoUrl, String date, String type, Color typeColor, String? datetime, String? location, String? contactName, String? note, List<String> images, int? statusValidasi, String? noteValidasi, int? logId, int salesPersonId})>> grouped = {};
                  for (final e in entries) {
                    grouped.putIfAbsent(e.date, () => []).add(e);
                  }
                  final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  content = ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: dates.length,
                    itemBuilder: (_, i) {
                      final date = dates[i];
                      final items = grouped[date]!;
                      final parsedDate = DateTime.tryParse(date);
                      final dateLabel = parsedDate != null
                          ? DateHelper.formatToIndonesian(parsedDate)
                          : date;
                      return RepaintBoundary(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 10),
                              child: Text(
                                dateLabel,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...items.map((e) => _buildCardActivityNew(
                              fullName: e.fullName,
                              photoUrl: e.photoUrl,
                              type: e.type,
                              typeColor: e.typeColor,
                              datetime: e.datetime,
                              location: e.location,
                              contactName: e.contactName,
                              note: e.note,
                              images: e.images,
                              statusValidasi: e.statusValidasi,
                              noteValidasi: e.noteValidasi,
                              logId: e.logId,
                              isAtasan: isAtasan,
                              isSelf: currentSalesPersonId != null && e.salesPersonId == currentSalesPersonId,
                            )),
                          ],
                        ),
                      );
                    },
                  );
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Activity", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _filterOwner(isMultiSelect: true, section: 'activity'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  content,
                ],
              );
            },
          ),
          BlocBuilder<AttendanceActivityBloc, AttendanceActivityState>(
            builder: (context, state) {
              if (state is AttendanceActivityLoaded && state.activityLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardActivityNew({
    required String fullName,
    String? photoUrl,
    required String type,
    required Color typeColor,
    required String? datetime,
    required String? location,
    required String? contactName,
    required String? note,
    required List<String> images,
    int? statusValidasi,
    String? noteValidasi,
    int? logId,
    bool isAtasan = false,
    bool isSelf = false,
  }) {
    return _ActivityCard(
      fullName: fullName,
      photoUrl: photoUrl,
      type: type,
      typeColor: typeColor,
      datetime: datetime,
      location: location,
      contactName: contactName,
      note: note,
      images: images,
      statusValidasi: statusValidasi,
      noteValidasi: noteValidasi,
      logId: logId,
      isAtasan: isAtasan,
      isSelf: isSelf,
      onValidated: _getLog,
      onImageTap: (url) => _showActivityDetailDialog(
        tappedUrl: url,
        allImages: images,
        datetime: datetime,
        location: location,
        note: note,
        contactName: contactName,
        type: type,
      ),
    );
  }

  void _showActivityDetailDialog({
    required String tappedUrl,
    required List<String> allImages,
    String? datetime,
    String? location,
    String? note,
    String? contactName,
    String? type,
  }) {
   
    // Index gambar yang ditap — untuk sorot di thumbnail strip
    int selectedIndex = allImages.indexOf(tappedUrl);
    if (selectedIndex < 0) selectedIndex = 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentUrl = allImages[selectedIndex];
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.85,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gambar utama — klik untuk fullscreen
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DriveImage(
                              url: currentUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              onTap: () => _showImagePreview(context, allImages, selectedIndex),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _showImagePreview(context, allImages, selectedIndex),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Thumbnail strip kalau lebih dari 1 gambar
                      if (allImages.length > 1) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allImages.length,
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => setDialogState(() => selectedIndex = i),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: i == selectedIndex ? Color(primaryColor) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: DriveImage(url: allImages[i], width: 52, height: 52, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (type != null)
                                _buildInfoRow(Icons.local_activity, type, Color(primaryColor)),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.access_time_filled, datetime != null ? DateHelper.formatTime(DateTime.parse(datetime)) : '-', Color(greenPercentColor)),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.calendar_today, datetime != null ? DateHelper.formatDate(DateTime.parse(datetime)) : '-', Color(primaryColor)),
                              if (location != null && location.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(Icons.map, location, Color(primaryColor)),
                              ],
                              if (contactName != null && contactName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(Icons.person, contactName, Color(primaryColor)),
                              ],
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(Icons.notes, note, Color(primaryColor)),
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardAttendance(AttendanceEntity item) {
    final date = DateTime.parse(item.date);
    final bool pendingIn = item.clockIn != null && (item.needsApproval0 ?? false) && item.isApprove0 == null && item.isReject0 == null;
    final bool pendingOut = item.clockOut != null && (item.needsApproval1 ?? false) && item.isApprove1 == null && item.isReject1 == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
          color: Colors.transparent,

        child: Row(
          children: [

            /// DATE
            Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                color: Color(grey9Color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${date.day}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// CLOCK IN
            Expanded(
              child: GestureDetector(
                onTap: (!pendingIn && item.clockIn != null) ? () => _showAttendanceDialog(item, 0) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Color(greenPercentColor)),
                    const SizedBox(height: 2),
                    if (pendingIn) ...[
                      const Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      _buildPendingLabel(),
                    ] else ...[
                      Text(item.clockIn != null ? DateHelper.formatTime(DateTime.parse(item.clockIn!)) : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      if (item.isApprove0 == 1)
                        _buildStatusDot(true)
                      else if (item.isReject0 == 1)
                        _buildStatusDot(false),
                    ],
                  ],
                ),
              ),
            ),

            Container(width: 1, height: 40, color: Color(grey9Color)),

            /// CLOCK OUT
            Expanded(
              child: GestureDetector(
                onTap: (!pendingOut && item.clockOut != null) ? () => _showAttendanceDialog(item, 1) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Color(redPeriodColor)),
                    const SizedBox(height: 2),
                    if (pendingOut) ...[
                      const Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      _buildPendingLabel(),
                    ] else ...[
                      Text(item.clockOut != null ? DateHelper.formatTime(DateTime.parse(item.clockOut!)) : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      if (item.isApprove1 == 1)
                        _buildStatusDot(true)
                      else if (item.isReject1 == 1)
                        _buildStatusDot(false),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLabel() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusDot(bool isApproved) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isApproved ? 'Approved' : 'Rejected',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCardAktivity(AttendanceEntity item) {
    final images = item.fileAttchment6 ?? [];

    return StatefulBuilder(
      builder: (context, setStateSB) {
        final ScrollController scrollController = ScrollController();

        bool isAtStart = true;
        bool isAtEnd = false;

        void updateScrollState() {
          if (!scrollController.hasClients) return;

          final maxScroll = scrollController.position.maxScrollExtent;
          final offset = scrollController.offset;

          setStateSB(() {
            isAtStart = offset <= 0;
            isAtEnd = offset >= maxScroll;
          });
        }

        scrollController.addListener(updateScrollState);

        return Container(
          margin: const EdgeInsets.only(bottom: 30),
          decoration: BoxDecoration(
            color: const Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(purpleColor),
                      width: 5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(primaryColor),
                            shape: BoxShape.circle
                          ),
                          child: Center(
                            child: Text(
                              getInitials(item.fullName??''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(whiteColor)
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fullName??'',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 180,
                              child: Text(item.location6 ?? '',maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11),)),
                          ],
                        ),
                      ],
                    ),
                    
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text(item.checkInActivity != null && item.checkInActivity!.isNotEmpty? DateFormat('dd/MM/yyyy').format(DateTime.parse(item.checkInActivity!)): '-',style: const TextStyle(fontSize: 11)),
                      Text(item.checkInActivity != null && item.checkInActivity!.isNotEmpty? DateFormat('hh:mm').format(DateTime.parse(item.checkInActivity!)): '-',style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  ],
                ),
              ),

              const SizedBox(height: 5),
              Text(
                item.note6 ?? '',
                style: TextStyle(fontWeight: FontWeight.w100),
              ),
              const SizedBox(height: 10),
              /// ================= IMAGES =================
              if (images.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DriveImage(
                                url: images[index],
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                onTap: () => _showImagePreview(context, images, index),
                              ),
                            ),
                          );
                        },
                      ),

                      /// ================= LEFT ARROW =================
                      if (images.length > 1 && !isAtStart)
                        Positioned(
                          left: 5,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                final newOffset =(scrollController.offset - 250).clamp(0.0,scrollController.position.maxScrollExtent,);
                                scrollController.animateTo(newOffset,duration: const Duration(milliseconds: 250),curve: Curves.easeInOut,);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      /// ================= RIGHT ARROW =================
                      if (images.length > 1 && !isAtEnd)
                        Positioned(
                          right: 5,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                final newOffset = (scrollController.offset + 250).clamp(0.0,scrollController.position.maxScrollExtent,);
                                scrollController.animateTo(newOffset,duration: const Duration(milliseconds: 250),curve: Curves.easeInOut,);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderProfile() {
    return Container(
      height: 160,
      color: Color(primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard() {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return buildAttendanceFloatingCardShimmer();
            }
            final AttendanceEntity? today = state is AttendanceLoaded ? state.todayData : null;
            return Column(
              children: [
                _buildTabBar(),
                const SizedBox(height: 5),

                _buildPageView(today),
              ],
            );
          },
        ),
      ),
    );
  }



  Widget _buildTabBar() {
    const double height = 45;
    final tabs = ["Clock In", "Check In", "Clock Out"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double overlap = 25;
            final tabWidth = (constraints.maxWidth + (tabs.length - 1) * overlap) / tabs.length;

            final page = _pageController.hasClients? (_pageController.page ?? 0): selectedIndex.toDouble();

            List<int> order = [0, 1, 2];
            order.sort((a, b) {
              return (b - page).abs().compareTo((a - page).abs());
            });

            return Stack(
              children: order.map((index) {
                return _buildStackTab(
                  index: index,
                  left: index * (tabWidth - overlap),
                  tabWidth: tabWidth,
                  height: height,
                  tabs: tabs,
                  page: page,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }


  Widget _buildStackTab({required int index,required double left,required double tabWidth,required double height,required List<String> tabs,required double page,}) {
    final isActive = (page - index).abs() < 0.5;

    return Positioned(
      left: left,
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: tabWidth,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive? Color(primaryColor): Colors.transparent,
           borderRadius: BorderRadius.circular(height / 2),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ] : [],
          ),
          child: Text(
            tabs[index],
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildPageView(AttendanceEntity? today) {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => selectedIndex = index);
        },
        children: [
          _buildClockIn(today),
          _buildCheckInActivity(today),
          _buildClockOut(today),
        ],
      ),
    );
  }


  bool _hasAttendancePermission(int flagParam) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! PermissionsLoaded) return true;
    final permissions = authState.data as PermissionsModel;

    String? featureName;
    if (flagParam == 0) featureName = 'ClockInOffice';
    else if (flagParam == 1) featureName = 'ClockOutOffice';
    else if (flagParam == 6) featureName = 'ClockInPameran';
    if (featureName == null) return true;

    for (final software in permissions.permissions) {
      for (final module in software.modules) {
        for (final form in module.forms) {
          if (form.formName == 'Attendance') {
            for (final feature in form.features) {
              if (feature.featureName == featureName) return feature.active;
            }
          }
        }
      }
    }
    return true;
  }

  Widget _buildCheckInActivity(AttendanceEntity? today) {
    return Column(
      children: [
        _buildCheckForm(
          title: "Check In",
          flagParam: 6,
          image: (today?.fileAttchment6 != null && today!.fileAttchment6!.isNotEmpty)? today.fileAttchment6!.first: null,
          attendance: today,
        ),
      ],
    );
  }

  Widget _buildCheckForm({
    required String title,
    required int flagParam,
    String? image,
    AttendanceEntity? attendance,
    int? isApprove,
    int? isReject,
    bool needsApproval = false,
    String? approveName,
    String? rejectName,
  }) {
    final bool hasPermission = _hasAttendancePermission(flagParam);
    // Build status badge based on new logic
    Widget? statusBadge;
    if (needsApproval) {
      final Color badgeColor;
      final IconData badgeIcon;
      final String badgeLabel;
      if (isApprove == 1) {
        badgeColor = const Color(0xFF27AE60);
        badgeIcon = Icons.check_circle_outline;
        badgeLabel = 'Approved';
      } else if (isReject == 1) {
        badgeColor = const Color(0xFFE74C3C);
        badgeIcon = Icons.cancel_outlined;
        badgeLabel = 'Rejected';
      } else {
        badgeColor = Colors.orange;
        badgeIcon = Icons.hourglass_top_rounded;
        badgeLabel = 'Pending';
      }
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(badgeLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    }

    final raw = flagParam == 0 ? attendance?.clockIn : flagParam == 1 ? attendance?.clockOut : attendance?.checkInActivity;
    final dt = raw != null ? DateTime.tryParse(raw) : null;

    return Expanded(
      child: image != null && flagParam != 6
          ? GestureDetector(
              onTap: () { if (attendance != null) _showAttendanceDialog(attendance, flagParam); },
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 5),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DriveImage(
                      url: image,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    top: 123,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Color(blue2Color).withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.access_time_filled, color: flagParam == 0 ? Color(greenPercentColor) : Color(redPeriodColor), size: 10),
                            const SizedBox(width: 6),
                            Text(dt != null ? DateHelper.formatTime(dt) : '-', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ]),
                          Row(children: [
                            Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 10),
                            const SizedBox(width: 6),
                            Text(dt != null ? DateHelper.formatDate(dt) : DateHelper.formatDate(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ]),
                          Row(children: [
                            Icon(Icons.location_on, color: Color(primaryColor), size: 10),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 150,
                              child: Text(
                                '${flagParam == 0 ? attendance?.location0 : attendance?.location1}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  if (statusBadge != null)
                    Positioned(top: 8, left: 8, child: statusBadge),
                   if (isReject == 1) ...[
                       Positioned(top: 8, right: 8, child: GestureDetector(
                          onTap: () {
                            if (_isCameraOpening) return;
                            if (!hasPermission) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Anda tidak punya akses untuk fitur ini'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ));
                              return;
                            }
                            _handleMoveCamera(title, flagParam);
                          },
                         child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(primaryColor),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.refresh, size: 18, color: Colors.white),
                         ),
                       )),
                      ],
                ],
              ),
            ),
            )
          : SingleChildScrollView(
              reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateHelper.formatTime(DateTime.now()), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(fontSize: 11, color: Color(grey6Color))),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () {
                    if (_isCameraOpening) return;
                    if (!hasPermission) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Anda tidak punya akses untuk fitur ini'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    _handleMoveCamera(title, flagParam);
                  },
                      child: Container(
                        height: 90, width: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color(primaryColor).withValues(alpha: 0.1)),
                        child: Container(
                          height: 80, width: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(primaryColor).withValues(alpha: 0.2)),
                          child: Container(
                            height: 70, width: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Color((_isCameraOpening || !hasPermission) ? grey6Color : primaryColor)),
                            child: _isCameraOpening
                                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(whiteColor))),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Please $title!", style: TextStyle(fontSize: 12, color: Color(grey6Color))),
                ],
              ),
            ),
    );
  }  

  Widget _buildClockOut(AttendanceEntity? today) {
    return Column(
      children: [
        _buildCheckForm(
          title: "Clock Out",
          flagParam: 1,
          image: (today?.fileAttchment1 != null && today!.fileAttchment1!.isNotEmpty)? today.fileAttchment1!.last: null,
          attendance: today,
          isApprove: today?.isApprove1,
          isReject: today?.isReject1,
          needsApproval: today?.needsApproval1 ?? false,
          approveName: today?.approveName1,
          rejectName: today?.rejectName1,
        ),
      ],
    );
  }

  Widget _buildClockIn(AttendanceEntity? today) {
    return Column(
      children: [
        

        _buildCheckForm(
          title: "Clock In",
          flagParam: 0,
          image: (today?.fileAttchment0 != null && today!.fileAttchment0!.isNotEmpty)? today.fileAttchment0!.first: null,
          attendance: today,
          isApprove: today?.isApprove0,
          isReject: today?.isReject0,
          needsApproval: today?.needsApproval0 ?? false,
          approveName: today?.approveName0,
          rejectName: today?.rejectName0,
        ),
      ],
    );
  }


    
  void _showAttendanceDialog(AttendanceEntity item, int flag) {
    final String timeValue = flag == 0 ? item.clockIn ?? "-" : item.clockOut ?? "-";
    final List<String>? images =flag == 0 ? item.fileAttchment0 : item.fileAttchment1;
    final String note = flag == 0 ? item.note0 ?? "-" : item.note1 ?? "-";
    final String location =flag == 0 ? item.location0 ?? "-" : item.location1 ?? "-";
    final int? isApprove = flag == 0 ? item.isApprove0 : item.isApprove1;
    final int? isReject = flag == 0 ? item.isReject0 : item.isReject1;
    final String? approveName = flag == 0 ? item.approveName0 : item.approveName1;
    final String? rejectName = flag == 0 ? item.rejectName0 : item.rejectName1;

    final String displayTime = (timeValue != '-') ? DateHelper.formatTime(DateTime.parse(timeValue)) : '-';
    final String? displayImage =  (images != null && images.isNotEmpty)       ? (flag == 0 ? images.first : images.last)       : null;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: displayImage != null
                            ? DriveImage(
                                url: displayImage,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                onTap: () => _showImagePreview(context, images!, flag == 0 ? 0 : images.length - 1),
                              )
                            : Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 50),
                              ),
                      ),
                      if (displayImage != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _showImagePreview(context, images!, flag == 0 ? 0 : images.length - 1),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time_filled,
                    displayTime,
                    Color(flag == 0 ? greenPercentColor : redPeriodColor),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateHelper.formatDate(DateTime.parse(item.date)),
                    Color(primaryColor),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.map,
                    location,
                    Color(primaryColor),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.notes,
                    note,
                    Color(primaryColor),
                  ),
                  if (isApprove == 1 || isReject == 1) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      isApprove == 1 ? Icons.check_circle : Icons.cancel,
                      isApprove == 1
                          ? 'Approved${approveName != null ? ' by $approveName' : ''}'
                          : 'Rejected${rejectName != null ? ' by $rejectName' : ''}',
                      isApprove == 1 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatefulWidget {
  final String fullName;
  final String? photoUrl;
  final String type;
  final Color typeColor;
  final String? datetime;
  final String? location;
  final String? contactName;
  final String? note;
  final List<String> images;
  final void Function(String url) onImageTap;
  final int? statusValidasi;
  final String? noteValidasi;
  final int? logId;
  final bool isAtasan;
  final bool isSelf;
  final VoidCallback? onValidated;

  const _ActivityCard({
    required this.fullName,
    this.photoUrl,
    required this.type,
    required this.typeColor,
    required this.datetime,
    required this.location,
    required this.contactName,
    required this.note,
    required this.images,
    required this.onImageTap,
    this.statusValidasi,
    this.noteValidasi,
    this.logId,
    this.isAtasan = false,
    this.isSelf = false,
    this.onValidated,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late final ScrollController _scrollController;
  bool _isAtStart = true;
  bool _isAtEnd = false;
  bool _photoError = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollState);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    setState(() {
      _isAtStart = offset <= 0;
      _isAtEnd = offset >= maxScroll;
    });
  }

  void _showNoteValidasiDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alasan Invalid'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(hintText: 'Masukkan catatan validasi...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AttendanceActivityBloc>().add(
                ValidasiCheckInEvent(
                  logId: widget.logId!,
                  statusValidasi: 0,
                  noteValidasi: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                ),
              );
              widget.onValidated?.call();
            },
            child: const Text('Kirim', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  Widget _buildValidasiBottom() {
    if (widget.statusValidasi == 1) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thumb_up_rounded, color: Color(0xFF27AE60), size: 18),
        ],
      );
    } else if (widget.statusValidasi == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_down_rounded, color: Color(0xFFE74C3C), size: 18),
            ],
          ),
          if (widget.noteValidasi != null && widget.noteValidasi!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.noteValidasi!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    } else {
      if (widget.isSelf || widget.logId == null) return const SizedBox();
      if (!widget.isAtasan) {
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
            SizedBox(width: 6),
            Text('Menunggu validasi', style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showNoteValidasiDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE74C3C)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thumb_down_rounded, color: Color(0xFFE74C3C), size: 16),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              context.read<AttendanceActivityBloc>().add(
                ValidasiCheckInEvent(logId: widget.logId!, statusValidasi: 1),
              );
              widget.onValidated?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(purpleColor), width: 5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      () {
                        final url = widget.photoUrl;
                        final validUrl = url != null && url.startsWith('http');
                        if (validUrl && !_photoError) {
                          return CircleAvatar(
                            radius: 22.5,
                            backgroundColor: Color(primaryColor),
                            backgroundImage: NetworkImage(url),
                            onBackgroundImageError: (_, __) {
                              if (mounted) setState(() => _photoError = true);
                            },
                          );
                        }
                        return CircleAvatar(
                          radius: 22.5,
                          backgroundColor: Color(primaryColor),
                          child: Text(
                            getInitials(widget.fullName),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(whiteColor)),
                          ),
                        );
                      }(),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(widget.location ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                            if (widget.contactName != null && widget.contactName!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 11, color: Color(0xFFE67E22)),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(widget.contactName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFFE67E22))),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateHelper.formatTime(DateTime.parse(widget.datetime!)), style: const TextStyle(fontSize: 10)),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: widget.typeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(widget.type, style: TextStyle(fontSize: 10, color: widget.typeColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(widget.note ?? '', style: const TextStyle(fontWeight: FontWeight.w100)),
          const SizedBox(height: 10),
          if (widget.images.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final imageWidth = widget.images.length == 1 ? availableWidth : 200.0;
                return SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DriveImage(
                                url: widget.images[index],
                                width: imageWidth,
                                height: 200,
                                fit: BoxFit.cover,
                                onTap: () => widget.onImageTap(widget.images[index]),
                                errorWidget: Container(
                                  width: imageWidth,
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  if (widget.images.length > 1 && !_isAtStart)
                    Positioned(
                      left: 5, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            final newOffset = (_scrollController.offset - 250).clamp(0.0, _scrollController.position.maxScrollExtent);
                            _scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  if (widget.images.length > 1 && !_isAtEnd)
                    Positioned(
                      right: 5, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            final newOffset = (_scrollController.offset + 250).clamp(0.0, _scrollController.position.maxScrollExtent);
                            _scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
          if (widget.type == 'Check In') ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildValidasiBottom(),
          ],
        ],
      ),
    );
  }
}

class _ButtonLogDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isPinned;
  static const double _height = 76.0;

  _ButtonLogDelegate(this.child, {this.isPinned = false});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1),
      color:  Colors.transparent,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(_ButtonLogDelegate oldDelegate) =>
      oldDelegate.isPinned != isPinned || oldDelegate.child != child;
}