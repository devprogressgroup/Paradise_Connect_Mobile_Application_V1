import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/attandance/data/arguments/attandance_args.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';

class CameraPage extends StatefulWidget {
  final AttandanceArgs args;

  const CameraPage({super.key, required this.args});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  XFile? _imageFile;
  int _cameraIndex = 0;
  bool get _isCameraReady =>_controller != null && _controller!.value.isInitialized;
  List<CameraDescription>? _cameras;
  bool _isSwitching = false;


  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      _controller = CameraController(
        _cameras![_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("ERROR CAMERA: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final file = await _controller!.takePicture();
      setState(() {
        _imageFile = file;
      });
    } catch (e) {
      debugPrint("ERROR TAKE PICTURE: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    setState(() => _isSwitching = true);

    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;

    await _controller?.dispose();

    _controller = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() => _isSwitching = false);
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
           customHeader(context,widget.args.type ?? "-",colorBg: Color(primaryColor),colorBack: Color(whiteColor),colorTitle: Color(whiteColor),isBack: true),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
  Widget _buildBody() {
    if (!_isCameraReady || _isSwitching) {
      return Center(child: CircularProgressIndicator());
    }
    if (_imageFile != null) {
      return _buildPreview();
    }
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
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
          Text(widget.args.location ?? "",style: const TextStyle(color: Colors.white)),
          Text(widget.args.time ?? "",style: const TextStyle(color: Colors.white)),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: 70),
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
        GestureDetector(
          onTap: _switchCamera,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
          ),
        ),
      ],
    ));
  }

  Widget _buildPreview(){
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              child: Image.file(File(_imageFile!.path),fit: BoxFit.cover,)),
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
                        Icon(Icons.access_time_filled, color: Color(greenPercentColor)),
                        SizedBox(width: 10),
                        Text(widget.args.time ?? "",style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_sharp, color: Color(primaryColor)),
                        SizedBox(width: 10),
                        Text(DateHelper.formatDayDate(DateTime.now()),style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Color(primaryColor)),
                        SizedBox(width: 10),
                        Container(
                          width: 250,
                          child: Text(
                            widget.args.location ?? "",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal:  16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text("Pameran/ Open Table (optional)", style: TextStyle(fontSize: 14, color: Color(grey2Color)),),
              SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(grey4Color))
                ),
              ),
              SizedBox(height: 20),
              Text("Notes", style: TextStyle(fontSize: 14, color: Color(grey2Color)),),
              SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(grey4Color))
                ),
              ),
              SizedBox(height: 40,),
              customButton((){ context.pop();}, "Submit")
            ],
          ),
        ),
        
      ],
    );
  }
}