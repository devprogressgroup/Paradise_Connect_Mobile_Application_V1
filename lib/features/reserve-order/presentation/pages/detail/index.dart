import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/core/utils/widget/reject_banner.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_detail_dummy_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_customer_data.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_detail.dart';

import '../edit-customer/index.dart';
import '../top-up/index.dart';

class ReserveOrderDetailPage extends StatefulWidget {
  final bool initiallyRejected;

  const ReserveOrderDetailPage({super.key, this.initiallyRejected = false});

  @override
  State<ReserveOrderDetailPage> createState() => _ReserveOrderDetailPageState();
}

class _ReserveOrderDetailPageState extends State<ReserveOrderDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _messageController = TextEditingController();
  final _messageScrollController = ScrollController();
  late final ReserveOrderDetail _order =
      const ReserveOrderDetailDummyDataSource().getOrder(
        rejected: widget.initiallyRejected,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
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
            const Text(
              'Reserve Order',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              order.unitName,
              style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(whiteColor),
        child: Column(
          children: [
            _buildHeader(order),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimelineTab(order),
                  _buildCustomerTab(order),
                  _buildAttachmentTab(order),
                  _buildMessagesTab(order),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: order.rejected ? _buildResubmitFooter(order) : null,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [order.unitName, order.unitSub, order.phone].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(grey4Color),
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
            onPressed: () => order.rejectFixIsCustomerData
                ? _openEditCustomer(order)
                : _openResubmitPayment(order),
            child: Text(
              order.rejectFixIsCustomerData
                  ? 'Perbaiki Data Customer'
                  : 'Edit & Ajukan Ulang',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
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
        tabs: const [
          Tab(text: 'Timeline'),
          Tab(text: 'Customer'),
          Tab(text: 'Attachment'),
          Tab(text: 'Messages'),
        ],
      ),
    );
  }

  // ===================== TIMELINE =====================

  Widget _buildTimelineTab(ReserveOrderDetail order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < order.timeline.length; i++)
            _buildTimelineStep(
              order.timeline[i],
              isLast: i == order.timeline.length - 1,
            ),
          if (order.canTopup) ...[
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
                      onTap: () => _openEditCustomer(
                        order,
                        highlightKey: section.fields[i].key,
                      ),
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
    required VoidCallback onTap,
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
    if (uploaded) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(grey10Color)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(roIconBgColor),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
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
                  const Text(
                    'Terupload',
                    style: TextStyle(fontSize: 10, color: Color(grey4Color)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Color(successColor),
              size: 18,
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () => setState(() => order.docsUploaded[docName] = true),
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

  // ===================== MESSAGES =====================

  Widget _buildMessagesTab(ReserveOrderDetail order) {
    return Column(
      children: [
        Expanded(
          child: order.notes.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pesan',
                    style: TextStyle(color: Color(grey4Color), fontSize: 12),
                  ),
                )
              : ListView.builder(
                  controller: _messageScrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: order.notes.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(order.notes[index]),
                ),
        ),
        _buildMessageInput(order),
      ],
    );
  }

  Widget _buildMessageItem(ReserveOrderChatMessage note) {
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(grey11Color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
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
                              TextSpan(
                                text: ' · ${note.role}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(grey4Color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        note.time,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(grey4Color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
              onTap: () => _sendMessage(order),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(primaryColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ReserveOrderDetail order) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      order.notes.add(
        ReserveOrderChatMessage(
          who: 'Anda',
          role: 'Sales',
          time: 'baru saja',
          text: text,
          color: const Color(primaryColor),
        ),
      );
      _messageController.clear();
    });
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

  void _callCustomer(ReserveOrderDetail order) =>
      _showComingSoon('Menelepon ${order.phone}');

  void _chatCustomer(ReserveOrderDetail order) =>
      _showComingSoon('Membuka WhatsApp ke ${order.phone}');

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
          _menuItem(
            '✎',
            'Edit Reserve Order',
            () => _showComingSoon('Edit Reserve Order'),
          ),
          _menuItem(
            '🗑️',
            'Delete Reserve Order',
            () => _confirmDelete(order),
            color: const Color(redColor),
          ),
          _menuItem('🔗', 'Share Reserve Order', () => _shareOrder(order)),
        ],
      ),
    );
  }

  void _openTopup(ReserveOrderDetail order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopupReserveOrderPage(
          unitName: order.unitName,
          customerName: order.customerName,
          currentStatus: order.rejected ? 'Ditolak' : 'Diproses',
          totalPaidSoFar: order.totalPaidSoFar,
        ),
      ),
    );
  }

  void _openResubmitPayment(ReserveOrderDetail order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopupReserveOrderPage(
          unitName: order.unitName,
          customerName: order.customerName,
          currentStatus: 'Ditolak',
          totalPaidSoFar: order.totalPaidSoFar,
          isResubmit: true,
          rejectReason: order.rejectReason,
          suggestedAmount: order.price != null
              ? order.price! - order.totalPaidSoFar
              : null,
        ),
      ),
    );
  }

  Future<void> _openEditCustomer(
    ReserveOrderDetail order, {
    String? highlightKey,
  }) async {
    final updated = await Navigator.of(context).push<ReserveOrderCustomerData>(
      MaterialPageRoute(
        builder: (_) => EditCustomerReserveOrderPage(
          customer: order.customer,
          highlightKey: highlightKey,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      order.customer = updated;
      order.customerName = updated.nama ?? order.customerName;
      order.phone = updated.hp ?? order.phone;
    });
  }

  Future<void> _confirmDelete(ReserveOrderDetail order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Reserve Order?'),
        content: Text(
          'Hapus Reserve Order ${order.unitName} a.n. ${order.customerName}? Tindakan ini tidak bisa dibatalkan.',
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
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  void _shareOrder(ReserveOrderDetail order) {
    Clipboard.setData(
      ClipboardData(
        text: 'https://devconnect.paradise.id/reserve-order/${order.unitName}',
      ),
    );
    _showComingSoon('Link Reserve Order disalin ke clipboard (simulasi)');
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature belum tersedia')));
  }
}

String _rupiah(int value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(value);
