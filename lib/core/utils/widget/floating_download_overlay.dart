import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class FloatingDownloadManager {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required String url,
    required String filename,
  }) {
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => FloatingDownloadWidget(
        url: url,
        filename: filename,
        onDismiss: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    Overlay.of(context).insert(_entry!);
  }
}

// ---------------------------------------------------------------------------
// Floating card widget
// ---------------------------------------------------------------------------

class FloatingDownloadWidget extends StatefulWidget {
  final String url;
  final String filename;
  final VoidCallback onDismiss;

  const FloatingDownloadWidget({
    super.key,
    required this.url,
    required this.filename,
    required this.onDismiss,
  });

  @override
  State<FloatingDownloadWidget> createState() => _FloatingDownloadWidgetState();
}

class _FloatingDownloadWidgetState extends State<FloatingDownloadWidget>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  String? _localPath;
  String? _error;
  String _resolvedFilename = '';
  CancelToken? _cancelToken;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  bool get _isDone => _localPath != null;

  String get _ext {
    final name = _resolvedFilename.isNotEmpty ? _resolvedFilename : widget.filename;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot).toLowerCase() : '';
  }

  bool get _isVideo =>
      const ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(_ext);

  bool get _isPdf => _ext == '.pdf';

  bool get _isImage =>
      const ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(_ext);

  bool get _canOpen => _isVideo || _isPdf || _isImage;

  String get _openLabel =>
      _isVideo ? 'Tonton' : _isPdf ? 'Buka PDF' : 'Lihat';

  IconData get _openIcon =>
      _isVideo ? Icons.play_circle_outline : _isPdf ? Icons.picture_as_pdf : Icons.image;

  @override
  void initState() {
    super.initState();
    _resolvedFilename = widget.filename;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _download();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    _animController.dispose();
    super.dispose();
  }

  // Coba ambil nama file asli dari Content-Disposition header
  Future<String> _resolveFilename() async {
    try {
      final response = await Dio().head(
        widget.url,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final cd = response.headers.value('content-disposition') ?? '';
      final name = _parseContentDisposition(cd);
      if (name.isNotEmpty) return name;
    } catch (_) {}
    return widget.filename;
  }

  // Pisah tiga pola agar tidak ada masalah escape di dalam raw string
  static String _parseContentDisposition(String cd) {
    // filename*=UTF-8''encoded%20name.mp4
    var m = RegExp(r"filename\*=UTF-8''([^;\s]+)", caseSensitive: false).firstMatch(cd);
    if (m != null) {
      final name = Uri.decodeComponent(m.group(1) ?? '').replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      if (name.isNotEmpty) return name;
    }
    // filename="name.mp4"
    m = RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(cd);
    if (m != null) {
      final name = (m.group(1) ?? '').replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      if (name.isNotEmpty) return name;
    }
    // filename=name.mp4 (tanpa tanda kutip)
    m = RegExp(r'filename=([^;\s"]+)', caseSensitive: false).firstMatch(cd);
    if (m != null) {
      final name = (m.group(1) ?? '').replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  Future<void> _download() async {
    try {
      final dir = await getTemporaryDirectory();
      _cancelToken = CancelToken();

      // Resolve real filename (extension) from response headers
      final resolved = await _resolveFilename();
      if (mounted) setState(() => _resolvedFilename = resolved);

      final filePath = '${dir.path}/$resolved';

      await Dio().download(
        widget.url,
        filePath,
        cancelToken: _cancelToken,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
        ),
        onReceiveProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (mounted) setState(() => _localPath = filePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (mounted) setState(() => _error = 'Gagal mengunduh file');
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengunduh file');
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  void _openFile(BuildContext ctx) {
    if (_localPath == null) return;
    final path = _localPath!;
    final name = _resolvedFilename;
    Widget page;
    if (_isVideo) {
      page = _VideoPlayerPage(filePath: path, title: name);
    } else if (_isPdf) {
      page = _PdfLocalViewerPage(filePath: path, title: name);
    } else {
      page = _ImageViewerPage(filePath: path, title: name);
    }
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page));
  }

  void _share() {
    if (_localPath == null) return;
    Share.shareXFiles([XFile(_localPath!)], subject: _resolvedFilename);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black26,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    _StatusIcon(isDone: _isDone, isError: _error != null),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resolvedFilename.isNotEmpty
                                ? _resolvedFilename
                                : widget.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _isDone
                                ? 'Selesai diunduh'
                                : _error != null
                                ? _error!
                                : _progress > 0
                                ? '${(_progress * 100).toInt()}%'
                                : 'Menyiapkan unduhan...',
                            style: TextStyle(
                              fontSize: 11,
                              color: _error != null
                                  ? Colors.red
                                  : _isDone
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _cancelToken?.cancel('user dismissed');
                        _dismiss();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                // Progress bar
                if (!_isDone && _error == null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation(Color(primaryColor)),
                    ),
                  ),
                ],

                // Action buttons after done
                if (_isDone) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_canOpen) ...[
                        Expanded(
                          child: _ActionButton(
                            icon: _openIcon,
                            label: _openLabel,
                            color: Color(primaryColor),
                            outlined: true,
                            onTap: () => _openFile(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tombol bagikan selalu tampil
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share,
                          label: 'Bagikan',
                          color: Color(primaryColor),
                          outlined: !_canOpen,
                          onTap: _share,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _StatusIcon extends StatelessWidget {
  final bool isDone;
  final bool isError;
  const _StatusIcon({required this.isDone, required this.isError});

  @override
  Widget build(BuildContext context) {
    if (isError) return const Icon(Icons.error_outline, color: Colors.red, size: 22);
    if (isDone) return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(Color(primaryColor)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: shape,
        ),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: shape,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Video player page
// ---------------------------------------------------------------------------

class _VideoPlayerPage extends StatefulWidget {
  final String filePath;
  final String title;
  const _VideoPlayerPage({required this.filePath, required this.title});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.filePath));
      await _videoController.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          allowFullScreen: true,
          allowMuting: true,
        );
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak dapat memutar video ini');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareXFiles(
              [XFile(widget.filePath)],
              subject: widget.title,
            ),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white))
            : _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PDF viewer page (local file)
// ---------------------------------------------------------------------------

class _PdfLocalViewerPage extends StatefulWidget {
  final String filePath;
  final String title;
  const _PdfLocalViewerPage({required this.filePath, required this.title});

  @override
  State<_PdfLocalViewerPage> createState() => _PdfLocalViewerPageState();
}

class _PdfLocalViewerPageState extends State<_PdfLocalViewerPage> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareXFiles(
              [XFile(widget.filePath)],
              subject: widget.title,
            ),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: false,
              fitPolicy: FitPolicy.BOTH,
              onError: (e) => setState(() => _error = e.toString()),
              onPageError: (_, __) {},
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image viewer page (local file)
// ---------------------------------------------------------------------------

class _ImageViewerPage extends StatelessWidget {
  final String filePath;
  final String title;
  const _ImageViewerPage({required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareXFiles(
              [XFile(filePath)],
              subject: title,
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Image.file(
            File(filePath),
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
