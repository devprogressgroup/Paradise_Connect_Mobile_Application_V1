import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/reserve/reserve_order_model.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/widgets.dart';

/// Detail satu transaksi Reserve Order — Bagian 3 mockup, kolom "Detail — Perjalanan & Dokumen".
///
/// Empat tab: Perjalanan (timeline L1–L10), Data Pembeli, Attachment, dan Catatan. Transaksi yang
/// ditolak kasir menampilkan banner merah + tombol "Edit & Ajukan Ulang" di atas tab.
class ReserveOrderDetailPage extends StatefulWidget {
  final ReserveOrder order;

  const ReserveOrderDetailPage({super.key, required this.order});

  @override
  State<ReserveOrderDetailPage> createState() => _ReserveOrderDetailPageState();
}

enum _RoTab { perjalanan, pembeli, attachment, catatan }

class _ReserveOrderDetailPageState extends State<ReserveOrderDetailPage> {
  _RoTab _tab = _RoTab.perjalanan;
  final noteTC = TextEditingController();

  ReserveOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_detail');
  }

  @override
  void dispose() {
    noteTC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(whiteColor),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            roAppBar(
              title: 'Reserve Order',
              subtitle: order.unitLabel,
              onBack: () {
                AnalyticsService.logEvent('reserve_order_detail_back');
                context.pop();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildQuickContact(),
                    if (order.statusText != null) _buildStatusBox(),
                    if (order.isRejected) ...[
                      const SizedBox(height: 10),
                      roRejectBanner(order.rejectReason!),
                      customButton(_openRevise, 'Edit & Ajukan Ulang'),
                    ],
                    const SizedBox(height: 12),
                    _buildTabBar(),
                    const SizedBox(height: 12),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
            if (_tab == _RoTab.catatan) _buildNoteInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        roAvatar(order.initials),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.customerName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(blue2Color)),
              ),
              Text(order.detailUnitLine, style: const TextStyle(fontSize: 11, color: Color(grey4Color))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickContact() {
    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 13, color: Color(grey1Color)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              order.phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(grey1Color)),
            ),
          ),
          InkWell(
            onTap: _openFullProfile,
            child: const Text(
              'Profil & Riwayat Lengkap ›',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(primaryColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox() {
    final icon = switch (order.status) {
      ReserveOrderStatus.ditolak => Icons.close_rounded,
      ReserveOrderStatus.akad => Icons.check_circle_outline,
      ReserveOrderStatus.diproses => Icons.schedule,
      _ => Icons.flag_outlined,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(grey10Color)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          const Text('Status', style: TextStyle(fontSize: 9.5, color: Color(grey4Color))),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: order.status.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  order.statusText!,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: order.status.color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const labels = {
      _RoTab.perjalanan: 'Perjalanan',
      _RoTab.pembeli: 'Data Pembeli',
      _RoTab.attachment: 'Attachment',
      _RoTab.catatan: 'Catatan',
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        border: Border(bottom: BorderSide(color: const Color(grey10Color))),
      ),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: InkWell(
                onTap: () {
                  AnalyticsService.logEvent('reserve_order_detail_tab');
                  setState(() => _tab = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(_tab == entry.key ? primaryColor : transparentColor),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(_tab == entry.key ? primaryColor : grey4Color),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_tab) {
      _RoTab.perjalanan => _buildJourney(),
      _RoTab.pembeli => _buildBuyer(),
      _RoTab.attachment => _buildAttachment(),
      _RoTab.catatan => _buildNotes(),
    };
  }

  Widget _buildJourney() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < order.journey.length; i++) _buildStep(order.journey[i], isLast: i == order.journey.length - 1),
        if (order.canTopUp) ...[
          const SizedBox(height: 12),
          roGhostButton('+ Top Up Pembayaran', _openTopUp),
        ],
      ],
    );
  }

  Widget _buildStep(ReserveOrderStep step, {required bool isLast}) {
    final isActive = step.state == ReserveOrderStepState.active;
    final dotColor = switch (step.state) {
      ReserveOrderStepState.done => const Color(successColor),
      ReserveOrderStepState.active => const Color(primaryColor),
      ReserveOrderStepState.todo => const Color(grey7Color),
    };
    final lineColor = step.state == ReserveOrderStepState.done ? const Color(successColor) : const Color(grey10Color);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: isActive ? 18 : 14,
                  height: isActive ? 18 : 14,
                  margin: EdgeInsets.only(top: isActive ? 0 : 2),
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: step.state == ReserveOrderStepState.todo ? FontWeight.w600 : FontWeight.w700,
                      color: switch (step.state) {
                        ReserveOrderStepState.active => const Color(primaryColor),
                        ReserveOrderStepState.todo => const Color(grey4Color),
                        ReserveOrderStepState.done => const Color(blue2Color),
                      },
                    ),
                  ),
                  if (step.sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        step.sub!,
                        style: TextStyle(fontSize: 10, color: Color(step.subIsError ? redColor : grey4Color)),
                      ),
                    ),
                  if (step.lockLabel != null) _buildChipRow(_lockChip(step.lockLabel!)),
                  if (step.isGoal) _buildChipRow(_goalChip()),
                  for (final note in step.notes) _buildTimelineNote(note),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(Widget chip) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Align(alignment: Alignment.centerLeft, child: chip),
    );
  }

  Widget _lockChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 9, color: Color(0xFF854F0B)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF854F0B)),
          ),
        ],
      ),
    );
  }

  Widget _goalChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(spColor), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.flag_rounded, size: 9, color: Color(whiteColor)),
          SizedBox(width: 3),
          Text(
            'Tujuan Akhir',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(whiteColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNote(ReserveOrderTimelineNote note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(grey11Color), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${note.who} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '${note.text} '),
                TextSpan(text: note.time, style: const TextStyle(color: Color(grey4Color))),
              ],
            ),
            style: const TextStyle(fontSize: 10.5, height: 1.45, color: Color(grey1Color)),
          ),
          if (note.linkLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: _openFullProfile,
                child: Text(
                  note.linkLabel!,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(primaryColor)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuyer() {
    // Data pembeli hanya bisa diubah lewat "Edit & Ajukan Ulang", jadi tanda panah cuma muncul
    // saat transaksinya memang ditolak — supaya tidak ada baris yang terlihat bisa ditekan padahal
    // tidak ada tujuannya.
    final editable = order.isRejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in order.buyer) ...[
          roFieldLabel(field.label),
          InkWell(
            onTap: editable ? _openRevise : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(grey10Color), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(field.value, style: const TextStyle(fontSize: 12.5, color: Color(blue2Color))),
                  ),
                  if (editable) const Icon(Icons.chevron_right, size: 18, color: Color(grey4Color)),
                ],
              ),
            ),
          ),
        ],
        if (order.buyer.isEmpty) _buildEmpty('Data pembeli belum diisi.'),
      ],
    );
  }

  Widget _buildAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final doc in order.docs) roDocTile(doc, onTap: () => _onDocTap(doc)),
        if (order.docs.isEmpty) _buildEmpty('Belum ada dokumen.'),
        const SizedBox(height: 4),
        roGhostButton('+ Upload Dokumen Tambahan', _uploadExtraDoc),
      ],
    );
  }

  Widget _buildNotes() {
    if (order.notes.isEmpty) return _buildEmpty('Belum ada catatan.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final note in order.notes) _buildNoteItem(note)],
    );
  }

  Widget _buildNoteItem(ReserveOrderNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roAvatar(note.initials, size: 26, color: note.avatarColor, textColor: const Color(whiteColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(grey11Color), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: note.author,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            children: [
                              TextSpan(
                                text: ' · ${note.role}',
                                style: const TextStyle(fontWeight: FontWeight.w400, color: Color(grey4Color)),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 10.5, color: Color(grey1Color)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(note.time, style: const TextStyle(fontSize: 9, color: Color(grey4Color))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(note.text, style: const TextStyle(fontSize: 11.5, height: 1.45, color: Color(0xFF25262B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        border: Border(top: BorderSide(color: const Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: roInput(noteTC, hint: 'Tulis catatan...')),
            const SizedBox(width: 8),
            InkWell(
              onTap: _sendNote,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(primaryColor), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, size: 16, color: Color(whiteColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 12, color: Color(grey4Color))),
      ),
    );
  }

  void _openFullProfile() {
    AnalyticsService.logEvent('reserve_order_detail_open_profile');

    final contactId = order.contactId;
    if (contactId == null) {
      showSnackbar(context, 'Transaksi ini belum tertaut ke kontak mana pun', isError: true);
      return;
    }

    // ContactDetailPage memuat ulang detail & aktivitasnya dari server berbekal contactId; field
    // lain diisi seadanya supaya header-nya tidak kosong selagi data lengkapnya dimuat.
    context.pushNamed(
      'detailContact',
      extra: ContactDetailArgs(
        dataContact: ContactEntity(
          contactId: contactId,
          dealId: order.dealId,
          fullName: order.customerName,
          primaryPhone: order.phone,
        ),
      ),
    );
  }

  Future<void> _openTopUp() async {
    AnalyticsService.logEvent('reserve_order_detail_open_top_up');
    await context.pushNamed('reserveOrderTopUp', extra: order);
    if (mounted) setState(() {});
  }

  Future<void> _openRevise() async {
    AnalyticsService.logEvent('reserve_order_detail_open_revise');
    await context.pushNamed('reserveOrderRevise', extra: order);
    if (mounted) setState(() {});
  }

  void _onDocTap(ReserveOrderDoc doc) {
    if (doc.state == ReserveOrderDocState.rejected && order.isRejected) {
      _openRevise();
      return;
    }
    showSnackbar(context, 'Pratinjau dokumen tersedia setelah file-nya tersimpan di server.');
  }

  Future<void> _uploadExtraDoc() async {
    AnalyticsService.logEvent('reserve_order_detail_upload_doc');
    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData) return;
    if (!mounted) return;

    final bytes = picked.bytes?.lengthInBytes ?? 0;
    final size = bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(bytes / 1024).round()} KB';

    setState(() {
      order.docs.add(ReserveOrderDoc(
        icon: picked.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
        name: picked.name,
        badge: '· Dokumen tambahan',
        status: 'Terupload · $size',
      ));
    });
    if (mounted) showSnackbar(context, 'Dokumen ditambahkan.');
  }

  void _sendNote() {
    final text = noteTC.text.trim();
    if (text.isEmpty) {
      showSnackbar(context, 'Catatan masih kosong', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_detail_add_note');
    // List ini isinya transaksi milik sales yang login, jadi penulis catatannya ya sales yang
    // tercatat di transaksi itu sendiri.
    setState(() {
      order.notes.add(ReserveOrderNote(
        author: order.salesName,
        role: 'Sales',
        roleKind: ReserveOrderNoteRole.sales,
        time: DateFormat('dd MMM, HH:mm').format(DateTime.now()),
        text: text,
      ));
      noteTC.clear();
    });
  }
}
