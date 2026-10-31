import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_comment_sheet.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';
import 'package:share_plus/share_plus.dart';

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
        if (message.toLowerCase().contains('tidak ditemukan') || message.toLowerCase().contains('not found')) {
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
      SnackBar(content: Text(message.isNotEmpty ? message : 'Post tidak ditemukan.')),
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

    final result = await context.read<MarketingFeedCubit>().sendReaction(post.id, next);

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() => _post = post);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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

    final result = await context.read<MarketingFeedCubit>().submitVote(post.id, optionIndexes);

    return result.fold(
      (error) => error,
      (newPoll) {
        if (mounted) {
          setState(() {
            _post = _post?.copyWith(poll: newPoll);
          });
        }
        return null;
      },
    );
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

  void _share() {
    final post = _post;
    if (post == null) return;
    AnalyticsService.logEvent('marketing_feed_detail_share');
    final url = post.link?.url;
    Share.share(url == null ? post.plainText : '${post.plainText}\n$url');
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
          ),
        ],
      ),
    );
  }
}
