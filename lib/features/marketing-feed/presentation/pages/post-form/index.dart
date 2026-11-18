import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_create_tabs.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_moderator_form_scaffold.dart';

const _maxMedia = 10;
const _maxCaption = 2000;

/// Postingan: foto/video + caption + pengaturan interaksi (permission CreatePost).
/// Target township hanya tampil dengan permission SetTownship, waktu tayang hanya dengan SetSchedule.
/// Kiriman baru dikirim lewat /submit: permission SkipReview dicentang = langsung tayang, tidak = menunggu approval.
/// Edit draft/terjadwal (post != null) tetap lewat jalur moderator. Pop `true` kalau tersimpan.
class FeedPostFormPage extends StatefulWidget {
  final FeedPostEntity? post;

  const FeedPostFormPage({super.key, this.post});

  @override
  State<FeedPostFormPage> createState() => _FeedPostFormPageState();
}

class _FeedPostFormPageState extends State<FeedPostFormPage> {
  late final TextEditingController _textController;
  late List<FeedMediaEntity> _media;
  late FeedInteractionSettings _settings;
  int? _townshipId;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_post_form');
    final post = widget.post;
    _textController = TextEditingController(text: post?.text ?? '');
    _media = post?.media ?? const [];
    _settings = post?.settings ?? const FeedInteractionSettings();
    _townshipId = post?.township?.id;
    _scheduledAt = post?.status == FeedPostStatus.scheduled ? post!.publishAt : null;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save(bool asDraft) {
    final text = _textController.text.trim();
    if (text.isEmpty && _media.isEmpty) return _showMessage('Isi caption atau tambahkan media dulu.');
    final mediaError = validateFeedMediaFiles(_media);
    if (mediaError != null) return _showMessage(mediaError);
    final scheduledAt = _scheduledAt;
    if (!asDraft && scheduledAt != null && !scheduledAt.isAfter(AppTime.now())) {
      return _showMessage('Pilih waktu tayang yang akan datang.');
    }
    AnalyticsService.logEvent(asDraft ? 'marketing_feed_post_draft' : 'marketing_feed_post_submit');

    final cubit = context.read<FeedComposeCubit>();
    if (widget.post == null) {
      // Kiriman baru: jalur sales. Township dan jadwal hanya dikirim kalau user punya permission-nya.
      cubit.shareMoment(ShareFeedMomentParams(
        text: text,
        media: _media,
        townshipId: PermissionsHelper.canSetTownshipMarketingFeed ? _townshipId : null,
        settings: _settings,
        scheduledAt: !asDraft && PermissionsHelper.canSetScheduleMarketingFeed ? scheduledAt : null,
        asDraft: asDraft,
      ));
      return;
    }

    cubit.savePost(SaveFeedPostParams(
      postId: widget.post?.id,
      type: FeedPostType.post,
      text: text,
      media: _media,
      townshipId: _townshipId,
      settings: _settings,
      scheduledAt: scheduledAt,
      asDraft: asDraft,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.post == null;
    final canSetTownship = !isNew || PermissionsHelper.canSetTownshipMarketingFeed;
    final canSetSchedule = !isNew || PermissionsHelper.canSetScheduleMarketingFeed;

    final primaryLabel = isNew && !PermissionsHelper.canSkipReviewMarketingFeed
        ? 'Kirim untuk Ditinjau'
        : _scheduledAt != null
            ? 'Jadwalkan'
            : 'Publikasikan';

    return FeedModeratorFormScaffold(
      title: isNew ? 'Post Baru' : 'Edit Post',
      primaryLabel: primaryLabel,
      onSave: _save,
      children: [
        if (isNew && FeedCreateTabs.showRow) ...[
          const FeedCreateTabs(current: FeedCreateTab.postingan),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const FeedFormLabel('Foto/Video'),
            Text('${_media.length}/$_maxMedia file', style: const TextStyle(fontSize: 11, color: Color(grey2Color))),
          ],
        ),
        const SizedBox(height: 8),
        FeedMediaPickerGrid(media: _media, maxItems: _maxMedia, onChanged: (m) => setState(() => _media = m)),
        const SizedBox(height: 12),
        const FeedFormLabel('Caption'),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 3,
          maxLength: _maxCaption,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: const TextStyle(fontSize: 13.5),
          decoration: feedInputDecoration(hintText: 'Tulis caption… (apit dengan ** untuk teks tebal)'),
        ),
        if (canSetTownship) ...[
          const SizedBox(height: 12),
          const FeedFormLabel('Target Township'),
          const SizedBox(height: 8),
          FeedTownshipField(townshipId: _townshipId, onChanged: (id) => setState(() => _townshipId = id)),
        ],
        const SizedBox(height: 12),
        const FeedFormLabel('Pengaturan Interaksi'),
        const SizedBox(height: 8),
        FeedInteractionSettingsCard(settings: _settings, onChanged: (s) => setState(() => _settings = s)),
        if (canSetSchedule) ...[
          const SizedBox(height: 12),
          const FeedFormLabel('Waktu Tayang'),
          const SizedBox(height: 8),
          FeedScheduleField(scheduledAt: _scheduledAt, onChanged: (at) => setState(() => _scheduledAt = at)),
        ],
      ],
    );
  }
}
