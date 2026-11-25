import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/my_profile/my_profile_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';

/// Daftar reel seperti di Home, di halaman sendiri. Dimulai dari reel yang diklik (startIndex),
/// lalu lanjut ke bawah dengan pagination yang sama dengan grid Reels di profil.
class ProfileReelListPage extends StatefulWidget {
  final int startIndex;

  const ProfileReelListPage({super.key, required this.startIndex});

  @override
  State<ProfileReelListPage> createState() => _ProfileReelListPageState();
}

class _ProfileReelListPageState extends State<ProfileReelListPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
            customHeader(context, 'Foto & Video', isBack: true),
            Expanded(
              child: BlocBuilder<MyProfileCubit, MyProfileState>(
                builder: (context, state) {
                  final items = state.items;
                  final start = widget.startIndex
                      .clamp(0, items.length)
                      .toInt();
                  final count = items.length - start;
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: count + (state.loadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= count) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12,
                          ),
                          child: ShimmerPostCardItem(),
                        );
                      }
                      final post = items[start + i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12,
                        ),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
