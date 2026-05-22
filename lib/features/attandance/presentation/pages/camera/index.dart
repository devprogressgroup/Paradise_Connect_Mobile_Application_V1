import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/attandance/data/arguments/attandance_args.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';

class CameraPage extends StatefulWidget {
  final AttandanceArgs args;

  const CameraPage({super.key, required this.args});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  TextEditingController notesTC = TextEditingController();
  TextEditingController pameranTC = TextEditingController();
  FocusNode notesFN = FocusNode();
  FocusNode pameranFN = FocusNode();
  CameraController? _controller;
  List<XFile> _imageFiles = [];
  int _cameraIndex = 0;
  bool get _isCameraReady => _controller != null && _controller!.value.isInitialized;
  bool get _isMultiplePhotosSupported => widget.args.type?.toLowerCase() == 'checkin' || widget.args.flag == 6;
  List<CameraDescription>? _cameras;
  bool _isSwitching = false;
  bool _isAddingMore = false;
  int? _selectedLocationId;


  @override
  void initState() {
    super.initState();
    _initCamera();
    context.read<AttendanceBloc>().add(GetOfficeLocationsEvent());
    context.read<AttendanceBloc>().add(GetLocationsEvent());
  }


  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Camera not found on this device")),
          );
        }
        return;
      }

      // cari kamera depan
      final frontCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      // kalau ada pakai depan, kalau tidak fallback ke 0
      _cameraIndex = frontCameraIndex != -1 ? frontCameraIndex : 0;

      _controller = CameraController(
        _cameras![_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("ERROR CAMERA: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open camera: $e")),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final file = await _controller!.takePicture();
      if (widget.args.skipPreview == true) {
        if (mounted) {
          context.pop(file.path);
        }
        return;
      }
      setState(() {
        _imageFiles.add(file);
        _isAddingMore = false;
      });
    } catch (e) {
      debugPrint("ERROR TAKE PICTURE: $e");
    }
  }

  void _takeMorePhotos() {
    setState(() {
      _isAddingMore = true;
    });
  }



  void _handleSubmit() {
    if (_imageFiles.isEmpty) return;

    if (widget.args.isReturnImage == true) {
      context.pop(_imageFiles.first.path);
      return;
    }

    final flag = widget.args.flag;
    final datetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final location = pameranTC.text.isNotEmpty ? pameranTC.text : (widget.args.location ?? "Unknown");

    int nikNumber = 0;
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      nikNumber = profileState.profile.nikNumber ?? 0;
    }

    if (_isMultiplePhotosSupported) {
      context.read<AttendanceBloc>().add(SubmitAttendanceActivityEvent(datetime: datetime,flag: flag!,location: location,note: notesTC.text,filePaths: _imageFiles.map((e) => e.path).toList(),nikNumber: nikNumber,));
    } else {
      context.read<AttendanceBloc>().add(SubmitAttendanceEvent(datetime: datetime,flag: flag!,location: location,note: notesTC.text,filePath: _imageFiles.first.path,nikNumber: nikNumber,));
    }
  }




  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attendance recorded successfully!")),
          );
          
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/attandance');
          }
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              customHeader(
                context,
                widget.args.type ?? "-",
                colorBg: Color(primaryColor),
                colorBack: Color(whiteColor),
                colorTitle: Color(whiteColor),
                isBack: true,
                iconLeft: _isMultiplePhotosSupported
                    ? (_isAddingMore ? Icons.close : null)
                    : (_imageFiles.isNotEmpty ? Icons.history : null),
                iconLeftOnTap: () {
                  setState(() {
                    if (_isAddingMore) {
                      _isAddingMore = false;
                    } else {
                      _imageFiles.clear();
                    }
                  });
                },
                colorIconLeft: Color(whiteColor),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isCameraReady || _isSwitching) {
      return Center(child: CircularProgressIndicator());
    }
    if (_imageFiles.isNotEmpty && !_isAddingMore) {
      return _buildPreview();
    }
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),
        ),
        _buildBottomOverlay(),
      ],
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            widget.args.location ?? "",
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            widget.args.time ?? "",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          _buildCaptureButton(),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(primaryColor),
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPreview() {
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
                    if (!_isMultiplePhotosSupported)
                      Stack(
                        children: [
                          Container(
                            height: 330,
                            width: double.infinity,
                            child: Image.file(File(_imageFiles.first.path), fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Color(blue2Color).withOpacity(0.5),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(children: [Icon(Icons.access_time_filled, color: Color(greenPercentColor), size: 25), SizedBox(width: 10), Text(widget.args.time ?? "-", style: TextStyle(color: Colors.white))]),
                                  SizedBox(height: 10),
                                  Row(children: [Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 25), SizedBox(width: 10), Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(color: Colors.white))]),
                                  SizedBox(height: 10),
                                  Row(children: [Icon(Icons.location_on, color: Color(primaryColor), size: 25), SizedBox(width: 10), SizedBox(width: 250, child: Text(widget.args.location ?? "-", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis))]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Check In Photos",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                                ),
                                IconButton(
                                  onPressed: _takeMorePhotos,
                                  icon: Icon(Icons.camera_alt, color: Color(primaryColor)),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Add Photo',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _imageFiles.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(File(_imageFiles[index].path), width: 100, height: 100, fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imageFiles.removeAt(index)),
                                        child: Container(
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                         _buildfield(label: "Location", value: widget.args.location ?? "-"),
                         SizedBox(height: 8),
                         _buildfield(label: "Time", value: widget.args.time ?? "-"),
                         SizedBox(height: 8),
                         _buildfield(label: "Date", value:DateHelper.formatDate(DateTime.now())),
                        ],
                      ),

                    if (widget.args.isReturnImage != true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                             Text("Pameran/ Open Table (optional)", style: TextStyle(fontSize: 14, color: Color(grey2Color))),
                             SizedBox(height: 5),

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
                                   final state = context.read<AttendanceBloc>().state;
                                   if (state is! AttendanceLoaded || state.locations == null) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(
                                         content: Text('Data lokasi belum tersedia, silahkan tunggu sebentar'),
                                         duration: Duration(seconds: 2),
                                       ),
                                     );
                                     return;
                                   }
                                   final items = state.locations!.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();

                                   final result = await context.pushNamed(
                                     'detailContactDropdown',
                                     extra: ContactDropdownArgs(
                                       title: 'Select Pameran',
                                       items: items,
                                       selectedId: _selectedLocationId,
                                       isMultiSelect: false,
                                     ),
                                   );

                                   if (result != null) {
                                     final selected = result as OwnerDropdownItem;
                                     setState(() {
                                       _selectedLocationId = selected.id;
                                       pameranTC.text = selected.name;
                                     });
                                   }
                                 },
                                 child: Row(
                                   children: [
                                     Expanded(
                                       child: TextField(
                                         enabled: false,
                                         maxLines: 1,
                                         minLines: 1,
                                         controller: pameranTC,
                                         decoration: InputDecoration(
                                           hintText: "Select Pameran",
                                           hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
                                           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                           border: InputBorder.none,
                                         ),
                                       ),
                                     ),
                                     Icon(Icons.keyboard_arrow_up),
                                     SizedBox(width: 5),
                                   ],
                                 ),
                               ),
                             ),

                            SizedBox(height: 8),
                            Text("Notes", style: TextStyle(fontSize: 14, color: Color(grey2Color))),
                            SizedBox(height: 5),

                            Container(
                              height: 80,
                              child: TextFormField(
                                maxLines: null,
                                minLines: 3,
                                controller: notesTC,
                                focusNode: notesFN,
                                onTapOutside: (event) => notesFN.unfocus(),
                                decoration: InputDecoration(
                                  hintText: "Enter notes...",
                                  hintStyle: TextStyle(fontSize: 14, color: Color(grey4Color)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(grey8Color))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(grey8Color))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(primaryColor))),
                                ),
                              ),
                            ),

                            SizedBox(height: 40),
                            customButton(_handleSubmit, "Submit"),
                            SizedBox(height: 20),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: customButton(_handleSubmit, "Confirm Photo"),
                      ),

                  ],
                ),
              ),
            ),

            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildfield({required String label, String? value}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Color(grey2Color))),
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(grey8Color)),
            ),
            child: Text(value ?? "-", style: TextStyle(fontSize: 13, color: Color(grey2Color)), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// widget.args.location ?? "-"
   // Row(children: [Icon(Icons.access_time_filled, color: Color(greenPercentColor), size: 18), SizedBox(width: 10), Text(widget.args.time ?? "-", style: TextStyle(fontSize: 13, color: Color(grey2Color)))]),
                // SizedBox(height: 8),
                // Row(children: [Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 18), SizedBox(width: 10), Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(fontSize: 13, color: Color(grey2Color)))]),
                // SizedBox(height: 8),