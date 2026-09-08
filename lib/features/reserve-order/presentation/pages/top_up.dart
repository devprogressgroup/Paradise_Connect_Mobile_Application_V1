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
                  title: 'Top Up Pembayaran',
                  subtitle: '${order.unitLabel} · ${order.customerName}',
                  onBack: () => context.pop(),
                ),
              Expanded(child: _submitted ? _buildSukses() : _buildForm()),
              roFooter([
                _submitted
                    ? roPrimaryButton('Kembali ke Reserve Order', () => context.pop())
                    : roPrimaryButton('Ajukan Top Up', _onSubmit, loading: _submitting),
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
                roSummaryLine('Status saat ini', order.stageLabel),
                roSummaryLine('Total dibayar sejauh ini', 'Rp ${NumberHelper.thousands(order.paidSoFar)}'),
                roSummaryLine('Jenis Transaksi', _transactionType, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          roFieldLabel('Bukti Transfer Top Up'),
          roDocTile(_proofDoc, onTap: _submitting ? null : _pickProof),
          const SizedBox(height: 6),
          roFieldLabel('Nominal Top Up'),
          roInput(
            nominalTC,
            hint: 'Rp 0',
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsInputFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          roFieldLabel('Catatan'),
          roInput(
            catatanTC,
            hint: 'Mis: customer commit tambah DP, mau lanjut ke Booking Reserve',
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
        name: 'Upload bukti transfer baru',
        badge: '· Wajib',
        status: 'Ketuk untuk upload',
        state: ReserveOrderDocState.awaitingUpload,
        isPaymentProof: true,
      );
    }

    return ReserveOrderDoc(
      icon: proof.isPdf ? Icons.picture_as_pdf_outlined : Icons.receipt_long_outlined,
      name: proof.name,
      badge: '· Wajib',
      status: 'Terupload · ${_fileSize(proof)}',
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
            decoration: const BoxDecoration(color: Color(0xFFE7F9EE), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 32, color: Color(successColor)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Up Berhasil Diajukan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
          const SizedBox(height: 6),
          Text(
            '$_transactionType Rp ${NumberHelper.thousands(_submittedAmount)} untuk ${order.unitLabel} sedang diverifikasi.',
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
                        'Total setelah top up',
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
                    'Menunggu',
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
      showSnackbar(context, 'Bukti transfer top up wajib dilampirkan', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Nominal top up wajib diisi', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_top_up_submit');
    setState(() => _submitting = true);

    // Berdiri di tempat panggilan `POST /api/reserve/top-up` nanti; sekarang perubahannya cuma
    // ditulis ke objek transaksi di memori.
    await Future.delayed(const Duration(milliseconds: 400));
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
      name: 'Bukti Top Up',
      badge: '· $amount',
      status: 'Menunggu verifikasi',
      state: ReserveOrderDocState.pending,
      isPaymentProof: true,
    ));

    final activeStep = order.journey.firstWhere(
      (step) => step.state == ReserveOrderStepState.active,
      orElse: () => order.journey.last,
    );
    activeStep.notes.add(ReserveOrderTimelineNote(
      who: 'Sistem ·',
      text: '$_transactionType $amount diajukan$quoted',
      time: '($now)',
    ));

    order.notes.add(ReserveOrderNote(
      author: 'Sistem',
      role: 'otomatis',
      roleKind: ReserveOrderNoteRole.sistem,
      time: now,
      text: '$_transactionType $amount diajukan$quoted.',
    ));
  }

  String _fileSize(PickedFileResult file) {
    final bytes = file.bytes?.lengthInBytes ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
