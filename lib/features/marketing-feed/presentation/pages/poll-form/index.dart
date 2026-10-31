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
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Batas backend: maks 6 opsi, tiap opsi maks 100 karakter, pertanyaan maks 500 karakter.
const _maxOptions = 6;

/// Moderator: buat/edit poll — gambar opsional, pertanyaan, opsi jawaban, single/multi, target township,
/// interaksi, waktu tayang. [post] diisi = edit draft/terjadwal. Pop `true` kalau tersimpan.
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
  int? _townshipId;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_poll_form');
    final post = widget.post;
    final poll = post?.poll;
    _questionController = TextEditingController(text: post?.plainText ?? '');
    _answerControllers = (poll?.options.map((o) => o.label) ?? const ['', ''])
        .map((label) => TextEditingController(text: label))
        .toList();
    // Gambar pertanyaan dikirim API di media[] post (lihat FeedPollBox).
    _image = (post?.media.isNotEmpty ?? false) ? post!.media.first : null;
    _multiple = poll?.isMultiple ?? true;
    _settings = post?.settings ?? const FeedInteractionSettings(allowDislike: false);
    _townshipId = post?.township?.id;
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
    if (text.isEmpty || _answerControllers.length >= _maxOptions) return;
    setState(() => _answerControllers.add(TextEditingController(text: text)));
    _newAnswerController.clear();
    _newAnswerFocus.requestFocus();
  }

  void _removeAnswer(int index) {
    final controller = _answerControllers[index];
    setState(() => _answerControllers.removeAt(index));
    controller.dispose();
  }

  void _save(bool asDraft) {
    final question = _questionController.text.trim();
    final answers = [
      ..._answerControllers.map((c) => c.text.trim()),
      _newAnswerController.text.trim(),
    ].where((a) => a.isNotEmpty).toList();
    if (question.isEmpty) return _showMessage('Tulis pertanyaan poll.');
    if (answers.length < 2) return _showMessage('Isi minimal 2 jawaban.');
    if (answers.length > _maxOptions) return _showMessage('Maksimal $_maxOptions jawaban.');
    final image = _image;
    final media = [if (image != null) image];
    final mediaError = validateFeedMediaFiles(media);
    if (mediaError != null) return _showMessage(mediaError);
    final scheduledAt = _scheduledAt;
    if (!asDraft && scheduledAt != null && !scheduledAt.isAfter(AppTime.now())) {
      return _showMessage('Pilih waktu tayang yang akan datang.');
    }
    AnalyticsService.logEvent(asDraft ? 'marketing_feed_poll_draft' : 'marketing_feed_poll_submit');
    context.read<FeedComposeCubit>().savePost(SaveFeedPostParams(
      postId: widget.post?.id,
      type: FeedPostType.poll,
      text: question,
      media: media,
      pollOptions: answers,
      pollMultiple: _multiple,
      townshipId: _townshipId,
      settings: _settings,
      scheduledAt: scheduledAt,
      asDraft: asDraft,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FeedModeratorFormScaffold(
      title: widget.post == null ? 'Poll Baru' : 'Edit Poll',
      primaryLabel: _scheduledAt != null ? 'Jadwalkan' : 'Publikasikan Poll',
      onSave: _save,
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
          maxLength: 500,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
                    Text('Bisa pilih lebih dari satu', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
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
                  maxLength: 100,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
      if (_answerControllers.length < _maxOptions)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newAnswerController,
                focusNode: _newAnswerFocus,
                maxLength: 100,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
