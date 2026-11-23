import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/my_profile/my_profile_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/my-profile/reel_list_page.dart';

/// Profil Marketing Feed: punya sendiri (userId null) atau user lain (dibuka dari nama/avatar pembuat kiriman).
/// Tab Semua = kartu seperti Home, Reels = grid video, Tautan = kiriman berisi link. Ketiganya dipaginasi.
class FeedProfilePage extends StatefulWidget {
  final int? userId;

  const FeedProfilePage({super.key, this.userId});

  @override
  State<FeedProfilePage> createState() => _FeedProfilePageState();
}

class _FeedProfilePageState extends State<FeedProfilePage> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    context.read<MyProfileCubit>().fetch(userId: widget.userId);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Minta halaman berikutnya saat scroll tinggal sedikit lagi sampai bawah.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels < 300) {
      context.read<MyProfileCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Profil', isBack: true),
            Expanded(
              child: BlocBuilder<MyProfileCubit, MyProfileState>(
                builder: (context, state) {
                  final profile = state.profile;
                  if (profile == null) {
                    if (state.status == MyProfileStatus.error) {
                      return _errorView(context, state.errorMessage);
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<MyProfileCubit>().fetch(userId: widget.userId),
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _header(profile)),
                        SliverToBoxAdapter(child: _stats(profile)),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        SliverToBoxAdapter(
                          child: Divider(color: Color(grey10Color)),
                        ),
                        SliverToBoxAdapter(child: _tabs(context, state.tab)),
                        ..._content(context, state),
                        if (state.loadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Gagal memuat profil.'),
          TextButton(
            onPressed: () =>
                context.read<MyProfileCubit>().fetch(userId: widget.userId),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  /// Isi tab yang aktif. Halaman pertama sedang dimuat = spinner; gagal dan kosong = pesan.
  List<Widget> _content(BuildContext context, MyProfileState state) {
    if (state.items.isEmpty) {
      if (state.status == MyProfileStatus.loading) {
        return const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ];
      }
      if (state.status == MyProfileStatus.error) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Gagal memuat kiriman.',
                      style: const TextStyle(color: Color(grey2Color)),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<MyProfileCubit>().fetch(userId: widget.userId),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                _emptyText(state.tab),
                style: const TextStyle(color: Color(grey2Color)),
              ),
            ),
          ),
        ),
      ];
    }

    if (state.tab == ProfileTab.reels) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 4 / 5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _reelTile(context, state.items[i], i),
              childCount: state.items.length,
            ),
          ),
        ),
      ];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _listCard(context, state.items[i]),
          childCount: state.items.length,
        ),
      ),
    ];
  }

  String _emptyText(ProfileTab tab) {
    switch (tab) {
      case ProfileTab.semua:
        return 'Belum ada kiriman';
      case ProfileTab.reels:
        return 'Belum ada reel';
      case ProfileTab.tautan:
        return 'Belum ada tautan';
    }
  }

  /// Satu kartu seperti di Home (dipakai tab Semua dan Tautan).
  Widget _listCard(BuildContext context, FeedPostEntity post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: FeedPostCard(
        key: ValueKey(post.id),
        post: post,
        linkAuthorProfile: false,
        onComment: () => context.pushNamed(
          'marketingFeedDetail',
          queryParameters: {'feed_post_id': '${post.id}'},
        ),
      ),
    );
  }

  /// Satu reel di grid: thumbnail, jumlah suka di kiri bawah, tombol play di kanan bawah.
  /// Tap membuka daftar reel seperti Home sebagai halaman sendiri, mulai dari reel ini.
  Widget _reelTile(BuildContext context, FeedPostEntity post, int index) {
    final media = post.media.isNotEmpty ? post.media.first : null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<MyProfileCubit>(),
            child: ProfileReelListPage(startIndex: index),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _reelThumb(media),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 9,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail tile: gambar langsung dari server. Video tidak punya poster di server, jadi frame pertamanya
  /// diambil dari video itu sendiri (diam, tanpa kontrol). Gagal / belum siap = warna abu-abu.
  Widget _reelThumb(FeedMediaEntity? media) {
    final placeholder = ColoredBox(color: Color(grey10Color));
    if (media == null) return placeholder;
    if (media.isVideo) {
      final url = media.url;
      if (url == null || url.isEmpty) return placeholder;
      return FeedVideoPlayer(
        url: url,
        hideControls: true,
        placeholder: placeholder,
        fallback: placeholder,
      );
    }
    return FeedMediaView(media: media, compact: true);
  }

  Widget _header(MyProfileEntity p) {
    return Container(
      color: Color(whiteColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            FeedAvatar(
              name: p.name,
              initials: p.initials,
              photoUrl: p.photoUrl,
              size: 96,
            ),
            const SizedBox(height: 12),
            Text(
              p.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(primaryColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                p.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(MyProfileEntity p) {
    Widget stat(String value, String label, {bool highlight = false}) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(background2Color).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(grey10Color)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: highlight ? const Color(primaryColor) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          stat('${p.postCount}', 'Kiriman'),
          stat('${p.likeCount}', 'Suka', highlight: true),
          stat('${p.commentCount}', 'Komentar'),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context, ProfileTab current) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        children: [
          for (final tab in ProfileTab.values)
            Expanded(
              child: InkWell(
                onTap: () => context.read<MyProfileCubit>().setTab(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: current == tab
                            ? const Color(primaryColor)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: current == tab
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: current == tab
                          ? const Color(primaryColor)
                          : const Color(grey2Color),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
