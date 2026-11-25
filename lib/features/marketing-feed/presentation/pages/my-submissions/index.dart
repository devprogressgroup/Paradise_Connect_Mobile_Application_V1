import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_action_button.dart';
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
      // Notifikasi laporan: filter Dilaporkan langsung aktif.
      cubit.setFilter(statuses: {}, kinds: {'post'}, reported: true);
    } else if (widget.initialTab == 'approval' &&
        PermissionsHelper.canApproveMarketingFeed) {
      cubit.setFilter(statuses: {'review'}, kinds: {'post'});
    } else {
      cubit.load();
    }
    _pollTimer = Timer.periodic(_pollInterval, (_) => cubit.load(silent: true));

    // Kartu Wall of Fame hanya muncul kalau user punya izin edit (hak akses dimuat ulang di sini).
    FeedCreateTabs.refreshFameAccess(context).then((_) {
      if (mounted) setState(() {});
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
            state.reported;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CustomFilterButton(
                label: 'Urutkan: $sortLabel',
                isSelected: state.sort != 'latest',
                onTap: () => _openSortSheet(context, state.sort),
              ),
              const SizedBox(width: 8),
              CustomFilterButton(
                label: filterActive ? 'Filter (aktif)' : 'Filter',
                isSelected: filterActive,
                onClear: filterActive
                    ? () => context.read<FeedListCubit>().setFilter(
                        statuses: {'published'},
                        kinds: {'post'},
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
              return KeyedSubtree(
                key: ValueKey(item.key),
                child: item.post != null
                    ? feedPostCard(
                        post: item.post!,
                        onTap: () => _openPost(item.post!),
                        footer: _postFooter(context, item.post!, busy),
                      )
                    : fameListCard(
                        card: item.fame!,
                        onTap: () {
                          if (FeedCreateTabs.fameEditable)
                            _editFame(item.fame!);
                        },
                        footer: _fameFooter(item.fame!, busy),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  /// Tombol kiriman. Muncul sesuai status dan izin, bukan siapa pembuatnya:
  /// - setujui / jadwalkan / tolak: kiriman menunggu review (izin ApproveReject);
  /// - turunkan tayang / hapus: kiriman tayang (izin ApproveReject).
  Widget? _postFooter(BuildContext context, FeedPostEntity post, bool busy) {
    final cubit = context.read<FeedListCubit>();
    final canApprove = PermissionsHelper.canApproveMarketingFeed;
    if (post.status == FeedPostStatus.draft) {
      return _draftFooter(context, cubit, post, busy);
    }
    final rows = <Widget>[
      // Kiriman yang dilaporkan: jumlah laporan dan tombol Abaikan (laporan ditutup, kiriman tetap tayang).
      if (canApprove && post.reportCount > 0)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${post.reportCount} laporan untuk kiriman ini',
              style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
            const SizedBox(height: 6),
            _actionRow(
              red: FeedActionButton(
                icon: Icons.check_rounded,
                label: 'Abaikan',
                color: const Color(grey2Color),
                onPressed: busy
                    ? null
                    : () async {
                        final error = await context
                            .read<FeedReportCubit>()
                            .decide(post.id, 'dismiss');
                        if (!context.mounted) return;
                        if (error == null) cubit.load(silent: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? 'Laporan diabaikan.'),
                          ),
                        );
                      },
              ),
              // Kiriman tayang yang dilaporkan: Hapus dan Unpublish ikut di satu baris bersama Abaikan.
              blue:
                  post.status == FeedPostStatus.published &&
                      PermissionsHelper.canDeleteMarketingFeed
                  ? FeedActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Hapus',
                      color: const Color(redAccentColor),
                      onPressed: busy
                          ? null
                          : () => deleteFeed(context, cubit, post.id),
                    )
                  : null,
              green: post.status == FeedPostStatus.published
                  ? FeedActionButton(
                      icon: Icons.visibility_off_outlined,
                      label: 'Unpublish',
                      color: const Color(primaryColor),
                      onPressed: busy
                          ? null
                          : () => unpublishFeed(context, cubit, post.id),
                    )
                  : null,
            ),
          ],
        ),
      if (canApprove && post.status == FeedPostStatus.review)
        _actionRow(
          red: FeedActionButton(
            icon: Icons.close_rounded,
            label: 'Tolak',
            color: const Color(redAccentColor),
            onPressed: busy ? null : () => rejectFeed(context, cubit, post.id),
          ),
          blue: FeedActionButton(
            icon: Icons.schedule_rounded,
            label: 'Jadwalkan',
            color: const Color(primaryColor),
            onPressed: busy
                ? null
                : () => scheduleFeed(context, cubit, post.id),
          ),
          green: FeedActionButton(
            icon: Icons.check_rounded,
            label: 'Setujui',
            color: const Color(successColor),
            filled: true,
            loading: busy,
            onPressed: busy ? null : () => approveFeed(context, cubit, post.id),
          ),
        ),
      // Kiriman tayang yang dilaporkan sudah ditampilkan di blok laporan di atas.
      if (post.status == FeedPostStatus.published &&
          !(canApprove && post.reportCount > 0) &&
          (canApprove || PermissionsHelper.canDeleteMarketingFeed))
        _actionRow(
          red: PermissionsHelper.canDeleteMarketingFeed
              ? FeedActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus',
                  color: const Color(redAccentColor),
                  loading: busy,
                  onPressed: busy
                      ? null
                      : () => deleteFeed(context, cubit, post.id),
                )
              : null,
          blue: canApprove
              ? FeedActionButton(
                  icon: Icons.visibility_off_outlined,
                  label: 'Unpublish',
                  color: const Color(primaryColor),
                  onPressed: busy
                      ? null
                      : () => unpublishFeed(context, cubit, post.id),
                )
              : null,
        ),
    ];
    return _stack(rows);
  }

  /// Tombol draft.
  /// - Bisa langsung tayang (ApproveReject atau SkipReview): Ubah, Publish", dan Hapus.
  /// - Milik sendiri tanpa izin itu: Ajukan ulang (buka editor; kirim dilakukan di form, hasilnya antrean review).
  /// - Draft orang lain tanpa izin: tidak ada tombol.
  Widget? _draftFooter(
    BuildContext context,
    FeedListCubit cubit,
    FeedPostEntity post,
    bool busy,
  ) {
    final canPublishDirect =
        PermissionsHelper.canApproveMarketingFeed ||
        PermissionsHelper.canSkipReviewMarketingFeed;
    if (canPublishDirect) {
      return _actionRow(
        red: PermissionsHelper.canDeleteMarketingFeed
            ? FeedActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Hapus',
                color: const Color(redAccentColor),
                onPressed: busy
                    ? null
                    : () => deleteFeed(context, cubit, post.id),
              )
            : null,
        blue: FeedActionButton(
          icon: Icons.edit_outlined,
          label: 'Ubah',
          color: const Color(primaryColor),
          onPressed: busy ? null : () => _editPost(post),
        ),
        green: FeedActionButton(
          icon: Icons.send_rounded,
          label: 'Publish',
          color: const Color(successColor),
          filled: true,
          loading: busy,
          onPressed: busy ? null : () => _publishDraft(cubit, post.id),
        ),
      );
    }
    if (post.isMine) {
      return _actionRow(
        green: FeedActionButton(
          icon: Icons.send_rounded,
          label: 'Ajukan ulang',
          color: const Color(successColor),
          filled: true,
          onPressed: busy ? null : () => _editPost(post),
        ),
      );
    }
    return null;
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

  /// Tombol kartu Wall of Fame: hanya untuk user yang bisa mengelola Wall of Fame.
  Widget? _fameFooter(FameListCardEntity card, bool busy) {
    if (!FeedCreateTabs.fameEditable) return null;
    return _actionRow(
      red: FeedActionButton(
        icon: Icons.delete_outline_rounded,
        label: 'Hapus',
        color: const Color(redAccentColor),
        onPressed: busy ? null : () => _deleteFame(card),
      ),
      blue: FeedActionButton(
        icon: Icons.edit_outlined,
        label: 'Ubah',
        color: const Color(primaryColor),
        onPressed: busy ? null : () => _editFame(card),
      ),
      green: card.status != 'published'
          ? FeedActionButton(
              icon: Icons.send_rounded,
              label: 'Publish',
              color: const Color(successColor),
              filled: true,
              loading: busy,
              onPressed: busy ? null : () => _publishFame(card),
            )
          : null,
    );
  }

  /// Tiga kolom berlebar di semua baris: merah kiri, biru tengah, hijau kanan.
  /// Kolom yang kosong tetap ada, jadi lebar tombol sama di semua kartu.
  Widget _actionRow({Widget? red, Widget? blue, Widget? green}) {
    Widget slot(Widget? w) => Expanded(child: w ?? const SizedBox.shrink());
    return Row(
      children: [
        slot(red),
        const SizedBox(width: 8),
        slot(blue),
        const SizedBox(width: 8),
        slot(green),
      ],
    );
  }

  Widget? _stack(List<Widget> rows) {
    if (rows.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          rows[i],
        ],
      ],
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
  final _canFame = FeedCreateTabs.fameEditable;
  late final List<(String, String)> _statusOpts;
  late final Set<String> _statuses;
  // Jenis: Wall of Fame dicentang = kartu fame ikut tampil (bersama kiriman); tidak dicentang = hanya kiriman.
  late bool _includeFame;
  late bool _reported;

  @override
  void initState() {
    super.initState();
    _statusOpts = feedListStatusOptions.toList();
    // Filter awal = Tayang saja (dari state cubit).
    _statuses = {...widget.statuses};
    _reported = widget.reported;
    // Wall of Fame: tercentang kalau kartu fame ikut tampil.
    _includeFame =
        _canFame && (widget.kinds.isEmpty || widget.kinds.contains('fame'));
  }

  // Semua mencakup Wall of Fame dan Dilaporkan (kalau user boleh melihatnya).
  bool get _allSelected =>
      _statuses.length == _statusOpts.length &&
      (!_canFame || _includeFame) &&
      (!PermissionsHelper.canApproveMarketingFeed || _reported);

  void _toggleStatus(String key) {
    setState(
      () =>
          _statuses.contains(key) ? _statuses.remove(key) : _statuses.add(key),
    );
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _statuses.clear();
        _includeFame = false;
        _reported = false;
      } else {
        _statuses
          ..clear()
          ..addAll(_statusOpts.map((o) => o.$1));
        _includeFame = _canFame;
        _reported = PermissionsHelper.canApproveMarketingFeed;
      }
    });
  }

  /// Terapkan persis yang dicentang. Tidak ada yang ditambah atau dikurangi di sini.
  void _apply() {
    Navigator.pop(context, (
      statuses: {..._statuses},
      reported: _reported,
      includeFame: _canFame && _includeFame,
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
                  // TextButton(
                  //   onPressed: _allSelected ? null : _toggleAll,
                  //   child: const Text('Reset'),
                  // ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(
                      _allSelected ? 'Reset' : 'All',
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
                    // _feedSheetRow(
                    //   icon: Icons.select_all_rounded,
                    //   label: 'Semua',
                    //   selected: _allSelected,
                    //   onTap: _toggleAll,
                    // ),
                    for (final (key, label) in _statusOpts)
                      _feedSheetRow(
                        icon: _statusIcon(key),
                        label: label,
                        selected: _statuses.contains(key),
                        onTap: () => _toggleStatus(key),
                      ),
                    if (PermissionsHelper.canApproveMarketingFeed)
                      _feedSheetRow(
                        icon: Icons.flag_outlined,
                        label: 'Dilaporkan',
                        selected: _reported,
                        onTap: () => setState(() => _reported = !_reported),
                      ),
                    if (_canFame)
                      _feedSheetRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Wall of Fame',
                        selected: _includeFame,
                        onTap: () =>
                            setState(() => _includeFame = !_includeFame),
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
