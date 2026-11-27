import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_drafts/feed_drafts_cubit.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/fame_programs_section.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_manage_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/feed_share.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_comment_sheet.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';

/// Kartu daftar Feeds dipetakan ke bentuk kartu Home (gelap) yang dipakai [FameEntryTile].
/// Like dan komentar tidak ada di data daftar, jadi kartu ini ditampilkan tanpa baris aksi.
FameEntryEntity _fameEntryOf(FameListCardEntity c) {
  final author = c.author;
  final winners = [
    for (final w in c.winners)
      FameWinnerEntity(
        userId: w.userId,
        name: w.name,
        initials: _initialsOf(w.name),
        ranking: w.ranking,
        rankLabel: w.peringkatLabel,
        posisiLabel: w.posisiLabel,
        timLabel: w.timLabel,
      ),
  ];
  return FameEntryEntity(
    id: c.id,
    programId: 0,
    programName: c.program,
    periodeLabel: c.periode,
    kategori: c.kategori,
    caption: c.caption,
    publishedAt: c.publishAt,
    creatorName: author?.name ?? 'Admin',
    creatorInitials: author?.initials ?? 'A',
    creatorPhotoUrl: author?.photoUrl,
    mediaType: c.mediaType,
    mediaUrl: c.mediaUrl,
    winners: winners,
    juaraCount: winners.length,
    topRank: winners.fold<int>(
      0,
      (m, w) => m == 0 || w.ranking < m ? w.ranking : m,
    ),
    reportCount: c.reportCount,
    myReport: c.myReport,
  );
}

String _initialsOf(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0].toUpperCase())
    .join();

/// Detail satu post — dibuka dari Kiriman Saya atau notifikasi `app://marketing_feed?feed_post_id=`.
/// Post milik sendiri ikut menampilkan status review & alasan penolakan.
class FeedPostDetailPage extends StatefulWidget {
  final int? postId;

  /// Kartu Wall of Fame dari daftar Feeds (lewat extra). Kalau ada, halaman ini menampilkan kartu itu
  /// dan daftar pelapor, tanpa memuat kiriman dari server.
  final FameListCardEntity? fame;

  const FeedPostDetailPage({super.key, required this.postId, this.fame});

  @override
  State<FeedPostDetailPage> createState() => _FeedPostDetailPageState();
}

class _FeedPostDetailPageState extends State<FeedPostDetailPage> {
  FeedPostEntity? _post;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_detail');
    // Kartu Wall of Fame sudah lengkap dari daftar: tidak perlu memuat kiriman.
    if (widget.fame != null) {
      _isLoading = false;
      return;
    }
    // Setelah frame pertama: _handleNotFound butuh ScaffoldMessenger & navigasi.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPost());
  }

  Future<void> _loadPost() async {
    final postId = widget.postId;
    if (postId == null) {
      _handleNotFound('Post tidak valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<MarketingFeedCubit>().getPost(postId);

    if (!mounted) return;

    result.fold(
      (message) {
        if (message.toLowerCase().contains('tidak ditemukan') ||
            message.toLowerCase().contains('not found')) {
          _handleNotFound(message);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = message;
          });
        }
      },
      (post) {
        setState(() {
          _isLoading = false;
          _post = post;
        });
      },
    );
  }

  /// Post dihapus/ditarik moderator atau tidak boleh dilihat: beri tahu lalu kembali ke feed.
  /// Dari notifikasi halaman ini bisa jadi tanpa riwayat, jadi fallback ke Home.
  void _handleNotFound(String message) {
    setState(() {
      _isLoading = false;
      _post = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isNotEmpty ? message : 'Post tidak ditemukan.'),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _react(FeedReaction tapped) async {
    final post = _post;
    if (post == null) return;

    final next = post.myReaction == tapped ? FeedReaction.none : tapped;
    int count(int current, FeedReaction type) =>
        current - (post.myReaction == type ? 1 : 0) + (next == type ? 1 : 0);

    setState(() {
      _post = post.copyWith(
        myReaction: next,
        likeCount: count(post.likeCount, FeedReaction.like),
        dislikeCount: count(post.dislikeCount, FeedReaction.dislike),
      );
    });

    final result = await context.read<MarketingFeedCubit>().sendReaction(
      post.id,
      next,
    );

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() => _post = post);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      (res) {
        setState(() {
          _post = _post?.copyWith(
            myReaction: res.myReaction,
            likeCount: res.likes,
            dislikeCount: res.dislikes,
          );
        });
      },
    );
  }

  Future<String?> _vote(List<int> optionIndexes) async {
    final post = _post;
    if (post == null) return 'Post tidak ditemukan.';

    final result = await context.read<MarketingFeedCubit>().submitVote(
      post.id,
      optionIndexes,
    );

    return result.fold((error) => error, (newPoll) {
      if (mounted) {
        setState(() {
          _post = _post?.copyWith(poll: newPoll);
        });
      }
      return null;
    });
  }

  Future<void> _openComments() async {
    final post = _post;
    if (post == null) return;
    final cubit = context.read<MarketingFeedCubit>();
    await showFeedCommentSheet(context, post);
    final result = await cubit.getPost(post.id);
    if (!mounted) return;
    result.fold((_) {}, (updated) => setState(() => _post = updated));
  }

  void _share(Rect? origin) {
    final post = _post;
    if (post == null) return;
    AnalyticsService.logEvent('marketing_feed_detail_share');
    FeedShare.sharePost(context, post, origin: origin);
  }

  /// Aksi draft di menu titik tiga, sama dengan halaman Feeds: Hapus, Ubah, Publish (kalau bisa langsung tayang),
  /// atau Ajukan ulang untuk draft milik sendiri tanpa izin itu.
  List<FeedCardAction> _draftActions(FeedPostEntity post) {
    final canPublishDirect =
        PermissionsHelper.canApproveMarketingFeed ||
        PermissionsHelper.canSkipReviewMarketingFeed;
    return [
      if (canPublishDirect) ...[
        if (PermissionsHelper.canDeleteMarketingFeed)
          FeedCardAction(
            label: 'Hapus',
            icon: Icons.delete_outline_rounded,
            color: const Color(redAccentColor),
            onPressed: () => _deleteDraft(post),
          ),
        FeedCardAction(
          label: 'Ubah',
          icon: Icons.edit_outlined,
          color: const Color(primaryColor),
          onPressed: () => _editDraft(post),
        ),
        FeedCardAction(
          label: 'Publish',
          icon: Icons.send_rounded,
          color: const Color(successColor),
          onPressed: () => _publishDraft(post),
        ),
      ] else if (post.isMine) ...[
        FeedCardAction(
          label: 'Ubah',
          icon: Icons.edit_outlined,
          color: const Color(primaryColor),
          onPressed: () => _editDraft(post),
        ),
        FeedCardAction(
          label: 'Ajukan ulang',
          icon: Icons.send_rounded,
          color: const Color(successColor),
          onPressed: () => _editDraft(post),
        ),
      ],
    ];
  }

  Future<void> _editDraft(FeedPostEntity post) async {
    AnalyticsService.logEvent('marketing_feed_detail_draft_edit');
    final route = switch (post.type) {
      FeedPostType.post => 'marketingFeedPostForm',
      FeedPostType.poll => 'marketingFeedPollForm',
      FeedPostType.link => 'marketingFeedLinkForm',
    };
    final saved = await context.pushNamed<bool>(route, extra: post);
    if (saved == true && mounted) {
      // Simpan dari form bisa langsung menayangkan kiriman, jadi halaman dimuat ulang.
      await _loadPost();
    }
  }

  Future<void> _publishDraft(FeedPostEntity post) async {
    AnalyticsService.logEvent('marketing_feed_detail_draft_publish');
    final error = await context.read<FeedDraftsCubit>().publishNow(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Konten ditayangkan, notifikasi dikirim ke sales'),
      ),
    );
    await _loadPost();
  }

  Future<void> _deleteDraft(FeedPostEntity post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus draft?'),
        content: const Text('Draft yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Color(redAccentColor)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await context.read<FeedDraftsCubit>().delete(post.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  /// Daftar pelapor dan isi laporan (hanya approver yang mendapat datanya dari server).
  Widget _reportsSection(List<FeedReportNote> reports) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey10Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan (${reports.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          for (final r in reports) ...[
            const SizedBox(height: 10),
            Text(
              r.reporterName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${FeedReportReason.labelOf(r.reason)} · ${DateHelper.timeAgo(r.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
            if (r.note != null && r.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.note!,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Menu titik tiga Detail Post: hanya aksi draft. Laporan kiriman dilakukan dari kartu di menu utama (Home).
  List<FeedCardAction>? _postMenu(FeedPostEntity post) {
    if (post.status != FeedPostStatus.draft) return null;
    final actions = _draftActions(post);
    return actions.isEmpty ? null : actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Detail Post', isBack: true),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(grey2Color)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadPost,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final fame = widget.fame;
    if (fame != null) {
      // Kartu Wall of Fame memakai kartu gelap dari Home, lalu daftar pelapor di bawahnya.
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FameEntryTile(entry: _fameEntryOf(fame), showActions: false),
          if (fame.reports.isNotEmpty) ...[
            const SizedBox(height: 12),
            _reportsSection(fame.reports),
          ],
        ],
      );
    }

    final post = _post;
    if (post == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadPost,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FeedPostCard(
            key: ValueKey('detail_${post.id}'),
            post: post,
            onReact: (r) => _react(r),
            onComment: _openComments,
            onShare: _share,
            onVote: _vote,
            menu: _postMenu(post),
            pendingTagAtBottom: true,
          ),
          if (post.reports.isNotEmpty) _reportsSection(post.reports),
        ],
      ),
    );
  }
}
