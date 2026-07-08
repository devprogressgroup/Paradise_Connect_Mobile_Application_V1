import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/services/ota_update_service.dart';
import 'package:progress_group/core/constants/colors.dart';

enum _UpdateState { idle, downloading, installing, error }

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _UpdateState _state = _UpdateState.idle;
  double _progress = 0;
  String _errorMessage = '';

  void _startDownload() {
    if (widget.downloadUrl.isEmpty) return;
    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
    });

    OtaUpdateService.downloadAndInstall(
      downloadUrl: widget.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (msg) {
        if (mounted) setState(() {
          _state = _UpdateState.error;
          _errorMessage = msg;
        });
      },
      onInstalling: () {
        if (mounted) setState(() => _state = _UpdateState.installing);
      },
    );
  }

  @override
  void dispose() {
    if (_state == _UpdateState.downloading) OtaUpdateService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(whiteColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(logoSplasShcreen, width: 90),
              const SizedBox(height: 20),
              const Icon(Icons.system_update_rounded, size: 48, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              const Text(
                'Update Tersedia!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
            
              const Text(
                'Versi terbaru tersedia. Update sekarang untuk melanjutkan.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    switch (_state) {
      case _UpdateState.idle:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.downloadUrl.isNotEmpty ? _startDownload : null,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download & Install', style: TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Color(whiteColor),
              disabledBackgroundColor: Color(greyShade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

      case _UpdateState.downloading:
        final percent = (_progress * 100).toInt();
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mengunduh...', style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
                Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                OtaUpdateService.cancel();
                setState(() => _state = _UpdateState.idle);
              },
              child: const Text('Batalkan', style: TextStyle(color: Color(greyShade500))),
            ),
          ],
        );

      case _UpdateState.installing:
        return Column(
          children: const [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 12),
            Text('Membuka installer...', style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
          ],
        );

      case _UpdateState.error:
        return Column(
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 12, color: Color(redAccentColor)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Color(whiteColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
    }
  }
}
