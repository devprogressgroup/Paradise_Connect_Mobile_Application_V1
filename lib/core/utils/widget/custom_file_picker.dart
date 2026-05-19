import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class PickedFileResult {
  /// File path — only populated on non-web platforms.
  final String? path;

  /// Raw bytes — always populated for image preview & upload on all platforms.
  final Uint8List? bytes;

  final String name;
  final bool isImage;
  final bool isPdf;

  const PickedFileResult({
    this.path,
    this.bytes,
    required this.name,
    required this.isImage,
    required this.isPdf,
  });

  bool get hasData => bytes != null || path != null;
}

// ─── Public API ───────────────────────────────────────────────────────────────
class CustomFilePicker {
  /// Shows a bottom-sheet with Camera / Gallery / Document options.
  /// Works on mobile (Android, iOS) and web.
  static Future<PickedFileResult?> show(
    BuildContext context, {
    bool allowCamera = true,
    bool allowImages = true,
    bool allowDocuments = true,
  }) {
    return showModalBottomSheet<PickedFileResult?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilePickerSheet(
        allowCamera: allowCamera,
        allowImages: allowImages,
        allowDocuments: allowDocuments,
      ),
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────
class _FilePickerSheet extends StatelessWidget {
  final bool allowCamera;
  final bool allowImages;
  final bool allowDocuments;

  const _FilePickerSheet({
    required this.allowCamera,
    required this.allowImages,
    required this.allowDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(grey9Color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Sumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(blackColor),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (allowCamera)
                  _OptionButton(
                    icon: Icons.camera_alt_rounded,
                    // web mobile browser: opens camera; web desktop: file dialog
                    label: 'Kamera',
                    color: Color(primaryColor),
                    onTap: () => _pick(context, _pickCamera),
                  ),
                if (allowImages)
                  _OptionButton(
                    icon: Icons.image_rounded,
                    label: kIsWeb ? 'Pilih Gambar' : 'Galeri',
                    color: Color(successColor),
                    onTap: () => _pick(context, _pickGallery),
                  ),
                if (allowDocuments)
                  _OptionButton(
                    icon: Icons.description_rounded,
                    label: 'Dokumen',
                    color: Color(warningColor),
                    onTap: () => _pick(context, _pickDocument),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Pick first, then close sheet passing the result back.
  void _pick(
    BuildContext context,
    Future<PickedFileResult?> Function() picker,
  ) async {
    final result = await picker();
    if (context.mounted) Navigator.pop(context, result);
  }

  // ─ Camera ────────────────────────────────────────────────────────────────────
  // Mobile (Android/iOS): opens native camera app.
  // Web mobile browser: triggers <input capture="environment">.
  // Web desktop browser: falls back to file picker.
  Future<PickedFileResult?> _pickCamera() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return PickedFileResult(
        path: kIsWeb ? null : file.path,
        bytes: bytes,
        name: file.name,
        isImage: true,
        isPdf: false,
      );
    } catch (_) {
      return null;
    }
  }

  // ─ Gallery ───────────────────────────────────────────────────────────────────
  // Mobile: uses ImagePicker (native gallery, more reliable).
  // Web: uses FilePicker (web file dialog for images).
  Future<PickedFileResult?> _pickGallery() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return null;
        final f = result.files.single;
        return PickedFileResult(
          path: null,
          bytes: f.bytes,
          name: f.name,
          isImage: true,
          isPdf: false,
        );
      } else {
        final XFile? file =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (file == null) return null;
        final bytes = await file.readAsBytes();
        return PickedFileResult(
          path: file.path,
          bytes: bytes,
          name: file.name,
          isImage: true,
          isPdf: false,
        );
      }
    } catch (_) {
      return null;
    }
  }

  // ─ Document ──────────────────────────────────────────────────────────────────
  // Works on mobile and web via FilePicker.
  Future<PickedFileResult?> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
        ],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.single;
      final isPdf = f.name.toLowerCase().endsWith('.pdf');
      return PickedFileResult(
        path: kIsWeb ? null : f.path,
        bytes: f.bytes,
        name: f.name,
        isImage: false,
        isPdf: isPdf,
      );
    } catch (_) {
      return null;
    }
  }
}

// ─── Option Button ────────────────────────────────────────────────────────────
class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(grey2Color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── File Preview Widget ──────────────────────────────────────────────────────
/// Thumbnail preview for a [PickedFileResult].
/// Uses [Image.memory] for cross-platform compatibility (web + mobile).
class FilePreviewWidget extends StatelessWidget {
  final PickedFileResult file;
  final VoidCallback? onRemove;
  final double size;

  const FilePreviewWidget({
    super.key,
    required this.file,
    this.onRemove,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Color(grey11Color),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(grey9Color)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildContent(),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(redColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (file.isImage && file.bytes != null && file.bytes!.isNotEmpty) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildFileIcon(),
      );
    }
    return _buildFileIcon();
  }

  Widget _buildFileIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            file.isPdf
                ? Icons.picture_as_pdf_rounded
                : file.isImage
                    ? Icons.broken_image_rounded
                    : Icons.insert_drive_file_rounded,
            color: file.isPdf ? Color(redColor) : Color(primaryColor),
            size: size * 0.42,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              file.name,
              style: TextStyle(fontSize: 9, color: Color(grey2Color)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
