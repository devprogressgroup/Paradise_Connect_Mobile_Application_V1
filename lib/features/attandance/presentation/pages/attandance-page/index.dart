import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/pameran_location/pameran_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/office_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_state.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
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
      }
      _getLog();

      context.read<OfficeLocationCubit>().load();
      context.read<PameranLocationCubit>().load();
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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // cek GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS belum aktif'),
        ),
      );
      return false;
    }

    // cek permission
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi ditolak permanen, buka settings'),
        ),
      );

      if (!kIsWeb) await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _initLocation() async {
    final hasPermission = await _handleLocationPermission();
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
        debugPrint('[Location] Web init: ${position.latitude}, ${position.longitude}');
        await _getAddressFromLatLng(position);
      } catch (e) {
        debugPrint('[Location] Web init error: $e');
      }
      // Tetap pasang stream untuk update posisi berikutnya di web
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).listen((Position position) async {
        _currentPosition = position;
        debugPrint('[Location] Web stream update: ${position.latitude}, ${position.longitude}');
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
          debugPrint('[Location] Web geocode error: $e');
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
        debugPrint('[Location] Stream error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
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

    // Fallback: minta sekali. Web pakai WebSettings (timeLimit hanya di web), mobile pakai LocationSettings.
    try {
      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            )
          : const LocationSettings(accuracy: LocationAccuracy.high);
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      debugPrint('[Location] getCurrentPosition error: $e');
      return null;
    }
  }


  Future<void> _handleMoveCamera(String title, int flagParam) async {
    if (!mounted) return;

    // Ambil lokasi
    final position = await _getCurrentLocationOnce();

    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lokasi belum terdeteksi"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final officeLocationCubit = context.read<OfficeLocationCubit>();
    var officeLocations = officeLocationCubit.state;

    // Race condition fix: kalau data belum dimuat, tunggu sebentar
    if (officeLocations.isEmpty) {
      debugPrint('[Attendance] Office locations belum ada, load ulang...');
      await officeLocationCubit.load();
      if (!mounted) return;
      officeLocations = officeLocationCubit.state;
    }

    debugPrint('[Attendance] officeLocations count: ${officeLocations.length}');
    debugPrint('[Attendance] device position: ${position.latitude}, ${position.longitude}');

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
            lat,
            lng,
            position.latitude,
            position.longitude,
          );
          debugPrint('[Attendance] Office "${office.name}" lat:$lat lng:$lng radius:${office.radius} → jarak: ${d.toStringAsFixed(1)}m');

          if (nearestDistance == null || d < nearestDistance) {
            nearestDistance = d;
            activeRadius = office.radius?.toDouble() ?? radiusMeter;
            nearestOfficeName = office.name;
            nearestOfficeId = office.id;
            nearestOfficeLat = office.latitude;
            nearestOfficeLng = office.longitude;
          }
        } else {
          debugPrint('[Attendance] Office "${office.name}" lat/lng invalid: ${office.latitude}, ${office.longitude}');
        }
      }
    }

    final effectiveDistance = nearestDistance ?? Geolocator.distanceBetween( officeLat, officeLng, position.latitude, position.longitude, );
    final effectiveRadius = activeRadius ?? radiusMeter;
    final isInRadius = effectiveDistance <= effectiveRadius;

    debugPrint('[Attendance] nearestOffice: $nearestOfficeName, distance: ${effectiveDistance.toStringAsFixed(1)}m, radius: ${effectiveRadius}m, inRadius: $isInRadius');

    if (!isInRadius && flagParam != 6) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text("Diluar Lokasi"), backgroundColor: Colors.red, ), );
      return;
    }
    final result = await context.pushNamed('camera', extra: AttandanceArgs(flag: flagParam, type: title, location: nearestOfficeName ?? _address, time: DateHelper.formatTime(DateTime.now()), locationId: nearestOfficeId, latitude: nearestOfficeLat, longitude: nearestOfficeLng, ), );

    if (result == true) {
      _getLog();
    }
  }

  Future<void> _getLog() async {
    context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
      salesPersonIds: _attendanceOwnerIds,
      startDate: _attendanceStartDate,
      endDate: _attendanceEndDate,
    ));
    context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
      salesPersonIds: _activityOwnerIds,
      startDate: _activityStartDate,
      endDate: _activityEndDate,
    ));
  }

  void _showImagePreview(String url) {
    final screen = MediaQuery.of(context).size;
    final imgW = screen.width - 20;
    final imgH = screen.height - 120;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const SizedBox.expand(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: DriveImage(
                      url: url,
                      width: imgW,
                      height: imgH,
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        width: imgW,
                        height: 300,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(grey11Color),
      body: BlocListener<AttendanceBloc, AttendanceState>(
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
              customHeader(context,'Attendance',colorBg: Color(primaryColor),colorBack: Color(whiteColor),colorTitle: Color(whiteColor),iconRight: Icons.arrow_back,iconRightOnTap: () => context.go('/'),colorIconRight: Color(whiteColor),),
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
    ));
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
                  setState(() {
                    selectedMenu = 'attendance';
                  });
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
        String label = 'Owner';
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
                    itemBuilder: (_, i) => _buildCardAttendance(data[i]),
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
                final isAtasan = profileState is ProfileLoaded && profileState.profile.subordinates.isNotEmpty;

                final List<({String fullName, String date, String type, Color typeColor, String? datetime, String? location, String? contactName, String? note, List<String> images, int? statusValidasi, String? noteValidasi, int? logId})> entries = [];

                for (final item in state.activityLogs) {
                  if (item.clockInDate != null) {
                    entries.add((fullName: item.fullName, date: item.date, type: 'Clock In', typeColor: const Color(0xFF27AE60), datetime: item.clockInDate, location: item.clockInLocation, contactName: null, note: item.clockInNote, images: item.clockInAttachment ?? [], statusValidasi: null, noteValidasi: null, logId: null));
                  }
                  if (item.clockOutDate != null) {
                    entries.add((fullName: item.fullName, date: item.date, type: 'Clock Out', typeColor: const Color(0xFFE74C3C), datetime: item.clockOutDate, location: item.clockOutLocation, contactName: null, note: item.clockOutNote, images: item.clockOutAttachment ?? [], statusValidasi: null, noteValidasi: null, logId: null));
                  }
                  for (final c in item.checkIns) {
                    if (c.checkInDate != null) {
                      entries.add((fullName: item.fullName, date: item.date, type: 'Check In', typeColor: const Color(0xFF2980B9), datetime: c.checkInDate, location: c.checkInLocation, contactName: null, note: c.checkInNote, images: c.checkInAttachment ?? [], statusValidasi: c.statusValidasi, noteValidasi: c.noteValidasi, logId: c.logId));
                    }
                  }
                  for (final v in item.visits) {
                    if (v.datetime != null) {
                      entries.add((fullName: item.fullName, date: item.date, type: 'Visit', typeColor: const Color(0xFFE67E22), datetime: v.datetime, location: v.lastProject, contactName: v.contactName, note: v.note, images: v.attachment ?? [], statusValidasi: null, noteValidasi: null, logId: null));
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
                  final Map<String, List<({String fullName, String date, String type, Color typeColor, String? datetime, String? location, String? contactName, String? note, List<String> images, int? statusValidasi, String? noteValidasi, int? logId})>> grouped = {};
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
                      return Column(
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
                          )),
                        ],
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
  }) {
    return _ActivityCard(
      fullName: fullName,
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
    String formatTime(String? value) {
      if (value == null) return '-';
      final dt = DateTime.tryParse(value);
      if (dt == null) return '-';
      return DateFormat('hh:mm a').format(dt);
    }

    String formatDate(String? value) {
      if (value == null) return '-';
      final dt = DateTime.tryParse(value);
      if (dt == null) return '-';
      return DateHelper.formatDate(dt);
    }

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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DriveImage(
                          url: currentUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          onTap: () => _showImagePreview(currentUrl),
                        ),
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
                              _buildInfoRow(Icons.access_time_filled, formatTime(datetime), Color(greenPercentColor)),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.calendar_today, formatDate(datetime), Color(primaryColor)),
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

    String formatTime(String? value) {
      if (value == null) return "-";
      final dt = DateTime.parse(value);
      return DateFormat('hh:mm a').format(dt);
    }

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
                onTap: item.clockIn != null ? () => _showAttendanceDialog(item, 0) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Color(greenPercentColor)),
                    const SizedBox(height: 2),
                    Text(formatTime(item.clockIn), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),

            Container(width: 1, height: 40, color: Color(grey9Color)),

            /// CLOCK OUT
            Expanded(
              child: GestureDetector(
                onTap: item.clockOut != null ? () => _showAttendanceDialog(item, 1) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Color(redPeriodColor)),
                    const SizedBox(height: 2),
                    Text(formatTime(item.clockOut), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                                onTap: () => _showImagePreview(images[index]),
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

  Widget _buildCheckForm({required String title, required int flagParam, String? image,AttendanceEntity? attendance}) {
  return Expanded(
    child: image != null && flagParam != 6
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal:70, vertical: 5),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: DriveImage(
                    url: image,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    onTap: () => _showImagePreview(image),
                  ),
                ),
                Positioned.fill(
                  top: 123,
                  bottom: 0,
                  child: Container(
                    height: 20,
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Color(blue2Color).withOpacity(0.5),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_filled, color: flagParam == 0 ? Color(greenPercentColor) : flagParam == 1 ? Color(redPeriodColor) : Color(primaryColor), size: 10),
                            SizedBox(width: 10),
                            Text(() { final raw = flagParam == 0 ? attendance?.clockIn : flagParam == 1 ? attendance?.clockOut : attendance?.checkInActivity; final dt = raw != null ? DateTime.tryParse(raw) : null; return dt != null ? DateHelper.formatTime(dt) : (raw ?? '-'); }(), style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 10),
                            SizedBox(width: 10),
                            Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Color(primaryColor), size: 10),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 150,
                              child: Text("${flagParam == 0 ? attendance?.location0 : flagParam == 1 ? attendance?.location1 : attendance?.location6}", style: TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            reverse: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateHelper.formatTime(DateTime.now()), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(fontSize: 11, color: Color(grey6Color))),
                SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () async { _handleMoveCamera(title, flagParam); },
                    child: Container(
                      height: 90,
                      width: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(primaryColor).withValues(alpha: 0.1)),
                      child: Container(
                        height: 80,
                        width: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color(primaryColor).withValues(alpha: 0.2)),
                        child: Container(
                          height: 70,
                          width: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(primaryColor)),
                          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(whiteColor))),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
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
        ),
      ],
    );
  }


    
  void _showAttendanceDialog(AttendanceEntity item, int flag) {
    final String timeValue = flag == 0 ? item.clockIn ?? "-" : item.clockOut ?? "-";
    final List<String>? images =flag == 0 ? item.fileAttchment0 : item.fileAttchment1;
    final String note = flag == 0 ? item.note0 ?? "-" : item.note1 ?? "-";
    final String location =flag == 0 ? item.location0 ?? "-" : item.location1 ?? "-";

    String formatTime(String? value) {
      if (value == null || value == "-") return "-";
      final dt = DateTime.parse(value);
      return DateFormat('hh:mm a').format(dt);
    }

    final String displayTime = formatTime(timeValue);
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: displayImage != null
                        ? DriveImage(
                            url: displayImage,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            onTap: () => _showImagePreview(displayImage),
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 50),
                          ),
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

  const _ActivityCard({
    required this.fullName,
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
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late final ScrollController _scrollController;
  bool _isAtStart = true;
  bool _isAtEnd = false;

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
            },
            child: const Text('Kirim', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  Widget _buildValidasiIcon() {
    if (widget.statusValidasi == 1) {
      return const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 30);
    } else if (widget.statusValidasi == 0) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Catatan Validasi'),
              content: Text(widget.noteValidasi?.isNotEmpty == true ? widget.noteValidasi! : 'Tidak ada catatan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 25),
      );
    } else {
      if (!widget.isAtasan || widget.logId == null) {
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 25),
            SizedBox(width: 2),
            Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 25),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showNoteValidasiDialog(),
            child: const Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 25),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              context.read<AttendanceActivityBloc>().add(
                ValidasiCheckInEvent(logId: widget.logId!, statusValidasi: 1),
              );
            },
            child: const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 25),
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
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Color(primaryColor),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            getInitials(widget.fullName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(whiteColor),
                            ),
                          ),
                        ),
                      ),
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
                            Text(DateHelper.formatTime(DateTime.parse(widget.datetime!)), style: const TextStyle(fontSize: 10)),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: widget.typeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(widget.type, style: TextStyle(fontSize: 10, color: widget.typeColor, fontWeight: FontWeight.w600)),
                    ),
                    if (widget.type == 'Check In') ...[
                      const SizedBox(height: 4),
                      _buildValidasiIcon(),
                    ],
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