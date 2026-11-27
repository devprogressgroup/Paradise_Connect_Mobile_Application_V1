import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/fame-form/index.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_list/feed_list_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_report/feed_report_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_manage_card.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_review_actions.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Feeds: satu daftar untuk kiriman dan kartu Wall of Fame, dengan pencarian, filter (status, jenis),
/// urutan, dan paginasi. Kartu yang sama untuk semua baris; tombol mengikuti status dan izin.
class FeedMySubmissionsPage extends StatefulWidget {
  /// 'approval' = buka langsung dengan filter Persetujuan (dari notifikasi kiriman yang menunggu persetujuan).
  final String? initialTab;

  const FeedMySubmissionsPage({super.key, this.initialTab});

  @override
  State<FeedMySubmissionsPage> createState() => _FeedMySubmissionsPageState();
}

class _FeedMySubmissionsPageState extends State<FeedMySubmissionsPage> {
  static const _pollInterval = Duration(seconds: 30);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_my_submissions');
    _scrollController.addListener(_onScroll);

    final cubit = context.read<FeedListCubit>();
    if (widget.initialTab == 'reports' &&
        PermissionsHelper.canApproveMarketingFeed) {
      // Notifikasi laporan: filter Dilaporkan langsung aktif (kiriman dan kartu Wall of Fame).
      cubit.setFilter(statuses: {}, kinds: {'post', 'fame'}, reported: true);
    } else if (widget.initialTab == 'approval' &&
        PermissionsHelper.canApproveMarketingFeed) {
      cubit.setFilter(statuses: {'review'}, kinds: {'post'});
    } else {
      // Default saat dibuka: semua konten, semua status. Dilaporkan tidak tercentang (khusus filter).
      cubit.setFilter(statuses: const {}, kinds: const {}, reported: false);
    }
    _pollTimer = Timer.periodic(_pollInterval, (_) => cubit.load(silent: true));

    // Hak akses Wall of Fame dimuat ulang di sini. Setelah selesai, daftar dimuat ulang juga
    // supaya kartu fame sesuai hak akses yang sudah diketahui.
    FeedCreateTabs.refreshFameAccess(context).then((_) {
      if (!mounted) return;
      setState(() {});
      context.read<FeedListCubit>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<FeedListCubit>().loadMore();
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openPost(FeedPostEntity post) {
    context.pushNamed(
      'marketingFeedDetail',
      queryParameters: {'feed_post_id': post.id.toString()},
    );
  }

  // ------------------------------------------------------------------ tombol +

  /// + langsung membuka form kiriman baru.
  Future<void> _onFabTap() async {
    AnalyticsService.logEvent('marketing_feed_fab');
    await context.pushNamed<bool>('marketingFeedPostForm');
    if (mounted) context.read<FeedListCubit>().load(silent: true);
  }

  // ------------------------------------------------------------------ Wall of Fame

  /// Aksi "Lihat" di menu titik tiga: masuk ke Detail Post (kiriman atau kartu Wall of Fame).
  FeedCardAction _viewAction(FeedListItem item) {
    return FeedCardAction(
      label: 'Lihat',
      icon: Icons.visibility_outlined,
      color: const Color(primaryColor),
      onPressed: item.post != null
          ? () => _openPost(item.post!)
          : () => _openFameDetail(item.fame!),
    );
  }

  /// Tap kartu: buka Detail Post yang ada, dengan kartu Wall of Fame lewat extra (tanpa memuat ulang).
  void _openFameDetail(FameListCardEntity card) {
    context.pushNamed('marketingFeedDetail', extra: card);
  }

  /// Ubah kartu: form yang sama dengan halaman kelola Wall of Fame.
  Future<void> _editFame(FameListCardEntity card) async {
    final manage = context.read<FameManageCubit>();
    await manage.load();
    if (!mounted) return;
    final state = manage.state;
    final saved = await context.pushNamed<bool>(
      'marketingFameForm',
      extra: FameFormArgs(
        card: _toAdminCard(card),
        programName: card.program,
        periodeLabel: card.periode,
        programs: state.programs,
        canCreateProgram: state.access?.canCreateProgram ?? false,
      ),
    );
    if (saved == true && mounted) {
      _message('Wall of Fame disimpan');
      context.read<FeedListCubit>().load(silent: true);
    }
  }

  FameAdminCardEntity _toAdminCard(FameListCardEntity card) {
    return FameAdminCardEntity(
      id: card.id,
      kategori: card.kategori,
      caption: card.caption,
      status: card.status,
      publishAt: card.publishAt,
      mediaId: card.mediaId,
      mediaType: card.mediaType,
      winners: card.winners,
      entry: FameEntryEntity(
        id: card.id,
        programId: 0,
        programName: card.program,
        kategori: card.kategori,
        caption: card.caption,
        mediaType: card.mediaType,
        mediaUrl: card.mediaUrl,
      ),
    );
  }

  Future<void> _deleteFame(FameListCardEntity card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Wall of Fame ini?'),
        content: const Text(
          'Juara dan poster di Wall of Fame ini ikut dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Color(redAccentColor)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AnalyticsService.logEvent('marketing_feed_fame_delete');
    final error = await context.read<FeedListCubit>().deleteFame(card.id);
    _message(error ?? 'Wall of Fame dihapus');
  }

  Future<void> _publishFame(FameListCardEntity card) async {
    AnalyticsService.logEvent('marketing_feed_fame_publish');
    final error = await context.read<FeedListCubit>().setFameStatus(
      card.id,
      'published',
    );
    _message(error ?? 'Kartu ditayangkan');
  }

  // ------------------------------------------------------------------ layar

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customHeader(context, 'Feeds', isBack: true),
            _buildSearch(),
            _buildFilters(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(grey10Color)),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          // Batas parameter q di backend: 100 karakter.
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          onChanged: (v) {
            context.read<FeedListCubit>().setQuery(v);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Cari nama, caption, atau judul link',
            prefixIcon: Image.asset(icSearch),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      context.read<FeedListCubit>().setQuery('');
                      setState(() {});
                    },
                  ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  /// Urutkan dan Filter (membuka sheet), seperti filter di Contacts.
  Widget _buildFilters() {
    return BlocBuilder<FeedListCubit, FeedListState>(
      buildWhen: (a, b) =>
          a.sort != b.sort || a.statuses != b.statuses || a.kinds != b.kinds,
      builder: (context, state) {
        final sortLabel = feedListSortOptions
            .firstWhere(
              (o) => o.$1 == state.sort,
              orElse: () => feedListSortOptions.first,
            )
            .$2;
        // Aktif kalau ada yang tidak sama dengan default (tidak semua status, Dilaporkan, atau jenis dibatasi).
        // Aktif kalau berbeda dari default (hanya Tayang), atau Dilaporkan, atau jenis dibatasi.
        final filterActive =
            state.noSelection ||
            !state.isDefaultStatuses ||
            !state.isDefaultKinds ||
            !state.isDefaultReported;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CustomFilterButton(
                label: 'Urutkan: $sortLabel',
                isSelected: state.sort != 'updated',
                onTap: () => _openSortSheet(context, state.sort),
              ),
              const SizedBox(width: 8),
              CustomFilterButton(
                label: filterActive ? 'Filter (aktif)' : 'Filter',
                isSelected: filterActive,
                onClear: filterActive
                    ? () => context.read<FeedListCubit>().setFilter(
                        statuses: const {},
                        kinds: const {},
                        reported: false,
                      )
                    : null,
                onTap: () => _openFilterSheet(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    FeedListState state,
  ) async {
    final result =
        await showModalBottomSheet<
          ({Set<String> statuses, bool reported, bool includeFame})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(backgroundColor),
          builder: (ctx) => _FeedFilterSheet(
            statuses: state.statuses,
            kinds: state.kinds,
            reported: state.reported,
          ),
        );
    if (result != null && context.mounted) {
      context.read<FeedListCubit>().applySheet(
        statuses: result.statuses,
        reported: result.reported,
        includeFame: result.includeFame,
      );
    }
  }

  /// Sheet "Urutkan" dengan gaya yang sama seperti sheet Filter: header, kartu putih, dan baris pilihan.
  /// Ketuk pilihan = langsung diterapkan.
  Future<void> _openSortSheet(BuildContext context, String current) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(backgroundColor),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Urutkan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _feedSheetCard([
                for (final (key, label) in feedListSortOptions)
                  _feedSheetRow(
                    icon: switch (key) {
                      'oldest' => Icons.history_rounded,
                      'updated' => Icons.update_rounded,
                      _ => Icons.arrow_downward_rounded,
                    },
                    label: label,
                    selected: key == current,
                    onTap: () => Navigator.pop(ctx, key),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      context.read<FeedListCubit>().setSort(result);
    }
  }

  Widget _buildList() {
    return BlocBuilder<FeedListCubit, FeedListState>(
      builder: (context, state) {
        if (state.noSelection) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pilih minimal satu filter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(grey2Color)),
              ),
            ),
          );
        }
        if (state.items.isEmpty) {
          if (state.status == FeedListStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Gagal memuat kiriman.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(grey2Color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<FeedListCubit>().load(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.status == FeedListStatus.loading ||
              state.status == FeedListStatus.initial) {
            return buildFeedListShimmer();
          }
          return RefreshIndicator(
            onRefresh: () => context.read<FeedListCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                FeedEmptyState(
                  icon: state.filtered
                      ? Icons.search_off_rounded
                      : Icons.history_edu_outlined,
                  title: state.filtered
                      ? 'Tidak ada yang cocok'
                      : 'Belum ada kiriman',
                  message: state.filtered
                      ? 'Coba kata kunci lain atau ubah filter.'
                      : 'Bagikan momen closing atau kunjungan serumu lewat tombol +!',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<FeedListCubit>().load(),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i >= state.items.length) {
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
              final item = state.items[i];
              final busy = state.busyKey == item.key;
              // Semua aksi kartu (kiri-kanan tombol lama) dibuka lewat menu titik tiga.
              final built = item.post != null
                  ? _postActions(context, item.post!, busy, item.reportActions)
                  : _fameActions(item.fame!, busy, item.reportActions);
              // Semua kartu memakai menu titik tiga, dan setiap menu selalu punya "Lihat" untuk masuk ke detail.
              final actions = [_viewAction(item), ...built];
              return KeyedSubtree(
                key: ValueKey(item.key),
                child: item.post != null
                    ? feedPostCard(
                        post: item.post!,
                        badge: item.badge,
                        onTap: () => _openPost(item.post!),
                        footer: item.isReported
                            ? _reportCountText(
                                reportCount: item.post!.reportCount,
                                isFame: false,
                              )
                            : null,
                        menu: actions,
                      )
                    : fameListCard(
                        card: item.fame!,
                        badge: item.badge,
                        onTap: () => _openFameDetail(item.fame!),
                        footer: item.isReported
                            ? _reportCountText(
                                reportCount: item.fame!.reportCount,
                                isFame: true,
                              )
                            : null,
                        menu: actions,
                      ),
              );
            },
          ),
        );
      },
    );
  }

  /// Aksi kiriman (menu titik tiga). Muncul sesuai status dan izin, bukan siapa pembuatnya:
  /// - setujui / jadwalkan / tolak: kiriman menunggu review (izin ApproveReject);
  /// - unpublish / hapus: kiriman tayang (izin ApproveReject / Delete).
  /// Item dilaporkan: hanya aksi laporan dari backend (tanpa Publish, Setujui, dan sebagainya).
  List<FeedCardAction> _postActions(
    BuildContext context,
    FeedPostEntity post,
    bool busy,
    List<String> reportActions,
  ) {
    final cubit = context.read<FeedListCubit>();
    final canApprove = PermissionsHelper.canApproveMarketingFeed;
    if (reportActions.isNotEmpty) {
      return _reportActions(
        id: post.id,
        kind: 'post',
        actions: reportActions,
        busy: busy,
        onDelete: () => deleteFeed(context, cubit, post.id),
        onUnpublish: () => unpublishFeed(context, cubit, post.id),
      );
    }
    if (post.status == FeedPostStatus.draft) {
      return _draftActions(context, cubit, post, busy);
    }
    return [
      if (canApprove && post.status == FeedPostStatus.review) ...[
        FeedCardAction(
          label: 'Tolak',
          icon: Icons.close_rounded,
          color: const Color(redAccentColor),
          onPressed: busy ? null : () => rejectFeed(context, cubit, post.id),
        ),
        FeedCardAction(
          label: 'Jadwalkan',
          icon: Icons.schedule_rounded,
          color: const Color(primaryColor),
          onPressed: busy ? null : () => scheduleFeed(context, cubit, post.id),
        ),
        FeedCardAction(
          label: 'Setujui',
          icon: Icons.check_rounded,
          color: const Color(successColor),
          onPressed: busy ? null : () => approveFeed(context, cubit, post.id),
        ),
      ],
      if (post.status == FeedPostStatus.published &&
          PermissionsHelper.canDeleteMarketingFeed)
        FeedCardAction(
          label: 'Hapus',
          icon: Icons.delete_outline_rounded,
          color: const Color(redAccentColor),
          onPressed: busy ? null : () => deleteFeed(context, cubit, post.id),
        ),
      if (post.status == FeedPostStatus.published && canApprove)
        FeedCardAction(
          label: 'Unpublish',
          icon: Icons.visibility_off_outlined,
          color: const Color(primaryColor),
          onPressed: busy ? null : () => unpublishFeed(context, cubit, post.id),
        ),
    ];
  }

  /// Aksi draft.
  /// - Bisa langsung tayang (ApproveReject atau SkipReview): Hapus, Ubah, dan Publish.
  /// - Milik sendiri tanpa izin itu: Ajukan ulang (buka editor; kirim dilakukan di form, hasilnya antrean review).
  /// - Draft orang lain tanpa izin: tidak ada aksi.
  List<FeedCardAction> _draftActions(
    BuildContext context,
    FeedListCubit cubit,
    FeedPostEntity post,
    bool busy,
  ) {
    final canPublishDirect =
        PermissionsHelper.canApproveMarketingFeed ||
        PermissionsHelper.canSkipReviewMarketingFeed;
    if (canPublishDirect) {
      return [
        if (PermissionsHelper.canDeleteMarketingFeed)
          FeedCardAction(
            label: 'Hapus',
            icon: Icons.delete_outline_rounded,
            color: const Color(redAccentColor),
            onPressed: busy ? null : () => deleteFeed(context, cubit, post.id),
          ),
        FeedCardAction(
          label: 'Ubah',
          icon: Icons.edit_outlined,
          color: const Color(primaryColor),
          onPressed: busy ? null : () => _editPost(post),
        ),
        FeedCardAction(
          label: 'Publish',
          icon: Icons.send_rounded,
          color: const Color(successColor),
          onPressed: busy ? null : () => _publishDraft(cubit, post.id),
        ),
      ];
    }
    if (post.isMine) {
      return [
        FeedCardAction(
          label: 'Ubah',
          icon: Icons.edit_outlined,
          color: const Color(primaryColor),
          onPressed: busy ? null : () => _editPost(post),
        ),
        FeedCardAction(
          label: 'Ajukan ulang',
          icon: Icons.send_rounded,
          color: const Color(successColor),
          onPressed: busy ? null : () => _editPost(post),
        ),
      ];
    }
    return const [];
  }

  /// Buka editor draft sesuai jenisnya (sama dengan halaman Draft & Terjadwal).
  Future<void> _editPost(FeedPostEntity post) async {
    final route = switch (post.type) {
      FeedPostType.post => 'marketingFeedPostForm',
      FeedPostType.poll => 'marketingFeedPollForm',
      FeedPostType.link => 'marketingFeedLinkForm',
    };
    final saved = await context.pushNamed<bool>(route, extra: post);
    if (mounted && saved == true) {
      context.read<FeedListCubit>().load(silent: true);
    }
  }

  /// Publish" draft sekarang. Pesan error dari server ditampilkan apa adanya.
  Future<void> _publishDraft(FeedListCubit cubit, int postId) async {
    final error = await cubit.moderate(postId, 'now');
    _message(error ?? 'Kiriman ditayangkan');
  }

  /// Aksi kartu Wall of Fame (menu titik tiga). Item dilaporkan: aksi laporan dari backend (sama dengan kiriman).
  /// Selain itu hanya untuk user yang bisa mengelola Wall of Fame, atau approver.
  List<FeedCardAction> _fameActions(
    FameListCardEntity card,
    bool busy,
    List<String> reportActions,
  ) {
    if (reportActions.isNotEmpty) {
      return _reportActions(
        id: card.id,
        kind: 'fame',
        actions: reportActions,
        busy: busy,
        onDelete: () => _deleteFame(card),
        onUnpublish: () => _decideReport(card.id, 'fame', 'takedown'),
      );
    }
    final canApprove = PermissionsHelper.canApproveMarketingFeed;
    final editable = FeedCreateTabs.fameEditable;
    if (!editable && !canApprove) return const [];
    // Unpublish kartu tayang (approver): kembali ke draf, sama seperti kiriman.
    final unpublish = card.status == 'published' && canApprove
        ? FeedCardAction(
            label: 'Unpublish',
            icon: Icons.visibility_off_outlined,
            color: const Color(primaryColor),
            onPressed: busy
                ? null
                : () async {
                    final error = await context
                        .read<FeedListCubit>()
                        .setFameStatus(card.id, 'draft');
                    _message(error ?? 'Kartu dikembalikan ke draf.');
                  },
          )
        : null;
    return [
      // Hapus: editor Wall of Fame atau approver.
      FeedCardAction(
        label: 'Hapus',
        icon: Icons.delete_outline_rounded,
        color: const Color(redAccentColor),
        onPressed: busy ? null : () => _deleteFame(card),
      ),
      if (editable)
        FeedCardAction(
          label: 'Ubah',
          icon: Icons.edit_outlined,
          color: const Color(primaryColor),
          onPressed: busy ? null : () => _editFame(card),
        ),
      if (editable && card.status != 'published')
        FeedCardAction(
          label: 'Publish',
          icon: Icons.send_rounded,
          color: const Color(successColor),
          onPressed: busy ? null : () => _publishFame(card),
        ),
      if (unpublish != null) unpublish,
    ];
  }

  /// Aksi laporan untuk kiriman DAN kartu Wall of Fame, dari report_actions backend, berurutan:
  /// dismiss = Abaikan (laporan ditutup, item tetap tayang), delete = Hapus, takedown = Unpublish.
  List<FeedCardAction> _reportActions({
    required int id,
    required String kind,
    required List<String> actions,
    required bool busy,
    required VoidCallback onDelete,
    required VoidCallback onUnpublish,
  }) {
    return [
      for (final action in actions)
        if (action == 'dismiss')
          FeedCardAction(
            label: 'Abaikan',
            icon: Icons.check_rounded,
            color: const Color(grey2Color),
            onPressed: busy ? null : () => _decideReport(id, kind, 'dismiss'),
          )
        else if (action == 'delete')
          FeedCardAction(
            label: 'Hapus',
            icon: Icons.delete_outline_rounded,
            color: const Color(redAccentColor),
            onPressed: busy ? null : onDelete,
          )
        else if (action == 'takedown')
          FeedCardAction(
            label: 'Unpublish',
            icon: Icons.visibility_off_outlined,
            color: const Color(primaryColor),
            onPressed: busy ? null : onUnpublish,
          ),
    ];
  }

  /// Keterangan jumlah laporan di bawah kartu yang dilaporkan.
  Widget _reportCountText({required int reportCount, required bool isFame}) {
    return Text(
      '${isFame ? 'Wall of Fame · ' : ''}$reportCount laporan untuk ${isFame ? 'kartu' : 'kiriman'} ini',
      style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
    );
  }


  /// Keputusan approver atas laporan kiriman atau kartu fame (kind = post | fame). Takedown mengembalikan item ke draf.
  Future<void> _decideReport(int id, String kind, String action) async {
    final error = await context
        .read<FeedReportCubit>()
        .decide(id, action, kind: kind);
    if (!mounted) return;
    if (error == null) context.read<FeedListCubit>().load(silent: true);
    _message(
      error ??
          (action == 'takedown'
              ? 'Diturunkan tayang, kembali ke draf.'
              : 'Laporan diabaikan.'),
    );
  }

}

/// Satu kartu putih berisi semua pilihan, dipisah garis tipis (tanpa judul bagian). Dipakai sheet Filter dan Urutkan.
Widget _feedSheetCard(List<Widget> rows) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(whiteColor),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(blackColor).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 56),
          rows[i],
        ],
      ],
    ),
  );
}

/// Satu baris pilihan dengan ikon bulat dan kotak centang. Dipakai sheet Filter dan Urutkan.
Widget _feedSheetRow({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(primaryColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: const Color(primaryColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(
            selected
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: selected
                ? const Color(primaryColor)
                : const Color(grey4Color),
          ),
        ],
      ),
    ),
  );
}

/// Sheet filter gaya Contacts: bagian dengan kartu putih, baris pilihan, dan tombol Terapkan di bawah.
class _FeedFilterSheet extends StatefulWidget {
  final Set<String> statuses;
  final Set<String> kinds;

  /// Filter "Dilaporkan" (approver): daftar diganti kiriman yang punya laporan terbuka.
  final bool reported;

  const _FeedFilterSheet({
    required this.statuses,
    required this.kinds,
    this.reported = false,
  });

  @override
  State<_FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<_FeedFilterSheet> {
  // Getter, bukan field: dibaca ulang setiap build, jadi ikut benar setelah refreshFameAccess selesai.
  // Wall of Fame difilter oleh user yang boleh mengelola kartu (canEdit), atau approver yang sedang
  // memfilter Dilaporkan. Hasil akhirnya tetap ditentukan backend.
  bool get _canFame =>
      FeedCreateTabs.fameEditable ||
      (PermissionsHelper.canApproveMarketingFeed && _reported);
  late final List<(String, String)> _statusOpts;
  late final Set<String> _statuses;
  // Jenis: Wall of Fame dicentang = kartu fame ikut tampil (bersama kiriman); tidak dicentang = hanya kiriman.
  late bool _includeFame;
  late bool _reported;
  // All = semua konten (default). Saat aktif, baris filter lain tidak tercentang.
  late bool _all;

  @override
  void initState() {
    super.initState();
    _statusOpts = feedListStatusOptions.toList();
    // Tanpa filter dari cubit = All (default). Ada filter = All tidak aktif, pilihan sesuai filter.
    _all = widget.statuses.isEmpty && widget.kinds.isEmpty && !widget.reported;
    _statuses = _all ? <String>{} : {...widget.statuses};
    _reported = !_all && widget.reported;
    // Wall of Fame: tercentang kalau kartu fame ikut tampil (jenis kosong = semua).
    _includeFame =
        !_all &&
        _canFame &&
        (widget.kinds.isEmpty || widget.kinds.contains('fame'));
  }

  // Tidak ada yang dipilih sama sekali (All juga tidak aktif).
  /// Tidak ada yang dipilih sama sekali (All juga tidak aktif).
  bool get _noneSelected =>
      !_all && _statuses.isEmpty && !_reported && !_includeFame;

  /// Baris All dipilih: semua konten, tanpa filter status, jenis, atau dilaporkan. Baris lain dikosongkan.
  void _selectAll() {
    setState(() {
      _all = true;
      _statuses.clear();
      _reported = false;
      _includeFame = false;
    });
  }

  /// Tombol Reset: hapus semua pilihan (All juga dilepas).
  void _clearAll() {
    setState(() {
      _all = false;
      _statuses.clear();
      _reported = false;
      _includeFame = false;
    });
  }

  /// Menyentuh filter lain saat All aktif: All dilepas dan pilihan dimulai dari kosong.
  void _pick(void Function() change) {
    setState(() {
      if (_all) {
        _all = false;
        _statuses.clear();
        _reported = false;
        _includeFame = false;
      }
      change();
    });
  }

  /// Terapkan persis yang dipilih. All = semua status dicentang tanpa Dilaporkan, jadi cubit tanpa filter status.
  void _apply() {
    Navigator.pop(context, (
      statuses: _all
          ? {for (final o in _statusOpts) o.$1}
          : {..._statuses},
      reported: !_all && _reported,
      includeFame: _all || !_canFame || _includeFame,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.8;
    // Tinggi mengikuti isi sheet, dengan batas atas 60% tinggi layar.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _noneSelected ? null : _clearAll,
                    child: Text(
                      'Reset',
                      style: TextStyle(color: Color(primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _feedSheetCard([
                    // All: baris pertama, gaya sama dengan baris filter lain. Default tercentang.
                    _feedSheetRow(
                      icon: Icons.select_all_rounded,
                      label: 'All',
                      selected: _all,
                      onTap: _selectAll,
                    ),
                    for (final (key, label) in _statusOpts)
                      _feedSheetRow(
                        icon: _statusIcon(key),
                        label: label,
                        selected: !_all && _statuses.contains(key),
                        onTap: () => _pick(
                          () => _statuses.contains(key)
                              ? _statuses.remove(key)
                              : _statuses.add(key),
                        ),
                      ),
                    if (PermissionsHelper.canApproveMarketingFeed)
                      _feedSheetRow(
                        icon: Icons.flag_outlined,
                        label: 'Dilaporkan',
                        selected: !_all && _reported,
                        onTap: () => _pick(() => _reported = !_reported),
                      ),
                    if (_canFame)
                      _feedSheetRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Wall of Fame',
                        selected: !_all && _includeFame,
                        onTap: () => _pick(() => _includeFame = !_includeFame),
                      ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: customButton(_apply, 'Terapkan'),

                // FilledButton(

                //   // Kosong di status atau jenis = semua, jadi tombol selalu bisa ditekan.
                //   onPressed: ,
                //   child: const Text('Terapkan'),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String key) {
    switch (key) {
      case 'published':
        return Icons.check_circle_outline_rounded;
      case 'draft':
        return Icons.edit_note_rounded;
      case 'scheduled':
        return Icons.schedule_rounded;
      case 'review':
        return Icons.hourglass_empty_rounded;

      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.fact_check_outlined;
    }
  }
}
