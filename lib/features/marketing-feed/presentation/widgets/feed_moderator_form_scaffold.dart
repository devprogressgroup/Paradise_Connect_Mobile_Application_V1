import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_compose/feed_compose_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_compose_fields.dart';

/// Kerangka form moderator (Post / Poll / Link): header, isi form, progress upload, lalu tombol
/// "Simpan Draft" + tombol utama. Hasil simpan lewat [FeedComposeCubit]; sukses → snackbar sesuai status
/// hasil (tayang / terjadwal / draft) lalu pop `true`. Gagal upload MinIO → dialog dengan "Coba Lagi".
class FeedModeratorFormScaffold extends StatefulWidget {
  final String title;
  final String primaryLabel;
  final List<Widget> children;

  /// Validasi lalu panggil [FeedComposeCubit.savePost]. [asDraft] = tombol "Simpan Draft".
  final void Function(bool asDraft) onSave;

  const FeedModeratorFormScaffold({
    super.key,
    required this.title,
    required this.primaryLabel,
    required this.children,
    required this.onSave,
  });

  @override
  State<FeedModeratorFormScaffold> createState() => _FeedModeratorFormScaffoldState();
}

class _FeedModeratorFormScaffoldState extends State<FeedModeratorFormScaffold> {
  bool _lastAsDraft = false;

  @override
  void initState() {
    super.initState();
    context.read<FeedComposeCubit>().reset();
  }

  void _save(bool asDraft) {
    _lastAsDraft = asDraft;
    widget.onSave(asDraft);
  }

  String _successMessage(FeedPostEntity post) {
    final label = switch (post.type) {
      FeedPostType.post => 'Post',
      FeedPostType.poll => 'Poll',
      FeedPostType.link => 'Link',
    };
    return switch (post.status) {
      FeedPostStatus.published => '$label dipublikasikan, notifikasi dikirim ke sales',
      FeedPostStatus.scheduled => 'Dijadwalkan tayang ${DateHelper.relativeDayTime(post.publishAt)}',
      _ => 'Disimpan sebagai draft',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedComposeCubit, FeedComposeState>(
      listener: (context, state) {
        if (state is FeedComposeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_successMessage(state.post))));
          context.pop(true);
        } else if (state is FeedComposeError) {
          if (state.isStorageError) {
            showFeedStorageErrorDialog(
              context,
              message: state.message,
              raptor: state.raptor,
              hint: state.hint,
              onRetry: () => _save(_lastAsDraft),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        }
      },
      builder: (context, state) {
        final submitting = state is FeedComposeSubmitting;
        final progress = state is FeedComposeSubmitting ? state.progress : null;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, widget.title, isBack: true),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: submitting,
                    child: ListView(padding: const EdgeInsets.all(16), children: widget.children),
                  ),
                ),
                if (progress != null) FeedUploadProgressBar(progress: progress),
                FeedFormBottomBar(
                  primaryLabel: widget.primaryLabel,
                  onPrimary: () => _save(false),
                  onSaveDraft: () => _save(true),
                  isLoading: submitting,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
