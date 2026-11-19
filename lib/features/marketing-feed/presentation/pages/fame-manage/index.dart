import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/fame-form/index.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Kelola Wall of Fame (admin mobile). Hak akses dari backend (t_feed_fame_perm): tanpa can_edit,
/// halaman hanya menampilkan keterangan. Dengan izin: daftar kartu per program, aksi per kartu,
/// dan tombol + untuk kartu baru.
class FameManagePage extends StatefulWidget {
  /// [embedded] = dipakai sebagai tab di dalam halaman lain (Kiriman Saya): tanpa header dan Scaffold.
  const FameManagePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FameManagePage> createState() => _FameManagePageState();
}

class _FameManagePageState extends State<FameManagePage> {
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

  Future<void> _pickPoster(int cardId) async {
    final x = await ImagePicker().pickMedia(imageQuality: 80);
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    final media = FeedMediaEntity(
      bytes: bytes,
      fileName: x.name,
      filePath: x.path,
      isVideo: (x.mimeType ?? '').startsWith('video/'),
    );
    AnalyticsService.logEvent('marketing_feed_fame_poster_upload');
    await _runAction(
      context.read<FameManageCubit>().uploadCardPoster(cardId, media),
      'Poster diunggah',
    );
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
      case 'draft':
        await _runAction(
          cubit.setStatus(card.id, 'draft'),
          'Dikembalikan ke draf',
        );
      case 'edit':
        await _openForm(card: card);
      case 'poster':
        await _pickPoster(card.id);
      case 'poster_delete':
        await _runAction(cubit.deleteCardPoster(card.id), 'Poster dihapus');
      case 'delete':
        final ok = await _confirm(
          'Hapus kartu ini?',
          'Juara dan poster di kartu ini ikut dihapus.',
        );
        if (!ok) return;
        AnalyticsService.logEvent('marketing_feed_fame_delete');
        await _runAction(cubit.deleteCard(card.id), 'Kartu dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FameManageCubit>().state;
    final canEdit = state.access?.canEdit ?? false;
    if (widget.embedded) {
      return Column(
        children: [
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ),
            ),
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

  Widget _buildCard(FameAdminCardEntity card, bool busy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey10Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.kategori.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(primaryColor),
                  ),
                ),
              ),
              _statusBadge(card),
              PopupMenuButton<String>(
                enabled: !busy,
                onSelected: (v) => _onMenu(v, card),
                itemBuilder: (_) => [
                  if (card.status != 'published')
                    const PopupMenuItem(
                      value: 'publish',
                      child: Text('Tayangkan sekarang'),
                    ),
                  if (card.status != 'draft')
                    const PopupMenuItem(value: 'draft', child: Text('Ke draf')),
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(
                    value: 'poster',
                    child: Text(
                      card.hasPoster ? 'Ganti poster' : 'Unggah poster',
                    ),
                  ),
                  if (card.hasPoster)
                    const PopupMenuItem(
                      value: 'poster_delete',
                      child: Text('Hapus poster'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus kartu',
                      style: TextStyle(color: Color(redAccentColor)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (card.caption != null && card.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                card.caption!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(grey1Color),
                ),
              ),
            ),
          const SizedBox(height: 4),
          for (final w in card.winners) _buildWinnerRow(w),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                card.hasPoster
                    ? Icons.image_outlined
                    : Icons.hide_image_outlined,
                size: 14,
                color: const Color(grey2Color),
              ),
              const SizedBox(width: 4),
              Text(
                card.hasPoster ? 'Poster ada' : 'Tanpa poster',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(grey2Color),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: busy ? null : () => _openForm(card: card),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Ubah'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerRow(FameAdminWinnerEntity w) {
    final sub = [
      w.posisiLabel,
      w.timLabel,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final top = w.ranking == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: top
                  ? const Color(orangeAccentColor)
                  : const Color(grey10Color),
            ),
            child: Text(
              w.rankText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: top ? const Color(whiteColor) : const Color(grey1Color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11.5,
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

  Widget _statusBadge(FameAdminCardEntity card) {
    final (label, color) = switch (card.status) {
      'published' => ('Tayang', const Color(successColor)),
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
