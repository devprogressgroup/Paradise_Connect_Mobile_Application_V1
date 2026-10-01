// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Kamera beneran di web/PWA (`getUserMedia`) — `image_picker` di web cuma pakai
/// `<input capture>`, yang di browser desktop malah buka dialog pilih file.
/// Balikannya JPEG bytes (null kalau dibatalkan).
class WebCameraCapture {
  static Future<Uint8List?> open(
    BuildContext context, {
    double? maxDimension,
    int? quality,
  }) {
    return Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _WebCameraCapturePage(maxDimension: maxDimension, quality: quality),
      ),
    );
  }
}

enum _Status { requesting, ready, error }

class _WebCameraCapturePage extends StatefulWidget {
  final double? maxDimension;
  final int? quality;

  const _WebCameraCapturePage({this.maxDimension, this.quality});

  @override
  State<_WebCameraCapturePage> createState() => _WebCameraCapturePageState();
}

class _WebCameraCapturePageState extends State<_WebCameraCapturePage> {
  final String _viewId =
      'web-camera-capture-${DateTime.now().millisecondsSinceEpoch}';
  late final html.VideoElement _video;
  html.MediaStream? _stream;
  _Status _status = _Status.requesting;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = 'black';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => _video);
    _requestCamera();
  }

  Future<void> _requestCamera() async {
    setState(() => _status = _Status.requesting);
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        _fail('Browser tidak mendukung akses kamera (pastikan pakai HTTPS).');
        return;
      }
      // Kamera belakang di HP; di laptop otomatis jatuh ke webcam yang ada.
      final stream = await mediaDevices
          .getUserMedia({
            'video': {
              'facingMode': {'ideal': 'environment'},
              'width': {'ideal': 1920},
              'height': {'ideal': 1080},
            },
            'audio': false,
          })
          .timeout(const Duration(seconds: 15));
      _stream = stream;
      _video.srcObject = stream;
      _video.play().catchError((_) {});
      await _video.onCanPlay.first.timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _status = _Status.ready);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      _fail(
        msg.contains('notallowed') || msg.contains('permission')
            ? 'Akses kamera ditolak. Izinkan kamera lewat ikon 🔒 di address bar, lalu coba lagi.'
            : msg.contains('notfound')
            ? 'Kamera tidak ditemukan di perangkat ini.'
            : msg.contains('notreadable')
            ? 'Kamera sedang dipakai aplikasi/tab lain.'
            : 'Kamera tidak dapat dibuka.',
      );
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _status = _Status.error;
      _errorMessage = message;
    });
  }

  void _capture() {
    final vw = _video.videoWidth;
    final vh = _video.videoHeight;
    if (vw == 0 || vh == 0) return;

    var scale = 1.0;
    final max = widget.maxDimension;
    if (max != null && (vw > max || vh > max)) {
      scale = max / (vw > vh ? vw : vh);
    }
    final w = (vw * scale).round();
    final h = (vh * scale).round();

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImageScaled(_video, 0, 0, w, h);
    final dataUrl = canvas.toDataUrl(
      'image/jpeg',
      (widget.quality ?? 85) / 100,
    );
    final bytes = base64Decode(dataUrl.split(',')[1]);
    Navigator.of(context).pop(Uint8List.fromList(bytes));
  }

  @override
  void dispose() {
    _stream?.getTracks().forEach((t) => t.stop());
    _video.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ambil Foto', style: TextStyle(fontSize: 16)),
      ),
      body: switch (_status) {
        _Status.requesting => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Izinkan akses kamera di popup browser…',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        _Status.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  size: 56,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _requestCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(primaryColor),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        _Status.ready => Stack(
          children: [
            Positioned.fill(child: HtmlElementView(viewType: _viewId)),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(primaryColor),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(primaryColor),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}
