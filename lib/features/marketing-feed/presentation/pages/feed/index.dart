import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_comment_sheet.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/progress_funnel_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/wall_of_fame_card.dart';
import 'package:share_plus/share_plus.dart';

/// Home = Marketing Feed: ajakan bagikan momen, Progress Kamu, Wall of Fame, lalu aliran feed.
/// Dashboard lama sekarang ada di menu Report (`/report`).
class MarketingFeedPage extends StatefulWidget {
  const MarketingFeedPage({super.key});

  @override
  State<MarketingFeedPage> createState() => _MarketingFeedPageState();
}

class _MarketingFeedPageState extends State<MarketingFeedPage> {
  final _scrollController = ScrollController();
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed');
    _scrollController.addListener(_onScroll);
    _loadHeaderData();
    context.read<MarketingFeedCubit>().fetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Data untuk badge lonceng notifikasi di header (sebelumnya dimuat oleh Dashboard).
  void _loadHeaderData() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is! ProfileLoaded && profileState is! ProfileLoading) {
      context.read<ProfileBloc>().add(GetProfileEvent());
    }
    final isSales = profileState is! ProfileLoaded || profileState.profile.salesPersonId != null;
    if (isSales && context.read<NotifActivityBloc>().state.status != ActivityStatus.loaded) {
      context.read<NotifActivityBloc>().add(const FetchActivitiesEvent(isRefresh: true));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final state = context.read<MarketingFeedCubit>().state;
      if (state.status == MarketingFeedStatus.loaded) {
        context.read<MarketingFeedCubit>().loadMore();
      }
    }
  }

  Future<void> _refresh() => context.read<MarketingFeedCubit>().fetch();

  /// Buka halaman form/draft; feed dimuat ulang begitu kembali dengan hasil.
  Future<void> _open(String routeName) async {
    setState(() => _menuOpen = false);
    final changed = await context.pushNamed<bool>(routeName);
    if (!mounted) return;
    if (changed == true || routeName == 'marketingFeedDrafts') {
      await _refresh();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  void _onFabTap() {
    AnalyticsService.logEvent('marketing_feed_fab');
    if (!PermissionsHelper.canModerateMarketingFeed) {
      _open('marketingFeedShare');
      return;
    }
    setState(() => _menuOpen = !_menuOpen);
  }

  Future<void> _react(FeedPostEntity post, FeedReaction reaction) async {
    AnalyticsService.logEvent('marketing_feed_${reaction.name}');
    final error = await context.read<MarketingFeedCubit>().react(post.id, reaction);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openComments(FeedPostEntity post) async {
    AnalyticsService.logEvent('marketing_feed_open_comments');
    final cubit = context.read<MarketingFeedCubit>();
    await showFeedCommentSheet(context, post);
    cubit.reloadPost(post.id);
  }

  void _share(FeedPostEntity post) {
    AnalyticsService.logEvent('marketing_feed_share');
    final url = post.link?.url;
    Share.share(url == null ? post.plainText : '${post.plainText}\n$url');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<MarketingFeedCubit, MarketingFeedState>(
                  builder: (context, state) => RefreshIndicator(
                    onRefresh: () async {
                      AnalyticsService.logEvent('marketing_feed_refresh');
                      await _refresh();
                    },
                    child: _buildList(state),
                  ),
                ),
                if (_menuOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _menuOpen = false),
                    ),
                  ),
                if (_menuOpen) Positioned(right: 16, bottom: 82, child: _buildComposeMenu()),
                Positioned(right: 16, bottom: 16, child: _buildFab()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<NotifActivityBloc, ActivityState>(
      builder: (context, notifState) {
        return BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
          builder: (context, whatsappState) {
            final hasUnseenNotif = notifState.activities.any((a) => !notifState.seenActivityIds.contains(a.activityId));
            final showBadge = hasUnseenNotif || whatsappState.data.isNotEmpty;
            return customHeader(
              context,
              'Marketing Feed',
              iconRight: Icons.menu,
              iconRightOnTap: () {
                AnalyticsService.logEvent('marketing_feed_open_menu');
                Scaffold.of(context).openDrawer();
              },
              iconLeft: Icons.notifications_none_rounded,
              showBadgeLeft: showBadge,
              iconLeftOnTap: () {
                AnalyticsService.logEvent('marketing_feed_open_notifications');
                context.pushNamed('notif');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList(MarketingFeedState state) {
    final posts = state.posts;
    final children = <Widget>[
  
      ProgressFunnelCard(
        funnel: state.funnel,
        onOpenReport: () {
          AnalyticsService.logEvent('marketing_feed_open_report');
          context.go('/report');
        },
      ),
      WallOfFameCard(levels: state.wallOfFame),
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Feed Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      if (posts.isEmpty) _buildFeedStatus(state),
      for (final post in posts)
        FeedPostCard(
          key: ValueKey(post.id),
          post: post,
          onReact: (reaction) => _react(post, reaction),
          onComment: () => _openComments(post),
          onShare: () => _share(post),
          onVote: (indexes) {
            AnalyticsService.logEvent('marketing_feed_vote');
            return context.read<MarketingFeedCubit>().vote(post.id, indexes);
          },
        ),
      if (state.hasMore && posts.isNotEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
    ];

    return ListView.separated(
      controller: _scrollController,
      // Wajib supaya tarik-refresh tetap jalan walau isinya belum bisa di-scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => children[i],
    );
  }

  Widget _buildFeedStatus(MarketingFeedState state) {
    if (state.status == MarketingFeedStatus.error) {
      return Column(
        children: [
          Text(
            state.errorMessage ?? 'Gagal memuat Marketing Feed.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
          ),
          TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
        ],
      );
    }
    if (state.status == MarketingFeedStatus.loaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Belum ada konten di Marketing Feed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(grey4Color)),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  
  Widget _buildFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: 'marketing_feed_fab',
        onPressed: _onFabTap,
        backgroundColor: const Color(primaryColor),
        shape: const CircleBorder(),
        child: AnimatedRotation(
          turns: _menuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add, size: 28, color: Color(whiteColor)),
        ),
      ),
    );
  }

  Widget _buildComposeMenu() {
    return Material(
      color: const Color(whiteColor),
      elevation: 8,
      shadowColor: const Color(blue2Color).withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _menuItem(Icons.photo_camera_outlined, 'Bagikan Momen', 'Sales', 'marketingFeedShare'),
              _menuItem(Icons.article_outlined, 'Post Baru', 'Moderator', 'marketingFeedPostForm'),
              _menuItem(Icons.poll_outlined, 'Poll Baru', 'Moderator', 'marketingFeedPollForm'),
              _menuItem(Icons.drafts_outlined, 'Draft & Terjadwal', 'Moderator', 'marketingFeedDrafts'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String role, String routeName) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        AnalyticsService.logEvent('marketing_feed_menu_$routeName');
        _open(routeName);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(primaryColor)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                Text(role, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(grey5Color))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
