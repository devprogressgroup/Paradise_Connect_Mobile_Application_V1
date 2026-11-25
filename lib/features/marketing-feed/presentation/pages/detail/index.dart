import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_drafts/feed_drafts_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/feed_share.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_comment_sheet.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';

/// Detail satu post — dibuka dari Kiriman Saya atau notifikasi `app://marketing_feed?feed_post_id=`.
/// Post milik sendiri ikut menampilkan status review & alasan penolakan.
class FeedPostDetailPage extends StatefulWidget {
  final int? postId;

  const FeedPostDetailPage({super.key, required this.postId});

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

  /// Aksi draft, sama dengan halaman Draf: Ubah, Publish" (kalau bisa langsung tayang) atau Ajukan ulang, dan Hapus.
  Widget _draftActions(FeedPostEntity post) {
    final canPublishDirect =
        PermissionsHelper.canApproveMarketingFeed ||
        PermissionsHelper.canSkipReviewMarketingFeed;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editDraft(post),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Ubah'),
        ),
        if (canPublishDirect)
          ElevatedButton.icon(
            onPressed: () => _publishDraft(post),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Publish'),
          )
        else
          ElevatedButton.icon(
            onPressed: () => _editDraft(post),
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text('Ajukan ulang'),
          ),
        // Hapus butuh izin Delete atau ApproveReject (sama dengan backend), jadi tombolnya hanya tampil kalau ada.
        if (PermissionsHelper.canDeleteMarketingFeed)
          OutlinedButton.icon(
            onPressed: () => _deleteDraft(post),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(redAccentColor),
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Hapus'),
          ),
      ],
    );
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

  /// Footer kartu di Detail Post: hanya aksi draft. Laporan kiriman dilakukan dari kartu di menu utama (Home).
  Widget? _postFooter(FeedPostEntity post) {
    if (post.status == FeedPostStatus.draft) return _draftActions(post);
    return null;
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
            footer: _postFooter(post),
          ),
        ],
      ),
    );
  }
}
