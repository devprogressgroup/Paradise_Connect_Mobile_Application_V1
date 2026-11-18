import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/my_profile/my_profile_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';

/// Profil Marketing Feed: punya sendiri (userId null) atau user lain (dibuka dari nama/avatar pembuat kiriman).
class FeedProfilePage extends StatefulWidget {
  final int? userId;

  const FeedProfilePage({super.key, this.userId});

  @override
  State<FeedProfilePage> createState() => _FeedProfilePageState();
}

class _FeedProfilePageState extends State<FeedProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<MyProfileCubit>().fetch(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.errorMessage ?? 'Gagal memuat profil.'),
                            TextButton(
                              onPressed: () => context
                                  .read<MyProfileCubit>()
                                  .fetch(userId: widget.userId),
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<MyProfileCubit>().fetch(
                      userId: widget.userId,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _header(profile),
                        _stats(profile),
                        const SizedBox(height: 8),
                        _grid(context, profile),
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

  Widget _header(MyProfileEntity p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          FeedAvatar(
            name: p.name,
            initials: p.initials,
            photoUrl: p.photoUrl,
            size: 84,
          ),
          const SizedBox(height: 10),
          Text(
            p.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            p.subtitle,
            style: const TextStyle(fontSize: 13, color: Color(grey2Color)),
          ),
        ],
      ),
    );
  }

  Widget _stats(MyProfileEntity p) {
    Widget stat(String value, String label) => Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
        ),
      ],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        stat('${p.postCount}', 'Kiriman'),
        stat('${p.likeCount}', 'Suka'),
        stat('${p.commentCount}', 'Komentar'),
      ],
    );
  }

  Widget _grid(BuildContext context, MyProfileEntity p) {
    if (p.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Belum ada kiriman tayang.',
            style: TextStyle(color: Color(grey2Color)),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: p.posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, i) => _tile(context, p.posts[i]),
    );
  }

  /// Satu kiriman di grid: foto (atau teks / ikon video), badge sematan profil, dan jumlah suka.
  Widget _tile(BuildContext context, MyProfilePostEntity post) {
    final url = post.thumbUrl;
    final isImage = url != null && post.thumbKind == 'image';
    return GestureDetector(
      onTap: () => context.pushNamed(
        'marketingFeedDetail',
        queryParameters: {'feed_post_id': '${post.id}'},
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isImage)
            Image.network(
              url,
              headers: AuthTokenCache.getAuthHeadersFor(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _textOrIcon(post),
            )
          else
            _textOrIcon(post),
          if (post.isProfilePinned)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(primaryColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin, size: 10, color: Color(whiteColor)),
                    SizedBox(width: 3),
                    Text(
                      'Disematkan',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(whiteColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 11,
                    color: Color(whiteColor),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${post.likes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(whiteColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kiriman tanpa foto (atau video): ikon video, atau cuplikan teks.
  Widget _textOrIcon(MyProfilePostEntity post) {
    if (post.thumbUrl != null && post.thumbKind == 'video') {
      return Container(
        color: const Color(background2Color),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_outline,
          size: 32,
          color: Color(whiteColor),
        ),
      );
    }
    return Container(
      color: const Color(grey10Color),
      padding: const EdgeInsets.all(6),
      alignment: Alignment.topLeft,
      child: Text(
        post.text ?? '',
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Color(grey2Color)),
      ),
    );
  }
}
