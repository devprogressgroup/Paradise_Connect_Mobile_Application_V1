import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/widget/error_dialog.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_type.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_event.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_event.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_state.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
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

  final _attachSearchTC = TextEditingController();
  final _attachSearchFN = FocusNode();
  bool _uploadingAttachment = false;
  late AttachmentCubit _attachmentCubit;

  bool _loadingNotes = false;
  bool _sendingNote = false;

  ReserveOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_detail');
    _attachmentCubit = context.read<AttachmentCubit>();
    context.read<AttachmentTypeBloc>().add(FetchAttachmentTypesEvent());
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

  /// Sama seperti tab Attachment di Contact Detail: dokumen diambil lewat
  /// `GET /contacts/{contactId}/attachments?deal_id=` ([AttachmentCubit]), disaring ke deal
  /// transaksi ini — bukan lagi `GET /reserve/attachment`.
  Future<void> _loadAttachments() async {
    final contactId = order.contactId;
    if (contactId == null) return;
    await _attachmentCubit.fetch(contactId, order.dealId);
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
    _attachSearchTC.dispose();
    _attachSearchFN.dispose();
    _attachmentCubit.reset();
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
              title: 'Transaction',
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
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          ],
                        ),
                      ),
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
      _RoTab.perjalanan: 'Timeline',
      _RoTab.pembeli: 'Customer',
      _RoTab.attachment: 'Attachment',
      _RoTab.catatan: 'Messages',
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

  /// Tab lain tetap kepadding 14 seperti sebelumnya — Padding-nya dipindah ke sini (bukan lagi dari
  /// `SingleChildScrollView` pembungkus di [build]) supaya tab Customer bisa dikecualikan, dibuat
  /// edge-to-edge (section abu-abu & field underline-nya nempel ke tepi layar, ala Contact).
  Widget _buildTabContent() {
    return switch (_tab) {
      _RoTab.perjalanan => _tabPad(_buildTimeline()),
      _RoTab.pembeli => _buildBuyer(),
      _RoTab.attachment => _tabPad(_buildAttachment()),
      _RoTab.catatan => _tabPad(_buildNotes()),
    };
  }

  Widget _tabPad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: child);

  Widget _buildTimeline() {
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
            'Tujuan Akhir',
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
      return _buildEmpty('Data pembeli belum diisi.');
    }

    final slotKeys = {for (final group in reserveCustomerSlotGroups) ...group.keys};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in reserveCustomerFieldSections)
          CustomDropdownGroupContact(
            hint: section.title,
            child: Column(
              children: [
                for (final field in section.fields)
                  if (!slotKeys.contains(field.key))
                    _buildFieldRow(field.label, _formatFieldValue(detail, field), field.key)
                  else if (_firstSlotKeyOf(field.key) case final group?)
                    ..._buildSlotRows(detail, group),
              ],
            ),
          ),
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
        return raw ? 'Laki-laki' : 'Perempuan';
      case ReserveCustomerFieldKind.yesNoBool:
        if (raw is! bool) return '-';
        return raw ? 'Ya' : 'Tidak';
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

  /// Baris baca-saja ala "Edit Contact" (gaya sama dengan field underline di
  /// `ReserveOrderEditCustomerPage`) — label kecil di atas, nilai di bawah, tanpa kotak/border
  /// bundar. Tetap tappable ke [_openEditCustomer] supaya field-nya ter-highlight begitu sampai
  /// di halaman Edit.
  Widget _buildFieldRow(String label, String value, String highlightKey) {
    return InkWell(
      onTap: () => _openEditCustomer(highlightKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: const BoxDecoration(
          color: Color(whiteColor),
          border: Border(bottom: BorderSide(color: Color(grey9Color))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(grey2Color))),
                  Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blackColor))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(grey4Color)),
          ],
        ),
      ),
    );
  }

  /// Sama seperti tab Attachment di Contact Detail: list bebas (bukan slot tetap KTP/NPWP/Bukti
  /// Transfer) dari [AttachmentCubit], dengan kartu "Add New File" di atasnya. `order.docs` tetap
  /// dirender di bawahnya — itu dokumen ephemeral lokal dari alur Top Up/Revise (lihat
  /// `ReserveOrderTopUpPage`/`ReserveOrderRevisePage`), bukan bagian dari perubahan ini.
  Widget _buildAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customSearchField(
          controller: _attachSearchTC,
          focusNode: _attachSearchFN,
          hintText: 'Cari dokumen...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 9),
        if (PermissionsHelper.canUploadAttachment) _buildAddNewFileCard(),
        BlocListener<UploadAttachmentBloc, UploadAttachmentState>(
          listenWhen: (prev, curr) => curr is UploadAttachmentSuccess || curr is UploadAttachmentError,
          listener: (context, state) {
            setState(() => _uploadingAttachment = false);
            if (state is UploadAttachmentSuccess) {
              showSnackbar(context, 'Dokumen berhasil disimpan.');
              _loadAttachments();
            } else if (state is UploadAttachmentError) {
              showSnackbar(context, state.message, isError: true);
            }
          },
          child: BlocConsumer<AttachmentCubit, AttachmentState>(
            listenWhen: (prev, curr) => curr is AttachmentError && prev is! AttachmentError,
            listener: (context, state) {
              if (state is AttachmentError) showErrorDialog(context, state.message);
            },
            builder: (context, state) {
              if (state is AttachmentLoaded) {
                final list = _filteredAttachments(state.data);
                if (list.isEmpty) return _buildEmpty('Belum ada dokumen.');
                return Column(children: [for (final item in list) _buildAttachmentTile(item)]);
              }
              if (state is AttachmentError) return _buildEmpty('Gagal memuat dokumen.');
              return buildAttachmentShimmer();
            },
          ),
        ),
        for (final doc in order.docs) roDocTile(doc, onTap: () => _onDocTap(doc)),
      ],
    );
  }

  List<ContactAttachment> _filteredAttachments(List<ContactAttachment> data) {
    final query = _attachSearchTC.text.trim().toLowerCase();
    if (query.isEmpty) return data;
    return data
        .where((a) => a.attachmentTypeName.toLowerCase().contains(query) || a.attachmentNote.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildAddNewFileCard() {
    final enabled = !_uploadingAttachment;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? () => _openAttachmentSheet() : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(blackColor).withValues(alpha: 0.08), blurRadius: 12)],
        ),
        child: Row(
          children: [
            BgIcon(asset: icUpload, color: enabled ? const Color(primaryColor) : const Color(greyShade500)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _uploadingAttachment ? 'Mengunggah…' : 'Tambah Dokumen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: enabled ? const Color(primaryColor) : const Color(greyShade500)),
                ),
                Text('unggah dokumen baru', style: TextStyle(fontSize: 12, color: enabled ? const Color(grey5Color) : const Color(greyShade500))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentTile(ContactAttachment item) {
    final uploadedAt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.createDatetime);

    return GestureDetector(
      onTap: () => _openAttachmentUrl(item.attachmentUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(blackColor).withValues(alpha: 0.08), blurRadius: 12)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(greyShade300), borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DriveImage(
                  url: item.attachmentUrl,
                  width: 58,
                  height: 44,
                  fit: BoxFit.cover,
                  onTap: () => _openAttachmentUrl(item.attachmentUrl),
                  errorWidget: Container(
                    width: 58,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(whiteColor),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(primaryColor)),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Color(primaryColor)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.attachmentTypeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(uploadedAt, style: const TextStyle(fontSize: 10, color: Color(grey4Color))),
                  if (item.attachmentNote.isNotEmpty)
                    Text(
                      item.attachmentNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(grey4Color)),
                    ),
                ],
              ),
            ),
            if (PermissionsHelper.canEditAttachmentItem || PermissionsHelper.canDeleteAttachmentItem)
              PopupMenuButton<String>(
                icon: Container(
                  height: 44,
                  width: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(grey11Color), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.more_vert),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openAttachmentSheet(editing: item);
                  } else if (value == 'delete') {
                    _confirmDeleteAttachment(item);
                  }
                },
                itemBuilder: (context) => [
                  if (PermissionsHelper.canEditAttachmentItem)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')]),
                    ),
                  if (PermissionsHelper.canDeleteAttachmentItem)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 18, color: Color(redAccentColor)), SizedBox(width: 8), Text('Hapus')]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAttachment(ContactAttachment item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Dokumen'),
        content: const Text('Yakin ingin menghapus dokumen ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              AnalyticsService.logEvent('reserve_order_detail_delete_attachment_confirm');
              Navigator.pop(context);
              final contactId = order.contactId;
              if (contactId == null) return;
              _attachmentCubit.delete(contactId: contactId, attachmentId: item.contactAttachmentId, dealId: order.dealId);
            },
            child: const Text('Hapus', style: TextStyle(color: Color(redAccentColor))),
          ),
        ],
      ),
    );
  }

  /// Pilih tipe dokumen dari `GET /contacts/attachment-types` — sumber yang sama dengan dropdown
  /// tipe di form "Add New File" Contact Detail.
  Future<AttachmentType?> _pickAttachmentType({String? currentName}) async {
    final bloc = context.read<AttachmentTypeBloc>();
    var state = bloc.state;
    if (state is! AttachmentTypeLoaded) {
      bloc.add(FetchAttachmentTypesEvent());
      state = await bloc.stream.firstWhere((s) => s is AttachmentTypeLoaded || s is AttachmentTypeError);
    }
    if (!mounted) return null;

    if (state is AttachmentTypeError) {
      showSnackbar(context, state.message, isError: true);
      return null;
    }

    final types = (state as AttachmentTypeLoaded).data;
    if (types.isEmpty) {
      showSnackbar(context, 'Tipe dokumen belum tersedia', isError: true);
      return null;
    }

    final completer = Completer<String?>();
    roShowOptionSheet(
      context: context,
      title: 'Jenis Dokumen',
      items: types.map((t) => t.name).toList(),
      selected: currentName,
      onPicked: (v) => completer.complete(v),
    );
    final picked = await completer.future;
    if (picked == null) return null;
    return types.firstWhere((t) => t.name == picked);
  }

  /// Upload/edit dokumen — sama seperti "Add New File" di Contact Detail: pilih tipe lalu file,
  /// lalu kirim lewat [UploadAttachmentBloc] (`POST`/`PATCH /contacts/{id}/attachments`) dengan
  /// `dealId` transaksi ini supaya dokumennya tertaut ke deal yang benar.
  Future<void> _openAttachmentSheet({ContactAttachment? editing}) async {
    if (_uploadingAttachment) return;

    final contactId = order.contactId;
    if (contactId == null) {
      showSnackbar(context, 'Transaksi ini belum tertaut ke kontak mana pun', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_detail_upload_attachment');
    final type = await _pickAttachmentType(currentName: editing?.attachmentTypeName);
    if (type == null || !mounted) return;

    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData || picked.bytes == null || !mounted) return;

    setState(() => _uploadingAttachment = true);
    // Edit ([ContactRepositoryImpl.updateAttachment]) cuma baca `fileBytes`/`fileName` tunggal —
    // `filesBytesList` diam-diam diabaikan di jalur PATCH, jadi wajib dibedakan dari create.
    final params = editing == null
        ? UploadAttachmentParams(
            contactId: contactId,
            dealId: order.dealId,
            attachmentTypeId: type.id,
            filesBytesList: [picked.bytes!],
            fileNames: [picked.name],
          )
        : UploadAttachmentParams(
            contactId: contactId,
            dealId: order.dealId,
            attachmentTypeId: type.id,
            fileBytes: picked.bytes,
            fileName: picked.name,
          );
    context.read<UploadAttachmentBloc>().add(SubmitAttachmentEvent(params: params, attachmentId: editing?.contactAttachmentId));
  }

  void _openAttachmentUrl(String url) {
    if (url.isEmpty) {
      showSnackbar(context, 'Tautan dokumen tidak tersedia');
      return;
    }
    context.pushNamed('attachmentWebView', extra: url);
  }

  Widget _buildNotes() {
    if (_loadingNotes && order.notes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (order.notes.isEmpty) return _buildEmpty('Belum ada pesan.');

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
            Expanded(child: roInput(noteTC, hint: 'Tulis pesan...')),
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
      showSnackbar(context, 'Transaksi ini belum tertaut ke kontak mana pun', isError: true);
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
    if (saved == true) showSnackbar(context, 'Data pembeli berhasil diperbarui.');
    setState(() {});
  }

  void _onDocTap(ReserveOrderDoc doc) {
    if (doc.state == ReserveOrderDocState.rejected && order.isRejected) {
      _openRevise();
      return;
    }
    showSnackbar(context, 'Pratinjau dokumen tersedia setelah file tersimpan di server.');
  }

  Future<void> _sendNote() async {
    final text = noteTC.text.trim();
    if (text.isEmpty) {
      showSnackbar(context, 'Pesan masih kosong', isError: true);
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
