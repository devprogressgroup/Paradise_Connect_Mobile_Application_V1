import 'package:flutter/material.dart';

/// Tombol aksi kartu moderasi/manajemen kiriman: ikon + label, tinggi 44, sudut membulat 12.
/// Outline untuk aksi sekunder, terisi untuk aksi utama. [loading] menampilkan spinner di dalam tombol.
class FeedActionButton extends StatelessWidget {
  const FeedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const padding = EdgeInsets.symmetric(horizontal: 4);
    final content = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                // Label boleh turun dua baris kalau tidak muat, ukuran font tetap dan tidak dipotong.
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: padding,
          shape: shape,
        ),
        child: content,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        padding: padding,
        shape: shape,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: content,
    );
  }
}
