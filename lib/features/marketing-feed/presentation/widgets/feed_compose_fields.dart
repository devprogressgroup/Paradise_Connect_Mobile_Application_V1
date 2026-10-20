import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

const _videoExtensions = ['.mp4', '.mov', '.m4v', '.3gp', '.webm', '.mkv', '.avi'];

Future<FeedMediaEntity> _toMedia(XFile file) async {
  final name = file.name.toLowerCase();
  final isVideo = (file.mimeType?.startsWith('video') ?? false) || _videoExtensions.any(name.endsWith);
  return FeedMediaEntity(bytes: await file.readAsBytes(), fileName: file.name, isVideo: isVideo);
}

class FeedFormLabel extends StatelessWidget {
  final String text;

  const FeedFormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(grey2Color)));
  }
}

InputDecoration feedInputDecoration({String? hintText}) {
  OutlineInputBorder border(int color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(color)),
      );
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 13.5, color: Color(grey4Color)),
    filled: true,
    fillColor: const Color(whiteColor),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: border(greyShade300),
    enabledBorder: border(greyShade300),
    focusedBorder: border(primaryColor),
  );
}

/// Grid 3 kolom foto/video yang dipilih + tile "Upload".
class FeedMediaPickerGrid extends StatelessWidget {
  final List<FeedMediaEntity> media;
  final ValueChanged<List<FeedMediaEntity>> onChanged;
  final int maxItems;

  const FeedMediaPickerGrid({super.key, required this.media, required this.onChanged, this.maxItems = 6});

  Future<void> _pick() async {
    final picker = ImagePicker();
    final remaining = maxItems - media.length;
    final List<XFile> files;
    if (remaining > 1) {
      files = await picker.pickMultipleMedia(imageQuality: 80, limit: remaining);
    } else {
      final file = await picker.pickMedia(imageQuality: 80);
      files = file == null ? const [] : [file];
    }
    if (files.isEmpty) return;
    final picked = await Future.wait(files.take(remaining).map(_toMedia));
    onChanged([...media, ...picked]);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < media.length; i++)
          _FeedMediaTile(
            media: media[i],
            onRemove: () => onChanged([...media]..removeAt(i)),
          ),
        if (media.length < maxItems) _FeedUploadTile(label: 'Upload', onTap: _pick),
      ],
    );
  }
}

/// Satu gambar opsional (gambar pertanyaan poll), rasio 16:10.
class FeedSingleImagePicker extends StatelessWidget {
  final FeedMediaEntity? image;
  final ValueChanged<FeedMediaEntity?> onChanged;

  const FeedSingleImagePicker({super.key, required this.image, required this.onChanged});

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) onChanged(await _toMedia(file));
  }

  @override
  Widget build(BuildContext context) {
    final current = image;
    if (current == null) {
      return SizedBox(height: 90, child: _FeedUploadTile(label: 'Upload gambar', onTap: _pick));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FeedMediaView(media: current),
            Positioned(top: 6, right: 6, child: _RemoveButton(onTap: () => onChanged(null))),
          ],
        ),
      ),
    );
  }
}

class _FeedMediaTile extends StatelessWidget {
  final FeedMediaEntity media;
  final VoidCallback onRemove;

  const _FeedMediaTile({required this.media, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FeedMediaView(media: media, compact: true),
          Positioned(top: 6, right: 6, child: _RemoveButton(onTap: onRemove)),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(blue2Color).withValues(alpha: 0.65),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 14, color: Color(whiteColor)),
      ),
    );
  }
}

class _FeedUploadTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FeedUploadTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(greyShade300), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_upload_outlined, size: 22, color: Color(grey4Color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(grey4Color))),
          ],
        ),
      ),
    );
  }
}

/// "Pengaturan Interaksi" — saklar like/dislike/komentar/balasan/share per post.
class FeedInteractionSettingsCard extends StatelessWidget {
  final FeedInteractionSettings settings;
  final ValueChanged<FeedInteractionSettings> onChanged;

  const FeedInteractionSettingsCard({super.key, required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return FeedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          _toggle('Izinkan Like', s.allowLike, (v) => onChanged(s.copyWith(allowLike: v))),
          _toggle('Izinkan Dislike', s.allowDislike, (v) => onChanged(s.copyWith(allowDislike: v))),
          // Balasan ikut mati/nyala bersama komentar.
          _toggle(
            'Izinkan Komentar',
            s.allowComment,
            (v) => onChanged(s.copyWith(allowComment: v, allowReply: v)),
            subtitle: 'Sales bisa berkomentar di post ini',
          ),
          _toggle(
            'Izinkan Balasan',
            s.allowComment && s.allowReply,
            s.allowComment ? (v) => onChanged(s.copyWith(allowReply: v)) : null,
            subtitle: 'Sales bisa membalas komentar',
            indent: true,
          ),
          _toggle('Izinkan Share', s.allowShare, (v) => onChanged(s.copyWith(allowShare: v)), isLast: true),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    bool value,
    ValueChanged<bool>? onToggle, {
    String? subtitle,
    bool indent = false,
    bool isLast = false,
  }) {
    return Opacity(
      opacity: onToggle == null ? 0.45 : 1,
      child: Container(
        padding: EdgeInsets.only(left: indent ? 14 : 0, top: 6, bottom: 6),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(grey10Color))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(grey2Color))),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onToggle,
              activeTrackColor: const Color(primaryColor),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Waktu Tayang": Sekarang / Jadwalkan (tanggal + jam). [scheduledAt] null = sekarang.
/// Tanggal disimpan dengan konvensi [AppTime.now] (jam dinding WIB, flag UTC).
class FeedScheduleField extends StatelessWidget {
  final DateTime? scheduledAt;
  final ValueChanged<DateTime?> onChanged;

  const FeedScheduleField({super.key, required this.scheduledAt, required this.onChanged});

  static DateTime defaultSchedule() {
    final now = AppTime.now();
    return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute).add(const Duration(minutes: 5));
  }

  Future<void> _pickDate(BuildContext context, DateTime at) async {
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = DateTime(at.year, at.month, at.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(DateTime.utc(picked.year, picked.month, picked.day, at.hour, at.minute));
  }

  Future<void> _pickTime(BuildContext context, DateTime at) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: at.hour, minute: at.minute),
    );
    if (picked != null) onChanged(DateTime.utc(at.year, at.month, at.day, picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final at = scheduledAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(grey10Color), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _segment(Icons.send, 'Sekarang', at == null, () => onChanged(null)),
              const SizedBox(width: 4),
              _segment(Icons.schedule, 'Jadwalkan', at != null, () {
                if (at == null) onChanged(defaultSchedule());
              }),
            ],
          ),
        ),
        if (at != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 13,
                child: _pickerButton(
                  Icons.calendar_today_outlined,
                  DateFormat('d MMM yyyy', 'id_ID').format(at),
                  () => _pickDate(context, at),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: _pickerButton(Icons.schedule, DateFormat('HH:mm').format(at), () => _pickTime(context, at)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (at == null)
          const Text(
            'Langsung tayang di Marketing Feed setelah dipublikasikan.',
            style: TextStyle(fontSize: 12, color: Color(grey2Color)),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.schedule, size: 13, color: Color(primaryColor)),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12, height: 1.45, color: Color(grey2Color)),
                    children: [
                      const TextSpan(text: 'Tayang otomatis '),
                      TextSpan(
                        text: DateHelper.relativeDayTime(at),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '. Sampai saat itu tersimpan di Draft & Terjadwal.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _segment(IconData icon, String label, bool selected, VoidCallback onTap) {
    final color = Color(selected ? primaryColor : grey2Color);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(whiteColor) : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [BoxShadow(color: const Color(blackColor).withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(greyShade300)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(grey2Color)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      ),
    );
  }
}

/// Bar tombol bawah form: satu tombol utama, atau "Simpan Draft" + tombol utama.
class FeedFormBottomBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSaveDraft;
  final bool isLoading;

  const FeedFormBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSaveDraft,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ElevatedButton(
      onPressed: isLoading ? null : onPrimary,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(primaryColor),
        foregroundColor: const Color(whiteColor),
        disabledBackgroundColor: const Color(greyShade300),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(primaryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        boxShadow: [
          BoxShadow(color: const Color(blackColor).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: onSaveDraft == null
          ? SizedBox(width: double.infinity, child: primary)
          : Row(
              children: [
                Expanded(
                  flex: 10,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onSaveDraft,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(primaryColor),
                      side: const BorderSide(color: Color(primaryColor), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Draft', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 14, child: primary),
              ],
            ),
    );
  }
}
