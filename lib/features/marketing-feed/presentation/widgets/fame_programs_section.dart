import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Satu juara Wall of Fame di Home. Susunannya: header = pembuat entri (author), lalu media juara
/// dengan judul nama di bawahnya, lalu grid keterangan (peringkat, periode, kategori, jabatan, program),
/// lalu caption.
class FameEntryTile extends StatefulWidget {
  final FameEntryEntity entry;

  const FameEntryTile({super.key, required this.entry});

  @override
  State<FameEntryTile> createState() => _FameEntryTileState();
}

class _FameEntryTileState extends State<FameEntryTile> {
  FameEntryEntity get entry => widget.entry;

  bool get _hasMedia => (entry.mediaUrl ?? '').isNotEmpty;

  /// Rasio video asli, diisi setelah video siap. Sebelum itu dipakai 16:9.
  double? _videoRatio;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (entry.isChampion) ...[
                const SizedBox(height: 10),
                _buildChampionBadge(),
              ],
            ],
          ),
        ),
        if (_hasMedia)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildHero(),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(14, _hasMedia ? 12 : 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoGrid(),
              if (entry.caption != null && entry.caption!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(entry.caption!, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ],
    );

    if (!entry.isChampion) {
      return FeedCard(padding: EdgeInsets.zero, child: content);
    }

    // Juara #1: latar gradasi oranye ke biru yang lembut, bingkai oranye, dan bayangan supaya menonjol.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(whiteColor),
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     const Color(orangeAccentColor).withValues(alpha: 0.30),
        //     const Color(primaryColor).withValues(alpha: 0.8),
        //     const Color(whiteColor),
        //   ],
        //   stops: const [0, 0.5, 1],
        // ),
        boxShadow: [
          BoxShadow(
            color: const Color(grey4Color).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: content),
    );
  }

  /// Label pita juara, memakai nama kategori dan peringkat asli (bukan tulisan "JUARA #1" tetap).
  /// Kalau periode sama dengan bulan berjalan: "<KATEGORI> #<peringkat> BULAN INI".
  /// Selain itu: "<KATEGORI> #<peringkat> - <periode>", misalnya "TOP GM #1 - OKTOBER 2026".
  String _championLabel() {
    final kategori = entry.kategori.trim().toUpperCase();
    final rank = '#${entry.ranking}';
    final prefix = kategori.isEmpty ? 'JUARA $rank' : '$kategori';
    final period = entry.periodeLabel?.trim() ?? '';
    if (period.isEmpty) return prefix;
    final thisMonth = DateFormat('MMMM yyyy', 'id_ID').format(AppTime.now());
    if (period.toLowerCase() == thisMonth.toLowerCase())
      return '$prefix BULAN INI';
    return '$prefix - ${period.toUpperCase()}';
  }

  /// Label pita untuk juara #1 dengan gradasi oranye ke biru.
  Widget _buildChampionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [Color(orangeAccentColor), Color(secondaryColor)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(orangeAccentColor).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 16, color: Color(whiteColor)),
          SizedBox(width: 6),
          Text(
            _championLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: Color(whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Header: pembuat entri (sama seperti author kiriman), waktu tayang di bawah nama.
  Widget _buildHeader() {
    final when = entry.publishedAt == null
        ? 'Wall of Fame'
        : 'Wall of Fame · ${DateHelper.timeAgo(entry.publishedAt!)}';
    return Row(
      children: [
        FeedAvatar(
          name: entry.creatorName,
          initials: entry.creatorInitials,
          photoUrl: entry.creatorPhotoUrl,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.creatorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
              ),
            ],
          ),
        ),
        if (entry.isPinned) ...[
          const SizedBox(width: 8),
          const Icon(Icons.push_pin, size: 14, color: Color(primaryColor)),
        ],
      ],
    );
  }

  /// Media juara dalam bingkai membulat. Judul nama dan badge "Video" ditumpuk di atas media.
  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          _buildMedia(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: _buildTitleOverlay()),
          ),
          if (entry.mediaType == 'video')
            Positioned(
              top: 10,
              right: 10,
              child: IgnorePointer(child: _buildVideoBadge()),
            ),
        ],
      ),
    );
  }

  /// Nama juara di pojok bawah media, dengan latar gelap di bawah supaya teks terbaca.
  Widget _buildTitleOverlay() {
    final sub = [
      entry.posisiLabel,
      entry.kategori,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(whiteColor),
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(whiteColor).withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 12, color: Color(whiteColor)),
          SizedBox(width: 4),
          Text(
            'Video',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Grid keterangan juara: dua kolom, Program memakai lebar penuh. Baris kosong tidak ditampilkan.
  Widget _buildInfoGrid() {
    final cells = <_InfoCell>[
      if (!_hasMedia)
        _InfoCell('Juara', entry.name, fullWidth: true, bold: true),
      _InfoCell(
        'Peringkat',
        '#${entry.ranking}',
        valueColor: const Color(orangeAccentColor),
      ),
      if (entry.periodeLabel != null && entry.periodeLabel!.isNotEmpty)
        _InfoCell('Periode', entry.periodeLabel!),
      if (entry.programName.isNotEmpty) _InfoCell('Program', entry.programName),
      if (entry.posisiLabel != null && entry.posisiLabel!.isNotEmpty)
        _InfoCell('Jabatan', entry.posisiLabel!),
    ];

    final rows = <Widget>[];
    var i = 0;
    while (i < cells.length) {
      final first = cells[i];
      final second =
          !first.fullWidth && i + 1 < cells.length && !cells[i + 1].fullWidth
          ? cells[i + 1]
          : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCell(first)),
              if (second != null) ...[
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(grey10Color),
                ),
                Expanded(child: _buildCell(second)),
              ],
            ],
          ),
        ),
      );
      i += second != null ? 2 : 1;
    }

    final children = <Widget>[];
    for (var r = 0; r < rows.length; r++) {
      if (r > 0)
        children.add(
          const Divider(height: 1, thickness: 1, color: Color(grey10Color)),
        );
      children.add(rows[r]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(grey10Color)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildCell(_InfoCell cell) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cell.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(grey2Color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cell.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: cell.bold ? FontWeight.w800 : FontWeight.w700,
              color: cell.valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Media juara di bawah isi, seperti kiriman: gambar atau video (tanpa kontrol, diputar senyap).
  Widget _buildMedia() {
    final url = entry.mediaUrl!;
    if (entry.mediaType == 'video') {
      return AspectRatio(
        aspectRatio: _videoRatio ?? 16 / 9,
        child: OnScreenBuilder(
          builder: (context, visible) => FeedVideoPlayer(
            url: url,
            autoPlay: true,
            loop: true,
            muted: true,
            active: visible,
            hideControls:
                false, // tap = play/pause; autoplay & loop tetap jalan
            onAspectRatio: (r) {
              if (_videoRatio != r) setState(() => _videoRatio = r);
            },
            placeholder: _mediaPlaceholder(),
            fallback: _mediaPlaceholder(),
          ),
        ),
      );
    }
    // Gambar mengikuti rasio aslinya: lebar penuh kartu, tinggi menyesuaikan. Saat memuat, placeholder 16:9.
    return Image.network(
      url,
      headers: AuthTokenCache.getAuthHeadersFor(url),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : AspectRatio(aspectRatio: 16 / 9, child: _mediaPlaceholder()),
      errorBuilder: (_, __, ___) =>
          AspectRatio(aspectRatio: 16 / 9, child: _mediaPlaceholder()),
    );
  }

  /// Placeholder yang terlihat saat media belum siap atau gagal, supaya kartu tidak tampak kosong.
  Widget _mediaPlaceholder() {
    return Container(
      color: const Color(background2Color),
      alignment: Alignment.center,
      child: const Icon(
        Icons.emoji_events,
        size: 48,
        color: Color(orangeAccentColor),
      ),
    );
  }
}

/// Satu kotak keterangan di grid juara.
class _InfoCell {
  final String label;
  final String value;
  final Color? valueColor;
  final bool fullWidth;
  final bool bold;

  const _InfoCell(
    this.label,
    this.value, {
    this.valueColor,
    this.fullWidth = false,
    this.bold = false,
  });
}
