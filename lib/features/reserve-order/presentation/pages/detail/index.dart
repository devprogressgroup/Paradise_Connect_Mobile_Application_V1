import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/widget/reject_banner.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_customer_data.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_detail.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../edit-customer/index.dart';
import '../top-up/index.dart';

class ReserveOrderDetailPage extends StatefulWidget {
  final int reserveOrderId;

  const ReserveOrderDetailPage({super.key, required this.reserveOrderId});

  @override
  State<ReserveOrderDetailPage> createState() => _ReserveOrderDetailPageState();
}

class _ReserveOrderDetailPageState extends State<ReserveOrderDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _messageController = TextEditingController();
  final _messageScrollController = ScrollController();
  bool _sendingMessage = false;

  static const _messagesTabIndex = 3;

  /// Jumlah pesan yang sudah pernah dilihat user di tab Messages order ini (disimpan per
  /// reserve order di SharedPreferences) — pesan orang lain di atas jumlah ini = belum dibaca,
  /// ditandai titik merah di tab Messages.
  int? _seenMessageCount;
  bool _seenLoaded = false;

  String get _seenKey => 'reserve_order_seen_messages_${widget.reserveOrderId}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_onTabChanged);
    _loadSeenMessageCount();
    _refresh();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<ReserveOrderDetailCubit>().fetch(widget.reserveOrderId);

  Future<void> _loadSeenMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _seenMessageCount = prefs.getInt(_seenKey);
      _seenLoaded = true;
    });
    _markMessagesSeenIfOpen();
  }

  void _onTabChanged() {
    if (_tabController.index == _messagesTabIndex) _markMessagesSeenIfOpen();
  }

  /// Tandai semua pesan sudah dibaca kalau tab Messages sedang terbuka (dipanggil saat pindah
  /// tab & tiap detail ter-refresh).
  void _markMessagesSeenIfOpen() {
    if (!_seenLoaded || _tabController.index != _messagesTabIndex) return;
    final detail = context.read<ReserveOrderDetailCubit>().state.detail;
    if (detail == null || detail.reserveOrderId != widget.reserveOrderId)
      return;
    final count = detail.messages.length;
    if (_seenMessageCount == count) return;
    setState(() => _seenMessageCount = count);
    SharedPreferences.getInstance().then((p) => p.setInt(_seenKey, count));
  }

  bool _hasUnreadMessages(ReserveOrderDetail order) {
    if (!_seenLoaded) return false;
    final seen = _seenMessageCount ?? 0;
    if (order.notes.length <= seen) return false;
    return order.notes.skip(seen).any((m) => !m.isMe);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReserveOrderDetailCubit, ReserveOrderDetailState>(
      listenWhen: (prev, curr) => prev.detail != curr.detail,
      listener: (context, state) => _markMessagesSeenIfOpen(),
      builder: (context, state) {
        if (state.detail == null) {
          if (state.status == ReserveOrderDetailStatus.error) {
            return Scaffold(
              appBar: AppBar(title: const Text('Reserve Order')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ??
                            'Gagal memuat detail reserve order.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context
                            .read<ReserveOrderDetailCubit>()
                            .fetch(widget.reserveOrderId),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildScaffold(
          context,
          ReserveOrderDetail.fromEntity(state.detail!),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ReserveOrderDetail order) {
    return Scaffold(
      backgroundColor: const Color(backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(whiteColor),
        elevation: 0.6,
        shadowColor: const Color(shadowColor),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              order.unitName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            // Text(
            //   order.unitName,
            //   style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
            // ),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${order.productName} | ${order.projectName}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(grey4Color),
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    "${order.townshipName}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(grey4Color),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(whiteColor),
        child: Column(
          children: [
            _buildHeader(order),
            _buildTabBar(order),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildTimelineTab(order),
                  ),
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildCustomerTab(order),
                  ),
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildAttachmentTab(order),
                  ),
                  _buildMessagesTab(order),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: order.rejected && order.canEdit ? _buildResubmitFooter(order) : null,
    );
  }


  Widget _buildHeader(ReserveOrderDetail order) {
    return Container(
      color: const Color(whiteColor),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(roIconBgColor),
                child: Text(
                  order.avatarInitials,
                  style: const TextStyle(
                    color: Color(roAvatarTextColor),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (order.price != null)
                      Text(
                        _rupiah(order.price!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(grey4Color),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BgIcon(
                asset: icContactDetailPhone,
                onTap: () => _callCustomer(order),
              ),
              BgIcon(
                asset: icContactDetailWA,
                onTap: () => _chatCustomer(order),
              ),
              if (order.canEdit || order.canDelete)
                BgIcon(onTap: () => _openMenu(order)),
            ],
          ),
          if (order.rejected)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: RejectBanner(
                title:
                    'Ditolak di ${order.rejectStage ?? 'tahap ini'} — Perlu Revisi',
                reason: order.rejectReason ?? '',
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildResubmitFooter(ReserveOrderDetail order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: () => _openEditCustomer(order),
            child: const Text(
              'Perbaiki Data Customer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ReserveOrderDetail order) {
    final unread = _hasUnreadMessages(order);
    return Container(
      color: const Color(whiteColor),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(primaryColor),
        unselectedLabelColor: const Color(grey4Color),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: const Color(primaryColor),
        tabs: [
          const Tab(text: 'Timeline'),
          const Tab(text: 'Customer'),
          const Tab(text: 'Attachment'),
          Tab(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Text('Messages'),
                if (unread)
                  Positioned(
                    top: -2,
                    right: -9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(redColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TIMELINE =====================

  Widget _buildTimelineTab(ReserveOrderDetail order) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < order.timeline.length; i++)
            _buildTimelineStep(
              order.timeline[i],
              isLast: i == order.timeline.length - 1,
            ),
          if (order.canTopup && order.canEdit) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(primaryColor),
                    width: 1.4,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => _openTopup(order),
                child: const Text(
                  '+ Top Up Pembayaran',
                  style: TextStyle(
                    color: Color(primaryColor),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    ReserveOrderTimelineStep step, {
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 2),
                _stepDot(step.status),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(grey10Color)),
                  ),
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
                      fontWeight: step.status == ReserveOrderStepStatus.todo
                          ? FontWeight.w600
                          : FontWeight.w700,
                      color: switch (step.status) {
                        ReserveOrderStepStatus.active => const Color(
                          primaryColor,
                        ),
                        ReserveOrderStepStatus.todo => const Color(grey4Color),
                        ReserveOrderStepStatus.done => Colors.black87,
                      },
                    ),
                  ),
                  if (step.sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.sub!,
                      style: TextStyle(
                        fontSize: 10,
                        color: step.subColor ?? const Color(grey4Color),
                      ),
                    ),
                  ],
                  for (final note in step.notes) _buildTimelineNote(note),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(ReserveOrderStepStatus status) {
    final size = status == ReserveOrderStepStatus.active ? 16.0 : 13.0;
    final fill = switch (status) {
      ReserveOrderStepStatus.done => const Color(successColor),
      ReserveOrderStepStatus.active => const Color(primaryColor),
      ReserveOrderStepStatus.todo => const Color(whiteColor),
    };
    final border = switch (status) {
      ReserveOrderStepStatus.done => const Color(successColor),
      ReserveOrderStepStatus.active => const Color(primaryColor),
      ReserveOrderStepStatus.todo => const Color(grey7Color),
    };
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(
        top: status == ReserveOrderStepStatus.active ? 0 : 1.5,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 2),
      ),
    );
  }

  Widget _buildTimelineNote(ReserveOrderTimelineNote note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(grey11Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(grey1Color),
            height: 1.4,
          ),
          children: [
            const TextSpan(text: '💬 '),
            TextSpan(
              text: '${note.who} · ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: note.text),
          ],
        ),
      ),
    );
  }

  // ===================== CUSTOMER =====================

  Widget _buildCustomerTab(ReserveOrderDetail order) {
    final raw = order.customer.raw;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          for (final section in reserveCustomerFieldSections)
            CustomDropdownGroupContact(
              hint: section.title,
              child: Column(
                children: [
                  for (var i = 0; i < section.fields.length; i++)
                    _customerRow(
                      section.fields[i].label,
                      displayValueFor(section.fields[i], raw),
                      onTap: order.canEdit
                          ? () => _openEditCustomer(
                              order,
                              highlightKey: section.fields[i].key,
                            )
                          : null,
                      showDivider: i != section.fields.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _customerRow(
    String label,
    String? value, {
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(grey10Color)))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(grey4Color),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (value != null && value.isNotEmpty) ? value : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '›',
              style: TextStyle(
                fontSize: 18,
                color: Color(grey4Color),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ATTACHMENT =====================

  Widget _buildAttachmentTab(ReserveOrderDetail order) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(roSelectedBgColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.customer.raw['work_category']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final doc in order.requiredDocs) _buildDocRow(order, doc),
        ],
      ),
    );
  }

  Widget _buildDocRow(ReserveOrderDetail order, String docName) {
    final uploaded = order.docsUploaded[docName] ?? false;
    final icon = reserveOrderDocIcons[docName] ?? '📄';
    final files = order.docAttachments[docName] ?? const [];
    if (uploaded || files.isNotEmpty) {
      final anyRejected = files.any((a) => a.isRejected);
      final rejectedCount = files.where((a) => a.isRejected).length;
      final summary = files.isEmpty
          ? 'Terupload'
          : [
              '${files.length} file',
              if (rejectedCount > 0) '$rejectedCount ditolak',
            ].join(' · ');
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: anyRejected
                ? const Color(redColor)
                : const Color(grey10Color),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _docIconBox(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 10,
                          color: anyRejected
                              ? const Color(redColor)
                              : const Color(grey4Color),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _uploadDocument(order, docName),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      '+ Tambah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(primaryColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            for (var i = 0; i < files.length; i++)
              _buildDocFileRow(order, docName, icon, files[i], i + 1),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () => _uploadDocument(order, docName),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(grey7Color), width: 1.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              docName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(grey1Color),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ketuk untuk upload',
              style: TextStyle(fontSize: 10.5, color: Color(grey4Color)),
            ),
          ],
        ),
      ),
    );
  }

  /// Buka halaman "Attachment" yang sama dipakai tab Attachment di Contact Detail (`ContactAddPage`
  /// page 5, `POST /contacts/{contact_id}/attachments`) — Attachment Type-nya di-preset & dikunci
  /// ke dokumen yang di-tap (`reserveOrderId` + `initialAttachmentTypeId` di `ContactDetailArgs`)
  /// supaya upload-nya pasti kehitung di `required_docs.uploaded` order INI. Fetch ulang detail
  /// setelah kembali supaya checklist-nya ikut ter-refresh (baik upload sukses maupun dibatalkan).
  Future<void> _uploadDocument(ReserveOrderDetail order, String docName) async {
    if (order.contactId == null) {
      showSnackbar(
        context,
        'Reserve order ini belum terhubung ke data kontak, tidak bisa upload dokumen.',
        isError: true,
      );
      return;
    }
    final attachmentTypeId = order.docAttachmentTypeIds[docName];
    if (attachmentTypeId == null) return;

    await context.pushNamed(
      'addContact',
      extra: ContactDetailArgs(
        dataContact: ContactEntity(
          contactId: order.contactId,
          fullName: order.customerName,
        ),
        page: 5,
        namePage: 'Attachment',
        reserveOrderId: order.reserveOrderId,
        initialAttachmentTypeId: attachmentTypeId,
        initialAttachmentTypeName: docName,
      ),
    );

    if (!mounted) return;
    await context.read<ReserveOrderDetailCubit>().fetch(order.reserveOrderId);
  }

  void _viewDocument(String url) {
    if (url.isEmpty) return;
    context.pushNamed('attachmentWebView', extra: url);
  }

  Widget _docIconBox(String icon) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(roIconBgColor),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 16)),
    );
  }

  /// Satu file di dalam kartu dokumen — status verifikasinya sendiri2 (1 jenis dokumen bisa
  /// berisi beberapa file). Kalau ditolak reviewer, alasannya (`verification_note`) ditampilkan
  /// supaya sales tahu apa yang harus diperbaiki sebelum upload ulang.
  Widget _buildDocFileRow(
    ReserveOrderDetail order,
    String docName,
    String icon,
    ReserveOrderAttachmentEntity file,
    int number,
  ) {
    final url = file.attachmentPath ?? '';
    final rejectNote = file.verificationNote?.trim() ?? '';
    final (statusLabel, statusColor) = switch (file.verificationStatus) {
      'rejected' => ('Ditolak', const Color(redColor)),
      'approved' => ('Disetujui', const Color(successColor)),
      _ => ('Menunggu verifikasi', const Color(grey4Color)),
    };
    final uploadedAt = file.createDatetime == null
        ? null
        : DateFormat(
            'dd MMM yyyy HH:mm',
          ).format(file.createDatetime!.toLocal());

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openDocFileMenu(order, docName, file, number),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(grey10Color))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                url.isEmpty
                    ? _docIconBox(icon)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: DriveImage(
                          url: url,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          onTap: () => _viewDocument(url),
                          errorWidget: _docIconBox(icon),
                        ),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File $number',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (uploadedAt != null)
                        Text(
                          uploadedAt,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(grey4Color),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (file.isRejected)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(redColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alasan ditolak: ${rejectNote.isEmpty ? '-' : rejectNote}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(redColor),
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDocFileMenu(
    ReserveOrderDetail order,
    String docName,
    ReserveOrderAttachmentEntity file,
    int number,
  ) {
    final url = file.attachmentPath ?? '';
    showCustomBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$docName · File $number',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (url.isNotEmpty)
            _menuItem('👁️', 'Lihat Dokumen', () => _viewDocument(url)),
          _menuItem(
            '⤴️',
            'Upload Ulang',
            () => _reuploadDocument(order, docName, file),
          ),
        ],
      ),
    );
  }

  /// Ganti file dokumen yang sudah terupload — pakai mode edit attachment di `ContactAddPage`
  /// (page 7, `PATCH /contacts/{contact_id}/attachments/{id}`) supaya baris attachment yang sama
  /// (yang sudah tertaut ke reserve order ini) yang diganti filenya.
  Future<void> _reuploadDocument(
    ReserveOrderDetail order,
    String docName,
    ReserveOrderAttachmentEntity attachment,
  ) async {
    final attachmentTypeId = order.docAttachmentTypeIds[docName];
    if (order.contactId == null || attachmentTypeId == null) {
      return _uploadDocument(order, docName);
    }

    await context.pushNamed(
      'addContact',
      extra: ContactDetailArgs(
        dataContact: ContactEntity(
          contactId: order.contactId,
          fullName: order.customerName,
        ),
        dataAttachment: ContactAttachment(
          contactAttachmentId: attachment.contactAttachmentId,
          contactId: order.contactId!,
          attachmentTypeId: attachmentTypeId,
          attachmentUrl: attachment.attachmentPath ?? '',
          attachmentTypeName: docName,
          attachmentNote: '',
          createDatetime: attachment.createDatetime ?? DateTime.now(),
        ),
        page: 7,
        reserveOrderTtsId: attachment.reserveOrderTtsId,
        namePage: 'Attachment',
        reserveOrderId: order.reserveOrderId,
        initialAttachmentTypeId: attachmentTypeId,
        initialAttachmentTypeName: docName,
      ),
    );

    if (!mounted) return;
    await _refresh();
  }

  // ===================== MESSAGES =====================

  Widget _buildMessagesTab(ReserveOrderDetail order) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: order.notes.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: const Center(
                            child: Text(
                              'Belum ada pesan',
                              style: TextStyle(
                                color: Color(grey4Color),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _messageScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: order.notes.length,
                    itemBuilder: (context, index) =>
                        _buildMessageItem(order.notes[index]),
                  ),
          ),
        ),
        if (order.canEdit) _buildMessageInput(order),
      ],
    );
  }

  Widget _buildMessageItem(ReserveOrderChatMessage note) {
    return note.isMe
        ? _buildMessageBubbleRight(note)
        : _buildMessageBubbleLeft(note);
  }

  Widget _messageBubbleContent(
    ReserveOrderChatMessage note, {
    required bool isMe,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(primaryColor).withValues(alpha: 0.1)
            : const Color(grey11Color),
        borderRadius: BorderRadius.circular(12).copyWith(
          topRight: isMe ? Radius.zero : null,
          topLeft: isMe ? null : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bubble punya sendiri ("me" — dari `create_user_id` yang sama dengan user login, lihat
  /// `is_me` di `ReserveOrderService::getDetail()`), rata kanan tanpa avatar, khas chat.
  Widget _buildMessageBubbleRight(ReserveOrderChatMessage note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  note.time,
                  style: const TextStyle(fontSize: 9, color: Color(grey4Color)),
                ),
                const SizedBox(height: 2),
                _messageBubbleContent(note, isMe: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bubble dari orang lain, rata kiri dengan avatar inisial.
  Widget _buildMessageBubbleLeft(ReserveOrderChatMessage note) {
    final initials = note.who.length >= 2
        ? note.who.substring(0, 2).toUpperCase()
        : note.who.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: note.color,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: note.who,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(grey1Color),
                        ),
                      ),
                      if (note.role.isNotEmpty)
                        TextSpan(
                          text: ' · ${note.role}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(grey4Color),
                          ),
                        ),
                      TextSpan(
                        text: ' · ${note.time}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(grey4Color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                _messageBubbleContent(note, isMe: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ReserveOrderDetail order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan…',
                  filled: true,
                  fillColor: const Color(grey11Color),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _sendingMessage ? null : () => _sendMessage(order),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(primaryColor),
                  shape: BoxShape.circle,
                ),
                child: _sendingMessage
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `POST /reserve-order/message/{id}` — baris chat baru cukup didapat dari `getDetail()` yang
  /// dibalikkan (via [ReserveOrderDetailCubit] yang rebuild `order` di `build()`), tidak perlu
  /// di-append manual ke [order.notes].
  Future<void> _sendMessage(ReserveOrderDetail order) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sendingMessage) return;

    setState(() => _sendingMessage = true);

    final error = await context.read<ReserveOrderDetailCubit>().sendMessage(
      order.reserveOrderId,
      text,
    );

    if (!mounted) return;
    setState(() => _sendingMessage = false);

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messageScrollController.hasClients) {
        _messageScrollController.animateTo(
          _messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===================== ACTIONS =====================

  Future<void> _callCustomer(ReserveOrderDetail order) async {
    if (order.phone.isEmpty || order.phone == '-') return;
    await launchUrl(Uri(scheme: 'tel', path: order.phone));
  }

  Future<void> _chatCustomer(ReserveOrderDetail order) async {
    if (order.phone.isEmpty || order.phone == '-') return;
    var phone = order.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }
    await launchUrl(
      Uri.parse('https://wa.me/$phone'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openMenu(ReserveOrderDetail order) {
    showCustomBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Reserve Order',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (order.canEdit)
            _menuItem('✎', 'Edit Data Pembeli', () => _openEditCustomer(order)),
          if (order.canDelete)
            _menuItem(
              '🗑️',
              'Delete Reserve Order',
              () => _confirmDelete(order),
              color: const Color(redColor),
            ),
        ],
      ),
    );
  }

  void _openTopup(ReserveOrderDetail order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopupReserveOrderPage(
          reserveOrderId: order.reserveOrderId,
          unitName: order.unitName,
          customerName: order.customerName,
          currentStatus: order.rejected ? 'Ditolak' : 'Diproses',
          totalPaidSoFar: order.totalPaidSoFar,
        ),
      ),
    );
  }

  /// Detail page-nya bersumber dari [ReserveOrderDetailCubit] — begitu `update` sukses, cubit
  /// emit detail baru & `BlocBuilder` di `build()` otomatis rebuild dgn data terbaru, jadi tidak
  /// perlu lagi merge manual hasil balik halaman ini ke `order`.
  Future<void> _openEditCustomer(
    ReserveOrderDetail order, {
    String? highlightKey,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCustomerReserveOrderPage(
          reserveOrderId: order.reserveOrderId,
          customer: order.customer,
          highlightKey: highlightKey,
        ),
      ),
    );
  }

  /// `DELETE /reserve-order/{id}` — hard delete PERMANEN (TTS, item pembayaran, dokumen, log
  /// aktivitas ikut terhapus). Begitu sukses, halaman ini pop dgn `true` supaya List Reserve Order
  /// (yang menunggu hasil push-nya) tahu harus refresh.
  Future<void> _confirmDelete(ReserveOrderDetail order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Reserve Order?'),
        content: Text(
          'Hapus Reserve Order ${order.unitName} a.n. ${order.customerName}? '
          'Seluruh riwayat pembayaran (TTS) & dokumen ikut terhapus PERMANEN — tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Color(redColor)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context.read<ReserveOrderDetailCubit>().delete(
      order.reserveOrderId,
    );

    if (!mounted) return;

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  Widget _menuItem(
    String icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 16,
                color: color ?? const Color(grey1Color),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _rupiah(int value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(value);
