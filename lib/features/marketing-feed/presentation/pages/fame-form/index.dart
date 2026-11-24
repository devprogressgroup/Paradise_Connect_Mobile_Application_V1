import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_form/fame_form_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_form/fame_form_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_moderator_form_scaffold.dart';

/// Argumen route form Wall of Fame. [card] null = kartu baru. [programs] = daftar program yang sudah ada.
class FameFormArgs {
  final FameAdminCardEntity? card;
  final int? programId;
  final String? programName;
  final String? periodeLabel;
  final List<FameManageProgramEntity> programs;
  final bool canCreateProgram;

  const FameFormArgs({
    this.card,
    this.programId,
    this.programName,
    this.periodeLabel,
    this.programs = const [],
    this.canCreateProgram = false,
  });
}

/// Form kartu Wall of Fame: program, kategori, caption, poster, waktu tayang, dan daftar juara.
/// Satu kartu = satu kategori dengan satu atau lebih juara (seri = peringkat yang sama).
/// Pop `true` kalau tersimpan.
class FameFormPage extends StatefulWidget {
  final FameFormArgs? args;

  const FameFormPage({super.key, this.args});

  @override
  State<FameFormPage> createState() => _FameFormPageState();
}

/// Satu baris juara di form (sebelum disimpan).
class _WinnerDraft {
  int? userId;
  String name;
  final TextEditingController ranking;
  final TextEditingController posisi;
  final TextEditingController tim;

  _WinnerDraft({
    this.userId,
    this.name = '',
    String ranking = '1',
    String posisi = '',
    String tim = '',
  }) : ranking = TextEditingController(text: ranking),
       posisi = TextEditingController(text: posisi),
       tim = TextEditingController(text: tim);

  void dispose() {
    ranking.dispose();
    posisi.dispose();
    tim.dispose();
  }
}

String? _nullIfEmpty(String s) {
  final t = s.trim();
  return t.isEmpty ? null : t;
}

class _FameFormPageState extends State<FameFormPage> {
  late final FameFormArgs _args = widget.args ?? const FameFormArgs();
  late final TextEditingController _programCtrl;
  late final TextEditingController _periodeCtrl;
  late final TextEditingController _kategoriCtrl;
  late final TextEditingController _captionCtrl;
  final List<_WinnerDraft> _winners = [];
  // Poster baru dari galeri (kosong = tidak mengganti poster).
  List<FeedMediaEntity> _poster = const [];
  // Poster yang sudah tersimpan di kartu, ditampilkan sebagai pratinjau.
  FeedMediaEntity? _existingPoster;
  // Poster tersimpan dihapus dari form: dihapus di server setelah kartu disimpan.
  bool _removedExisting = false;
  DateTime? _scheduledAt;

  /// Satu poster saja (gambar atau video): yang tampil poster baru, atau poster tersimpan kalau belum diganti.
  List<FeedMediaEntity> get _posterShown {
    if (_poster.isNotEmpty) return _poster;
    if (_existingPoster != null && !_removedExisting) return [_existingPoster!];
    return const [];
  }

  void _onPosterChanged(List<FeedMediaEntity> next) {
    setState(() {
      if (next.isEmpty) {
        // Menghapus poster yang tersimpan (bukan poster baru yang baru dipilih).
        if (_poster.isEmpty) _removedExisting = true;
        _poster = const [];
      } else {
        // Poster baru menggantikan poster tersimpan di server saat kartu disimpan.
        _removedExisting = false;
        _poster = next.take(1).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_fame_form');
    final card = _args.card;
    final existingUrl = card?.entry?.mediaUrl;
    if (card != null && card.hasPoster && existingUrl != null) {
      _existingPoster = FeedMediaEntity(
        url: existingUrl,
        isVideo: card.mediaType == 'video',
      );
    }
    _programCtrl = TextEditingController(text: _args.programName ?? '');
    _periodeCtrl = TextEditingController(text: _args.periodeLabel ?? '');
    _kategoriCtrl = TextEditingController(text: card?.kategori ?? '');
    _captionCtrl = TextEditingController(text: card?.caption ?? '');
    _scheduledAt = card?.status == 'scheduled' ? card?.publishAt : null;
    for (final w in card?.winners ?? const <FameAdminWinnerEntity>[]) {
      _winners.add(
        _WinnerDraft(
          userId: w.userId,
          name: w.name,
          ranking: w.rankText,
          posisi: w.posisiLabel ?? '',
          tim: w.timLabel ?? '',
        ),
      );
    }
    if (_winners.isEmpty) _winners.add(_WinnerDraft());
    context.read<FameFormCubit>().loadCandidates();
  }

  @override
  void dispose() {
    _programCtrl.dispose();
    _periodeCtrl.dispose();
    _kategoriCtrl.dispose();
    _captionCtrl.dispose();
    for (final w in _winners) {
      w.dispose();
    }
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  FameManageProgramEntity? _matchProgram(String name) {
    final k = name.trim().toLowerCase();
    for (final p in _args.programs) {
      if (p.namaProgram.trim().toLowerCase() == k) return p;
    }
    return null;
  }

  Future<void> _save(bool asDraft) async {
    final kategori = _kategoriCtrl.text.trim();
    final programName = _programCtrl.text.trim();
    if (programName.isEmpty) return _msg('Isi nama program dulu.');
    if (kategori.isEmpty) return _msg('Isi kategori dulu.');
    // Izin membuat program baru dan izin per juara dicek di backend (superuser selalu boleh),
    // jadi tidak ada pengecekan izin di sisi app yang bisa salah membaca hak akses.
    final matched = _matchProgram(programName);
    if (_winners.isEmpty) return _msg('Tambahkan minimal satu juara.');

    final inputs = <FameWinnerInput>[];
    final seen = <int>{};
    for (final w in _winners) {
      if (w.userId == null) return _msg('Pilih user untuk setiap juara.');
      if (!seen.add(w.userId!)) return _msg('User ${w.name} sudah dipilih.');
      // Angka di depan label jadi peringkat (urutan & seri); label utuh (mis. "1+") yang tampil.
      final label = w.ranking.text.trim();
      final rank = int.tryParse(RegExp(r'^\d+').stringMatch(label) ?? '');
      if (rank == null || rank < 1) {
        return _msg('Peringkat harus diawali angka minimal 1 (mis. 1, 1+, 3).');
      }
      inputs.add(
        FameWinnerInput(
          userId: w.userId!,
          ranking: rank,
          peringkatLabel: label.isEmpty ? null : label,
          posisiLabel: _nullIfEmpty(w.posisi.text),
          timLabel: _nullIfEmpty(w.tim.text),
        ),
      );
    }

    final scheduled = _scheduledAt;
    if (!asDraft && scheduled != null && !scheduled.isAfter(AppTime.now())) {
      return _msg('Pilih waktu tayang yang akan datang.');
    }
    final status = asDraft
        ? 'draft'
        : (scheduled != null ? 'scheduled' : 'published');

    AnalyticsService.logEvent(
      asDraft ? 'marketing_feed_fame_draft' : 'marketing_feed_fame_save',
    );
    final params = FameCardParams(
      programId: matched?.id,
      namaProgram: matched == null ? programName : null,
      periodeLabel: matched == null ? _nullIfEmpty(_periodeCtrl.text) : null,
      kategori: kategori,
      caption: _nullIfEmpty(_captionCtrl.text),
      status: status,
      publishAt: status == 'scheduled' ? scheduled : null,
      winners: inputs,
      poster: _poster.isEmpty ? null : _poster.first,
    );
    final cardId = _args.card?.id;
    final error = await context.read<FameFormCubit>().save(
      params,
      cardId: cardId,
    );
    if (!mounted) return;
    if (error != null) return _msg(error);
    // Poster tersimpan dihapus dari form (tanpa pengganti): hapus juga di server.
    if (_removedExisting && _poster.isEmpty && cardId != null) {
      await context.read<FameManageCubit>().deleteCardPoster(cardId);
      if (!mounted) return;
    }
    context.pop(true);
  }

  void _addWinner() {
    var next = 1;
    for (final w in _winners) {
      final r = int.tryParse(w.ranking.text.trim()) ?? 0;
      if (r + 1 > next) next = r + 1;
    }
    setState(() => _winners.add(_WinnerDraft(ranking: '$next')));
  }

  void _removeWinner(int index) {
    final removed = _winners.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _pickSales(_WinnerDraft draft) async {
    final candidates = context.read<FameFormCubit>().state.candidates;
    final picked = await showModalBottomSheet<FameCandidateEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CandidateSheet(candidates: candidates),
    );
    if (picked == null || !mounted) return;
    if (_winners.any((w) => w != draft && w.userId == picked.userId)) {
      return _msg('User ${picked.name} sudah dipilih.');
    }
    setState(() {
      draft.userId = picked.userId;
      draft.name = picked.name;
      draft.posisi.text = picked.position ?? '';
      draft.tim.text = picked.team ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _args.card;
    final matchedProgram = _matchProgram(_programCtrl.text);
    return FeedModeratorFormScaffold(
      title: card == null ? 'Wall of Fame Baru' : 'Ubah Kartu Wall of Fame',
      primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Tayangkan',
      onSave: (asDraft) => _save(asDraft),
      children: [
        // Tab Buat Konten tetap tampil di halaman ini, dengan Wall of Fame aktif (satu layout dengan Postingan/Polling/Link).
        if (card == null) ...[
          const FeedCreateTabs(current: FeedCreateTab.wallOfFame),
          const SizedBox(height: 16),
        ],
        const FeedFormLabel('Program'),
        const SizedBox(height: 8),
        TextField(
          controller: _programCtrl,
          onChanged: (_) => setState(() {}),
          decoration: feedInputDecoration(
            hintText: 'mis. Top Salebration Oktober 2026',
          ),
        ),
        if (_args.programs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in _args.programs)
                ActionChip(
                  label: Text(
                    p.namaProgram,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => setState(() {
                    _programCtrl.text = p.namaProgram;
                    _periodeCtrl.text = p.periodeLabel ?? '';
                  }),
                ),
            ],
          ),
        ],
        if (matchedProgram == null) ...[
          const SizedBox(height: 12),
          const FeedFormLabel('Periode (untuk program baru)'),
          const SizedBox(height: 8),
          TextField(
            controller: _periodeCtrl,
            decoration: feedInputDecoration(
              hintText: 'mis. Oktober 2026 (bebas)',
            ),
          ),
        ],
        const SizedBox(height: 12),
        const FeedFormLabel('Kategori'),
        const SizedBox(height: 8),
        TextField(
          controller: _kategoriCtrl,
          decoration: feedInputDecoration(hintText: 'mis. TOP SALES EXECUTIVE'),
        ),
        const SizedBox(height: 12),
        const FeedFormLabel('Caption'),
        const SizedBox(height: 8),
        TextField(
          controller: _captionCtrl,
          maxLines: 2,
          maxLength: 255,
          decoration: feedInputDecoration(
            hintText: 'mis. Selamat para juara TOP GM Oktober 2026!',
          ),
        ),
        const SizedBox(height: 12),
        const FeedFormLabel('Poster (opsional)'),
        const SizedBox(height: 8),
        FeedMediaPickerGrid(
          media: _posterShown,
          maxItems: 1,
          onChanged: _onPosterChanged,
        ),
        if (_existingPoster != null && _poster.isEmpty && !_removedExisting)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Poster saat ini tersimpan. Hapus untuk menggantinya dengan file baru.',
              style: TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
          ),
        // Jadwal tayang kartu memakai permission SetSchedule.
        if (PermissionsHelper.canSetScheduleMarketingFeed) ...[
          const SizedBox(height: 12),
          const FeedFormLabel('Waktu Tayang'),
          const SizedBox(height: 8),
          FeedScheduleField(
            scheduledAt: _scheduledAt,
            onChanged: (at) => setState(() => _scheduledAt = at),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: FeedFormLabel('Juara')),
            Text(
              '${_winners.length} juara',
              style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _winners.length; i++) ...[
          _buildWinnerEditor(i),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _addWinner,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Peringkat yang sama dianggap seri. Jabatan dan tim terisi otomatis dari user, tetapi bisa diubah.',
          style: TextStyle(fontSize: 12, color: Color(grey2Color)),
        ),
      ],
    );
  }

  Widget _buildWinnerEditor(int index) {
    final w = _winners[index];
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _pickSales(w),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(blueShade50Color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          w.name.isEmpty
                              ? Icons.person_add_alt_1
                              : Icons.person,
                          size: 18,
                          color: const Color(primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            w.name.isEmpty ? 'Pilih user' : w.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(primaryColor),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus juara',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(redAccentColor),
                ),
                onPressed: _winners.length > 1
                    ? () => _removeWinner(index)
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: w.ranking,
                  keyboardType: TextInputType.text,
                  decoration: feedInputDecoration(
                    hintText: 'Peringkat (mis. 1, 1+, 3)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: w.posisi,
                  decoration: feedInputDecoration(
                    hintText: 'Jabatan (mis. SE)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: w.tim,
            decoration: feedInputDecoration(hintText: 'Tim (mis. Team B)'),
          ),
        ],
      ),
    );
  }
}

/// Lembar pilih sales dengan pencarian nama. Daftar diambil dari [FameFormCubit] (kandidat juara).
class _CandidateSheet extends StatefulWidget {
  final List<FameCandidateEntity> candidates;

  const _CandidateSheet({required this.candidates});

  @override
  State<_CandidateSheet> createState() => _CandidateSheetState();
}

class _CandidateSheetState extends State<_CandidateSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FameFormCubit, FameFormState>(
      builder: (context, state) {
        final source = state.candidates.isNotEmpty
            ? state.candidates
            : widget.candidates;
        final q = _query.trim().toLowerCase();
        final list = source
            .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
            .toList();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: feedInputDecoration(hintText: 'Cari nama user'),
                  ),
                  const SizedBox(height: 8),
                  if (state.loadingCandidates && source.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (list.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'User tidak ditemukan.',
                          style: TextStyle(color: Color(grey2Color)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.name),
                            subtitle: c.info == null || c.info!.isEmpty
                                ? null
                                : Text(c.info!),
                            onTap: () => Navigator.pop(context, c),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
