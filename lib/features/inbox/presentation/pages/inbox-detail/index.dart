import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/domain/entities/chat_message_entity.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_event.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_state.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/utils/widget/error_dialog.dart';

class InboxDetailPage extends StatefulWidget {
  final InboxDetailArgs args;
  const InboxDetailPage({super.key, required this.args});

  @override
  State<InboxDetailPage> createState() => _InboxDetailPageState();
}

class _InboxDetailPageState extends State<InboxDetailPage> {
  late ScrollController _scrollController;
  int _page = 1;
  bool _isFetchingMore = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchMessages();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isFetchingMore) _loadMore();
  }

  void _fetchMessages({int page = 1, bool isLoadMore = false}) {
    context.read<MessageBloc>().add(GetChatHistoryEvent(sessionId: widget.args.data.sessionCode, jid: widget.args.data.jid, page: page, isLoadMore: isLoadMore));
  }

  Future<void> _loadMore() async {
    _isFetchingMore = true;
    _page++;
    _fetchMessages(page: _page, isLoadMore: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateHeader(int timestamp) {
    if (timestamp == 0) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final msgDate = DateTime(date.year, date.month, date.day);
    if (msgDate == today) return "Hari ini";
    if (msgDate == yesterday) return "Kemarin";
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  bool _shouldShowDate(int index, List messages) {
    if (index == 0) return true;
    final curr = DateTime.fromMillisecondsSinceEpoch(messages[index].timestamp * 1000);
    final prev = DateTime.fromMillisecondsSinceEpoch(messages[index - 1].timestamp * 1000);
    return curr.day != prev.day || curr.month != prev.month || curr.year != prev.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(color: Color(whiteColor), borderRadius: BorderRadius.circular(24)),
                child: BlocConsumer<MessageBloc, MessageState>(
                  listenWhen: (prev, curr) => curr is MessageError && prev is! MessageError,
                  listener: (context, state) {
                    if (state is MessageError) {
                      _isFetchingMore = false;
                      showErrorDialog(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is MessageLoading) return buildMessageShimmer();

                    if (state is MessageLoaded) {
                      _isFetchingMore = state.isFetchingMore;

                      /// 🔥 WA STYLE (NEWEST DI BAWAH)
                      final messages = state.chatHistory.messages.reversed.toList();

                      /// 🔥 AUTO SCROLL KE PALING BAWAH SAAT PERTAMA
                      if (_isFirstLoad) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                          }
                        });
                        _isFirstLoad = false;
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length + (state.isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {

                          /// 🔥 LOADING PESAN LAMA (DI ATAS)
                          if (state.isFetchingMore && index == messages.length) {
                            return const ShimmerMessageItem();
                          }

                          final msg = messages[index];
                          final isMe = msg.isFromMe;
                          final sender = isMe ? "Saya" : (msg.senderName ?? widget.args.data.name);

                          return Column(
                            children: [
                              if (_shouldShowDate(index, messages))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Color(grey10Color).withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                                    child: Text(_formatDateHeader(msg.timestamp), style: TextStyle(fontSize: 12, color: Color(grey2Color))),
                                  ),
                                ),

                              isMe ? _right(msg, sender) : _left(msg, sender),
                            ],
                          );
                        },
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.arrow_back, color: Color(primaryColor))),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.args.data.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _right(ChatMessage msg, String sender) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [Text(msg.formattedTime, style: TextStyle(fontSize: 12, color: Color(grey2Color))), const SizedBox(width: 6), Text(sender, style: const TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(msg.mediaUrl != null ? 4 : 10),
                  decoration: BoxDecoration(color: Color(primaryColor).withOpacity(0.1), borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero)),
                  child: _content(msg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _left(ChatMessage msg, String sender) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: Color(grey10Color)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 6), Text(msg.formattedTime, style: TextStyle(fontSize: 12, color: Color(grey2Color)))]),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(msg.mediaUrl != null ? 4 : 10),
                  decoration: BoxDecoration(color: Color(grey10Color).withOpacity(0.5), borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero)),
                  child: _content(msg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(ChatMessage msg) {
    final text = msg.body.replaceAll("[REACTION]", "").trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(msg.mediaUrl!, width: MediaQuery.of(context).size.width * 0.6, fit: BoxFit.cover),
          ),
        if (text.isNotEmpty) Text(text),
      ],
    );
  }
}


class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Chewie(controller: _chewieController!),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}