import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:progress_group/core/utils/web_debug_util.dart' as web_debug;
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/helpers/camera_permission_primer.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/presentation/pages/location-permission-guide/index.dart';
import 'package:progress_group/core/constants/attendance_feedback_labels.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_feedback_entity.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/office_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_state.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_excel/attendance_excel_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_excel/attendance_excel_state.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/web_download.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/arguments/attandance_args.dart';

part 'index_location.dart';

class AttandancePage extends StatefulWidget {
  final int? initialTab;
  const AttandancePage({super.key, this.initialTab});

  @override
  State<AttandancePage> createState() => _AttandancePageState();
}

class _AttandancePageState extends State<AttandancePage>
    with AttendanceLocationMixin<AttandancePage> {
  late PageController _pageController;
  late ScrollController _scrollController;

  int selectedIndex = 0;
  String selectedMenu ='activity';
  bool _isCameraOpening = false;
  bool _attendanceLogLoaded = false;
  bool _hasSetInitialTab = false;
  bool _isButtonPinned = false;
  bool _showScrollToTop = false;
  bool _permissionsReady = false;
  AttendanceLoaded? _pendingInitialTabState;
  List<int>? _attendanceOwnerIds;
  String? _attendanceStartDate;
  String? _attendanceEndDate;

  List<int>? _activityOwnerIds;
  String? _activityStartDate;
  String? _activityEndDate;
  String? _activityDateLabel;
  List<String>? _activityTypes;
  final GlobalKey _activityFilterButtonKey = GlobalKey();

  List<AttendanceActivityEntity>? _activityRowsSourceRef;
  List<_ActivityRow> _activityRowsCache = const [];

  Timer? _loadMoreDebounce;
  StreamSubscription? _officeLocationSub;


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
    Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
          });
    Future.microtask(() {
      context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
      context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true, silent: true));
      final officeLocationCubit = context.read<OfficeLocationCubit>();
      officeLocationCubit.load();
      _officeLocationSub = officeLocationCubit.stream.listen((locations) {
        if (locations.isNotEmpty && _currentPosition != null) {
          _computeNearestLocation(_currentPosition!);
        }
      });
      _initLocation();

      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded) {
        _attendanceOwnerIds = [profileState.profile.userId];
        if (PermissionsHelper.canApproveRejectAttendance) {
          context.read<AttendanceApprovalCubit>().loadBadge();
        }
      }

      _fetchActivityLogs();

     
    });
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _positionStream?.cancel();
    _officeLocationSub?.cancel();
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

    final showScrollToTop = _scrollController.position.pixels > 400;
    if (showScrollToTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showScrollToTop);
    }

    final atBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300;
    if (!atBottom) return;

    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 400), _triggerLoadMore);
  }

  void _triggerLoadMore() {
    if (selectedMenu == 'activity') {
      final activityState = context.read<AttendanceActivityBloc>().state;
      if (activityState is! AttendanceActivityLoaded) return;
      if (activityState.activityLoadingMore) return;
      if (activityState.activityPage >= activityState.activityLastPage) return;
      context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
        salesPersonIds: _activityOwnerIds,
        startDate: _activityDateRange.start,
        endDate: _activityDateRange.end,
        types: _activityTypes,
        page: activityState.activityPage + 1,
        perPage: 8,
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
    if (!mounted) return;
    setState(() => selectedIndex = index);

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
      });
    }
  }

  bool _isApprover(UserProfileEntity profile) {
    return PermissionsHelper.canApproveRejectAttendance;
  }

  Future<void> _handleMoveCamera(String title, int flagParam) async {
    if (!mounted || _isCameraOpening) return;
    setState(() => _isCameraOpening = true);
    web_debug.logDebugInfo('[Camera] _handleMoveCamera mulai — title=$title flag=$flagParam');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mohon tunggu, sedang mempersiapkan kamera...'),
        duration: Duration(seconds: 30),
        backgroundColor: Color(blueGreyColor),
      ),
    );

    try {
      await primeCameraPermission();

      final hasPermission = await _handleLocationPermission(fromUserGesture: true);
      web_debug.logDebugInfo('[Camera] cek izin lokasi -> hasPermission=$hasPermission');
      if (!hasPermission) {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      final position = await _getCurrentLocationOnce();
      web_debug.logDebugInfo('[Camera] ambil lokasi -> ${position == null ? "null" : "${position.latitude},${position.longitude}"}');

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi sudah diizinkan tapi belum terdeteksi. Tutup dan buka kembali aplikasi, lalu coba lagi."),
              backgroundColor: Color(orangeAccentColor),
            ),
          );
        }
        return;
      }

      final officeLocationCubit = context.read<OfficeLocationCubit>();
      await officeLocationCubit.load(force: true);
      if (!mounted) return;
      var officeLocations = officeLocationCubit.state;
      web_debug.logDebugInfo('[Camera] office locations loaded -> ${officeLocations.length} lokasi');

      String? officeCandidateName;
      int? officeCandidateId;
      double? officeCandidateDistance;

      String? pameranCandidateName;
      int? pameranCandidateId;
      double? pameranCandidateDistance;

      if (officeLocations.isNotEmpty) {
        for (var office in officeLocations) {
          final lat = double.tryParse(office.latitude ?? '');
          final lng = double.tryParse(office.longitude ?? '');
          if (lat != null && lng != null) {
            final d = Geolocator.distanceBetween(
              lat, lng,
              position.latitude, position.longitude,
            );
            final radius = office.radius?.toDouble() ?? radiusMeter;
            if (d <= radius) {
              if (office.typeLocationId == 2) {
                if (pameranCandidateDistance == null || d < pameranCandidateDistance) {
                  pameranCandidateDistance = d;
                  pameranCandidateName = office.name;
                  pameranCandidateId = office.id;
                }
              } else {
                if (officeCandidateDistance == null || d < officeCandidateDistance) {
                  officeCandidateDistance = d;
                  officeCandidateName = office.name;
                  officeCandidateId = office.id;
                }
              }
            }
          }
        }
      }

      final bool inOfficeRadius = officeCandidateId != null;
      final bool inPameranRadius = pameranCandidateId != null;
      final isInRadius = inOfficeRadius || inPameranRadius;

      final bool officeAllowed = inOfficeRadius &&
          (flagParam == 0 ? PermissionsHelper.canClockInOffice : PermissionsHelper.canClockOutOffice);
      final bool pameranAllowed = inPameranRadius &&
          (flagParam == 0 ? PermissionsHelper.canClockInPameran : PermissionsHelper.canClockOutPameran);
      final bool luarLokasiAllowed = flagParam == 0
          ? (PermissionsHelper.canClockInLuarLokasi || PermissionsHelper.canClockInLuarLokasiRequestApprove)
          : (PermissionsHelper.canClockOutLuarLokasi || PermissionsHelper.canClockOutLuarLokasiRequestApprove);

      final bool canProceed = flagParam == 6 || officeAllowed || pameranAllowed || luarLokasiAllowed;

      web_debug.logDebugInfo('[Camera] canProceed=$canProceed isInRadius=$isInRadius officeId=$officeCandidateId pameranId=$pameranCandidateId');

      if (!canProceed) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showSnackbar(context, 'Anda tidak punya akses', isError: true);
        }
        return;
      }

      String? nearestOfficeName;
      int? nearestOfficeId;
      if (flagParam == 6) {
        final useOffice = (officeCandidateDistance ?? double.infinity) <=
            (pameranCandidateDistance ?? double.infinity);
        nearestOfficeName = useOffice ? officeCandidateName : pameranCandidateName;
        nearestOfficeId = useOffice ? officeCandidateId : pameranCandidateId;
      } else if (officeAllowed && pameranAllowed) {
        final useOffice = officeCandidateDistance! <= pameranCandidateDistance!;
        nearestOfficeName = useOffice ? officeCandidateName : pameranCandidateName;
        nearestOfficeId = useOffice ? officeCandidateId : pameranCandidateId;
      } else if (officeAllowed) {
        nearestOfficeName = officeCandidateName;
        nearestOfficeId = officeCandidateId;
      } else if (pameranAllowed) {
        nearestOfficeName = pameranCandidateName;
        nearestOfficeId = pameranCandidateId;
      }

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      web_debug.logDebugInfo('[Camera] navigasi ke halaman camera...');
      final result = await context.pushNamed('camera', extra: AttandanceArgs(flag: flagParam, type: title, location: isInRadius ? (nearestOfficeName ?? _address) : _address, time: DateHelper.formatTime(AppTime.now()), locationId: isInRadius ? nearestOfficeId : null, latitude: position.latitude.toString(), longitude: position.longitude.toString(), ), );
      web_debug.logDebugInfo('[Camera] balik dari halaman camera -> result=$result');

      if (result == true) {
        _getLog();
      }
    } catch (e) {
      web_debug.logDebugError('[Camera] Gagal membuka kamera : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera mohon cek pengaturan kamera dan coba lagi.'),
            backgroundColor: Color(redAccentColor),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCameraOpening = false);
    }
  }

  ({String start, String end}) get _activityDateRange {
    final now = AppTime.now();
    return (
      start: _activityStartDate ?? DateHelper.formatNumericCompact(now.subtract(const Duration(days: 7))),
      end: _activityEndDate ?? DateHelper.formatNumericCompact(now),
    );
  }

  int get _activityActiveFilterCount {
    int count = 0;
    if (_activityOwnerIds != null && _activityOwnerIds!.isNotEmpty) count++;
    if (_activityTypes != null && _activityTypes!.isNotEmpty) count++;
    if (_activityStartDate != null && _activityEndDate != null) count++;
    return count;
  }

  void _fetchActivityLogs() {
    context.read<AttendanceActivityBloc>().add(GetAttendanceActivityEvent(
      salesPersonIds: _activityOwnerIds,
      startDate: _activityDateRange.start,
      endDate: _activityDateRange.end,
      types: _activityTypes,
      perPage: 8,
    ));
  }

  Future<void> _getLog() async {
    if (mounted) {
      setState(() {
        _hasSetInitialTab = false;
      });
    }
    // Always refresh "today" data via the lightweight event first so the
    // Clock In/Check In/Clock Out tab updates immediately, instead of being
    // gated behind the much heavier full-history fetch below.
    context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
    if (_attendanceLogLoaded) {
      context.read<AttendanceBloc>().add(FetchAttendanceDataEvent(
        salesPersonIds: _attendanceOwnerIds,
        startDate: _attendanceStartDate,
        endDate: _attendanceEndDate,
      ));
    }
    _fetchActivityLogs();
  }

  void _showImagePreview(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    AnalyticsService.logEvent('attendance_view_image_fullscreen');
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierColor: Color(blackColor).withValues(alpha: 0.87),
      builder: (dialogContext) {
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Color(transparentColor),
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

                  if (currentIndex > 0)
                    Positioned(
                      left: 10,
                      child: IconButton(
                        iconSize: 40,
                        color: Color(whiteColor),
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          setState(() {
                            currentIndex--;
                          });
                        },
                      ),
                    ),

                  if (currentIndex < imageUrls.length - 1)
                    Positioned(
                      right: 10,
                      child: IconButton(
                        iconSize: 40,
                        color: Color(whiteColor),
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          setState(() {
                            currentIndex++;
                          });
                        },
                      ),
                    ),

                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(whiteColor),
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),

                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(blackColor).withValues(alpha: 0.54),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${imageUrls.length}',
                          style: const TextStyle(color: Color(whiteColor)),
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

    final List<OwnerDropdownItem> ownerItems = [];
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

    final now = AppTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);
    DateTime startDate = DateTime(prevMonth.year, prevMonth.month, 25);
    DateTime endDate = DateTime(now.year, now.month, 26);
    OwnerDropdownItem selectedOwner = ownerItems.first;
    final searchController = TextEditingController();
    String searchQuery = '';
    bool dropdownOpen = false;

    Widget dateButton({required String label, required DateTime date, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: Color(greyShade400)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Color(greyShade500))),
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
                                border: Border.all(color: Color(greyShade400)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Karyawan', style: TextStyle(fontSize: 10, color: Color(greyShade500))),
                                        const SizedBox(height: 2),
                                        Text(selectedOwner.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    dropdownOpen ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: Color(greyShade600),
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
                            if (picked != null) {
                              AnalyticsService.logEvent('attendance_select_export_date_range');
                              setStateDialog(() => startDate = picked);
                            }
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
                            if (picked != null) {
                              AnalyticsService.logEvent('attendance_select_export_date_range');
                              setStateDialog(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

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
                            onTap: () {
                              AnalyticsService.logEvent('attendance_select_export_employee');
                              setStateDialog(() {
                                selectedOwner = item;
                                dropdownOpen = false;
                                searchController.clear();
                                searchQuery = '';
                              });
                            },
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
                                          Text(item.subtitle!, style: TextStyle(fontSize: 11, color: Color(greyShade600))),
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
                onPressed: () {
                  AnalyticsService.logEvent('attendance_confirm_download_excel');
                  Navigator.of(ctx).pop(true);
                },
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
      context.read<AttendanceExcelCubit>().download(
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
                  color: Color(greyShade300),
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
                  AnalyticsService.logEvent('attendance_save_exported_file');
                  Navigator.of(ctx).pop();
                  _savePdfToStorage(filePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Bagikan'),
                onTap: () {
                  AnalyticsService.logEvent('attendance_share_exported_file');
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
                  color: Color(greyShade300),
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
                  AnalyticsService.logEvent('attendance_save_exported_file');
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



  void _trySetInitialTab() {
    if (_hasSetInitialTab || !_permissionsReady || !_locationResolved || _pendingInitialTabState == null) return;
    final today = _pendingInitialTabState!.todayData;
    final now = AppTime.now();
    final noClockAccess = _isClockButtonDisabled(0) && _isClockButtonDisabled(1);

    int targetIndex;
    if (noClockAccess) {
      targetIndex = 1;
    } else if (now.hour >= 17) {
      targetIndex = 2;
    } else if (today == null || today.clockIn == null) {
      targetIndex = 0;
    } else {
      targetIndex = 1;
    }

    setState(() => _hasSetInitialTab = true);
    _onTabChanged(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(grey11Color),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showScrollToTop ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showScrollToTop,
            child: FloatingActionButton.small(
              heroTag: 'activity-scroll-to-top',
              backgroundColor: Color(primaryColor),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(whiteColor)),
            ),
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PermissionsLoaded) {
            _permissionsReady = true;
            _trySetInitialTab();
            if (_currentPosition != null) _computeNearestLocation(_currentPosition!);
            if (_hasSetInitialTab && selectedIndex == 0 && _isClockButtonDisabled(0)) {
              _onTabChanged(1);
            }
          }
        },
        child: BlocListener<AttendanceExcelCubit, AttendanceExcelState>(
        listener: (context, state) async {
          if (state is AttendanceExcelLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor))),
                    SizedBox(width: 12),
                    Text('Mengunduh Excel...'),
                  ],
                ),
                duration: Duration(seconds: 30),
              ),
            );
          } else if (state is AttendanceExcelSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showPdfOptions(context, state.filePath);
            context.read<AttendanceExcelCubit>().reset();
          } else if (state is AttendanceExcelWebSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showPdfOptionsWeb(context, state.bytes, state.fileName);
            context.read<AttendanceExcelCubit>().reset();
          } else if (state is AttendanceExcelError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            debugPrint('AttendanceExcelError: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mengunduh data kehadiran')),
            );
            context.read<AttendanceExcelCubit>().reset();
          }
        },
        child: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceLoaded && !_hasSetInitialTab) {
            _pendingInitialTabState = state;
            _trySetInitialTab();
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
                        iconRightOnTap: () {
                          AnalyticsService.logEvent('attendance_back');
                          context.go('/');
                        },
                        colorIconRight: Color(whiteColor),
                        iconLeft: isAtasan && PermissionsHelper.canApproveRejectAttendance ? Icons.checklist : null,
                        colorIconLeft: Color(whiteColor),
                        iconLeftOnTap: isAtasan && PermissionsHelper.canApproveRejectAttendance ? () {
                          AnalyticsService.logEvent('attendance_open_approval');
                          context.pushNamed('approval');
                        } : null,
                        showBadgeLeft: isAtasan && hasPending,
                        iconLeft2: Icons.download,
                        colorIconLeft2: Color(whiteColor),
                        iconLeft2OnTap: () {
                          AnalyticsService.logEvent('attendance_download_attendance_excel');
                          _showPdfDatePickerDialog();
                        },
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
                          
                          if (selectedMenu == 'activity')
                            ..._buildActivityLogSlivers()
                          else
                            SliverToBoxAdapter(child: _buildAttendanceLog()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ))));
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AnalyticsService.logEvent('attendance_switch_menu_tab', parameters: {'tab': 'activity'});
                  setState(() {
                    selectedMenu = 'activity';
                  });
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedMenu == 'activity'
                        ? Color(primaryColor)
                        : Color(whiteColor),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedMenu != 'activity'
                        ? Color(primaryColor)
                        : Color(whiteColor),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedMenu == 'activity'
                          ? Color(whiteColor)
                          : Color(primaryColor),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: GestureDetector(
                onTap: () {
                  AnalyticsService.logEvent('attendance_switch_menu_tab', parameters: {'tab': 'attendance'});
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
                        ? Color(primaryColor)
                        : Color(whiteColor),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(primaryColor),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Attendance Log',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedMenu == 'attendance'
                          ? Color(whiteColor)
                          : Color(primaryColor),
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

  static const List<({String value, String label})> _activityTypeOptions = [
    (value: 'clock_in', label: 'Clock In'),
    (value: 'clock_out', label: 'Clock Out'),
    (value: 'check_in', label: 'Check In'),
    (value: 'visit', label: 'Visit'),
  ];

  String _activityTypeLabel(String type) {
    for (final opt in _activityTypeOptions) {
      if (opt.value == type) return opt.label;
    }
    return type;
  }

  Color _activityTypeColor(String type) {
    switch (type) {
      case 'clock_in':
        return const Color(clockInColor);
      case 'clock_out':
        return const Color(clockOutColor);
      case 'check_in':
        return const Color(checkInColor);
      case 'visit':
        return const Color(visitColor);
      default:
        return const Color(greyShade500);
    }
  }

  Widget _buildActivityFilterButton() {
    final activeCount = _activityActiveFilterCount;
    return CustomFilterButton(
      key: _activityFilterButtonKey,
      label: activeCount > 0 ? 'Filter ($activeCount)' : 'Filter',
      isSelected: activeCount > 0,
      onTap: _showActivityFilterMenu,
    );
  }

  Future<void> _showActivityFilterMenu() async {
    final renderBox = _activityFilterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlayBox == null) return;

    final topLeft = renderBox.localToGlobal(Offset(0, renderBox.size.height + 6), ancestor: overlayBox);
    final bottomRight = renderBox.localToGlobal(renderBox.size.bottomRight(const Offset(0, 6)), ancestor: overlayBox);

    final selected = await showMenu<String>(
      context: context,
      color: Color(whiteColor),
      position: RelativeRect.fromRect(Rect.fromPoints(topLeft, bottomRight), Offset.zero & overlayBox.size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildActivityFilterMenuItem(
          value: 'user',
          label: 'User',
          isActive: _activityOwnerIds != null && _activityOwnerIds!.isNotEmpty,
          clearValue: 'user_clear',
        ),
        _buildActivityFilterMenuItem(
          value: 'type',
          label: 'Type',
          isActive: _activityTypes != null && _activityTypes!.isNotEmpty,
          clearValue: 'type_clear',
        ),
        _buildActivityFilterMenuItem(
          value: 'date',
          label: 'Date',
          isActive: _activityStartDate != null && _activityEndDate != null,
          clearValue: 'date_clear',
        ),
      ],
    );

    if (!mounted || selected == null) return;
    switch (selected) {
      case 'user':
        await _openActivityUserFilter();
      case 'type':
        await _openActivityTypeFilter();
      case 'date':
        await _openActivityDateFilter();
      case 'user_clear':
        _clearActivityUserFilter();
      case 'type_clear':
        _clearActivityTypeFilter();
      case 'date_clear':
        _clearActivityDateFilter();
    }
  }

  PopupMenuItem<String> _buildActivityFilterMenuItem({
    required String value,
    required String label,
    required bool isActive,
    required String clearValue,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (isActive)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(clearValue),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Color(greyShade500)),
              ),
            ),
        ],
      ),
    );
  }

  void _clearActivityUserFilter() {
    if (_activityOwnerIds == null) return;
    setState(() => _activityOwnerIds = null);
    _fetchActivityLogs();
  }

  void _clearActivityTypeFilter() {
    if (_activityTypes == null) return;
    setState(() => _activityTypes = null);
    _fetchActivityLogs();
  }

  void _clearActivityDateFilter() {
    if (_activityStartDate == null && _activityEndDate == null) return;
    setState(() {
      _activityStartDate = null;
      _activityEndDate = null;
      _activityDateLabel = null;
    });
    _fetchActivityLogs();
  }

  Future<void> _openActivityTypeFilter() async {
    final items = List<OwnerDropdownItem>.generate(
      _activityTypeOptions.length,
      (i) => OwnerDropdownItem(id: i, name: _activityTypeOptions[i].label),
    );
    final selectedIds = (_activityTypes ?? const <String>[])
        .map((v) => _activityTypeOptions.indexWhere((opt) => opt.value == v))
        .where((i) => i >= 0)
        .toList();

    final result = await context.pushNamed(
      'attendanceOwnerDropdown',
      extra: ContactDropdownArgs(
        title: 'Pilih Tipe',
        items: items,
        selectedIds: selectedIds,
        isMultiSelect: true,
        allowClear: false,
      ),
    );

    if (result == null || !mounted) return;
    final List<OwnerDropdownItem> selected = result is List<OwnerDropdownItem> ? result : [result as OwnerDropdownItem];
    final values = selected.where((e) => e.id != null).map((e) => _activityTypeOptions[e.id!].value).toList();
    setState(() => _activityTypes = values.isEmpty ? null : values);
    _fetchActivityLogs();
  }

  Future<void> _openActivityUserFilter() async {
    AnalyticsService.logEvent('attendance_filter_activity_owner');
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is! ProfileLoaded) return;
    final user = profileState.profile;
    final List<OwnerDropdownItem> ownerItems = [];

    ownerItems.add(OwnerDropdownItem(
      id: user.userId,
      name: user.fullName,
      subtitle: user.positionName,
    ));

    if (user.subordinates.isNotEmpty) {
      void addSubs(List<HierarchyNodeEntity> subs) {
        for (var s in subs) {
          ownerItems.add(OwnerDropdownItem(
            id: s.userId,
            name: s.fullName,
            subtitle: s.positionName,
          ));
          if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
        }
      }
      addSubs(user.subordinates);
    } else {
      final seen = <int>{user.userId};
      void addGroupUsers(List<GroupHierarchyEntity> groups) {
        for (final g in groups) {
          for (final u in g.users) {
            if (seen.contains(u.userId)) continue;
            seen.add(u.userId);
            ownerItems.add(OwnerDropdownItem(id: u.userId, name: u.fullName, subtitle: g.groupName));
          }
          if (g.children.isNotEmpty) addGroupUsers(g.children);
        }
      }
      addGroupUsers(user.groupHierarchy);
      void addTeamMembers(List<SalesTeamMemberEntity> members, String teamName) {
        for (final m in members) {
          if (m.userId != null && !seen.contains(m.userId!)) {
            seen.add(m.userId!);
            ownerItems.add(OwnerDropdownItem(id: m.userId, name: m.fullName, subtitle: '$teamName - ${m.positionName ?? ''}'));
          }
          if (m.subordinates.isNotEmpty) addTeamMembers(m.subordinates, teamName);
        }
      }
      for (final team in user.salesTeamHierarchy) {
        addTeamMembers(team.members, team.salesTeamName);
      }
    }

    final result = await context.pushNamed(
      'attendanceOwnerDropdown',
      extra: ContactDropdownArgs(
        title: 'Pilih User',
        items: ownerItems,
        selectedIds: _activityOwnerIds,
        isMultiSelect: true,
        allowClear: false,
      ),
    );

    if (result == null || !mounted) return;
    final List<OwnerDropdownItem> selected = result is List<OwnerDropdownItem> ? result : [result as OwnerDropdownItem];
    final newIds = selected.map((e) => e.id!).toList();
    setState(() => _activityOwnerIds = newIds.isNotEmpty ? newIds : null);
    _fetchActivityLogs();
  }

  Future<void> _openActivityDateFilter() async {
    final result = await context.pushNamed<DateFilterResult>(
      'dateFilter',
      extra: {
        'label': _activityDateLabel,
        'startDate': _activityStartDate,
        'endDate': _activityEndDate,
        'isSingleSelect': true,
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      if (result.isClear) {
        _activityStartDate = null;
        _activityEndDate = null;
        _activityDateLabel = null;
      } else {
        _activityStartDate = result.startDate;
        _activityEndDate = result.endDate;
        _activityDateLabel = result.label;
      }
    });
    _fetchActivityLogs();
  }

  Widget _filterOwner({bool isMultiSelect = true, String section = 'activity'}) {
    final isAttendance = section == 'attendance';

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final currentIds = isAttendance ? _attendanceOwnerIds : _activityOwnerIds;
        String label = 'User';
        final isSelected = currentIds != null && currentIds.isNotEmpty;

        if (isSelected && profileState is ProfileLoaded) {
          final user = profileState.profile;

          String? findName(int? id) {
            if (id == null) return null;
            if (user.userId == id) return user.fullName;
            HierarchyNodeEntity? found;
            void search(List<HierarchyNodeEntity> nodes) {
              for (var n in nodes) {
                if (n.userId == id) found = n;
                if (found == null && n.subordinates.isNotEmpty) search(n.subordinates);
              }
            }
            search(user.subordinates);
            if (found != null) return found!.fullName;
            String? groupFound;
            void searchGroup(List<GroupHierarchyEntity> groups) {
              for (final g in groups) {
                for (final u in g.users) {
                  if (u.userId == id) { groupFound = u.fullName; return; }
                }
                if (groupFound == null && g.children.isNotEmpty) searchGroup(g.children);
              }
            }
            searchGroup(user.groupHierarchy);
            if (groupFound != null) return groupFound;
            void searchTeam(List<SalesTeamMemberEntity> members) {
              for (final m in members) {
                if (m.userId == id) { groupFound = m.fullName; return; }
                if (groupFound == null && m.subordinates.isNotEmpty) searchTeam(m.subordinates);
              }
            }
            for (final team in user.salesTeamHierarchy) {
              if (groupFound != null) break;
              searchTeam(team.members);
            }
            return groupFound;
          }

          if (currentIds.length == 1) {
            label = findName(currentIds.first) ?? 'Filtered';
          } else {
            label = '${currentIds.length} User';
          }
        }

        return CustomFilterButton(
          label: label,
          isSelected: isSelected,
          maxWidth: 130,
          onTap: () async {
            AnalyticsService.logEvent('attendance_filter_attendance_owner');
            if (profileState is ProfileLoaded) {
              final user = profileState.profile;
              final List<OwnerDropdownItem> ownerItems = [];

              ownerItems.add(OwnerDropdownItem(
                id: user.userId,
                name: user.fullName,
                subtitle: user.positionName,
              ));

              if (user.subordinates.isNotEmpty) {
                void addSubs(List<HierarchyNodeEntity> subs) {
                  for (var s in subs) {
                    ownerItems.add(OwnerDropdownItem(
                      id: s.userId,
                      name: s.fullName,
                      subtitle: s.positionName,
                    ));
                    if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
                  }
                }
                addSubs(user.subordinates);
              } else {
                final seen = <int>{user.userId};
                void addGroupUsers(List<GroupHierarchyEntity> groups) {
                  for (final g in groups) {
                    for (final u in g.users) {
                      if (seen.contains(u.userId)) continue;
                      seen.add(u.userId);
                      ownerItems.add(OwnerDropdownItem(id: u.userId, name: u.fullName, subtitle: g.groupName));
                    }
                    if (g.children.isNotEmpty) addGroupUsers(g.children);
                  }
                }
                addGroupUsers(user.groupHierarchy);
                void addTeamMembers(List<SalesTeamMemberEntity> members, String teamName) {
                  for (final m in members) {
                    if (m.userId != null && !seen.contains(m.userId!)) {
                      seen.add(m.userId!);
                      ownerItems.add(OwnerDropdownItem(id: m.userId, name: m.fullName, subtitle: '$teamName - ${m.positionName ?? ''}'));
                    }
                    if (m.subordinates.isNotEmpty) addTeamMembers(m.subordinates, teamName);
                  }
                }
                for (final team in user.salesTeamHierarchy) {
                  addTeamMembers(team.members, team.salesTeamName);
                }
              }

              final currentIds = isAttendance ? _attendanceOwnerIds : _activityOwnerIds;
              final result = await context.pushNamed(
                'attendanceOwnerDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih User',
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
                    types: _activityTypes,
                    perPage: 8,
                  ));
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _buildAttendanceLog() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
      
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
                    style: TextStyle(fontSize: 14, color: Color(greyShade500)),
                  ),
                ),
              );
            } else {
              DateTime weekStartOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

              final Map<String, List<AttendanceEntity>> weekGroups = {};
              for (final item in data) {
                final d = DateTime.tryParse(item.date) ?? DateTime(2000);
                final ws = weekStartOf(d);
                final key = '${item.fullName ?? ""}__${ws.year}-${ws.month.toString().padLeft(2, "0")}-${ws.day.toString().padLeft(2, "0")}';
                weekGroups.putIfAbsent(key, () => []).add(item);
              }

              final sortedKeys = weekGroups.keys.toList()
                ..sort((a, b) => b.split('__').last.compareTo(a.split('__').last));

              content = Column(
                children: [
                  ...sortedKeys.map((key) => RepaintBoundary(
                    child: _buildWeeklyAttendanceCard(weekGroups[key]!),
                  )),
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

  List<_ActivityRow> _buildActivityRows(List<AttendanceActivityEntity> logs) {
    if (logs.isEmpty) return const [];

    final Map<String, List<AttendanceActivityEntity>> grouped = {};
    for (final item in logs) {
      grouped.putIfAbsent(item.date, () => []).add(item);
    }

    final rows = <_ActivityRow>[];
    int cardCounter = 0;
    for (final group in grouped.entries) {
      rows.add(_ActivityRow(date: group.key, entry: null));
      for (final item in group.value) {
        rows.add(_ActivityRow(
          date: group.key,
          entry: _ActivityEntry(
            item: item,
            typeLabel: _activityTypeLabel(item.activityType),
            typeColor: _activityTypeColor(item.activityType),
            cardIndex: cardCounter,
          ),
        ));
        cardCounter++;
      }
    }
    return rows;
  }

  List<Widget> _buildActivityLogSlivers() {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Activity", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildActivityFilterButton(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: Color(grey11Color),
            borderRadius: BorderRadius.circular(16),
          ),
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            sliver: SliverMainAxisGroup(
              slivers: [
                BlocBuilder<AttendanceActivityBloc, AttendanceActivityState>(
                  builder: (context, state) {
                    if (state is AttendanceActivityLoading) {
                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildLogHeaderShimmer(),
                            const SizedBox(height: 5),
                            buildActivityLogShimmer(),
                          ],
                        ),
                      );
                    }

                    if (state is! AttendanceActivityLoaded) {
                      return SliverToBoxAdapter(child: header);
                    }

                    final profileState = context.read<ProfileBloc>().state;
                    final canVerify = PermissionsHelper.canCheckInVerify;
                    final currentSalesPersonId = profileState is ProfileLoaded ? profileState.profile.salesPersonId : null;

                    if (!identical(_activityRowsSourceRef, state.activityLogs)) {
                      _activityRowsSourceRef = state.activityLogs;
                      _activityRowsCache = _buildActivityRows(state.activityLogs);
                    }
                    final rows = _activityRowsCache;

                    if (rows.isEmpty) {
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(child: header),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('Tidak ada data aktivitas')),
                            ),
                          ),
                        ],
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(child: header),
                        SliverList.builder(
                          itemCount: rows.length,
                          itemBuilder: (_, i) {
                            final row = rows[i];
                            final entry = row.entry;
                            if (entry == null) {
                              final parsedDate = DateTime.tryParse(row.date);
                              final dateLabel = parsedDate != null
                                  ? DateHelper.formatToIndonesian(parsedDate)
                                  : row.date;
                              return Padding(
                                key: ValueKey('activity-date-header-${row.date}'),
                                padding: const EdgeInsets.only(top: 12, bottom: 10),
                                child: Text(
                                  dateLabel,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              );
                            }

                            final item = entry.item;
                            final cardKey = ValueKey('${item.salesPersonId}_${item.date}_${entry.typeLabel}_${item.activityDatetime}_${item.logId ?? ''}');

                            return RepaintBoundary(
                              key: cardKey,
                              child: _buildCardActivityNew(
                                fullName: item.fullName,
                                photoUrl: item.photoUrl,
                                type: entry.typeLabel,
                                typeColor: entry.typeColor,
                                datetime: item.activityDatetime,
                                location: item.projectName ?? item.location,
                                contactName: item.contactName,
                                contactId: item.contactId,
                                note: item.note,
                                images: item.attachments,
                                statusValidasi: item.statusValidasi,
                                noteValidasi: item.noteValidasi,
                                logId: item.logId,
                                canVerify: canVerify,
                                isSelf: currentSalesPersonId != null && item.salesPersonId == currentSalesPersonId,
                                feedback: item.feedback,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                BlocBuilder<AttendanceActivityBloc, AttendanceActivityState>(
                  builder: (context, state) {
                    if (state is AttendanceActivityLoaded && state.activityLoadingMore) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCardActivityNew({
    Key? key,
    required String fullName,
    String? photoUrl,
    required String type,
    required Color typeColor,
    required String? datetime,
    required String? location,
    required String? contactName,
    int? contactId,
    required String? note,
    required List<String> images,
    int? statusValidasi,
    String? noteValidasi,
    int? logId,
    bool canVerify = false,
    bool isSelf = false,
    VoidCallback? onFullyLoaded,
    AttendanceFeedbackEntity? feedback,
  }) {
    return _ActivityCard(
      key: key,
      onFullyLoaded: onFullyLoaded,
      fullName: fullName,
      photoUrl: photoUrl,
      type: type,
      typeColor: typeColor,
      datetime: datetime,
      location: location,
      contactName: contactName,
      contactId: contactId,
      note: note,
      images: images,
      statusValidasi: statusValidasi,
      noteValidasi: noteValidasi,
      logId: logId,
      canVerify: canVerify,
      isSelf: isSelf,
      feedback: feedback,
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
    String? serial,
  }) {
    AnalyticsService.logEvent('attendance_view_activity_detail');
    int selectedIndex = allImages.indexOf(tappedUrl);
    if (selectedIndex < 0) selectedIndex = 0;

    int loadedThumbCount = 1;

    showDialog(
      context: context,
      barrierColor: Color(blackColor).withValues(alpha: 0.54),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentUrl = allImages[selectedIndex];
            return Dialog(
              backgroundColor: Color(whiteColor),
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
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DriveImage(
                              url: currentUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorWidget: _buildImageErrorWidget(serial: serial, height: 200),
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
                                  color: Color(blackColor).withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.fullscreen, color: Color(whiteColor), size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (allImages.length > 1) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allImages.length,
                            itemBuilder: (_, i) {
                              if (i >= loadedThumbCount) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Color(greyShade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedIndex = i),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: i == selectedIndex ? Color(primaryColor) : Color(transparentColor),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: DriveImage(
                                      url: allImages[i],
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorWidget: _buildImageErrorWidget(serial: serial, height: 52),
                                      onLoad: () {
                                        if (i != loadedThumbCount - 1) return;
                                        if (loadedThumbCount >= allImages.length) return;
                                        setDialogState(() => loadedThumbCount++);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              _buildInfoRow(Icons.access_time_filled, () { final d = DateTime.tryParse(datetime ?? ''); return d != null ? DateHelper.formatTime(d) : (datetime ?? '-'); }(), Color(greenPercentColor)),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.calendar_today, () { final d = DateTime.tryParse(datetime ?? ''); return d != null ? DateHelper.formatDate(d) : (datetime ?? '-'); }(), Color(primaryColor)),
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

  Widget _buildWeeklyAttendanceCard(List<AttendanceEntity> items) {
    final name = items.first.fullName ?? '';
    final sorted = [...items]..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (name.isNotEmpty)
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          ...sorted.map((item) => _buildCardAttendance(item)),
        ],
      ),
    );
  }

  Widget _buildCardAttendance(AttendanceEntity item) {
    final date = DateTime.tryParse(item.date) ?? DateTime(2000);
    final bool pendingIn = item.clockIn != null && (item.needsApproval0 ?? false) && item.isApprove0 == null && item.isReject0 == null;
    final bool pendingOut = item.clockOut != null && (item.needsApproval1 ?? false) && item.isApprove1 == null && item.isReject1 == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: Color(grey10Color),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('EEE').format(date), style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(width: 8),

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
                    _buildInlineBadge('Pending', Color(orangeAccentColor)),
                  ] else ...[
                    Text(
                      item.clockIn != null ? (DateTime.tryParse(item.clockIn!) != null ? DateHelper.formatTime(DateTime.tryParse(item.clockIn!)!) : item.clockIn!) : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (item.isApprove0 == 1)
                      _buildInlineBadge('Approved', const Color(clockInColor))
                    else if (item.isReject0 == 1)
                      _buildInlineBadge('Rejected', const Color(clockOutColor)),
                  ],
                ],
              ),
            ),
          ),

          Container(width: 1, height: 40, color: Color(grey9Color)),

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
                    _buildInlineBadge('Pending', Color(orangeAccentColor)),
                  ] else ...[
                    Text(
                      item.clockOut != null ? (DateTime.tryParse(item.clockOut!) != null ? DateHelper.formatTime(DateTime.tryParse(item.clockOut!)!) : item.clockOut!) : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (item.isApprove1 == 1)
                      _buildInlineBadge('Approved', const Color(clockInColor))
                    else if (item.isReject1 == 1)
                      _buildInlineBadge('Rejected', const Color(clockOutColor)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Color(whiteColor), fontSize: 9, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Color(greyShade100),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  AnalyticsService.logEvent('attendance_switch_clock_tab', parameters: {'tab': tabs[index]});
                  _onTabChanged(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Color(primaryColor) : Color(transparentColor),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Color(blackColor).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ] : [],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        tabs[index],
                        maxLines: 1,
                        style: TextStyle(
                          color: isActive ? Color(whiteColor) : Color(greyShade700),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
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
    Widget? statusBadge;
    if (needsApproval) {
      final Color badgeColor;
      final IconData badgeIcon;
      final String badgeLabel;
      if (isApprove == 1) {
        badgeColor = const Color(clockInColor);
        badgeIcon = Icons.check_circle_outline;
        badgeLabel = 'Approved';
      } else if (isReject == 1) {
        badgeColor = const Color(clockOutColor);
        badgeIcon = Icons.cancel_outlined;
        badgeLabel = 'Rejected';
      } else {
        badgeColor = Color(orangeAccentColor);
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
                Icon(badgeIcon, color: Color(whiteColor), size: 12),
                const SizedBox(width: 4),
                Text(badgeLabel, style: const TextStyle(color: Color(whiteColor), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    }

    final raw = flagParam == 0 ? attendance?.clockIn : flagParam == 1 ? attendance?.clockOut : attendance?.checkInActivity;
    final dt = raw != null ? DateTime.tryParse(raw) : null;

    return Expanded(
      child: dt != null && flagParam != 6
          ? GestureDetector(
              onTap: () { if (attendance != null) _showAttendanceDialog(attendance, flagParam); },
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 170.0;
                  final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 170.0;
                  final size = [maxW, maxH, 170.0].reduce((a, b) => a < b ? a : b);
                  return Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: image != null
                                ? DriveImage(
                                    url: image,
                                    width: size,
                                    height: size,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      color: Color(primaryColor).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.punch_clock, size: size * 0.4, color: Color(primaryColor).withValues(alpha: 0.4)),
                                  ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(blue2Color).withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.access_time_filled, color: flagParam == 0 ? Color(greenPercentColor) : flagParam == 1 ? Color(redPeriodColor) : Color(checkInColor), size: 10),
                                    const SizedBox(width: 6),
                                    Text(DateHelper.formatTime(dt), style: const TextStyle(color: Color(whiteColor), fontSize: 10)),
                                  ]),
                                  Row(children: [
                                    Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 10),
                                    const SizedBox(width: 6),
                                    Text(DateHelper.formatDate(dt), style: const TextStyle(color: Color(whiteColor), fontSize: 10)),
                                  ]),
                                  Row(children: [
                                    Icon(Icons.location_on, color: Color(primaryColor), size: 10),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${flagParam == 0 ? attendance?.location0 : flagParam == 1 ? attendance?.location1 : attendance?.location6}',
                                        style: const TextStyle(color: Color(whiteColor), fontSize: 10),
                                        maxLines: 1,
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
                                  onTap: _isCameraOpening ? null : () {
                                    AnalyticsService.logEvent('attendance_retry_rejected_clock');
                                    _handleMoveCamera(title, flagParam);
                                  },
                                 child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Color(primaryColor),
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: const Icon(Icons.refresh, size: 18, color: Color(whiteColor)),
                                 ),
                               )),
                              ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            )
          : 
          SingleChildScrollView(
              reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateHelper.formatTime(AppTime.now()), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(DateHelper.formatDate(AppTime.now()), style: TextStyle(fontSize: 11, color: Color(grey6Color))),
                  const SizedBox(height: 8),
                  Material(
                    color: Color(transparentColor),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () {
                        if (_isClockButtonDisabled(flagParam)) {
                          showSnackbar(context, 'Anda tidak punya akses', isError: true);
                          return;
                        }
                        if (_isCameraOpening) return;
                        AnalyticsService.logEvent(switch (flagParam) {
                          0 => 'attendance_clock_in',
                          1 => 'attendance_clock_out',
                          _ => 'attendance_check_in_activity',
                        });
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
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Color(_isCameraOpening || _isClockButtonDisabled(flagParam) ? grey6Color : primaryColor)),
                            child: _isCameraOpening
                                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Color(whiteColor), strokeWidth: 2.5))
                                : Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(whiteColor))),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    flagParam == 6 ? "Hanya untuk ambil foto aktivitas hari ini" : "Please $title!",
                    style: TextStyle(fontSize: 12, color:flagParam == 6 ? Color(redColor) : Color(grey6Color)),
                  ),
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


    
  Widget _buildImageErrorWidget({String? serial, double height = 180}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Color(primaryColor).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.punch_clock, size: 50, color: Color(primaryColor).withValues(alpha: 0.4)),
    );
  }

  void _showAttendanceDialog(AttendanceEntity item, int flag) {
    AnalyticsService.logEvent('attendance_view_attendance_detail');
    final String timeValue = flag == 0
        ? item.clockIn ?? "-"
        : flag == 1
            ? item.clockOut ?? "-"
            : item.checkInActivity ?? "-";
    final List<String>? images = flag == 0
        ? item.fileAttchment0
        : flag == 1
            ? item.fileAttchment1
            : item.fileAttchment6;
    final String note = flag == 0
        ? item.note0 ?? "-"
        : flag == 1
            ? item.note1 ?? "-"
            : item.note6 ?? "-";
    final String location = flag == 0
        ? item.location0 ?? "-"
        : flag == 1
            ? item.location1 ?? "-"
            : item.location6 ?? "-";
    final int? isApprove = flag == 0 ? item.isApprove0 : flag == 1 ? item.isApprove1 : null;
    final int? isReject = flag == 0 ? item.isReject0 : flag == 1 ? item.isReject1 : null;
    final String? approveName = flag == 0 ? item.approveName0 : flag == 1 ? item.approveName1 : null;
    final String? rejectName = flag == 0 ? item.rejectName0 : flag == 1 ? item.rejectName1 : null;
    final String? serial = flag == 0 ? item.serial0 : flag == 1 ? item.serial1 : item.serial6;

    final String displayTime = (timeValue != '-') ? (DateTime.tryParse(timeValue) != null ? DateHelper.formatTime(DateTime.tryParse(timeValue)!) : timeValue) : '-';
    final String? displayImage = (images != null && images.isNotEmpty)
        ? (flag == 1 ? images.last : images.first)
        : null;

    showDialog(
      context: context,
      barrierColor: Color(blackColor).withValues(alpha: 0.54),
      builder: (context) {
        return Dialog(
          backgroundColor: Color(whiteColor),
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
                                errorWidget: _buildImageErrorWidget(serial: serial),
                                onTap: () => _showImagePreview(context, images!, flag == 1 ? images.length - 1 : 0),
                              )
                            : _buildImageErrorWidget(serial: serial),
                      ),
                      if (displayImage != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _showImagePreview(context, images!, flag == 1 ? images.length - 1 : 0),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(blackColor).withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.fullscreen, color: Color(whiteColor), size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time_filled,
                    displayTime,
                    Color(flag == 0 ? greenPercentColor : flag == 1 ? redPeriodColor : checkInColor),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateHelper.formatDate(DateTime.tryParse(item.date) ?? DateTime(2000)),
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
                      isApprove == 1 ? const Color(clockInColor) : const Color(clockOutColor),
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

class _ActivityEntry {
  final AttendanceActivityEntity item;
  final String typeLabel;
  final Color typeColor;
  final int cardIndex;

  const _ActivityEntry({
    required this.item,
    required this.typeLabel,
    required this.typeColor,
    required this.cardIndex,
  });
}

class _ActivityRow {
  final String date;
  final _ActivityEntry? entry;

  const _ActivityRow({required this.date, this.entry});
}

class _ActivityCard extends StatefulWidget {
  final String fullName;
  final String? photoUrl;
  final String type;
  final Color typeColor;
  final String? datetime;
  final String? location;
  final String? contactName;
  final int? contactId;
  final String? note;
  final List<String> images;
  final void Function(String url) onImageTap;
  final int? statusValidasi;
  final String? noteValidasi;
  final int? logId;
  final bool canVerify;
  final bool isSelf;
  final VoidCallback? onValidated;
  final VoidCallback? onFullyLoaded;
  final AttendanceFeedbackEntity? feedback;

  const _ActivityCard({
    super.key,
    required this.fullName,
    this.photoUrl,
    required this.type,
    required this.typeColor,
    required this.datetime,
    required this.location,
    required this.contactName,
    this.contactId,
    required this.note,
    required this.images,
    required this.onImageTap,
    this.statusValidasi,
    this.noteValidasi,
    this.logId,
    this.canVerify = false,
    this.isSelf = false,
    this.onValidated,
    this.onFullyLoaded,
    this.feedback,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late final ScrollController _scrollController;
  bool _isAtStart = true;
  bool _isAtEnd = false;
  bool _photoError = false;

  int _loadedImageCount = 1;
  bool _fullyLoadedFired = false;

  void _advanceImageLoad(int index) {
    if (!mounted) return;
    if (index != _loadedImageCount - 1) return;
    if (_loadedImageCount >= widget.images.length) {
      _fireFullyLoaded();
      return;
    }
    setState(() => _loadedImageCount++);
  }

  void _fireFullyLoaded() {
    if (_fullyLoadedFired) return;
    _fullyLoadedFired = true;
    widget.onFullyLoaded?.call();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollState);
    if (widget.images.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fireFullyLoaded();
      });
    }
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
              AnalyticsService.logEvent('attendance_validate_checkin_reject');
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
            child: const Text('Kirim', style: TextStyle(color: Color(clockOutColor))),
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
          Icon(Icons.thumb_up_rounded, color: Color(clockInColor), size: 18),
        ],
      );
    } else if (widget.statusValidasi == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_down_rounded, color: Color(clockOutColor), size: 18),
            ],
          ),
          if (widget.noteValidasi != null && widget.noteValidasi!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.noteValidasi!,
              style: const TextStyle(fontSize: 12, color: Color(greyShade500)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    } else {
      if (widget.isSelf || widget.logId == null) return const SizedBox();
      if (!widget.canVerify) {
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Color(orangeAccentColor), size: 16),
            SizedBox(width: 6),
            Text('Menunggu validasi', style: TextStyle(color: Color(orangeAccentColor), fontSize: 12)),
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
                border: Border.all(color: const Color(clockOutColor)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thumb_down_rounded, color: Color(clockOutColor), size: 16),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              AnalyticsService.logEvent('attendance_validate_checkin_approve');
              context.read<AttendanceActivityBloc>().add(
                ValidasiCheckInEvent(logId: widget.logId!, statusValidasi: 1),
              );
              widget.onValidated?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(clockInColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thumb_up_rounded, color: Color(whiteColor), size: 16),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFeedbackSection() {
    final feedback = widget.feedback;
    if (feedback == null) return const SizedBox();

    final isOk = feedback.verdict == 1;
    final color = isOk ? const Color(clockInColor) : const Color(clockOutColor);
    final icon = isOk ? Icons.check_circle_rounded : Icons.error_rounded;
    final label = feedback.verdictLabel ?? (isOk ? 'Sesuai' : 'Perlu Perbaikan');
    final categoryLabels = feedback.categories.map((c) => attendanceFeedbackCategoryLabels[c] ?? c).toList();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Feedback: $label',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (categoryLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categoryLabels.map((label) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
          if (feedback.note != null && feedback.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feedback.note!,
              style: const TextStyle(fontSize: 12, color: Color(greyShade500)),
            ),
          ],
        ],
      ),
    );
  }

  void _openContactActivity(BuildContext context) {
    print("debug contact ${widget.contactId} ${widget.contactName}");
    context.pushNamed(
      'detailContact',
      extra: ContactDetailArgs(
        dataContact: ContactEntity(contactId: widget.contactId, fullName: widget.contactName ?? widget.fullName),
        initialTab: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deferImageLoad = Scrollable.recommendDeferredLoadingForContext(context);
    final card = Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(blackColor).withValues(alpha: 0.06),
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
                                  const Icon(Icons.person_outline, size: 11, color: Color(visitColor)),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(widget.contactName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(visitColor))),
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
                    Text(
                      () {
                        final dt = DateTime.tryParse(widget.datetime ?? '');
                        return dt != null ? DateHelper.formatTime(dt) : (widget.datetime ?? '-');
                      }(),
                      style: const TextStyle(fontSize: 10),
                    ),

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
          if (widget.images.isNotEmpty && deferImageLoad)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(greyShade200),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else if (widget.images.isNotEmpty)
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
                          if (index >= _loadedImageCount) {
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: imageWidth,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Color(greyShade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
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
                                onLoad: () => _advanceImageLoad(index),
                                errorWidget: Container(
                                  width: imageWidth,
                                  height: 200,
                                  color: Color(greyShade200),
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
                            decoration: BoxDecoration(color: Color(blackColor).withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_ios, color: Color(whiteColor), size: 16),
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
                            decoration: BoxDecoration(color: Color(blackColor).withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_ios, color: Color(whiteColor), size: 16),
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
          if (widget.feedback != null) _buildFeedbackSection(),
        ],
      ),
    );

    if (widget.type == 'Visit' && widget.contactId != null) {
      return GestureDetector(
        onTap: () => _openContactActivity(context),
        child: card,
      );
    }
    return card;
  }
}
