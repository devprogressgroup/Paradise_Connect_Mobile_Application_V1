import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/floating_download_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showGlobalNotificationDialog(
  BuildContext context, {
  required String title,
  required String description,
  String? mediaType,
  String? mediaUrl,
  String? linkUrl,
}) {
  final hasImage = mediaType == 'image' && (mediaUrl?.isNotEmpty ?? false);
  final hasPdf = mediaType == 'pdf' && (mediaUrl?.isNotEmpty ?? false);
  final hasLink = linkUrl != null && linkUrl.isNotEmpty;
  final hasText = title.isNotEmpty || description.isNotEmpty || hasPdf || hasLink;

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    Image.network(
                      mediaUrl!,
                      width: double.maxFinite,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  if (hasText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, hasImage ? 16 : 24, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 28),
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (description.isNotEmpty) ...[
                            SizedBox(height: title.isNotEmpty ? 8 : 0),
                            Text(
                              description,
                              style: TextStyle(fontSize: 14, color: Color(grey2Color), height: 1.4),
                            ),
                          ],
                          if (hasPdf) ...[
                            SizedBox(height: (title.isNotEmpty || description.isNotEmpty) ? 16 : 0),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                FloatingDownloadManager.show(
                                  context: context,
                                  url: mediaUrl!,
                                  filename: '$title.pdf',
                                );
                              },
                              child: Container(
                                width: double.maxFinite,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Color(primaryColor).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(primaryColor).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf_rounded, color: Color(primaryColor), size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Lihat Dokumen',
                                        style: TextStyle(color: Color(primaryColor), fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Color(primaryColor), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (hasLink) ...[
                            SizedBox(height: (title.isNotEmpty || description.isNotEmpty || hasPdf) ? 12 : 0),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final uri = Uri.tryParse(linkUrl);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                width: double.maxFinite,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Color(primaryColor).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(primaryColor).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_new_rounded, color: Color(primaryColor), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Buka Link',
                                        style: TextStyle(color: Color(primaryColor), fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Color(primaryColor), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(ctx).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
