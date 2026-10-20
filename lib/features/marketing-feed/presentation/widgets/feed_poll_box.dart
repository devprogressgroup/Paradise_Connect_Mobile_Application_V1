import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';

/// Opsi poll + tombol "Kirim Jawaban". Setelah menjawab, opsi berubah jadi bar persentase.
class FeedPollBox extends StatefulWidget {
  final FeedPollEntity poll;

  /// Balikan: pesan error, atau null kalau terkirim. null = mode pratinjau (tidak bisa dijawab).
  final Future<String?> Function(List<int> optionIndexes)? onVote;

  const FeedPollBox({super.key, required this.poll, this.onVote});

  @override
  State<FeedPollBox> createState() => _FeedPollBoxState();
}

class _FeedPollBoxState extends State<FeedPollBox> {
  final Set<int> _selected = {};
  bool _sending = false;

  void _toggle(int index) {
    if (widget.poll.hasVoted || widget.onVote == null) return;
    setState(() {
      if (widget.poll.isMultiple) {
        _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
      } else {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final error = await widget.onVote!((_selected.toList()..sort()));
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Jawaban terkirim')));
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final voted = poll.hasVoted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (poll.image != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(aspectRatio: 16 / 10, child: FeedMediaView(media: poll.image!)),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < poll.options.length; i++) ...[
          _buildOption(i, voted),
          const SizedBox(height: 6),
        ],
        if (!voted) ...[
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: _selected.isEmpty || _sending || widget.onVote == null ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(primaryColor),
              foregroundColor: const Color(whiteColor),
              disabledBackgroundColor: const Color(greyShade300),
              disabledForegroundColor: const Color(greyShade600),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor)),
                  )
                : const Text('Kirim Jawaban', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${poll.totalVoters} sudah menjawab', style: const TextStyle(fontSize: 12, color: Color(grey2Color))),
            Text(
              poll.isMultiple ? 'Multi-jawaban' : 'Pilih satu',
              style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(int index, bool voted) {
    final poll = widget.poll;
    final selected = voted ? poll.myVotes.contains(index) : _selected.contains(index);
    final percent = poll.percentOf(index);
    return InkWell(
      onTap: () => _toggle(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: !voted && selected ? const Color(roSelectedBgColor) : const Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(primaryColor) : const Color(grey10Color),
          ),
        ),
        child: Stack(
          children: [
            if (voted)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (percent / 100).clamp(0.0, 1.0),
                  child: const ColoredBox(color: Color(blueShade50Color)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildMark(selected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      poll.options[index],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (voted)
                    Text(
                      '$percent%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(primaryColor)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMark(bool selected) {
    final multi = widget.poll.isMultiple;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: multi ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multi ? BorderRadius.circular(4) : null,
        color: selected ? const Color(primaryColor) : null,
        border: Border.all(
          color: selected ? const Color(primaryColor) : const Color(greyShade300),
          width: 2,
        ),
      ),
      child: !selected
          ? null
          : multi
              ? const Icon(Icons.check, size: 12, color: Color(whiteColor))
              : Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(whiteColor), shape: BoxShape.circle),
                  ),
                ),
    );
  }
}
