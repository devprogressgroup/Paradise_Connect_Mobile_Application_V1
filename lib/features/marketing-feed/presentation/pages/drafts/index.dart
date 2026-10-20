import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_drafts/feed_drafts_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_drafts/feed_drafts_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Moderator: daftar post terjadwal & draft (dari app maupun Admin Web) — edit, tayangkan
/// sekarang, atau hapus.
class FeedDraftsPage extends StatefulWidget {
  const FeedDraftsPage({super.key});

  @override
  State<FeedDraftsPage> createState() => _FeedDraftsPageState();
}

class _FeedDraftsPageState extends State<FeedDraftsPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_drafts');
    context.read<FeedDraftsCubit>().fetch();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(FeedPostEntity post) async {
    if (post.type == FeedPostType.link) {
      _showMessage('Konten link sosmed diedit dari Admin Web');
      return;
    }
    AnalyticsService.logEvent('marketing_feed_draft_edit');
    final saved = await context.pushNamed<bool>(
      post.type == FeedPostType.poll ? 'marketingFeedPollForm' : 'marketingFeedPostForm',
      extra: post,
    );
    if (saved == true && mounted) context.read<FeedDraftsCubit>().fetch();
  }

  Future<void> _publishNow(FeedPostEntity post) async {
    AnalyticsService.logEvent('marketing_feed_draft_publish_now');
    final error = await context.read<FeedDraftsCubit>().publishNow(post.id);
    if (mounted) _showMessage(error ?? 'Post ditayangkan sekarang');
  }

  Future<void> _delete(FeedPostEntity post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(post.status == FeedPostStatus.draft ? 'Hapus draft?' : 'Hapus post terjadwal?'),
        content: Text('"${post.plainText}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(redAccentColor))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AnalyticsService.logEvent('marketing_feed_draft_delete');
    final error = await context.read<FeedDraftsCubit>().delete(post.id);
    if (mounted) _showMessage(error ?? 'Draft dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Draft & Terjadwal', isBack: true),
            Expanded(
              child: BlocBuilder<FeedDraftsCubit, FeedDraftsState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () => context.read<FeedDraftsCubit>().fetch(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const FeedNotice(
                          'Post terjadwal tayang otomatis sesuai jam. Draft & jadwal dari Admin Web juga muncul di sini.',
                        ),
                        const SizedBox(height: 12),
                        ..._buildBody(state),
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

  List<Widget> _buildBody(FeedDraftsState state) {
    if (state.status == FeedDraftsStatus.loading && state.items.isEmpty ||
        state.status == FeedDraftsStatus.initial) {
      return const [
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (state.status == FeedDraftsStatus.error && state.items.isEmpty) {
      return [
        Text(
          state.errorMessage ?? 'Gagal memuat draft.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
        ),
        TextButton(onPressed: () => context.read<FeedDraftsCubit>().fetch(), child: const Text('Coba lagi')),
      ];
    }
    if (state.items.isEmpty) {
      return const [
        FeedEmptyState(
          icon: Icons.drafts_outlined,
          title: 'Belum ada draft',
          message: 'Simpan post sebagai draft atau jadwalkan dari form Post Baru.',
        ),
      ];
    }
    return [
      for (final post in state.items)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildRow(post)),
    ];
  }

  Widget _buildRow(FeedPostEntity post) {
    final scheduled = post.status == FeedPostStatus.scheduled;
    final thumb = post.thumbnail;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: feedCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: thumb != null
                  ? FeedMediaView(media: thumb, compact: true)
                  : ColoredBox(
                      color: const Color(grey10Color),
                      child: Icon(
                        post.type == FeedPostType.poll ? Icons.poll_outlined : Icons.article_outlined,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(scheduled ? blueShade50Color : grey10Color),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    scheduled ? 'Terjadwal' : 'Draft',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(scheduled ? blueShade800Color : grey2Color),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  post.plainText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (scheduled) ...[
                      const Icon(Icons.schedule, size: 13, color: Color(grey2Color)),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        '${scheduled ? DateHelper.relativeDayTime(post.publishAt) : 'Diubah ${DateHelper.timeAgo(post.publishAt).toLowerCase()}'}'
                        ' · dari ${post.fromAdminWeb ? 'Admin Web' : 'App'}',
                        style: const TextStyle(fontSize: 11.5, color: Color(grey2Color)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _action(Icons.edit_outlined, 'Edit', () => _edit(post)),
                    _action(Icons.send, 'Tayangkan', () => _publishNow(post)),
                    _action(Icons.delete_outline, 'Hapus', () => _delete(post), color: const Color(redAccentColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Color color = const Color(primaryColor)}) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
