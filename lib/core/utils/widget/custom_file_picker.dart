import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import 'web_camera_capture/web_camera_capture.dart';

class PickedFileResult {
  final String? path;

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

class CustomFilePicker {
  static Future<PickedFileResult?> show(
    BuildContext context, {
    bool allowCamera = true,
    bool allowImages = true,
    bool allowDocuments = true,
    double? imageMaxDimension,
    int? imageQuality,
    VoidCallback? onAttachment,
  }) {
    return showModalBottomSheet<PickedFileResult?>(
      context: context,
      backgroundColor: Color(transparentColor),
      isScrollControlled: true,
      builder: (_) => _FilePickerSheet(
        allowCamera: allowCamera,
        allowImages: allowImages,
        allowDocuments: allowDocuments,
        imageMaxDimension: imageMaxDimension,
        imageQuality: imageQuality,
        onAttachment: onAttachment,
      ),
    );
  }
}

class _FilePickerSheet extends StatelessWidget {
  final bool allowCamera;
  final bool allowImages;
  final bool allowDocuments;

  /// Opsional: kecilkan foto (sisi terpanjang, px) + kualitas JPEG sebelum dikembalikan —
  /// bikin upload jauh lebih cepat. Null = perilaku lama (foto asli).
  final double? imageMaxDimension;
  final int? imageQuality;

  /// Opsional: tampilkan kotak ke-4 "Attachment" — sheet ditutup (hasil null) lalu callback ini
  /// dipanggil, mis. untuk buka halaman Attachment (file + Attachment Type + deskripsi).
  final VoidCallback? onAttachment;

  const _FilePickerSheet({
    required this.allowCamera,
    required this.allowImages,
    required this.allowDocuments,
    this.imageMaxDimension,
    this.imageQuality,
    this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

                    label: 'Kamera',
                    color: Color(primaryColor),
                    onTap: () => _pick(context, () => _pickCamera(context)),
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
                if (onAttachment != null)
                  _OptionButton(
                    icon: Icons.attach_file_rounded,
                    label: 'Attachment',
                    color: Color(purpleColor),
                    onTap: () {
                      Navigator.pop(context);
                      onAttachment!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pick(
    BuildContext context,
    Future<PickedFileResult?> Function() picker,
  ) async {
    final result = await picker();
    if (context.mounted) Navigator.pop(context, result);
  }

  Future<PickedFileResult?> _pickCamera(BuildContext context) async {
    try {
      if (kIsWeb) {
        // image_picker di web cuma `<input capture>` — di browser desktop jadinya dialog pilih
        // file, bukan kamera. Pakai getUserMedia langsung supaya kamera beneran kebuka.
        final bytes = await WebCameraCapture.open(
          context,
          maxDimension: imageMaxDimension,
          quality: imageQuality,
        );
        if (bytes == null) return null;
        return PickedFileResult(
          path: null,
          bytes: bytes,
          name: 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg',
          isImage: true,
          isPdf: false,
        );
      }
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality ?? 85,
        maxWidth: imageMaxDimension,
        maxHeight: imageMaxDimension,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return PickedFileResult(
        path: file.path,
        bytes: bytes,
        name: file.name,
        isImage: true,
        isPdf: false,
      );
    } catch (e) {
      return null;
    }
  }

  Future<PickedFileResult?> _pickGallery() async {
    try {
      if (kIsWeb && (imageMaxDimension != null || imageQuality != null)) {
        // FilePicker tidak bisa resize — pakai image_picker (web) supaya foto tetap dikecilkan.
        final XFile? file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: imageQuality,
          maxWidth: imageMaxDimension,
          maxHeight: imageMaxDimension,
        );
        if (file == null) return null;
        return PickedFileResult(
          path: null,
          bytes: await file.readAsBytes(),
          name: file.name,
          isImage: true,
          isPdf: false,
        );
      } else if (kIsWeb) {
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
        final XFile? file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: imageQuality,
          maxWidth: imageMaxDimension,
          maxHeight: imageMaxDimension,
        );
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
    } catch (e) {
      return null;
    }
  }

  Future<PickedFileResult?> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
        ],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.single;
      final isPdf = f.name.toLowerCase().endsWith('.pdf');
      // `withData: true` di atas biasanya sudah mengisi `f.bytes`, tapi di beberapa perangkat
      // Android (content:// provider tertentu, file besar) file_picker cuma ngisi `f.path` dan
      // ngebiarin `bytes` null. Kalau bytes-nya sampai null di sini, upload (Reserve Order,
      // attachment, dst) diam-diam skip dokumen ini karena semua caller cuma baca `.bytes` —
      // bukan fallback ke `.path` — jadi baca manual dari path di sini supaya `bytes` SELALU
      // terisi selama filenya beneran ada.
      var bytes = f.bytes;
      if (bytes == null && !kIsWeb && f.path != null) {
        bytes = await File(f.path!).readAsBytes();
      }
      return PickedFileResult(
        path: kIsWeb ? null : f.path,
        bytes: bytes,
        name: f.name,
        isImage: false,
        isPdf: isPdf,
      );
    } catch (e) {
      return null;
    }
  }
}

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
                  border: Border.all(color: Color(whiteColor), width: 2),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(whiteColor),
                  size: 11,
                ),
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
