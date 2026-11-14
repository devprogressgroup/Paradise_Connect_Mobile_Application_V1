import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Satu juara Wall of Fame sebagai kartu, sama seperti kartu kiriman lain di feed.
/// Juara #1 tampil besar (kartu gradasi), peringkat lain tampil ringkas.
class FameEntryTile extends StatelessWidget {
  final FameEntryEntity entry;

  const FameEntryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final label = [entry.kategori, entry.programName].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 14, color: Color(orangeAccentColor)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(primaryColor)),
                ),
              ),
              if (entry.isPinned) const Icon(Icons.push_pin, size: 14, color: Color(primaryColor)),
            ],
          ),
        ),
        entry.isChampion ? _buildChampion() : _buildRunnerUp(),
      ],
    );
  }

  Widget _buildChampion() {
    return Container(
      height: 122,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(secondaryColor), Color(background2Color)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(whiteColor).withValues(alpha: 0.25),
                ),
                child: ClipOval(child: _buildMedia()),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
              decoration: BoxDecoration(
                color: const Color(orangeAccentColor),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 13, color: Color(whiteColor)),
                  SizedBox(width: 4),
                  Text(
                    'Juara #1',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(whiteColor)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 112,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.posisiLabel == null || entry.posisiLabel!.isEmpty
                      ? entry.name
                      : '${entry.name} · ${entry.posisiLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(whiteColor)),
                ),
                if (entry.caption != null && entry.caption!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: const Color(whiteColor).withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerUp() {
    return FeedCard(
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: ClipOval(child: _buildMedia()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                if (entry.posisiLabel != null && entry.posisiLabel!.isNotEmpty)
                  Text(
                    entry.posisiLabel!,
                    style: const TextStyle(fontSize: 11.5, color: Color(grey2Color)),
                  ),
                if (entry.caption != null && entry.caption!.isNotEmpty)
                  Text(
                    entry.caption!,
                    style: const TextStyle(fontSize: 12, color: Color(grey5Color)),
                  ),
              ],
            ),
          ),
          Text(
            '#${entry.ranking}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(grey2Color)),
          ),
        ],
      ),
    );
  }

  /// Foto khusus (kalau gambar) -> foto profil -> inisial. Video belum diputar di kartu ini.
  Widget _buildMedia() {
    final url = entry.mediaType == 'image' ? entry.mediaUrl : null;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        headers: AuthTokenCache.getAuthHeadersFor(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatar(),
      );
    }
    return _avatar();
  }

  Widget _avatar() {
    return FeedAvatar(
      name: entry.name,
      initials: entry.initials,
      photoUrl: entry.photoUrl,
      size: 76,
    );
  }
}
