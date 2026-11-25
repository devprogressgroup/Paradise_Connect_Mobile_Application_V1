import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_search/feed_search_cubit.dart';

/// Pencarian kiriman: caption, judul/channel/deskripsi link, dan nama pembuat.
class FeedSearchPage extends StatefulWidget {
  const FeedSearchPage({super.key});

  @override
  State<FeedSearchPage> createState() => _FeedSearchPageState();
}

class _FeedSearchPageState extends State<FeedSearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => context.read<FeedSearchCubit>().search(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Cari', isBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Cari judul, caption, channel, atau nama',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _submit,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<FeedSearchCubit, FeedSearchState>(
                builder: (context, state) {
                  switch (state.status) {
                    case FeedSearchStatus.initial:
                      return const _Hint('Ketik kata kunci lalu tekan cari.');
                    case FeedSearchStatus.loading:
                      return buildPostFeedShimmer();
                    case FeedSearchStatus.error:
                      return _Hint(
                        state.errorMessage ?? 'Gagal mencari kiriman.',
                      );
                    case FeedSearchStatus.loaded:
                      if (state.items.isEmpty) {
                        return _Hint(
                          'Tidak ada kiriman yang cocok dengan "${state.query}".',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 16,
                          color: Color(grey10Color),
                        ),
                        itemBuilder: (_, i) =>
                            _ResultTile(post: state.items[i]),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(grey2Color)),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final FeedPostEntity post;

  const _ResultTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final link = post.link;
    final linkTitle = link?.title.trim() ?? '';
    final title = linkTitle.isNotEmpty ? linkTitle : post.text;
    final channel = link?.channel ?? '';
    final thumb = post.media.isNotEmpty && !post.media.first.isVideo
        ? post.media.first.url
        : null;
    final by = [post.author.name, if (channel.isNotEmpty) channel].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.pushNamed(
        'marketingFeedDetail',
        queryParameters: {'feed_post_id': '${post.id}'},
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: thumb != null
                  ? Image.network(
                      thumb,
                      headers: AuthTokenCache.getAuthHeadersFor(thumb),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '(tanpa judul)' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  by,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(grey2Color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(grey10Color),
    alignment: Alignment.center,
    child: const Icon(Icons.article_outlined, color: Color(grey2Color)),
  );
}
