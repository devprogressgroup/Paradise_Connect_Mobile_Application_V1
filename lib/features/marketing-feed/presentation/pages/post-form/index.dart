import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';

/// Moderator: buat/edit post (media + caption), atur interaksi, tayang sekarang/jadwalkan, atau
/// simpan draft. [post] diisi = mode edit. Pop dengan `true` kalau tersimpan.
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
  DateTime? _scheduledAt;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_post_form');
    context.read<FeedComposeCubit>().reset();
    final post = widget.post;
    _textController = TextEditingController(text: post?.text ?? '');
    _media = post?.media ?? const [];
    _settings = post?.settings ?? const FeedInteractionSettings();
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

  void _save({required bool asDraft}) {
    final text = _textController.text.trim();
    if (text.isEmpty && _media.isEmpty) {
      _showMessage('Isi caption atau tambahkan media');
      return;
    }
    final scheduledAt = _scheduledAt;
    if (!asDraft && scheduledAt != null && !scheduledAt.isAfter(AppTime.now())) {
      _showMessage('Pilih waktu tayang yang akan datang');
      return;
    }
    _successMessage = asDraft
        ? 'Disimpan sebagai draft'
        : scheduledAt != null
            ? 'Dijadwalkan tayang ${DateHelper.relativeDayTime(scheduledAt)}'
            : 'Post dipublikasikan';
    AnalyticsService.logEvent(asDraft ? 'marketing_feed_post_draft' : 'marketing_feed_post_submit');
    context.read<FeedComposeCubit>().savePost(SaveFeedPostParams(
      postId: widget.post?.id,
      type: FeedPostType.post,
      text: text,
      media: _media,
      settings: _settings,
      scheduledAt: scheduledAt,
      asDraft: asDraft,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedComposeCubit, FeedComposeState>(
      listener: (context, state) {
        if (state is FeedComposeSuccess) {
          _showMessage(_successMessage);
          context.pop(true);
        } else if (state is FeedComposeError) {
          _showMessage(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, widget.post == null ? 'Post Baru' : 'Edit Post', isBack: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FeedMediaPickerGrid(media: _media, onChanged: (m) => setState(() => _media = m)),
                      const SizedBox(height: 12),
                      const FeedFormLabel('Caption'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: feedInputDecoration(hintText: 'Tulis caption… (apit dengan ** untuk teks tebal)'),
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
                  ),
                ),
                FeedFormBottomBar(
                  primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Publikasikan',
                  onPrimary: () => _save(asDraft: false),
                  onSaveDraft: () => _save(asDraft: true),
                  isLoading: state is FeedComposeSubmitting,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
