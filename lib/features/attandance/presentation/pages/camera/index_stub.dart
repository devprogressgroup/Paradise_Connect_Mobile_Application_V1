// Web-only camera implementation using browser getUserMedia API.
// Loaded via conditional export in index.dart when dart.library.io is false.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/attandance/data/arguments/attandance_args.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/office_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/pameran_location/pameran_location_cubit.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';

enum _CameraStatus { requesting, ready, error }

enum _CameraError { permissionDenied, noDevice, inUse, insecure, unknown }

// ── Outer coordinator ────────────────────────────────────────────────────────

class CameraPage extends StatefulWidget {
  final AttandanceArgs args;
  const CameraPage({super.key, required this.args});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<Uint8List> _imageBytesList = [];
  List<String> _imageDataUrls = [];
  bool _onSubmitPage = false;

  bool get _isMultiplePhotosSupported =>
      widget.args.type?.toLowerCase() == 'checkin' || widget.args.flag == 6;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSubmitSuccess) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/attandance');
          }
        } else if (state is AttendanceError) {
          debugPrint('AttendanceError: ${state.message}');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Gagal'),
              // Tampilkan pesan asli backend (mis. "NIK absensi belum diatur") bukan teks generik.
              content: Text(
                state.message.replaceFirst('Exception: ', '').trim().isEmpty
                    ? 'Gagal menyimpan data kehadiran'
                    : state.message.replaceFirst('Exception: ', '').trim(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _onSubmitPage
              ? _WebSubmitPage(
                  args: widget.args,
                  imageBytesList: _imageBytesList,
                  imageDataUrls: _imageDataUrls,
                  onRetake: () => setState(() {
                    _imageBytesList = [];
                    _imageDataUrls = [];
                    _onSubmitPage = false;
                  }),
                  onAddMore: _isMultiplePhotosSupported
                      ? (bytes, urls) => setState(() {
                            _imageBytesList = bytes;
                            _imageDataUrls = urls;
                            _onSubmitPage = false;
                          })
                      : null,
                )
              : _WebCameraPage(
                  args: widget.args,
                  initialBytes: _imageBytesList,
                  initialUrls: _imageDataUrls,
                  onCapture: (bytes, urls) => setState(() {
                    _imageBytesList = bytes;
                    _imageDataUrls = urls;
                    _onSubmitPage = true;
                  }),
                ),
        ),
      ),
    );
  }
}

// ── Camera page ──────────────────────────────────────────────────────────────

class _WebCameraPage extends StatefulWidget {
  final AttandanceArgs args;
  final List<Uint8List> initialBytes;
  final List<String> initialUrls;
  final void Function(List<Uint8List>, List<String>) onCapture;

  const _WebCameraPage({
    required this.args,
    required this.initialBytes,
    required this.initialUrls,
    required this.onCapture,
  });

  @override
  State<_WebCameraPage> createState() => _WebCameraPageState();
}

class _WebCameraPageState extends State<_WebCameraPage> {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  _CameraStatus _status = _CameraStatus.requesting;
  _CameraError? _error;
  final String _viewId = 'web-camera-${DateTime.now().millisecondsSinceEpoch}';

  late List<Uint8List> _imageBytesList;
  late List<String> _imageDataUrls;

  bool get _isMultiplePhotosSupported =>
      widget.args.type?.toLowerCase() == 'checkin' || widget.args.flag == 6;

  @override
  void initState() {
    super.initState();
    _imageBytesList = List.from(widget.initialBytes);
    _imageDataUrls = List.from(widget.initialUrls);
    _setupAndRegister();
  }

  void _setupAndRegister() {
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => video);
    _video = video;
    _requestCamera();
  }

  Future<void> _requestCamera() async {
    if (mounted) setState(() => _status = _CameraStatus.requesting);
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      }).timeout(const Duration(seconds: 15));
      _video!.srcObject = stream;
      _stream = stream;
      // Don't await play() — browser can interrupt it when widget rebuilds
      _video!.play().catchError((_) {});
      await _video!.onCanPlay.first.timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _status = _CameraStatus.ready);
    } on TimeoutException catch (_) {
      if (mounted) setState(() {
        _status = _CameraStatus.error;
        _error = _CameraError.unknown;
      });
    } catch (e) {
      if (mounted) setState(() {
        _status = _CameraStatus.error;
        _error = _parseError(e);
      });
    }
  }

  _CameraError _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('notallowed') || msg.contains('permissiondenied') || msg.contains('permission')) {
      return _CameraError.permissionDenied;
    }
    if (msg.contains('notfound') || msg.contains('devicenotfound')) {
      return _CameraError.noDevice;
    }
    if (msg.contains('notreadable') || msg.contains('trackstart') || msg.contains('abort')) {
      return _CameraError.inUse;
    }
    if (msg.contains('security') || msg.contains('https')) {
      return _CameraError.insecure;
    }
    return _CameraError.unknown;
  }

  void _takePicture() {
    final video = _video;
    if (video == null || video.videoWidth == 0) return;

    final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    canvas.context2D.drawImage(video, 0, 0);
    double quality = 0.8;
    String dataUrl;
    Uint8List bytes;
    do {
      dataUrl = canvas.toDataUrl('image/jpeg', quality);
      bytes = Uint8List.fromList(base64Decode(dataUrl.split(',')[1]));
      quality -= 0.1;
    } while (bytes.lengthInBytes > 300 * 1024 && quality > 0.1);

    if (widget.args.skipPreview == true) {
      if (mounted) context.pop(bytes);
      return;
    }

    setState(() {
      _imageBytesList.add(bytes);
      _imageDataUrls.add(dataUrl);
    });

    if (!_isMultiplePhotosSupported) {
      widget.onCapture(List.from(_imageBytesList), List.from(_imageDataUrls));
    }
  }

  @override
  void dispose() {
    _stream?.getTracks().forEach((t) => t.stop());
    _video?.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        customHeader(
          context,
          widget.args.type ?? '-',
          colorBg: Color(primaryColor),
          colorBack: Color(whiteColor),
          colorTitle: Color(whiteColor),
          isBack: true,
          iconLeft: _isMultiplePhotosSupported && _imageBytesList.isNotEmpty ? Icons.close : null,
          iconLeftOnTap: () {
            setState(() {
              _imageBytesList.clear();
              _imageDataUrls.clear();
            });
            _requestCamera();
          },
          colorIconLeft: Color(whiteColor),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _CameraStatus.requesting:
        return _buildRequesting();
      case _CameraStatus.error:
        return _buildError(_error ?? _CameraError.unknown);
      case _CameraStatus.ready:
        return _buildCameraView();
    }
  }

  Widget _buildRequesting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Meminta akses kamera...', style: TextStyle(fontSize: 14, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Izinkan akses kamera di popup browser.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: _viewId)),
        // Thumbnail strip for multiple photos
        if (_isMultiplePhotosSupported && _imageBytesList.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageBytesList.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageDataUrls[i], width: 60, height: 60, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(widget.args.location ?? '', style: const TextStyle(color: Colors.white)),
              Text(widget.args.time ?? '', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(primaryColor),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                ),
              ),
              if (_isMultiplePhotosSupported && _imageBytesList.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => widget.onCapture(
                    List.from(_imageBytesList),
                    List.from(_imageDataUrls),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Selesai (${_imageBytesList.length} foto)'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(_CameraError error) {
    final info = _errorInfo(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(info.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(info.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            if (info.steps != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text(info.steps!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.6)),
              ),
            ],
            if (error != _CameraError.insecure) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ErrorInfo _errorInfo(_CameraError error) {
    switch (error) {
      case _CameraError.permissionDenied:
        return _ErrorInfo(
          icon: Icons.no_photography_outlined,
          title: 'Akses Kamera Ditolak',
          message: 'Browser tidak mendapat izin mengakses kamera.',
          steps: '1. Klik ikon 🔒 / kamera di address bar browser\n2. Ubah izin Kamera ke "Izinkan"\n3. Refresh halaman lalu coba lagi',
        );
      case _CameraError.noDevice:
        return _ErrorInfo(icon: Icons.videocam_off_outlined, title: 'Kamera Tidak Ditemukan', message: 'Perangkat tidak memiliki kamera atau kamera tidak terdeteksi.\nPastikan kamera sudah terpasang dan tidak dinonaktifkan.');
      case _CameraError.inUse:
        return _ErrorInfo(icon: Icons.camera_outlined, title: 'Kamera Sedang Digunakan', message: 'Kamera sedang dipakai oleh aplikasi atau tab lain.\nTutup aplikasi lain yang menggunakan kamera, lalu coba lagi.');
      case _CameraError.insecure:
        return _ErrorInfo(icon: Icons.lock_open_outlined, title: 'Koneksi Tidak Aman', message: 'Browser hanya mengizinkan akses kamera melalui koneksi HTTPS.\nHubungi administrator untuk mengaktifkan HTTPS.');
      case _CameraError.unknown:
        return _ErrorInfo(icon: Icons.error_outline, title: 'Kamera Tidak Dapat Dibuka', message: 'Terjadi kesalahan saat membuka kamera.');
    }
  }
}

// ── Submit page ──────────────────────────────────────────────────────────────

class _WebSubmitPage extends StatefulWidget {
  final AttandanceArgs args;
  final List<Uint8List> imageBytesList;
  final List<String> imageDataUrls;
  final VoidCallback onRetake;
  final void Function(List<Uint8List>, List<String>)? onAddMore;

  const _WebSubmitPage({
    required this.args,
    required this.imageBytesList,
    required this.imageDataUrls,
    required this.onRetake,
    this.onAddMore,
  });

  @override
  State<_WebSubmitPage> createState() => _WebSubmitPageState();
}

class _WebSubmitPageState extends State<_WebSubmitPage> {
  late List<Uint8List> _imageBytesList;
  late List<String> _imageDataUrls;

  final TextEditingController notesTC = TextEditingController();
  final TextEditingController pameranTC = TextEditingController();
  final FocusNode notesFN = FocusNode();
  AttendanceLocation? _selectedPameranLocation;

  bool get _isMultiplePhotosSupported =>
      widget.args.type?.toLowerCase() == 'checkin' || widget.args.flag == 6;

  bool get _showRealtimeLocationWarning {
    final flag = widget.args.flag;
    if (flag != 0 && flag != 1) return false;
    return _selectedPameranLocation == null;
  }

  @override
  void initState() {
    super.initState();
    _imageBytesList = List.from(widget.imageBytesList);
    _imageDataUrls = List.from(widget.imageDataUrls);
    context.read<OfficeLocationCubit>().load();
    context.read<PameranLocationCubit>().load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoFillLocation());
  }

  void _tryAutoFillLocation() {
    if (widget.args.locationId == null) return;
    final isClockInOut = widget.args.flag == 0 || widget.args.flag == 1;
    final locationList = isClockInOut
        ? context.read<OfficeLocationCubit>().state
        : context.read<PameranLocationCubit>().state;
    if (locationList.isEmpty) return;
    final match = locationList.cast<AttendanceLocation?>().firstWhere(
      (e) => e?.id == widget.args.locationId,
      orElse: () => null,
    );
    if (match != null) {
      setState(() {
        _selectedPameranLocation = match;
        pameranTC.text = match.name;
      });
    }
  }

  void _handleSubmit() {
    if (_imageBytesList.isEmpty) return;

    

    if (widget.args.isReturnImage == true) {
      context.pop(_imageBytesList.first);
      return;
    }

    final flag = widget.args.flag;
    final datetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final location = pameranTC.text.isNotEmpty
        ? pameranTC.text
        : (widget.args.location ?? 'Unknown');

    final activeLocationId = _selectedPameranLocation?.id ?? widget.args.locationId;
    // Koordinat yang disimpan = posisi GPS asli device (dibawa dari halaman utama via args),
    // bukan koordinat statis kantor/pameran. Identitas lokasi tetap via activeLocationId.
    final activeLat = widget.args.latitude;
    final activeLng = widget.args.longitude;

    if (_isMultiplePhotosSupported) {
      context.read<AttendanceBloc>().add(SubmitAttendanceActivityEvent(
        datetime: datetime,
        flag: flag!,
        location: location,
        note: notesTC.text,
        filePaths: const [],
        fileBytesData: _imageBytesList,
        locationId: activeLocationId,
        latitude: activeLat,
        longitude: activeLng,
      ));
    } else {
      context.read<AttendanceBloc>().add(SubmitAttendanceEvent(
        datetime: datetime,
        flag: flag!,
        location: location,
        note: notesTC.text,
        fileBytes: _imageBytesList.first,
        locationId: activeLocationId,
        latitude: activeLat,
        longitude: activeLng,
      ));
    }
  }

  @override
  void dispose() {
    notesTC.dispose();
    pameranTC.dispose();
    notesFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OfficeLocationCubit, List<AttendanceLocation>>(
          listener: (_, __) {
            if ((widget.args.flag == 0 || widget.args.flag == 1) && _selectedPameranLocation == null) {
              _tryAutoFillLocation();
            }
          },
        ),
        BlocListener<PameranLocationCubit, List<AttendanceLocation>>(
          listener: (_, __) {
            if (widget.args.flag == 6 && _selectedPameranLocation == null) {
              _tryAutoFillLocation();
            }
          },
        ),
      ],
      child: Column(
        children: [
          customHeader(
            context,
            widget.args.type ?? '-',
            colorBg: Color(primaryColor),
            colorBack: Color(whiteColor),
            colorTitle: Color(whiteColor),
            isBack: true,
            iconLeft: Icons.history,
            iconLeftOnTap: widget.onRetake,
            colorIconLeft: Color(whiteColor),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final isLoading = state is AttendanceSubmitLoading;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                color: Color(whiteColor),
                child: Column(
                  children: [
                    // Single photo preview
                    if (!_isMultiplePhotosSupported)
                      Stack(
                        children: [
                          SizedBox(
                            height: 330,
                            width: double.infinity,
                            child: Image.network(_imageDataUrls.first, fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              color: Color(blue2Color).withValues(alpha: 0.5),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(children: [Icon(Icons.access_time_filled, color: Color(greenPercentColor), size: 25), const SizedBox(width: 10), Text(widget.args.time ?? '-', style: const TextStyle(color: Colors.white))]),
                                  const SizedBox(height: 10),
                                  Row(children: [Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 25), const SizedBox(width: 10), Text(DateHelper.formatDate(DateTime.now()), style: const TextStyle(color: Colors.white))]),
                                  const SizedBox(height: 10),
                                  Row(children: [Icon(Icons.location_on, color: Color(primaryColor), size: 25), const SizedBox(width: 10), SizedBox(width: 250, child: Text(widget.args.location ?? '-', style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis))]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    // Multiple photos preview
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Check In Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color))),
                                if (widget.onAddMore != null)
                                  IconButton(
                                    onPressed: () => widget.onAddMore!(
                                      List.from(_imageBytesList),
                                      List.from(_imageDataUrls),
                                    ),
                                    icon: Icon(Icons.camera_alt, color: Color(primaryColor)),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _imageBytesList.length,
                              itemBuilder: (context, index) => Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(_imageDataUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _imageBytesList.removeAt(index);
                                        _imageDataUrls.removeAt(index);
                                      }),
                                      child: Container(
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoField(label: 'Location', value: widget.args.location ?? '-'),
                          const SizedBox(height: 8),
                          _buildInfoField(label: 'Time', value: widget.args.time ?? '-'),
                          const SizedBox(height: 8),
                          _buildInfoField(label: 'Date', value: DateHelper.formatDate(DateTime.now())),
                        ],
                      ),

                    if (widget.args.isReturnImage != true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text('Office / Pameran / Open Table (optional)', style: TextStyle(fontSize: 14, color: Color(grey2Color))),
                            const SizedBox(height: 5),

                            if (widget.args.flag == 0 || widget.args.flag == 1)
                              Container(
                                width: double.infinity,
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Color(grey10Color),
                                  border: Border.all(color: Color(grey8Color), width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  pameranTC.text.isNotEmpty ? pameranTC.text : '-',
                                  style: TextStyle(fontSize: 14, color: Color(grey2Color)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 50,
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(grey8Color), width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final locationList = context.read<PameranLocationCubit>().state;
                                    if (locationList.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Data lokasi belum tersedia, silahkan tunggu sebentar'), duration: Duration(seconds: 2)),
                                      );
                                      return;
                                    }
                                    final items = locationList.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                                    final result = await context.pushNamed(
                                      'attendanceOwnerDropdown',
                                      extra: ContactDropdownArgs(title: 'Pilih Pameran', items: items, selectedId: _selectedPameranLocation?.id, isMultiSelect: false),
                                    );
                                    if (result != null) {
                                      final selected = result as OwnerDropdownItem;
                                      final fullLoc = locationList.firstWhere((e) => e.id == selected.id);
                                      setState(() {
                                        _selectedPameranLocation = fullLoc;
                                        pameranTC.text = selected.name;
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          enabled: false,
                                          controller: pameranTC,
                                          decoration: InputDecoration(
                                            hintText: 'Pilih Pameran',
                                            hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_up),
                                      const SizedBox(width: 5),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 8),
                            Text('Notes', style: TextStyle(fontSize: 14, color: Color(grey2Color))),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 80,
                              child: TextFormField(
                                maxLines: null,
                                minLines: 3,
                                controller: notesTC,
                                focusNode: notesFN,
                                onTapOutside: (_) => notesFN.unfocus(),
                                decoration: InputDecoration(
                                  hintText: 'Enter notes...',
                                  hintStyle: TextStyle(fontSize: 14, color: Color(grey4Color)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(grey8Color))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(grey8Color))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(primaryColor))),
                                ),
                              ),
                            ),
                            BlocBuilder<ProfileBloc, ProfileState>(
                              builder: (context, profileState) {
                                final hasAtasan = profileState is ProfileLoaded && () {
                                  final profile = profileState.profile;
                                  final myPos = profile.positionName ?? '';
                                  if (myPos == 'General Manager') return false;
                                  if (myPos == 'Sales Manager') return profile.salesRoles.isNotEmpty;
                                  if (myPos == 'Sales Supervisor') return profile.salesRoles.any((r) => const ['General Manager', 'Sales Manager'].contains(r.positionName));
                                  return profile.salesRoles.isNotEmpty;
                                }();
                                final showWarning = _showRealtimeLocationWarning && hasAtasan;
                                final label = showWarning ? "Request Approval" : "Submit";
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showWarning) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: const [
                                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Absensi diluar lokasi kerja memerlukan approval atasan',
                                              style: TextStyle(color: Colors.orange, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: 20),
                                    customButton(_handleSubmit, label),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: customButton(_handleSubmit, 'Confirm Photo'),
                      ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoField({required String label, String? value}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Color(grey2Color))),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(grey8Color))),
            child: Text(value ?? '-', style: TextStyle(fontSize: 13, color: Color(grey2Color)), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ErrorInfo {
  final IconData icon;
  final String title;
  final String message;
  final String? steps;
  const _ErrorInfo({required this.icon, required this.title, required this.message, this.steps});
}
