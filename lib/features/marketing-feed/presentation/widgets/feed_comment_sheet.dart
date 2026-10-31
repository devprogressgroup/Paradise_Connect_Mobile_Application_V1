import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_comments/feed_comments_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_comments/feed_comments_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Buka sheet komentar sebuah post. Future selesai saat sheet ditutup.
Future<void> showFeedCommentSheet(BuildContext context, FeedPostEntity post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FeedCommentSheet(post: post),
  );
}

class FeedCommentSheet extends StatefulWidget {
  final FeedPostEntity post;

  const FeedCommentSheet({super.key, required this.post});

  @override
  State<FeedCommentSheet> createState() => _FeedCommentSheetState();
}

class _FeedCommentSheetState extends State<FeedCommentSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scrollController = ScrollController();
  FeedCommentEntity? _replyTo;

  bool get _allowReply => widget.post.settings.allowReply;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<FeedCommentsCubit>().load(widget.post.id);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedCommentsCubit>().loadMore();
    }
  }

  Future<void> _toggleLike(int commentId) async {
    final error = await context.read<FeedCommentsCubit>().toggleLike(commentId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final parentId = _replyTo?.id;
    final error = await context.read<FeedCommentsCubit>().send(text, parentId: parentId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _controller.clear();
    setState(() => _replyTo = null);
    if (parentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _startReply(FeedCommentEntity comment) {
    setState(() => _replyTo = comment);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BlocBuilder<FeedCommentsCubit, FeedCommentsState>(
          builder: (context, state) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(greyShade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.status == FeedCommentsStatus.loaded
                              // Balasan halaman berikutnya belum termuat, jadi pakai angka dari post.
                              ? 'Komentar (${state.hasMore ? widget.post.commentCount : state.totalCount})'
                              : 'Komentar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(grey10Color)),
                if (!_allowReply)
                  Container(
                    width: double.infinity,
                    color: const Color(roNoticeInfoBgColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Color(roNoticeInfoTextColor)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Balasan komentar dinonaktifkan moderator untuk post ini.',
                            style: TextStyle(fontSize: 12, color: Color(roNoticeInfoTextColor)),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildList(state)),
                if (_replyTo != null) _buildReplyingBar(),
                if (widget.post.settings.allowComment)
                  _buildInput(state)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(grey11Color),
                    alignment: Alignment.center,
                    child: const Text(
                      'Komentar dinonaktifkan untuk post ini.',
                      style: TextStyle(fontSize: 12, color: Color(grey2Color)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(FeedCommentsState state) {
    if (state.status == FeedCommentsStatus.loading || state.status == FeedCommentsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == FeedCommentsStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? 'Gagal memuat komentar.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
            ),
            TextButton(
              onPressed: () => context.read<FeedCommentsCubit>().load(widget.post.id),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (state.comments.isEmpty) {
      return const SingleChildScrollView(
        child: FeedEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Belum ada komentar',
          message: 'Jadi yang pertama memberi semangat!',
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: state.comments.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        if (i >= state.comments.length) {
          return const Center(
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _buildComment(state.comments[i], isReply: false);
      },
    );
  }

  Widget _buildComment(FeedCommentEntity comment, {required bool isReply}) {
    final author = comment.author;
    return Padding(
      padding: EdgeInsets.only(top: isReply ? 10 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAvatar(
            name: author.name,
            initials: author.initials,
            photoUrl: author.photoUrl,
            isModerator: author.isModerator,
            size: 30,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(author.isModerator ? blueShade50Color : grey11Color),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              author.name,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (author.isOfficial) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(primaryColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Resmi',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(whiteColor)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(comment.text, style: const TextStyle(fontSize: 13, height: 1.45)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      Text(DateHelper.timeAgo(comment.createdAt), style: _metaStyle),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _toggleLike(comment.id),
                        child: Text(
                          '${comment.isLiked ? 'Disukai' : 'Suka'}${comment.likeCount > 0 ? ' · ${comment.likeCount}' : ''}',
                          style: _metaStyle.copyWith(
                            fontWeight: FontWeight.w800,
                            color: comment.isLiked ? const Color(redAccentColor) : null,
                          ),
                        ),
                      ),
                      if (_allowReply && !isReply) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _startReply(comment),
                          child: Text('Balas', style: _metaStyle.copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isReply && comment.replies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(grey10Color), width: 2)),
                    ),
                    child: Column(
                      children: [for (final r in comment.replies) _buildComment(r, isReply: true)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _metaStyle = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(grey2Color));

  Widget _buildReplyingBar() {
    return Container(
      color: const Color(grey11Color),
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
                children: [
                  const TextSpan(text: 'Membalas '),
                  TextSpan(text: _replyTo!.author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(FeedCommentsState state) {
    final profile = context.read<ProfileBloc>().state;
    final myName = profile is ProfileLoaded ? profile.profile.fullName : 'Kamu';
    final myPhoto = profile is ProfileLoaded ? profile.profile.photoUrl : null;
    final firstName = myName.trim().split(RegExp(r'\s+')).first;
    final loaded = state.status == FeedCommentsStatus.loaded || state.status == FeedCommentsStatus.loadingMore;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(grey10Color)))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            FeedAvatar(name: myName, photoUrl: myPhoto, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: loaded,
                maxLength: 1000,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _replyTo != null ? 'Balas ${_replyTo!.author.name}…' : 'Tulis komentar sebagai $firstName…',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(grey4Color)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(99),
                    borderSide: const BorderSide(color: Color(greyShade300)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(99),
                    borderSide: const BorderSide(color: Color(greyShade300)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(99),
                    borderSide: const BorderSide(color: Color(primaryColor)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              height: 38,
              child: Material(
                color: const Color(primaryColor),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: loaded && !state.isSending ? _send : null,
                  child: state.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor)),
                        )
                      : const Icon(Icons.send, size: 18, color: Color(whiteColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
