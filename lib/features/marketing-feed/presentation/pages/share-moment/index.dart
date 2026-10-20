import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// "Bagikan Kontenmu" — sales kirim foto/video + cerita singkat. Masuk antrean review moderator
/// dulu sebelum tayang. Pop dengan `true` kalau terkirim.
class FeedShareMomentPage extends StatefulWidget {
  const FeedShareMomentPage({super.key});

  @override
  State<FeedShareMomentPage> createState() => _FeedShareMomentPageState();
}

class _FeedShareMomentPageState extends State<FeedShareMomentPage> {
  final _textController = TextEditingController();
  List<FeedMediaEntity> _media = const [];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_share');
    context.read<FeedComposeCubit>().reset();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty && _media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis cerita atau tambahkan foto dulu')),
      );
      return;
    }
    AnalyticsService.logEvent('marketing_feed_share_submit');
    context.read<FeedComposeCubit>().shareMoment(ShareFeedMomentParams(text: text, media: _media));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedComposeCubit, FeedComposeState>(
      listener: (context, state) {
        if (state is FeedComposeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terkirim! Tim Marketing akan meninjau kirimanmu')),
          );
          context.pop(true);
        } else if (state is FeedComposeError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, 'Bagikan Kontenmu', isBack: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const FeedFormLabel('Foto/Video Momen Kamu'),
                      const SizedBox(height: 8),
                      FeedMediaPickerGrid(media: _media, onChanged: (m) => setState(() => _media = m)),
                      const SizedBox(height: 12),
                      const FeedFormLabel('Cerita Singkat'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: feedInputDecoration(
                          hintText: 'Mis. Barusan site visit bareng keluarga Pak Hartono, langsung minta simulasi KPR! 🙌',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FeedNotice(
                        'Kiriman kamu akan ditinjau Tim Marketing dulu sebelum tayang di Marketing Feed '
                        '(biasanya kurang dari 1x24 jam).',
                      ),
                    ],
                  ),
                ),
                FeedFormBottomBar(
                  primaryLabel: 'Kirim untuk Ditinjau',
                  onPrimary: _submit,
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
