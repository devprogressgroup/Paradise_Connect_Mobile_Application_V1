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
                iconLeft: _imageFiles.isNotEmpty ? Icons.history : null,
                iconLeftOnTap: () {
                  setState(() {
                    _imageFiles.clear();
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
        if (_imageFiles.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isAddingMore = false;
                });
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: Icon(Icons.close, color: Colors.white, size: 25),
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
                    Stack(
                      children: [
                        if (!_isMultiplePhotosSupported)
                          Container(
                            height: 330,
                            width: double.infinity,
                            child: Image.file(File(_imageFiles.first.path), fit: BoxFit.cover),
                          )
                        else
                          Container(
                            height: 330,
                            width: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageFiles.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _imageFiles.length) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        // Trick to show camera again
                                        // We might need a separate state if we want to add more
                                        // But for now, let's just use a special flag or null check
                                      });
                                      _takeMorePhotos();
                                    },
                                    child: Container(
                                      width: 200,
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Color(primaryColor), width: 2, style: BorderStyle.none),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, color: Color(primaryColor), size: 40),
                                          SizedBox(height: 10),
                                          Text("Add Photo", style: TextStyle(color: Color(primaryColor), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Stack(
                                  children: [
                                    Container(
                                      width: 250,
                                      margin: EdgeInsets.all(5),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(_imageFiles[index].path), fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imageFiles.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: Icon(Icons.close, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
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
                                Row(
                                  children: [
                                    Icon(Icons.access_time_filled, color: Color(greenPercentColor), size: 25),
                                    SizedBox(width: 10),
                                    Text(widget.args.time ?? "-", style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_sharp, color: Color(primaryColor), size: 25),
                                    SizedBox(width: 10),
                                    Text(DateHelper.formatDate(DateTime.now()), style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: Color(primaryColor), size: 25),
                                    SizedBox(width: 10),
                                    SizedBox(
                                      width: 250,
                                      child: Text(widget.args.location ?? "-", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.args.isReturnImage != true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                               
                               SizedBox(height: 15),

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
                                   if (state is AttendanceLoaded && state.locations != null) {
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

                            SizedBox(height: 20),
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
}