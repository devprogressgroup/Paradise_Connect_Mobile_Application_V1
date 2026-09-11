import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/thousands_input_formatter.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';

/// Top Up Pembayaran — Bagian 3 mockup, kolom "Top Up Pembayaran" & "Top Up Diajukan".
///
/// Dipakai untuk menaikkan transaksi dari Reserve ke Booking Reserve: upload bukti transfer baru,
/// isi nominal, lalu ajukan. Pengajuannya masuk ke timeline & catatan transaksi sebagai entri
/// "menunggu verifikasi" — nominalnya belum menambah total dibayar sampai kasir menyetujui.
class ReserveOrderTopUpPage extends StatefulWidget {
  final ReserveOrder order;

  const ReserveOrderTopUpPage({super.key, required this.order});

  @override
  State<ReserveOrderTopUpPage> createState() => _ReserveOrderTopUpPageState();
}

class _ReserveOrderTopUpPageState extends State<ReserveOrderTopUpPage> {
  final nominalTC = TextEditingController();
  final catatanTC = TextEditingController();

  PickedFileResult? _proof;
  bool _submitting = false;
  bool _submitted = false;
  num _submittedAmount = 0;

  ReserveOrder get order => widget.order;

  static const String _transactionType = 'Top Up Booking Reserve';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_top_up');
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
              if (!_submitted)
                roAppBar(
                  title: 'Top Up Payment',
                  subtitle: '${order.unitLabel} · ${order.customerName}',
                  onBack: () => context.pop(),
                ),
              Expanded(child: _submitted ? _buildSukses() : _buildForm()),
              roFooter([
                _submitted
                    ? roPrimaryButton('Back to Reserve Order', () => context.pop())
                    : roPrimaryButton('Submit Top Up', _onSubmit, loading: _submitting),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(grey10Color)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                roSummaryLine('Current Status', order.stageLabel),
                roSummaryLine('Total Paid So Far', 'Rp ${NumberHelper.thousands(order.paidSoFar)}'),
                roSummaryLine('Transaction Type', _transactionType, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          roFieldLabel('Top Up Transfer Proof'),
          roDocTile(_proofDoc, onTap: _submitting ? null : _pickProof),
          const SizedBox(height: 6),
          roFieldLabel('Top Up Amount'),
          roInput(
            nominalTC,
            hint: 'Rp 0',
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsInputFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          roFieldLabel('Notes'),
          roInput(
            catatanTC,
            hint: 'E.g.: customer commits to an additional down payment, will proceed to Booking Reserve',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// Slot bukti transfer: sebelum ada file dia jadi tombol upload, sesudahnya menampilkan nama &
  /// ukuran file yang dipilih.
  ReserveOrderDoc get _proofDoc {
    final proof = _proof;
    if (proof == null) {
      return const ReserveOrderDoc(
        icon: Icons.receipt_long_outlined,
        name: 'Upload new transfer proof',
        badge: '· Required',
        status: 'Tap to upload',
        state: ReserveOrderDocState.awaitingUpload,
        isPaymentProof: true,
      );
    }

    return ReserveOrderDoc(
      icon: proof.isPdf ? Icons.picture_as_pdf_outlined : Icons.receipt_long_outlined,
      name: proof.name,
      badge: '· Required',
      status: 'Uploaded · ${_fileSize(proof)}',
      isPaymentProof: true,
    );
  }

  Widget _buildSukses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 10),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(roSuccessBgColor), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 32, color: Color(successColor)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Up Successfully Submitted',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
          const SizedBox(height: 6),
          Text(
            '$_transactionType of Rp ${NumberHelper.thousands(_submittedAmount)} for ${order.unitLabel} is being verified.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.6, color: Color(grey4Color)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(grey10Color)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total after top up',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                      ),
                      Text(
                        'Rp ${NumberHelper.thousands(order.paidSoFar)} + Rp ${NumberHelper.thousands(_submittedAmount)}',
                        style: const TextStyle(fontSize: 9.5, color: Color(grey4Color)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(warningColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(whiteColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProof() async {
    AnalyticsService.logEvent('reserve_order_top_up_upload_bukti');
    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData) return;
    if (!mounted) return;
    setState(() => _proof = picked);
  }

  Future<void> _onSubmit() async {
    if (_proof == null) {
      showSnackbar(context, 'Top up transfer proof is required', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Top up amount is required', isError: true);
      return;
    }
    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) {
      showSnackbar(context, 'Reserve order not recognized, please start over', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_top_up_submit');
    setState(() => _submitting = true);

    final proof = _proof!;
    final catatan = catatanTC.text.trim();

    try {
      // Beda dari `_uploadExtraDoc` (tab Attachment di halaman Detail): Top Up bikin TTS BARU
      // (sama seperti submit awal di reserve.dart), bukan menambah dokumen ke TTS yang sudah ada —
      // jadi `reserveOrderTtsId` SENGAJA tidak dikirim, sesuai instruksi eksplisit.
      await context.read<ReserveOrderListCubit>().dataSource.submitDocPayment(DocPaymentParams(
            reserveOrderId: reserveOrderId,
            ttsAmountRp: nominal,
            note: catatan.isEmpty ? null : catatan,
            buktiTransferBytes: [proof.bytes!],
            buktiTransferFileNames: [proof.name],
          ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
      return;
    }
    if (!mounted) return;

    _applyTopUp(nominal);
    setState(() {
      _submitting = false;
      _submitted = true;
      _submittedAmount = nominal;
    });
  }

  /// Menempelkan hasil pengajuan ke transaksi: dokumen bukti top up (menunggu verifikasi), catatan
  /// di tahap berjalan, dan satu entri di tab Catatan — persis seperti contoh Luthfi di mockup.
  void _applyTopUp(num nominal) {
    final amount = 'Rp ${NumberHelper.thousands(nominal)}';
    final catatan = catatanTC.text.trim();
    final now = DateFormat('dd MMM, HH:mm').format(DateTime.now());
    final quoted = catatan.isEmpty ? '' : ' — "$catatan"';

    order.docs.add(ReserveOrderDoc(
      icon: Icons.credit_card,
      name: 'Top Up Proof',
      badge: '· $amount',
      status: 'Awaiting verification',
      state: ReserveOrderDocState.pending,
      isPaymentProof: true,
    ));

    final activeStep = order.journey.firstWhere(
      (step) => step.state == ReserveOrderStepState.active,
      orElse: () => order.journey.last,
    );
    activeStep.notes.add(ReserveOrderTimelineNote(
      who: 'System ·',
      text: '$_transactionType $amount submitted$quoted',
      time: '($now)',
    ));

    order.notes.add(ReserveOrderNote(
      author: 'System',
      role: 'automated',
      roleKind: ReserveOrderNoteRole.sistem,
      time: now,
      text: '$_transactionType $amount submitted$quoted.',
    ));
  }

  String _fileSize(PickedFileResult file) {
    final bytes = file.bytes?.lengthInBytes ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
