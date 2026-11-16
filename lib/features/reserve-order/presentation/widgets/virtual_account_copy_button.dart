import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Tombol salin nomor Virtual Account — dipakai di Review Create Reserve Order & detail unit
/// Site Plan.
///
/// Yang disalin hanya [number] (`virtual_account_full`), tanpa nama bank. Umpan balik ada di
/// tombol itu sendiri (ikon berubah ✓ sebentar), jadi tetap terlihat walau tombol ada di dalam
/// modal bottom sheet (SnackBar halaman di belakang sheet tertutup sheet). [onCopied] opsional
/// untuk umpan balik tambahan, mis. SnackBar.
class VirtualAccountCopyButton extends StatefulWidget {
  final String number;
  final VoidCallback? onCopied;
  final double size;

  const VirtualAccountCopyButton({
    super.key,
    required this.number,
    this.onCopied,
    this.size = 15,
  });

  @override
  State<VirtualAccountCopyButton> createState() =>
      _VirtualAccountCopyButtonState();
}

class _VirtualAccountCopyButtonState extends State<VirtualAccountCopyButton> {
  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.number));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
    widget.onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            key: ValueKey(_copied),
            size: widget.size,
            color: Color(_copied ? successColor : primaryColor),
            semanticLabel: _copied
                ? 'Nomor Virtual Account disalin'
                : 'Salin nomor Virtual Account',
          ),
        ),
      ),
    );
  }
}
