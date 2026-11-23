import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/fame-manage/index.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_approval_list.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_published_list.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_link_default_thumb.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

class FeedMySubmissionsPage extends StatefulWidget {
  /// 'approval' = buka langsung di tab Persetujuan (dari notifikasi kiriman yang menunggu persetujuan).
  final String? initialTab;

  const FeedMySubmissionsPage({super.key, this.initialTab});

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
  // Tab seperti prototype: Draf, Ditinjau (menunggu Tim Marketing), Tayang, Ditolak.
  String _status = 'draft';
  // Dipakai + di bawah untuk membuka form kartu Wall of Fame saat tab Wall of Fame aktif.
  final _fameKey = GlobalKey<FameManagePageState>();
  static const _tabs = [
    ('draft', 'Draf'),
    ('scheduled', 'Terjadwal'),
    ('review', 'Ditinjau'),
    ('published', 'Tayang'),
    ('rejected', 'Ditolak'),
  ];

  /// Tab tambahan "Wall of Fame" (lihat & edit kartu) hanya untuk user yang punya izin edit.
  List<(String, String)> get _visibleTabs => [
    ..._tabs,
    if (FeedCreateTabs.fameEditable) ('fame', 'Wall of Fame'),
    // Persetujuan kiriman sales: hanya untuk user dengan izin ApproveReject (superuser selalu punya).
    if (PermissionsHelper.canApproveMarketingFeed) ('approval', 'Persetujuan'),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_my_submissions');
    _scrollController.addListener(_onScroll);
    if (widget.initialTab == 'approval' && PermissionsHelper.canApproveMarketingFeed) {
      _status = 'approval';
    } else {
      _fetch();
    }
    // Tab "Wall of Fame" hanya muncul kalau user punya izin edit (hak akses dimuat ulang di sini).
    FeedCreateTabs.refreshFameAccess(context).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
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

    final result = await context.read<MarketingFeedCubit>().getMySubmissions(
      status: _status,
    );

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
    final result = await context.read<MarketingFeedCubit>().getMySubmissions(
      page: _currentPage + 1,
      status: _status,
    );

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

  Future<void> _togglePin(FeedPostEntity post) async {
    final pinned = !post.profilePinned;
    final error = await context.read<MarketingFeedCubit>().setProfilePin(
      post.id,
      pinned: pinned,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _items = [
        for (final p in _items)
          p.id == post.id ? p.copyWith(profilePinned: pinned) : p,
      ];
    });
  }

  void _openDetail(FeedPostEntity post) {
    context.pushNamed(
      'marketingFeedDetail',
      queryParameters: {'feed_post_id': post.id.toString()},
    );
  }

  /// + seperti di Home: buat kiriman baru. Di tab Wall of Fame, + yang sama membuka form kartu Wall of Fame.
  Future<void> _onFabTap() async {
    if (_status == 'fame') {
      _fameKey.currentState?.openNewCard();
      return;
    }
    AnalyticsService.logEvent('marketing_feed_fab');
    await context.pushNamed<bool>('marketingFeedPostForm');
    if (mounted) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_submissions_fab',
        onPressed: _onFabTap,
        backgroundColor: const Color(primaryColor),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28, color: Color(whiteColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Feeds', isBack: true),
            _buildTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  void _selectTab(String status) {
    if (status == _status) return;
    setState(() {
      _status = status;
      _items = [];
      _currentPage = 1;
      _hasMore = false;
    });
    // Tab Wall of Fame memakai daftarnya sendiri (FameManagePage), tidak memuat kiriman.
    // Tab Persetujuan dan Tayang (untuk izin ApproveReject) memuat datanya sendiri.
    final ownList = !(status == 'published' && PermissionsHelper.canApproveMarketingFeed);
    if (status != 'fame' && status != 'approval' && ownList) _fetch();
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final (value, label) in _visibleTabs)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _status == value,
                selectedColor: const Color(
                  primaryColor,
                ).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _status == value
                      ? const Color(primaryColor)
                      : const Color(grey5Color),
                ),
                onSelected: (_) => _selectTab(value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_status == 'fame') {
      return FameManagePage(key: _fameKey, embedded: true);
    }
    // Tayang untuk user ApproveReject: semua kiriman tayang, dengan aksi turunkan tayang dan hapus.
    if (_status == 'published' && PermissionsHelper.canApproveMarketingFeed) {
      return const FeedPublishedList();
    }
    if (_status == 'approval') {
      return const FeedApprovalList();
    }
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
              ElevatedButton(onPressed: _fetch, child: const Text('Coba Lagi')),
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
              message:
                  'Bagikan momen closing atau kunjungan serumu lewat tombol Bagikan Momen!',
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
                        : post.link != null
                        ? FeedLinkDefaultThumb(
                            platform: post.link!.platform,
                            compact: true,
                          )
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
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(grey4Color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.text.isNotEmpty
                            ? post.plainText
                            : 'Momen tanpa cerita teks',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(grey2Color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.status == FeedPostStatus.rejected &&
                post.rejectReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(redAccentColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(redAccentColor).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(redAccentColor),
                    ),
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
            if (post.status == FeedPostStatus.published) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _togglePin(post),
                  icon: Icon(
                    post.profilePinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    size: 16,
                  ),
                  label: Text(
                    post.profilePinned ? 'Lepas sematan' : 'Sematkan di profil',
                  ),
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
        label =
            'Disetujui, tayang ${DateHelper.relativeDayTime(post.publishAt)}';
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
