import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

BoxDecoration feedCardDecoration() {
  return BoxDecoration(
    color: const Color(whiteColor),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: const Color(greyShade500).withValues(alpha: 0.2),
        blurRadius: 5,
        spreadRadius: 2,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// Kartu putih standar Marketing Feed.
class FeedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FeedCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: feedCardDecoration(),
      child: child,
    );
  }
}

/// Judul section ("Progress Kamu", "Wall of Fame", ...) + keterangan kecil di bawahnya.
class FeedSectionHeader extends StatelessWidget {
  final String title;
  final String? hint;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FeedSectionHeader({
    super.key,
    required this.title,
    this.hint,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(orangeAccentColor)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(primaryColor)),
                ),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: const TextStyle(fontSize: 12, color: Color(grey5Color))),
        ],
      ],
    );
  }
}

/// Kotak info biru muda (mis. "Kiriman kamu akan ditinjau Tim Marketing dulu...").
class FeedNotice extends StatelessWidget {
  final String text;
  final IconData? icon;

  const FeedNotice(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(roNoticeInfoBgColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(roNoticeInfoTextColor)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(roNoticeInfoTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong (belum ada komentar/draft).
class FeedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const FeedEmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: const Color(grey10Color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(grey2Color)),
          ),
        ],
      ),
    );
  }
}
