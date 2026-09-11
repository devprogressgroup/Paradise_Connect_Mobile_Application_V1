import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
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
  bool _loadingBuyer = true;
  List<CaraBayarOption> _caraBayarOptions = const [];
  final Set<String> _collapsedBuyerSections = {};

  List<ReserveOrderAttachment> _attachments = [];
  bool _loadingAttachments = false;
  // true kalau `order.id` gagal di-parse jadi int — praktis tidak pernah kejadian (selalu angka
  // dari `reserve_order_id`), tapi tetap dijaga daripada nge-throw diam-diam.
  bool _attachmentsUnavailable = false;
  bool _uploadingExtraDoc = false;

  bool _loadingNotes = false;
  bool _sendingNote = false;

  ReserveOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_detail');
    _loadBuyerDetail();
    _loadAttachments();
    _loadNotes();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final reserveOrderId = int.tryParse(order.id);
    final contactId = order.contactId;
    final dealId = order.dealId;
    if (reserveOrderId == null || contactId == null || dealId == null) return;

    try {
      final milestones = await context.read<ReserveOrderListCubit>().dataSource.getReserveTimeline(
            reserveOrderId: reserveOrderId,
            contactId: contactId,
            dealId: dealId,
          );
      if (!mounted || milestones.isEmpty) return;
      setState(() => order.applyTimeline(milestones));
    } catch (_) {
    }
  }

  Future<void> _loadBuyerDetail() async {
    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) {
      setState(() => _loadingBuyer = false);
      return;
    }

    final cubit = context.read<ReserveOrderListCubit>();
    try {
      final detail = await cubit.dataSource.getReserveCustomer(reserveOrderId);
      final caraBayarOptions = await cubit.ensureCaraBayarOptions();
      order.applyCustomerDetail(detail, caraBayarOptions);
      _caraBayarOptions = caraBayarOptions;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingBuyer = false);
    }
  }

  Future<void> _loadAttachments() async {
    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) {
      setState(() => _attachmentsUnavailable = true);
      return;
    }

    setState(() => _loadingAttachments = true);
    try {
      // Cuma `reserve_order_id` — TANPA `reserve_order_tts_id`, supaya dokumen dari SEMUA TTS
      // reserve order ini ikut tampil, bukan cuma TTS yang paling baru diketahui (lihat catatan di
      // `ReserveOrderRemoteDataSource.getReserveAttachments`).
      final attachments = await context.read<ReserveOrderListCubit>().dataSource.getReserveAttachments(
            reserveOrderId: reserveOrderId,
          );
      if (mounted) setState(() => _attachments = attachments);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAttachments = false);
    }
  }

  Future<void> _loadNotes() async {
    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) return;

    setState(() => _loadingNotes = true);
    try {
      final messages = await context.read<ReserveOrderListCubit>().dataSource.getReserveNotes(reserveOrderId);
      if (!mounted) return;
      if (messages.isNotEmpty) {
        setState(() {
          order.notes
            ..clear()
            ..addAll(messages.map((m) => ReserveOrderNote(
                  author: m.senderName,
                  role: m.senderRole ?? '-',
                  roleKind: ReserveOrderNoteRole.user,
                  time: m.createDatetime == null ? '' : DateFormat('dd MMM, HH:mm').format(m.createDatetime!),
                  text: m.message,
                )));
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  @override
  void dispose() {
    noteTC.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() {
    AnalyticsService.logEvent('reserve_order_detail_refresh');
    return switch (_tab) {
      _RoTab.perjalanan => _loadTimeline(),
      _RoTab.pembeli => _loadBuyerDetail(),
      _RoTab.attachment => _loadAttachments(),
      _RoTab.catatan => _loadNotes(),
    };
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
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        customButton(_openRevise, 'Edit & Resubmit'),
                      ],
                      const SizedBox(height: 12),
                      _buildTabBar(),
                      const SizedBox(height: 12),
                      _buildTabContent(),
                    ],
                  ),
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
              'Full Profile & History ›',
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
      _RoTab.perjalanan: 'Timeline',
      _RoTab.pembeli: 'Customer',
      _RoTab.attachment: 'Attachment',
      _RoTab.catatan: 'Notes',
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
      _RoTab.perjalanan => _buildTimeline(),
      _RoTab.pembeli => _buildBuyer(),
      _RoTab.attachment => _buildAttachment(),
      _RoTab.catatan => _buildNotes(),
    };
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < order.journey.length; i++) _buildStep(order.journey[i], isLast: i == order.journey.length - 1),
        if (order.canTopUp) ...[
          const SizedBox(height: 12),
          roGhostButton('+ Top Up Payment', _openTopUp),
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
      decoration: BoxDecoration(color: const Color(roAmberBgColor), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 9, color: Color(roLockTextColor)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(roLockTextColor)),
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
            'Final Goal',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(whiteColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNote(ReserveOrderTimelineNote note) {
    return Container(
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
    if (_loadingBuyer && order.customerDetail == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final detail = order.customerDetail;
    if (detail == null) {
      return _buildEmpty('Buyer data has not been filled in yet.');
    }

    final slotKeys = {for (final group in reserveCustomerSlotGroups) ...group.keys};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in reserveCustomerFieldSections) ...[
          roCollapsibleSectionHeader(
            title: section.title,
            collapsed: _collapsedBuyerSections.contains(section.title),
            onTap: () => setState(() {
              if (_collapsedBuyerSections.contains(section.title)) {
                _collapsedBuyerSections.remove(section.title);
              } else {
                _collapsedBuyerSections.add(section.title);
              }
            }),
          ),
          if (!_collapsedBuyerSections.contains(section.title)) ...[
            for (final field in section.fields)
              if (!slotKeys.contains(field.key))
                _buildFieldRow(field.label, _formatFieldValue(detail, field), field.key)
              else if (_firstSlotKeyOf(field.key) case final group?)
                ..._buildSlotRows(detail, group),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  ReserveCustomerSlotGroup? _firstSlotKeyOf(String key) {
    for (final group in reserveCustomerSlotGroups) {
      if (group.keys.first == key) return group;
    }
    return null;
  }

  List<Widget> _buildSlotRows(ReserveCustomerDetail detail, ReserveCustomerSlotGroup group) {
    final filled = group.keys.where((key) => _rawText(detail, key) != null).toList();

    if (filled.length <= 1) {
      final key = filled.isEmpty ? group.keys.first : filled.first;
      return [_buildFieldRow(group.baseLabel, _rawText(detail, key) ?? '-', key)];
    }

    return [
      for (final key in filled)
        _buildFieldRow(
          _fieldLabelOf(key) ?? group.baseLabel,
          _rawText(detail, key)!,
          key,
        ),
    ];
  }

  String? _fieldLabelOf(String key) {
    for (final section in reserveCustomerFieldSections) {
      for (final field in section.fields) {
        if (field.key == key) return field.label;
      }
    }
    return null;
  }

  String? _rawText(ReserveCustomerDetail detail, String key) {
    final text = detail.raw[key]?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _formatFieldValue(ReserveCustomerDetail detail, ReserveCustomerFieldSpec field) {
    final raw = detail.raw[field.key];
    switch (field.kind) {
      case ReserveCustomerFieldKind.date:
        final date = raw == null ? null : DateTime.tryParse('$raw');
        return date == null ? '-' : DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      case ReserveCustomerFieldKind.genderBool:
        if (raw is! bool) return '-';
        return raw ? 'Male' : 'Female';
      case ReserveCustomerFieldKind.yesNoBool:
        if (raw is! bool) return '-';
        return raw ? 'Yes' : 'No';
      case ReserveCustomerFieldKind.area:
        return raw == null ? '-' : '$raw';
      case ReserveCustomerFieldKind.paymentPlan:
        final id = raw is int ? raw : int.tryParse('$raw');
        if (id == null) return '-';
        for (final option in _caraBayarOptions) {
          if (option.caraBayarId == id) return option.name;
        }
        return '-';
      case ReserveCustomerFieldKind.maritalStatus:
      case ReserveCustomerFieldKind.religion:
      case ReserveCustomerFieldKind.text:
        return _rawText(detail, field.key) ?? '-';
    }
  }

  Widget _buildFieldRow(String label, String value, String highlightKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roFieldLabel(label),
          InkWell(
            onTap: () => _openEditCustomer(highlightKey),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(grey10Color), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(blue2Color))),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(grey4Color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _fixedDocTypes = [
    (label: 'KTP', icon: Icons.badge_outlined, keywords: ['ktp']),
    (label: 'NPWP', icon: Icons.description_outlined, keywords: ['npwp']),
    (label: 'Bukti Transfer', icon: Icons.receipt_long_outlined, keywords: ['bukti transfer', 'bukti bayar']),
  ];

  Widget _buildAttachment() {
    if (_loadingAttachments && _attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final missingStatus = _attachmentsUnavailable ? 'Status not available' : 'Not uploaded yet';

    final matched = <ReserveOrderAttachment>{};
    final fixedTiles = <Widget>[];
    for (final type in _fixedDocTypes) {
      final found = _attachments
          .where((a) => type.keywords.any((k) => a.attachmentTypeName.toLowerCase().contains(k)))
          .toList();
      if (found.isEmpty) {
        fixedTiles.add(roDocTile(
          ReserveOrderDoc(icon: type.icon, name: type.label, status: missingStatus, state: ReserveOrderDocState.awaitingUpload),
        ));
        continue;
      }
      matched.addAll(found);
      for (final attachment in found) {
        fixedTiles.add(roDocTile(_docFrom(attachment), onTap: () => _openAttachment(attachment)));
      }
    }

    final extraAttachments = _attachments.where((a) => !matched.contains(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fixedTiles,
        for (final attachment in extraAttachments)
          roDocTile(_docFrom(attachment), onTap: () => _openAttachment(attachment)),
        for (final doc in order.docs) roDocTile(doc, onTap: () => _onDocTap(doc)),
        const SizedBox(height: 4),
        roGhostButton(_uploadingExtraDoc ? 'Uploading…' : '+ Upload Additional Document', _uploadExtraDoc),
      ],
    );
  }

  ReserveOrderDoc _docFrom(ReserveOrderAttachment attachment) {
    final uploadedAt = attachment.createDatetime != null ? DateFormat('dd MMM yyyy', 'id_ID').format(attachment.createDatetime!) : null;
    final status = [
      if (attachment.createUserName != null) 'Uploaded by ${attachment.createUserName}',
      if (uploadedAt != null) uploadedAt,
    ].join(' · ');

    return ReserveOrderDoc(
      icon: Icons.insert_drive_file_outlined,
      name: attachment.attachmentTypeName,
      status: status.isEmpty ? 'Saved on server' : status,
      state: ReserveOrderDocState.uploaded,
    );
  }

  void _openAttachment(ReserveOrderAttachment attachment) {
    if (attachment.attachmentUrl.isEmpty) {
      showSnackbar(context, 'Document link not available');
      return;
    }
    AnalyticsService.logEvent('reserve_order_detail_open_attachment');
    context.pushNamed('attachmentWebView', extra: attachment.attachmentUrl);
  }

  Widget _buildNotes() {
    if (_loadingNotes && order.notes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (order.notes.isEmpty) return _buildEmpty('No notes yet.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final note in order.notes) _buildNoteItem(note)],
    );
  }

  Widget _buildNoteItem(ReserveOrderNote note) => note.isMine ? _buildNoteRight(note) : _buildNoteLeft(note);

  Widget _buildNoteLeft(ReserveOrderNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roAvatar(note.initials, size: 26, color: note.avatarColor, textColor: const Color(whiteColor)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _noteHeader(note),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(grey10Color).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero),
                  ),
                  child: Text(note.text, style: const TextStyle(fontSize: 11.5, height: 1.45, color: Color(roNoteTextColor))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRight(ReserveOrderNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _noteHeader(note),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(primaryColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero),
                  ),
                  child: Text(note.text, style: const TextStyle(fontSize: 11.5, height: 1.45, color: Color(roNoteTextColor))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteHeader(ReserveOrderNote note) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              text: note.displayAuthor,
              style: const TextStyle(fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' · ${note.role}',
                  style: const TextStyle(fontWeight: FontWeight.w400, color: Color(grey4Color)),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 10.5, color: Color(grey1Color)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(note.time, style: const TextStyle(fontSize: 9, color: Color(grey4Color))),
      ],
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
            Expanded(child: roInput(noteTC, hint: 'Write a note...')),
            const SizedBox(width: 8),
            InkWell(
              onTap: _sendingNote ? null : _sendNote,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(primaryColor), shape: BoxShape.circle),
                child: _sendingNote
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor)),
                      )
                    : const Icon(Icons.send_rounded, size: 16, color: Color(whiteColor)),
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
      showSnackbar(context, 'This transaction is not linked to any contact yet', isError: true);
      return;
    }

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

  Future<void> _openEditCustomer([String? highlightKey]) async {
    AnalyticsService.logEvent('reserve_order_detail_open_edit_customer');
    final saved = await context.pushNamed(
      'reserveOrderEditCustomer',
      extra: order,
      queryParameters: highlightKey == null ? const {} : {'field': highlightKey},
    );
    if (!mounted) return;
    if (saved == true) showSnackbar(context, 'Customer data updated.');
    setState(() {});
  }

  void _onDocTap(ReserveOrderDoc doc) {
    if (doc.state == ReserveOrderDocState.rejected && order.isRejected) {
      _openRevise();
      return;
    }
    showSnackbar(context, 'Document preview is available once the file is saved on the server.');
  }

  bool _hasAttachmentOfType(String label) {
    final type = _fixedDocTypes.firstWhere((t) => t.label == label);
    return _attachments.any((a) => type.keywords.any((k) => a.attachmentTypeName.toLowerCase().contains(k)));
  }

  int? get _latestAttachmentTtsId {
    final ids = _attachments.map((a) => a.reserveOrderTtsId).whereType<int>();
    return ids.isEmpty ? null : ids.reduce((a, b) => a > b ? a : b);
  }

  Future<String?> _pickDocType(List<String> options) {
    final completer = Completer<String?>();
    roShowOptionSheet(
      context: context,
      title: 'Document Type',
      items: options,
      selected: null,
      onPicked: (v) => completer.complete(v),
    );
    return completer.future;
  }

  Future<void> _uploadExtraDoc() async {
    if (_uploadingExtraDoc) return;

    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) return;

    AnalyticsService.logEvent('reserve_order_detail_upload_doc');
    final options = ['KTP', if (!_hasAttachmentOfType('NPWP')) 'NPWP', 'Bukti Transfer'];
    final docType = await _pickDocType(options);
    if (docType == null || !mounted) return;

    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData || picked.bytes == null) return;
    if (!mounted) return;

    setState(() => _uploadingExtraDoc = true);
    try {
      await context.read<ReserveOrderListCubit>().dataSource.submitDocPayment(DocPaymentParams(
            reserveOrderId: reserveOrderId,
            reserveOrderTtsId: _latestAttachmentTtsId,
            ktpBytes: docType == 'KTP' ? [picked.bytes!] : const [],
            ktpFileNames: docType == 'KTP' ? [picked.name] : const [],
            npwpBytes: docType == 'NPWP' ? picked.bytes : null,
            npwpFileName: docType == 'NPWP' ? picked.name : null,
            buktiTransferBytes: docType == 'Bukti Transfer' ? [picked.bytes!] : const [],
            buktiTransferFileNames: docType == 'Bukti Transfer' ? [picked.name] : const [],
          ));
      if (!mounted) return;
      setState(() => _attachmentsUnavailable = false);
      await _loadAttachments();
      if (mounted) showSnackbar(context, 'Document uploaded.');
    } catch (e) {
      if (mounted) showSnackbar(context, cleanErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _uploadingExtraDoc = false);
    }
  }

  Future<void> _sendNote() async {
    final text = noteTC.text.trim();
    if (text.isEmpty) {
      showSnackbar(context, 'Note is still empty', isError: true);
      return;
    }

    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) return;

    AnalyticsService.logEvent('reserve_order_detail_add_note');
    setState(() => _sendingNote = true);
    try {
      final cubit = context.read<ReserveOrderListCubit>();
      await cubit.dataSource.sendReserveNote(reserveOrderId: reserveOrderId, message: text);
      noteTC.clear();
      await _loadNotes();
    } catch (e) {
      if (mounted) showSnackbar(context, cleanErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _sendingNote = false);
    }
  }
}
