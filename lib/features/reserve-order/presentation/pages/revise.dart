import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/thousands_input_formatter.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';

/// "Perbaiki Reserve Order" — Bagian 3 mockup, kolom "Edit & Ajukan Ulang".
///
/// Hanya dibuka dari transaksi yang ditolak kasir: dokumen yang ditolak diunggah ulang, nominal
/// dibetulkan, lalu diajukan lagi sehingga transaksinya balik ke tahap Diproses.
class ReserveOrderRevisePage extends StatefulWidget {
  final ReserveOrder order;

  const ReserveOrderRevisePage({super.key, required this.order});

  @override
  State<ReserveOrderRevisePage> createState() => _ReserveOrderRevisePageState();
}

class _ReserveOrderRevisePageState extends State<ReserveOrderRevisePage> {
  final nominalTC = TextEditingController();
  final catatanTC = TextEditingController();

  /// File pengganti per posisi dokumen di `order.docs`, baru ditulis balik saat Submit Ulang.
  final Map<int, PickedFileResult> _replacements = {};

  bool _submitting = false;

  ReserveOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_revise');
    if (order.paidSoFar > 0) nominalTC.text = NumberHelper.thousands(order.paidSoFar);
  }

  @override
  void dispose() {
    nominalTC.dispose();
    catatanTC.dispose();
    super.dispose();
  }

  num? get _nominal {
    final digits = nominalTC.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return num.tryParse(digits);
  }

  /// Harga unit diambil dari label harga transaksi supaya peringatan kekurangannya ikut berubah
  /// begitu nominalnya diketik.
  num? get _unitPrice {
    final digits = (order.priceLabel ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return num.tryParse(digits);
  }

  num? get _shortfall {
    final price = _unitPrice;
    final nominal = _nominal;
    if (price == null || nominal == null || nominal >= price) return null;
    return price - nominal;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: const Color(whiteColor),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              roAppBar(
                title: 'Fix Reserve Order',
                subtitle: order.customerName,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.rejectReason != null) roRejectBanner(order.rejectReason!),
                      roSectionLabel('Identity Documents'),
                      for (final index in _docIndexes(payment: false)) roDocTile(_docAt(index), onTap: () => _pickReplacement(index)),
                      const SizedBox(height: 6),
                      roSectionLabel('Payment Proof'),
                      for (final index in _docIndexes(payment: true)) roDocTile(_docAt(index), onTap: () => _pickReplacement(index)),
                      const SizedBox(height: 4),
                      roFieldLabel('Payment Amount'),
                      roInput(
                        nominalTC,
                        hint: 'Rp 0',
                        keyboardType: TextInputType.number,
                        inputFormatters: const [ThousandsInputFormatter()],
                        hasError: _shortfall != null,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_shortfall != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Short by Rp ${NumberHelper.thousands(_shortfall!)} from the unit price (${order.priceLabel})',
                            style: const TextStyle(fontSize: 10, color: Color(redColor)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      roFieldLabel('Notes'),
                      roInput(
                        catatanTC,
                        hint: 'E.g.: customer will transfer the shortfall next week',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              roFooter([roPrimaryButton('Resubmit', _onSubmit, loading: _submitting)]),
            ],
          ),
        ),
      ),
    );
  }

  List<int> _docIndexes({required bool payment}) {
    return [
      for (var i = 0; i < order.docs.length; i++)
        if (order.docs[i].isPaymentProof == payment) i,
    ];
  }

  /// Dokumen yang digambar: file pengganti kalau sudah dipilih, kalau belum ya versi aslinya.
  /// Yang ditolak diberi teks ajakan supaya jelas barisnya harus ditekan.
  ReserveOrderDoc _docAt(int index) {
    final doc = order.docs[index];
    final replacement = _replacements[index];

    if (replacement != null) {
      return doc.copyWith(
        name: replacement.name,
        badge: '· Replacement',
        status: 'Uploaded · ${_fileSize(replacement)}',
        state: ReserveOrderDocState.uploaded,
      );
    }
    if (doc.state == ReserveOrderDocState.rejected) {
      return doc.copyWith(status: 'Tap to re-upload');
    }
    return doc;
  }

  Future<void> _pickReplacement(int index) async {
    if (_submitting) return;
    AnalyticsService.logEvent('reserve_order_revise_upload');
    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData) return;
    if (!mounted) return;
    setState(() => _replacements[index] = picked);
  }

  Future<void> _onSubmit() async {
    final pendingRejected = _docIndexes(payment: true).where((i) => order.docs[i].state == ReserveOrderDocState.rejected && !_replacements.containsKey(i));
    if (pendingRejected.isNotEmpty) {
      showSnackbar(context, 'Rejected documents must be re-uploaded', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Payment amount is required', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_revise_submit');
    setState(() => _submitting = true);

    // Berdiri di tempat panggilan `PUT /api/reserve/{id}` nanti; sekarang perubahannya cuma ditulis
    // ke objek transaksi di memori.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _applyRevision(nominal);
    setState(() => _submitting = false);

    showSnackbar(context, 'Reserve Order resubmitted, awaiting cashier verification.');
    context.pop();
  }

  /// Menulis hasil revisi ke transaksi: dokumen pengganti, status balik ke Diproses, dan catatan
  /// pengajuan ulang di timeline maupun tab Catatan.
  void _applyRevision(num nominal) {
    final now = DateTime.now();
    final stamp = DateFormat('dd MMM, HH:mm').format(now);
    final catatan = catatanTC.text.trim();
    final quoted = catatan.isEmpty ? '' : ' — "$catatan"';

    _replacements.forEach((index, file) {
      order.docs[index] = order.docs[index].copyWith(
        name: file.name,
        badge: '· Resubmitted',
        status: 'Uploaded · ${_fileSize(file)}',
        state: ReserveOrderDocState.pending,
      );
    });

    order.status = ReserveOrderStatus.diproses;
    order.statusText = 'Still Processing';
    order.rejectReason = null;

    final activeStep = order.journey.firstWhere(
      (step) => step.state == ReserveOrderStepState.active,
      orElse: () => order.journey.last,
    );
    activeStep.sub = 'Resubmitted ${DateFormat('dd MMM yyyy').format(now)} · Rp ${NumberHelper.thousands(nominal)} — under verification';
    activeStep.subIsError = false;
    activeStep.notes.add(ReserveOrderTimelineNote(
      who: 'System ·',
      text: 'Reserve Order resubmitted with an amount of Rp ${NumberHelper.thousands(nominal)}$quoted',
      time: '($stamp)',
    ));

    order.notes.add(ReserveOrderNote(
      author: 'System',
      role: 'automated',
      roleKind: ReserveOrderNoteRole.sistem,
      time: stamp,
      text: 'Reserve Order resubmitted with an amount of Rp ${NumberHelper.thousands(nominal)}$quoted.',
    ));
  }

  String _fileSize(PickedFileResult file) {
    final bytes = file.bytes?.lengthInBytes ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
