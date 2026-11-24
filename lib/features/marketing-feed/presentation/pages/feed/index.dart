import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
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
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/fame_programs_section.dart';
import 'package:progress_group/features/marketing-feed/presentation/feed_share.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/progress_funnel_card.dart';

/// Home = Marketing Feed: ajakan bagikan momen, Progress Kamu, Wall of Fame, lalu aliran feed.
/// Dashboard lama sekarang ada di menu Report (`/report`).
class MarketingFeedPage extends StatefulWidget {
  const MarketingFeedPage({super.key});

  @override
  State<MarketingFeedPage> createState() => _MarketingFeedPageState();
}

/// Jarak scroll (px) setelah tombol "kembali ke atas" mulai muncul.
const double _kShowToTopOffset = 400;

class _MarketingFeedPageState extends State<MarketingFeedPage> {
  final _scrollController = ScrollController();
  bool _showToTop = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed');
    _scrollController.addListener(_onScroll);
    _loadHeaderData();
    context.read<MarketingFeedCubit>().fetch();
    // Hak akses Wall of Fame untuk tab "Wall of Fame" di Post Baru dan Kiriman Saya.
    FeedCreateTabs.refreshFameAccess(context);
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
    final isSales =
        profileState is! ProfileLoaded ||
        profileState.profile.salesPersonId != null;
    if (isSales &&
        context.read<NotifActivityBloc>().state.status !=
            ActivityStatus.loaded) {
      context.read<NotifActivityBloc>().add(
        const FetchActivitiesEvent(isRefresh: true),
      );
    }
  }

  void _onScroll() {
    final showToTop = _scrollController.position.pixels > _kShowToTopOffset;
    if (showToTop != _showToTop) {
      setState(() => _showToTop = showToTop);
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final state = context.read<MarketingFeedCubit>().state;
      if (state.status == MarketingFeedStatus.loaded) {
        context.read<MarketingFeedCubit>().loadMore();
      }
    }
  }

  Future<void> _refresh() => context.read<MarketingFeedCubit>().fetch();


  /// Buka halaman lewat tombol + atau sidebar; feed dimuat ulang begitu kembali.
  /// Tidak memakai hasil `true` dari form: pindah tab Buat Konten memakai pushReplacement, jadi hasil
  /// simpan tidak sampai ke sini. Karena itu feed selalu dimuat ulang saat kembali.
  Future<void> _open(String routeName) async {
    await context.pushNamed<bool>(routeName);
    if (!mounted) return;
    await _refresh();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Sales dan moderator sama-sama langsung ke Buat Konten (Postingan). Tab Polling dan Link hanya tampil
  /// sesuai permission (lihat FeedCreateTabs).
  void _onFabTap() {
    AnalyticsService.logEvent('marketing_feed_fab');
    _open('marketingFeedPostForm');
  }

  Future<void> _react(FeedPostEntity post, FeedReaction reaction) async {
    AnalyticsService.logEvent('marketing_feed_${reaction.name}');
    final error = await context.read<MarketingFeedCubit>().react(
      post.id,
      reaction,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openComments(FeedPostEntity post) async {
    AnalyticsService.logEvent('marketing_feed_open_comments');
    final cubit = context.read<MarketingFeedCubit>();
    await showFeedCommentSheet(context, post);
    cubit.reloadPost(post.id);
  }

  void _share(FeedPostEntity post, Rect? origin) {
    AnalyticsService.logEvent('marketing_feed_share');
    FeedShare.sharePost(context, post, origin: origin);
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
                Positioned(right: 16, bottom: 16, child: _buildFab()),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildScrollToTop(),
                ),
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
            final hasUnseenNotif = notifState.activities.any(
              (a) => !notifState.seenActivityIds.contains(a.activityId),
            );
            final showBadge = hasUnseenNotif || whatsappState.data.isNotEmpty;
            return customHeader(
              context,
              'Marketing Feed',
              iconRight: Icons.menu,
              iconRightOnTap: () {
                AnalyticsService.logEvent('marketing_feed_open_menu');
                Scaffold.of(context).openDrawer();
              },
              iconLeft2: Icons.search,
              iconLeft2OnTap: () {
                AnalyticsService.logEvent('marketing_feed_open_search');
                context.pushNamed('marketingFeedSearch');
              },
              // Kalender Jadwal hanya untuk moderator (permission Modify).
              extraActions: [
                if (PermissionsHelper.canViewMarketingCalendar)
                  IconButton(
                    tooltip: 'Kalender Jadwal',
                    icon: const Icon(Icons.calendar_month_outlined, size: 24),
                    onPressed: () {
                      AnalyticsService.logEvent('marketing_feed_open_calendar');
                      _open('marketingFeedCalendar');
                    },
                  ),
              ],
              iconLeft: Icons.notifications_none_rounded,
              showBadgeLeft: showBadge,
              iconLeftOnTap: () {
                AnalyticsService.logEvent('marketing_feed_open_notifications');
                context.pushNamed('notif');
              },
              trailing: _ProfileAvatarButton(
                onTap: () {
                  AnalyticsService.logEvent('marketing_feed_open_profile');
                  context.go('/marketing-feed/profile');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(FeedPostEntity post) {
    return FeedPostCard(
      key: ValueKey(post.id),
      post: post,
      onReact: (reaction) => _react(post, reaction),
      onComment: () => _openComments(post),
      onShare: (origin) => _share(post, origin),
      onVote: (indexes) {
        AnalyticsService.logEvent('marketing_feed_vote');
        return context.read<MarketingFeedCubit>().vote(post.id, indexes);
      },
    );
  }

  /// Urutan Home 100% dari server (state.homeOrder). Tidak ada pengurutan ulang di klien.
  Widget _buildList(MarketingFeedState state) {
    final postById = {
      for (final p in [...state.pinnedPosts, ...state.posts]) p.id: p,
    };
    final fameById = {
      for (final prog in state.famePrograms)
        for (final cat in prog.categories)
          for (final e in cat.entries) e.id: e,
    };

    final children = <Widget>[
      // Progress Kamu: di paling atas Home (sesuai prototype), di atas kiriman dan Wall of Fame.
      ProgressFunnelCard(
        funnel: state.funnel,
        onOpenReport: () => context.pushNamed('report'),
      ),
      if (state.homeOrder.isEmpty) _buildFeedStatus(state),
      for (final ref in state.homeOrder)
        if (ref.type == 'post' && postById[ref.id] != null)
          _buildPostCard(postById[ref.id]!)
        else if (ref.type == 'fame' && fameById[ref.id] != null)
          FameEntryTile(
            key: ValueKey('fame_${ref.id}'),
            entry: fameById[ref.id]!,
          ),
      if (state.hasMore && state.posts.isNotEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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

  /// Tombol di tengah bawah; muncul setelah scroll cukup jauh, tap = kembali ke atas.
  Widget _buildScrollToTop() {
    return Center(
      child: IgnorePointer(
        ignoring: !_showToTop,
        child: AnimatedOpacity(
          opacity: _showToTop ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: _showToTop ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: const Color(primaryColor),
              elevation: 4,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  AnalyticsService.logEvent('marketing_feed_scroll_to_top');
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: Color(whiteColor),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Ke atas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(whiteColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
        child: const Icon(Icons.add, size: 28, color: Color(whiteColor)),
      ),
    );
  }
}

/// Avatar profil pengguna di header (foto, atau inisial nama kalau belum ada foto).
class _ProfileAvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAvatarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state is ProfileLoaded ? state.profile : null;
        final photoUrl = profile?.photoUrl;
        Widget fallback() => profile == null
            ? _fallbackIcon()
            : FeedAvatar(name: profile.fullName, size: 32);
        return SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        headers: AuthTokenCache.getAuthHeadersFor(photoUrl),
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : fallback(),
                        errorBuilder: (_, __, ___) => fallback(),
                      ),
                    )
                  : fallback(),
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackIcon() => const Icon(
    Icons.account_circle_outlined,
    size: 32,
    color: Color(grey2Color),
  );
}
