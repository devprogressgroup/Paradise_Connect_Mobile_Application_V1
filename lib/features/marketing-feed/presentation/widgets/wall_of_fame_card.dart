import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Section "Wall of Fame": semua level (TOP GM/SM/SPV/SE) tampil berurutan, masing-masing
/// juara #1 di kartu biru + peringkat berikutnya.
class WallOfFameCard extends StatelessWidget {
  final List<WallOfFameLevelEntity> levels;

  const WallOfFameCard({super.key, required this.levels});

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeedSectionHeader(
          title: 'Wall of Fame',
          icon: Icons.emoji_events,
          hint: 'Siapa paling panas bulan ini? Giliran kamu berikutnya!',
        ),
        const SizedBox(height: 8),
        FeedCard(
          child: Column(
            children: [
              for (var i = 0; i < levels.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(grey10Color)),
                  const SizedBox(height: 14),
                ],
                _buildLevel(levels[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevel(WallOfFameLevelEntity level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.level,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Color(primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        _buildChampion(level.champion),
        for (var i = 0; i < level.runnersUp.length; i++)
          _buildRunnerUp(level.runnersUp[i], i + 2),
      ],
    );
  }

  Widget _buildChampion(WallOfFameEntryEntity entry) {
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
                child: ClipOval(
                  child: _buildChampionMedia(entry),
                ),
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
                    '#1 Bulan Ini',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(whiteColor),
                    ),
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
              children: [
                Text(
                  _title(entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(whiteColor),
                  ),
                ),
                if (entry.highlight != null && entry.highlight!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.highlight!,
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

  /// Fallback: media (video auto-loop mute / image) -> photo_url -> initials
  Widget _buildChampionMedia(WallOfFameEntryEntity entry) {
    final media = entry.media;
    if (media != null && media.url != null && media.url!.isNotEmpty) {
      if (media.isVideo) {
        return FeedMediaView(media: media, autoPlayVideo: true);
      }
      return Image.network(
        media.url!,
        headers: AuthTokenCache.getAuthHeadersFor(media.url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPhotoOrInitials(entry),
      );
    }
    return _buildPhotoOrInitials(entry);
  }

  Widget _buildPhotoOrInitials(WallOfFameEntryEntity entry) {
    return FeedAvatar(
      name: entry.name,
      initials: entry.initials,
      photoUrl: entry.photoUrl,
      size: 76,
    );
  }

  Widget _buildRunnerUp(WallOfFameEntryEntity entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FeedAvatar(
                name: entry.name,
                initials: entry.initials,
                photoUrl: entry.photoUrl,
                size: 36,
                radius: 10,
              ),
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(rank == 2 ? greyShade500 : feedBronzeColor),
                    border: Border.all(color: const Color(whiteColor), width: 2),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(whiteColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(entry),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (entry.highlight != null && entry.highlight!.isNotEmpty)
                  Text(
                    entry.highlight!,
                    style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
                  ),
              ],
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(grey2Color),
            ),
          ),
        ],
      ),
    );
  }

  String _title(WallOfFameEntryEntity entry) =>
      entry.info == null ? entry.name : '${entry.name} · ${entry.info}';
}
