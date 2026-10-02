import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_loading.dart';
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

  /// Lampiran yang dipilih untuk pesan berikutnya (dikirim bareng teks, boleh tanpa teks).
  PickedFileResult? _messageAttachment;

  /// Attachment yang SUDAH ADA di order ini yang dilampirkan ke pesan berikutnya (mis. Bukti
  /// Transfer yang mau ditanyakan) — eksklusif dengan [_messageAttachment]; backend memakai ulang
  /// file-nya & menulis detailnya di pesan.
  ({String docName, ReserveOrderAttachmentEntity file})? _messageRefAttachment;
  final _messageFocusNode = FocusNode();

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
    _messageFocusNode.dispose();
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
      bottomNavigationBar: order.rejected && order.canEdit
          ? _buildResubmitFooter(order)
          : null,
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

  Widget _fittedTab(Widget label) => Tab(
    child: FittedBox(fit: BoxFit.scaleDown, child: label),
  );

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
        // 4 tab fixed: padding default 16px/sisi bikin label panjang ("Attachment") kepotong
        // di layar sempit — padding dikecilkan + FittedBox supaya label mengecil kalau perlu.
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: [
          _fittedTab(const Text('Timeline')),
          _fittedTab(const Text('Customer')),
          _fittedTab(const Text('Attachment')),
          _fittedTab(
            Stack(
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

  /// Pesan terakhir di tahap timeline (`latest_message`) — disamakan dengan web: teks pesan,
  /// lalu `who · time` di bawahnya, dengan aksen garis di kiri.
  Widget _buildTimelineNote(ReserveOrderTimelineNote note) {
    final meta = [
      note.who,
      note.time,
    ].where((s) => (s ?? '').trim().isNotEmpty).join(' · ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(grey11Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: const Color(primaryColor).withValues(alpha: 0.35),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 12,
                    color: Color(grey1Color),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    note.text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                meta,
                style: const TextStyle(fontSize: 9.5, color: Color(grey4Color)),
              ),
            ],
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
          _buildAddNewFileCard(order),
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

  /// Kartu "Add New File" (sama seperti di tab Attachment Contact Detail) — upload bebas tanpa
  /// harus tap salah satu dokumen wajib; Attachment Type dipilih sendiri di halaman upload.
  Widget _buildAddNewFileCard(ReserveOrderDetail order) {
    return GestureDetector(
      onTap: () => _uploadDocument(order, null),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          border: Border.all(color: const Color(grey10Color)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            BgIcon(
              asset: icUpload,
              color: const Color(primaryColor),
              onTap: () => _uploadDocument(order, null),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New File',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(primaryColor),
                  ),
                ),
                Text(
                  'upload new file',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(grey5Color),
                  ),
                ),
              ],
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
  /// [docName] null = dari kartu "Add New File": tipe tidak di-preset, user pilih sendiri
  /// (dropdown tidak dikunci karena `initialAttachmentTypeId` kosong).
  /// [postToMessage] true = dari kotak "Attachment" di tab Messages: file yang diupload ikut
  /// dicatat sebagai pesan (Attachment Type + deskripsi jadi teks pesannya).
  Future<void> _uploadDocument(
    ReserveOrderDetail order,
    String? docName, {
    bool postToMessage = false,
  }) async {
    if (order.contactId == null) {
      showSnackbar(
        context,
        'Reserve order ini belum terhubung ke data kontak, tidak bisa upload dokumen.',
        isError: true,
      );
      return;
    }
    final attachmentTypeId = docName == null
        ? null
        : order.docAttachmentTypeIds[docName];
    if (docName != null && attachmentTypeId == null) return;

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
        postToReserveOrderMessage: postToMessage,
      ),
    );

    if (!mounted) return;
    await context.read<ReserveOrderDetailCubit>().fetch(order.reserveOrderId);
    if (mounted && postToMessage) _scrollMessagesToBottom();
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
    final (statusLabel, statusColor) = _verificationBadge(
      file.verificationStatus,
    );
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

  /// `DELETE /contacts/{contact_id}/attachments/{id}` — baris d_contact_attachment & file Drive-nya
  /// terhapus permanen (pesan yang melampirkan file ini jadi tidak bisa membukanya lagi).
  Future<void> _confirmDeleteAttachment(
    ReserveOrderDetail order,
    String docName,
    ReserveOrderAttachmentEntity file,
    int number,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?'),
        content: Text(
          'Hapus $docName · File $number? '
          '${file.verificationStatus == 'approved' ? 'File ini sudah Disetujui. ' : ''}'
          'File ikut terhapus dari Google Drive, termasuk lampirannya di pesan — '
          'tindakan ini tidak bisa dibatalkan.',
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

    final cubit = context.read<ReserveOrderDetailCubit>();
    final error = await _runWithLoading(
      'Menghapus dokumen…',
      () => cubit.deleteAttachment(
        reserveOrderId: order.reserveOrderId,
        contactId: order.contactId!,
        attachmentId: file.contactAttachmentId,
      ),
    );
    if (!mounted) return;

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    if (_messageRefAttachment?.file.contactAttachmentId ==
        file.contactAttachmentId) {
      setState(() => _messageRefAttachment = null);
    }
    showSnackbar(context, 'Dokumen berhasil dihapus.');
  }

  (String, Color) _verificationBadge(String? status) => switch (status) {
    'rejected' => ('Ditolak', const Color(redColor)),
    'approved' => ('Disetujui', const Color(successColor)),
    _ => ('Menunggu verifikasi', const Color(grey4Color)),
  };

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
          if (order.canEdit)
            _menuItem(
              '💬',
              'Tanyakan di Pesan',
              () => _attachExistingToMessage(docName, file),
            ),
          _menuItem(
            '⤴️',
            'Upload Ulang',
            () => _reuploadDocument(order, docName, file),
          ),
          if (order.contactId != null &&
              PermissionsHelper.canDeleteAttachmentItem)
            _menuItem(
              '🗑️',
              'Hapus',
              () => _confirmDeleteAttachment(order, docName, file, number),
              color: const Color(redColor),
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
          if (note.hasMeta) ...[
            _messageMeta(note),
            if (note.hasAttachment || note.text.isNotEmpty)
              const SizedBox(height: 6),
          ],
          if (note.hasAttachment) _messageAttachmentTile(note),
          if (note.hasAttachment && note.text.isNotEmpty)
            const SizedBox(height: 6),
          if (note.text.isNotEmpty)
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

  /// Blok info pesan dari form Tulis Pesan (web) — Customer, Dihubungi oleh, Status, Follow Up.
  Widget _messageMeta(ReserveOrderChatMessage note) {
    Widget row(String label, String? value) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: (value ?? '').isNotEmpty ? value : '-',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      style: const TextStyle(
        fontSize: 10.5,
        color: Color(grey4Color),
        height: 1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Customer', note.customer),
        row('Dihubungi oleh', note.contactedBy),
        row('Status', note.status),
        if ((note.followUp ?? '').isNotEmpty) row('Follow Up', note.followUp),
      ],
    );
  }

  Widget _messageAttachmentTile(ReserveOrderChatMessage note) {
    final name = (note.attachmentName ?? '').isNotEmpty
        ? note.attachmentName!
        : 'Lampiran';
    final lower = name.toLowerCase();
    final url = note.attachmentUrl ?? '';
    final isImage = RegExp(r'\.(jpe?g|png|webp|heic)$').hasMatch(lower);

    // Gambar: langsung preview kecil (thumbnail Drive), tap buka penuh.
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DriveImage(
          url: url,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          onTap: () => _viewDocument(url),
          errorWidget: _messageFileChip(name, Icons.image_outlined, url),
        ),
      );
    }

    if (lower.endsWith('.pdf')) return _messagePdfPreview(name, url);

    return _messageFileChip(name, Icons.insert_drive_file_outlined, url);
  }

  /// PDF: thumbnail halaman pertama dari Drive + strip nama file di bawah. Kalau link bukan
  /// Drive, balik ke chip nama file; kalau thumbnail gagal dimuat, tampil ikon PDF besar.
  Widget _messagePdfPreview(String name, String url) {
    final fallback = _messageFileChip(name, Icons.picture_as_pdf_outlined, url);
    if (!url.contains('drive.google.com')) return fallback;

    return GestureDetector(
      onTap: () => _viewDocument(url),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(grey10Color)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DriveImage: mobile -> drive.google.com/thumbnail, web (PWA) -> CDN lh3 yang
            // aman CORS. Keduanya kasih render halaman pertama PDF.
            DriveImage(
              url: url,
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 160,
                height: 120,
                color: const Color(grey11Color),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 40,
                  color: Color(redColor),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 16,
                    color: Color(redColor),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageFileChip(String name, IconData icon, String url) {
    return InkWell(
      onTap: () => _viewDocument(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(grey10Color)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(primaryColor)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(primaryColor),
                ),
              ),
            ),
          ],
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_messageAttachment != null || _messageRefAttachment != null)
              _buildPendingAttachment(order),
            Row(
              children: [
                InkWell(
                  onTap: _sendingMessage
                      ? null
                      : () => _pickMessageAttachment(order),
                  borderRadius: BorderRadius.circular(18),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.attach_file,
                      color: Color(grey4Color),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
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
          ],
        ),
      ),
    );
  }

  /// Lampiran yang menunggu dikirim: file baru dari Kamera/Galeri/Dokumen ([_messageAttachment])
  /// ATAU attachment yang sudah ada di order ini ([_messageRefAttachment]) beserta detailnya.
  Widget _buildPendingAttachment(ReserveOrderDetail order) {
    final file = _messageAttachment;
    final ref = _messageRefAttachment;
    final Widget leading;
    final Widget body;
    if (file != null) {
      leading = file.isImage
          ? FilePreviewWidget(file: file, size: 44)
          : Icon(
              file.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.insert_drive_file_outlined,
              size: 18,
              color: const Color(primaryColor),
            );
      body = Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, color: Colors.black87),
      );
    } else {
      leading = _attachmentThumb(ref!.file, ref.docName, 44);
      body = _attachmentDetail(order, ref.docName, ref.file);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: const Color(grey11Color),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(child: body),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18, color: Color(grey4Color)),
              onPressed: _sendingMessage
                  ? null
                  : () => setState(() {
                      _messageAttachment = null;
                      _messageRefAttachment = null;
                    }),
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail Drive kecil satu attachment order (fallback ikon dokumennya).
  Widget _attachmentThumb(
    ReserveOrderAttachmentEntity file,
    String docName,
    double size,
  ) {
    final icon = reserveOrderDocIcons[docName] ?? '📄';
    final url = file.attachmentPath ?? '';
    if (url.isEmpty) return _docIconBox(icon);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DriveImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: _docIconBox(icon),
      ),
    );
  }

  /// Detail satu attachment order: nama dokumen, status verifikasi, No. TTS (kalau terikat ke
  /// TTS), tanggal upload, dan deskripsinya — sama dengan yang ikut terbawa di pesan.
  Widget _attachmentDetail(
    ReserveOrderDetail order,
    String docName,
    ReserveOrderAttachmentEntity file,
  ) {
    final ttsNumber = order.ttsNumbers[file.reserveOrderTtsId];
    final (statusLabel, statusColor) = _verificationBadge(
      file.verificationStatus,
    );
    final note = file.attachmentNote?.trim() ?? '';
    final meta = [
      if (ttsNumber != null) 'TTS $ttsNumber',
      if (file.createDatetime != null)
        DateFormat('dd MMM yyyy HH:mm').format(file.createDatetime!.toLocal()),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          docName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (meta.isNotEmpty) TextSpan(text: ' · $meta'),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9.5, color: Color(grey4Color)),
        ),
        if (note.isNotEmpty)
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
      ],
    );
  }

  Future<void> _pickMessageAttachment(ReserveOrderDetail order) async {
    // Foto dikecilkan (maks 1600px, JPEG 75%) supaya upload cepat — tetap jelas dibaca.
    final result = await CustomFilePicker.show(
      context,
      imageMaxDimension: 1600,
      imageQuality: 75,
      onAttachment: () => _chooseAttachmentForMessage(order),
    );
    if (!mounted || result == null || !result.hasData) return;
    setState(() {
      _messageAttachment = result;
      _messageRefAttachment = null;
    });
  }

  /// Kotak "Attachment": upload file baru lewat halaman Attachment (file + Attachment Type +
  /// deskripsi, ikut masuk jadi pesan) ATAU pilih attachment yang sudah ada di order ini untuk
  /// ditanyakan — detail file-nya ikut terbawa di pesan. Belum ada attachment = langsung upload.
  void _chooseAttachmentForMessage(ReserveOrderDetail order) {
    final existing = [
      for (final entry in order.docAttachments.entries)
        for (final file in entry.value) (docName: entry.key, file: file),
    ];
    if (existing.isEmpty) {
      _uploadDocument(order, null, postToMessage: true);
      return;
    }

    showCustomBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Attachment',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          _menuItem(
            '⤴️',
            'Upload File Baru',
            () => _uploadDocument(order, null, postToMessage: true),
          ),
          const Divider(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Pilih dari attachment yang sudah ada',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(grey4Color),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: existing.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (sheetContext, index) {
                final item = existing[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _attachExistingToMessage(item.docName, item.file);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        _attachmentThumb(item.file, item.docName, 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _attachmentDetail(
                            order,
                            item.docName,
                            item.file,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lampirkan attachment yang sudah ada ke pesan berikutnya — pindah ke tab Messages & fokus ke
  /// kolom teks supaya user langsung bisa menulis pertanyaannya.
  void _attachExistingToMessage(
    String docName,
    ReserveOrderAttachmentEntity file,
  ) {
    setState(() {
      _messageRefAttachment = (docName: docName, file: file);
      _messageAttachment = null;
    });
    _tabController.animateTo(_messagesTabIndex);
    // Kolom teks di tab Messages baru ter-build setelah animasi pindah tab selesai.
    Future.delayed(kTabScrollDuration, () {
      if (mounted) _messageFocusNode.requestFocus();
    });
  }

  void _scrollMessagesToBottom() {
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

  /// `POST /reserve-order/message/{id}` — baris chat baru cukup didapat dari `getDetail()` yang
  /// dibalikkan (via [ReserveOrderDetailCubit] yang rebuild `order` di `build()`), tidak perlu
  /// di-append manual ke [order.notes].
  Future<void> _sendMessage(ReserveOrderDetail order) async {
    final text = _messageController.text.trim();
    final attachment = _messageAttachment;
    final ref = _messageRefAttachment;
    if ((text.isEmpty && attachment == null && ref == null) ||
        _sendingMessage) {
      return;
    }

    setState(() => _sendingMessage = true);

    final error = await context.read<ReserveOrderDetailCubit>().sendMessage(
      order.reserveOrderId,
      text,
      attachmentBytes: attachment?.bytes,
      attachmentPath: attachment?.path,
      attachmentName: attachment?.name,
      contactAttachmentId: ref?.file.contactAttachmentId,
    );

    if (!mounted) return;
    setState(() => _sendingMessage = false);

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    _messageController.clear();
    setState(() {
      _messageAttachment = null;
      _messageRefAttachment = null;
    });
    _scrollMessagesToBottom();
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

    final cubit = context.read<ReserveOrderDetailCubit>();
    final error = await _runWithLoading(
      'Menghapus reserve order…',
      () => cubit.delete(order.reserveOrderId),
    );

    if (!mounted) return;

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  /// Jalankan [task] sambil menampilkan loading yang tidak bisa ditutup, supaya user tahu proses
  /// hapus (DB + file di Google Drive, bisa beberapa detik) masih berjalan. Navigator-nya diambil
  /// SEBELUM menunggu supaya loading tetap tertutup walau halaman sudah di-dispose.
  Future<T> _runWithLoading<T>(
    String message,
    Future<T> Function() task,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showLoadingDialog(true, context, message: message);
    try {
      return await task();
    } finally {
      navigator.pop();
    }
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
