import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/fame-form/index.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/fame_programs_section.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Kelola Wall of Fame (admin mobile). Hak akses dari backend (t_feed_fame_perm): tanpa can_edit,
/// halaman hanya menampilkan keterangan. Dengan izin: daftar kartu per program, aksi per kartu,
/// dan tombol + untuk kartu baru.
class FameManagePage extends StatefulWidget {
  /// [embedded] = dipakai sebagai tab di dalam halaman lain (Kiriman Saya): tanpa header dan Scaffold.
  const FameManagePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FameManagePage> createState() => FameManagePageState();
}

class FameManagePageState extends State<FameManagePage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_fame_manage');
    context.read<FameManageCubit>().load();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _runAction(Future<String?> action, String successMessage) async {
    final error = await action;
    if (!mounted) return;
    _message(error ?? successMessage);
  }

  FameManageProgramEntity? _programOf(FameAdminCardEntity card) {
    for (final p in context.read<FameManageCubit>().state.programs) {
      if (p.cards.any((c) => c.id == card.id)) return p;
    }
    return null;
  }

  /// Form kartu Wall of Fame baru. Dipanggil dari + di bawah halaman Feeds (tab Wall of Fame).
  void openNewCard() => _openForm();

  Future<void> _openForm({
    FameAdminCardEntity? card,
    FameManageProgramEntity? program,
  }) async {
    final state = context.read<FameManageCubit>().state;
    final owner = card == null ? program : _programOf(card);
    final saved = await context.pushNamed<bool>(
      'marketingFameForm',
      extra: FameFormArgs(
        card: card,
        programId: owner?.id,
        programName: owner?.namaProgram,
        periodeLabel: owner?.periodeLabel,
        programs: state.programs,
        canCreateProgram: state.access?.canCreateProgram ?? false,
      ),
    );
    if (saved == true && mounted) {
      _message('Wall of Fame disimpan');
      context.read<FameManageCubit>().load();
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return ok == true;
  }

  Future<void> _onMenu(String action, FameAdminCardEntity card) async {
    final cubit = context.read<FameManageCubit>();
    switch (action) {
      case 'publish':
        AnalyticsService.logEvent('marketing_feed_fame_publish');
        await _runAction(
          cubit.setStatus(card.id, 'published'),
          'Kartu ditayangkan',
        );
      case 'edit':
        await _openForm(card: card);
      case 'delete':
        final ok = await _confirm(
          'Hapus Wall of Fame ini?',
          'Juara dan poster di Wall of Fame ini ikut dihapus.',
        );
        if (!ok) return;
        AnalyticsService.logEvent('marketing_feed_fame_delete');
        await _runAction(cubit.deleteCard(card.id), 'Wall of Fame dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FameManageCubit>().state;
    final canEdit = state.access?.canEdit ?? false;
    if (widget.embedded) {
      // Tombol tambah ada di + bawah halaman Feeds (dipanggil lewat openNewCard).
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<FameManageCubit>().load(),
              child: _buildBody(state),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Wall of Fame', isBack: true),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<FameManageCubit>().load(),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              heroTag: 'fame_manage_fab',
              tooltip: 'Tambah',
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(FameManageState state) {
    if (state.status == FameManageStatus.initial ||
        (state.status == FameManageStatus.loading && state.programs.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == FameManageStatus.error && state.programs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FeedEmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat',
            message: state.errorMessage ?? 'Coba lagi beberapa saat.',
          ),
        ],
      );
    }
    if (state.access != null && !state.access!.canEdit) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          FeedEmptyState(
            icon: Icons.lock_outline,
            title: 'Tidak ada izin',
            message:
                'Kamu hanya bisa melihat Wall of Fame. Untuk mengubah, minta izin marketing-feed.fame.edit ke admin.',
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (state.busy) const LinearProgressIndicator(minHeight: 2),
        if (state.programs.isEmpty)
          const FeedEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Belum ada program',
            message: 'Tekan + untuk menambahkan juara pertama.',
          ),
        for (final program in state.programs) ...[
          _buildProgramHeader(program),
          const SizedBox(height: 8),
          if (program.cards.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Belum ada kartu di program ini.',
                style: TextStyle(color: Color(grey2Color)),
              ),
            ),
          for (final card in program.cards) ...[
            _buildCard(card, state.busy),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildProgramHeader(FameManageProgramEntity program) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            program.namaProgram,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        if (program.periodeLabel != null && program.periodeLabel!.isNotEmpty)
          Text(
            program.periodeLabel!,
            style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
          ),
      ],
    );
  }

  /// Kartu kelola memakai tampilan kartu Home. Badge status dan menu aksi ditaruh di header kanan.
  Widget _buildCard(FameAdminCardEntity card, bool busy) {
    final entry = card.entry;
    if (entry == null) return const SizedBox.shrink();
    return FameEntryTile(
      entry: entry,
      showActions: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBadge(card),
          PopupMenuButton<String>(
            enabled: !busy,
            icon: const Icon(Icons.more_vert, color: Color(whiteColor), size: 20),
            onSelected: (v) => _onMenu(v, card),
            itemBuilder: (_) => [
              if (card.status != 'published')
                const PopupMenuItem(
                  value: 'publish',
                  child: Text('Publish" sekarang'),
                ),
              const PopupMenuItem(value: 'edit', child: Text('Ubah')),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Hapus Wall of Fame',
                  style: TextStyle(color: Color(redAccentColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(FameAdminCardEntity card) {
    final (label, color) = switch (card.status) {
      'published' => ('Publish', const Color(successColor)),
      'scheduled' => ('Terjadwal', const Color(primaryColor)),
      _ => ('Draf', const Color(grey2Color)),
    };
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
