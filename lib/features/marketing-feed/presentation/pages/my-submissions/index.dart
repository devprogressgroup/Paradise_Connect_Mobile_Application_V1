import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

class FeedMySubmissionsPage extends StatefulWidget {
  const FeedMySubmissionsPage({super.key});

  @override
  State<FeedMySubmissionsPage> createState() => _FeedMySubmissionsPageState();
}

class _FeedMySubmissionsPageState extends State<FeedMySubmissionsPage> {
  final _scrollController = ScrollController();
  List<FeedPostEntity> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_my_submissions');
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<MarketingFeedCubit>().getMySubmissions();

    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _isLoading = false;
        _errorMessage = error;
      }),
      (page) => setState(() {
        _isLoading = false;
        _items = page.items;
        _currentPage = page.currentPage;
        _hasMore = page.hasMore;
      }),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final result = await context.read<MarketingFeedCubit>().getMySubmissions(page: _currentPage + 1);

    if (!mounted) return;

    result.fold(
      (error) => setState(() => _isLoadingMore = false),
      (page) => setState(() {
        _isLoadingMore = false;
        _items = [..._items, ...page.items];
        _currentPage = page.currentPage;
        _hasMore = page.hasMore;
      }),
    );
  }

  void _openDetail(FeedPostEntity post) {
    context.pushNamed(
      'marketingFeedDetail',
      queryParameters: {'feed_post_id': post.id.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Kiriman Saya', isBack: true),
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
                onPressed: _fetch,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 60),
            FeedEmptyState(
              icon: Icons.history_edu_outlined,
              title: 'Belum ada kiriman',
              message: 'Bagikan momen closing atau kunjungan serumu lewat tombol Bagikan Momen!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildItemCard(_items[i]);
        },
      ),
    );
  }

  Widget _buildItemCard(FeedPostEntity post) {
    final thumb = post.thumbnail;
    final timeStr = post.submittedAt != null
        ? 'Dikirim ${DateHelper.timeAgo(post.submittedAt!)}'
        : 'Dikirim ${DateHelper.timeAgo(post.publishAt)}';

    return InkWell(
      onTap: () => _openDetail(post),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: feedCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: thumb != null
                        ? FeedMediaView(media: thumb, compact: true)
                        : ColoredBox(
                            color: const Color(grey10Color),
                            child: Icon(
                              post.type == FeedPostType.poll
                                  ? Icons.poll_outlined
                                  : Icons.photo_outlined,
                              color: const Color(grey4Color),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(post),
                          const Icon(Icons.chevron_right, size: 18, color: Color(grey4Color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.text.isNotEmpty ? post.plainText : 'Momen tanpa cerita teks',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11.5, color: Color(grey2Color)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.status == FeedPostStatus.rejected && post.rejectReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(redAccentColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(redAccentColor).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(redAccentColor)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan penolakan: ${post.rejectReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(redAccentColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FeedPostEntity post) {
    final String label;
    final Color bgColor;
    final Color textColor;

    switch (post.status) {
      case FeedPostStatus.review:
        label = 'Menunggu review';
        bgColor = const Color(orangeAccentColor).withValues(alpha: 0.15);
        textColor = const Color(orangeAccentColor);
        break;
      case FeedPostStatus.scheduled:
        label = 'Disetujui, tayang ${DateHelper.relativeDayTime(post.publishAt)}';
        bgColor = const Color(blueShade50Color);
        textColor = const Color(primaryColor);
        break;
      case FeedPostStatus.published:
        label = 'Sudah tayang';
        bgColor = const Color(greenMaterialColor).withValues(alpha: 0.15);
        textColor = const Color(greenMaterialColor);
        break;
      case FeedPostStatus.rejected:
        label = 'Ditolak';
        bgColor = const Color(redAccentColor).withValues(alpha: 0.15);
        textColor = const Color(redAccentColor);
        break;
      default:
        label = post.status.name;
        bgColor = const Color(grey10Color);
        textColor = const Color(grey2Color);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
