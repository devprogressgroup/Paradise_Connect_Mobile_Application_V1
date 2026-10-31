import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_moderator_form_scaffold.dart';

const _maxMedia = 10;
const _maxCaption = 2000;

/// Moderator: buat/edit post (foto/video carousel + caption), target township, interaksi, tayang
/// sekarang/jadwalkan, atau simpan draft. [post] diisi = edit draft/terjadwal. Pop `true` kalau tersimpan.
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
    context.read<FeedComposeCubit>().savePost(SaveFeedPostParams(
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
    return FeedModeratorFormScaffold(
      title: widget.post == null ? 'Post Baru' : 'Edit Post',
      primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Publikasikan',
      onSave: _save,
      children: [
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
        const SizedBox(height: 12),
        const FeedFormLabel('Target Township'),
        const SizedBox(height: 8),
        FeedTownshipField(townshipId: _townshipId, onChanged: (id) => setState(() => _townshipId = id)),
        const SizedBox(height: 12),
        const FeedFormLabel('Pengaturan Interaksi'),
        const SizedBox(height: 8),
        FeedInteractionSettingsCard(settings: _settings, onChanged: (s) => setState(() => _settings = s)),
        const SizedBox(height: 12),
        const FeedFormLabel('Waktu Tayang'),
        const SizedBox(height: 8),
        FeedScheduleField(scheduledAt: _scheduledAt, onChanged: (at) => setState(() => _scheduledAt = at)),
      ],
    );
  }
}
