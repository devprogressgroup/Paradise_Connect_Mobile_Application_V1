import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Moderator: buat/edit poll — gambar opsional, pertanyaan, opsi jawaban, single/multi, interaksi,
/// waktu tayang. [post] diisi = mode edit. Pop dengan `true` kalau tersimpan.
class FeedPollFormPage extends StatefulWidget {
  final FeedPostEntity? post;

  const FeedPollFormPage({super.key, this.post});

  @override
  State<FeedPollFormPage> createState() => _FeedPollFormPageState();
}

class _FeedPollFormPageState extends State<FeedPollFormPage> {
  late final TextEditingController _questionController;
  final _newAnswerController = TextEditingController();
  final _newAnswerFocus = FocusNode();
  late final List<TextEditingController> _answerControllers;
  FeedMediaEntity? _image;
  late bool _multiple;
  late FeedInteractionSettings _settings;
  DateTime? _scheduledAt;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_poll_form');
    context.read<FeedComposeCubit>().reset();
    final post = widget.post;
    final poll = post?.poll;
    _questionController = TextEditingController(text: post?.plainText ?? '');
    _answerControllers = (poll?.options ?? const ['', ''])
        .map((o) => TextEditingController(text: o))
        .toList();
    _image = poll?.image;
    _multiple = poll?.isMultiple ?? true;
    _settings = post?.settings ?? const FeedInteractionSettings(allowDislike: false);
    _scheduledAt = post?.status == FeedPostStatus.scheduled ? post!.publishAt : null;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _newAnswerController.dispose();
    _newAnswerFocus.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addAnswer() {
    final text = _newAnswerController.text.trim();
    if (text.isEmpty) return;
    setState(() => _answerControllers.add(TextEditingController(text: text)));
    _newAnswerController.clear();
    _newAnswerFocus.requestFocus();
  }

  void _removeAnswer(int index) {
    final controller = _answerControllers[index];
    setState(() => _answerControllers.removeAt(index));
    controller.dispose();
  }

  void _save({required bool asDraft}) {
    final question = _questionController.text.trim();
    final answers = [
      ..._answerControllers.map((c) => c.text.trim()),
      _newAnswerController.text.trim(),
    ].where((a) => a.isNotEmpty).toList();
    if (question.isEmpty) {
      _showMessage('Tulis pertanyaan poll');
      return;
    }
    if (answers.length < 2) {
      _showMessage('Isi minimal 2 jawaban');
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
            : 'Poll dipublikasikan';
    AnalyticsService.logEvent(asDraft ? 'marketing_feed_poll_draft' : 'marketing_feed_poll_submit');
    context.read<FeedComposeCubit>().savePost(SaveFeedPostParams(
      postId: widget.post?.id,
      type: FeedPostType.poll,
      // Pertanyaan poll selalu tampil tebal di feed.
      text: '**$question**',
      pollOptions: answers,
      pollMultiple: _multiple,
      pollImage: _image,
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
                customHeader(context, widget.post == null ? 'Poll Baru' : 'Edit Poll', isBack: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const FeedFormLabel('Gambar Pertanyaan (opsional)'),
                      const SizedBox(height: 8),
                      FeedSingleImagePicker(image: _image, onChanged: (m) => setState(() => _image = m)),
                      const SizedBox(height: 12),
                      const FeedFormLabel('Pertanyaan'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _questionController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: feedInputDecoration(hintText: 'Mis. Objection apa yang paling sering kamu temui?'),
                      ),
                      const SizedBox(height: 12),
                      const FeedFormLabel('Jawaban'),
                      const SizedBox(height: 8),
                      ..._buildAnswers(),
                      const SizedBox(height: 6),
                      FeedCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bisa pilih lebih dari satu',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                  ),
                                  Text('Multiple answer poll', style: TextStyle(fontSize: 12, color: Color(grey2Color))),
                                ],
                              ),
                            ),
                            Switch(
                              value: _multiple,
                              onChanged: (v) => setState(() => _multiple = v),
                              activeTrackColor: const Color(primaryColor),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
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
                  primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Publikasikan Poll',
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

  List<Widget> _buildAnswers() {
    return [
      for (var i = 0; i < _answerControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _answerControllers[i],
                  style: const TextStyle(fontSize: 13.5),
                  decoration: feedInputDecoration(hintText: 'Jawaban ${i + 1}'),
                ),
              ),
              IconButton(
                tooltip: 'Hapus jawaban',
                icon: const Icon(Icons.close, color: Color(grey2Color)),
                onPressed: () => _removeAnswer(i),
              ),
            ],
          ),
        ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newAnswerController,
              focusNode: _newAnswerFocus,
              style: const TextStyle(fontSize: 13.5),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addAnswer(),
              decoration: feedInputDecoration(hintText: 'Tambah opsi jawaban...'),
            ),
          ),
          IconButton(
            tooltip: 'Tambah jawaban',
            icon: const Icon(Icons.add, color: Color(primaryColor)),
            onPressed: _addAnswer,
          ),
        ],
      ),
    ];
  }
}
