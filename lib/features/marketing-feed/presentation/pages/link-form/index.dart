import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/calendar/calendar_route_args.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_moderator_form_scaffold.dart';

/// Moderator: buat/edit link YouTube / website — platform, URL, channel/situs, judul, deskripsi,
/// thumbnail opsional (link YouTube tanpa thumbnail memakai thumbnail YouTube dari backend), target
/// township, interaksi, waktu tayang. [post] diisi = edit draft/terjadwal. Pop `true` kalau tersimpan.
class FeedLinkFormPage extends StatefulWidget {
  final FeedPostEntity? post;

  /// Tanggal tayang awal dari Kalender Jadwal (null = tidak dari kalender).
  final DateTime? initialScheduledAt;

  /// Dibuka dari Kalender Jadwal (dipakai untuk membawa tanggal saat pindah tab Buat Konten).
  final bool fromCalendar;

  const FeedLinkFormPage({
    super.key,
    this.post,
    this.initialScheduledAt,
    this.fromCalendar = false,
  });

  @override
  State<FeedLinkFormPage> createState() => _FeedLinkFormPageState();
}

/// Platform dari URL (sama dengan backend MarketingFeedService::detectPlatform). Tidak dipilih manual.
String detectLinkPlatform(String url) {
  final u = url.toLowerCase();
  if (RegExp(r'(^|[/.])(youtube\.com|youtu\.be)(/|$)').hasMatch(u))
    return 'youtube';
  if (RegExp(r'(^|[/.])instagram\.com(/|$)').hasMatch(u)) return 'instagram';
  if (RegExp(r'(^|[/.])(facebook\.com|fb\.watch|fb\.me)(/|$)').hasMatch(u))
    return 'facebook';
  if (RegExp(r'(^|[/.])tiktok\.com(/|$)').hasMatch(u)) return 'tiktok';
  return 'web';
}

String linkPlatformLabel(String platform) => switch (platform) {
  'youtube' => 'YouTube',
  'instagram' => 'Instagram',
  'facebook' => 'Facebook',
  'tiktok' => 'TikTok',
  _ => 'Website / Artikel',
};

class _FeedLinkFormPageState extends State<FeedLinkFormPage> {
  late final TextEditingController _urlController;
  late final TextEditingController _channelController;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _platform;
  FeedMediaEntity? _thumbnail;
  late FeedInteractionSettings _settings;
  int? _townshipId;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_link_form');
    final post = widget.post;
    final link = post?.link;
    _urlController = TextEditingController(text: link?.url ?? '');
    _platform = detectLinkPlatform(_urlController.text);
    _urlController.addListener(_onUrlChanged);
    _channelController = TextEditingController(text: link?.channel ?? '');
    _titleController = TextEditingController(text: link?.title ?? '');
    _descController = TextEditingController(text: link?.description ?? '');
    // Hanya thumbnail hasil upload (punya id). Thumbnail YouTube otomatis dari backend (id null) diabaikan.
    final uploaded = post?.media.where((m) => m.id != null);
    _thumbnail = (uploaded?.isNotEmpty ?? false) ? uploaded!.first : null;
    // Default prototype: link tanpa dislike & komentar.
    _settings =
        post?.settings ??
        const FeedInteractionSettings(
          allowDislike: false,
          allowComment: false,
          allowReply: false,
        );
    _townshipId = post?.township?.id;
    _scheduledAt = post?.status == FeedPostStatus.scheduled
        ? post!.publishAt
        : widget.initialScheduledAt;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _channelController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _save(bool asDraft) {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    // Draft boleh belum lengkap; yang tayang/terjadwal wajib URL valid + judul (dicek ulang di backend).
    if (!asDraft) {
      if (url.isEmpty || title.isEmpty)
        return _showMessage('Isi URL dan judul link dulu.');
      if (!_isValidUrl(url))
        return _showMessage(
          'URL link tidak valid (harus diawali http:// atau https://).',
        );
    } else if (url.isEmpty && title.isEmpty) {
      return _showMessage('Isi URL atau judul link dulu.');
    }
    final thumbnail = _thumbnail;
    final media = [if (thumbnail != null) thumbnail];
    final mediaError = validateFeedMediaFiles(media);
    if (mediaError != null) return _showMessage(mediaError);
    final scheduledAt = _scheduledAt;
    if (!asDraft &&
        scheduledAt != null &&
        !scheduledAt.isAfter(AppTime.now())) {
      return _showMessage('Pilih waktu tayang yang akan datang.');
    }
    AnalyticsService.logEvent(
      asDraft ? 'marketing_feed_link_draft' : 'marketing_feed_link_submit',
    );
    context.read<FeedComposeCubit>().savePost(
      SaveFeedPostParams(
        postId: widget.post?.id,
        type: FeedPostType.link,
        media: media,
        linkPlatform: _platform,
        linkUrl: url,
        linkChannel: _channelController.text.trim(),
        linkTitle: title,
        linkDescription: _descController.text.trim(),
        townshipId: _townshipId,
        settings: _settings,
        scheduledAt: scheduledAt,
        asDraft: asDraft,
      ),
    );
  }


  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedFormLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          keyboardType: keyboardType,
          autocorrect: keyboardType != TextInputType.url,
          style: const TextStyle(fontSize: 13.5),
          onChanged: (_) => setState(() {}),
          decoration: feedInputDecoration(hintText: hint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Platform mengikuti URL yang diketik.
  void _onUrlChanged() {
    final p = detectLinkPlatform(_urlController.text);
    if (p != _platform) setState(() => _platform = p);
  }

  /// Query tab Buat Konten: dari kalender, tanggal yang sedang dipilih ikut dibawa ke tab Postingan / Polling.
  Map<String, String> _calendarQuery() {
    if (!widget.fromCalendar) return const {};
    final at = _scheduledAt;
    return at == null
        ? {FeedCalendarRouteArgs.sourceKey: FeedCalendarRouteArgs.sourceCalendar}
        : FeedCalendarRouteArgs.forSchedule(at);
  }

  @override
  Widget build(BuildContext context) {
    final youtube = _platform == 'youtube';
    return FeedModeratorFormScaffold(
      title: widget.post == null ? 'Link Baru' : 'Edit Link',
      primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Publikasikan',
      onSave: _save,
      children: [
        if (widget.post == null) ...[
          FeedCreateTabs(
            current: FeedCreateTab.link,
            query: _calendarQuery(),
          ),
          const SizedBox(height: 16),
        ],
        const FeedFormLabel('Platform'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(grey10Color),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${linkPlatformLabel(_platform)} (otomatis dari URL)',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _field(
          'URL',
          _urlController,
          hint: youtube ? 'https://youtube.com/watch?v=…' : 'https://…',
          maxLength: 1000,
          keyboardType: TextInputType.url,
        ),
        _field(
          'Nama channel / situs',
          _channelController,
          hint: youtube
              ? 'Mis. Progress Group Official'
              : 'Mis. paradise.co.id',
          maxLength: 150,
        ),
        _field(
          'Judul',
          _titleController,
          hint: 'Judul yang tampil di kartu feed',
          maxLength: 200,
        ),
        _field(
          'Deskripsi singkat',
          _descController,
          hint: 'Opsional',
          maxLines: 2,
          maxLength: 500,
        ),
        FeedFormLabel(
          youtube
              ? 'Thumbnail (opsional, default thumbnail YouTube)'
              : 'Thumbnail (opsional)',
        ),
        const SizedBox(height: 8),
        FeedSingleImagePicker(
          image: _thumbnail,
          uploadLabel: 'Upload thumbnail',
          onChanged: (m) => setState(() => _thumbnail = m),
        ),
        const SizedBox(height: 12),
        const FeedFormLabel('Target Township'),
        const SizedBox(height: 8),
        FeedTownshipField(
          townshipId: _townshipId,
          onChanged: (id) => setState(() => _townshipId = id),
        ),
        const SizedBox(height: 12),
        const FeedFormLabel('Pengaturan Interaksi'),
        const SizedBox(height: 8),
        FeedInteractionSettingsCard(
          settings: _settings,
          onChanged: (s) => setState(() => _settings = s),
        ),
        const SizedBox(height: 12),
        const FeedFormLabel('Waktu Tayang'),
        const SizedBox(height: 8),
        FeedScheduleField(
          scheduledAt: _scheduledAt,
          onChanged: (at) => setState(() => _scheduledAt = at),
        ),
      ],
    );
  }
}
