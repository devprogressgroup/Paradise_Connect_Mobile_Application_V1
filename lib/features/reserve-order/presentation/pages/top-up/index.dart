import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/reject_banner.dart';

enum _PayMode { cash, transfer }

class _PaymentBlock {
  _PayMode mode;
  int amount;
  PickedFileResult? proof;
  final TextEditingController amountController;

  _PaymentBlock({this.mode = _PayMode.transfer, this.amount = 2000000})
      : amountController = TextEditingController(text: NumberHelper.thousands(amount));

  void dispose() => amountController.dispose();
}

/// Halaman "Top Up Pembayaran" — diakses dari tombol "+ Top Up Pembayaran" di tab
/// Timeline detail Reserve Order. Struktur & interaksi mengikuti bagian PAYMENT pada
/// prototype `reserve-order-prototype (1).html` (mode topup).
class TopupReserveOrderPage extends StatefulWidget {
  final String unitName;
  final String customerName;
  final String currentStatus;
  final Color? statusColor;
  final int totalPaidSoFar;
  final bool isResubmit;
  final String? rejectReason;
  final int? suggestedAmount;

  const TopupReserveOrderPage({
    super.key,
    this.unitName = 'Blok E1 No. 19',
    this.customerName = 'Luthfi Fajri',
    this.currentStatus = 'Diproses',
    this.statusColor,
    this.totalPaidSoFar = 2000000,
    this.isResubmit = false,
    this.rejectReason,
    this.suggestedAmount,
  });

  @override
  State<TopupReserveOrderPage> createState() => _TopupReserveOrderPageState();
}

class _TopupReserveOrderPageState extends State<TopupReserveOrderPage> {
  static const _paymentTypes = ['Reserve', 'Top up Reserve', 'RB', 'Top up RB', 'SP', 'Top up SP'];
  static const _quickAmounts = [2000000, 3000000, 5000000, 10000000, 15000000, 20000000, 25000000, 50000000];

  final _catatanController = TextEditingController();
  late String _jenisPembayaran;
  late final List<_PaymentBlock> _blocks;
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String _successText = '';
  int _totalAfterSubmit = 0;

  int get _total => _blocks.fold(0, (sum, b) => sum + b.amount);

  @override
  void initState() {
    super.initState();
    _jenisPembayaran = widget.isResubmit ? 'Reserve' : 'Top up Reserve';
    _blocks = [_PaymentBlock(mode: _PayMode.transfer, amount: widget.isResubmit ? (widget.suggestedAmount ?? 50000000) : 3000000)];
  }

  @override
  void dispose() {
    for (final block in _blocks) {
      block.dispose();
    }
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessView();
    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isResubmit) ...[
                      RejectBanner(title: 'Ditolak — Perlu Revisi', reason: widget.rejectReason ?? ''),
                      const SizedBox(height: 12),
                    ],
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Jenis Pembayaran'),
                    const SizedBox(height: 8),
                    _buildJenisChips(),
                    const SizedBox(height: 6),
                    for (var i = 0; i < _blocks.length; i++) ...[
                      _buildPaymentBlock(i),
                      const SizedBox(height: 12),
                    ],
                    _buildAddMoreButton(),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Catatan'),
                    const SizedBox(height: 8),
                    _buildCatatanField(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: const Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: Color(roSuccessBgColor), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Color(successColor), size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isResubmit ? 'Reserve Order Berhasil Diajukan Ulang' : 'Top Up Berhasil Diajukan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(_successText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(grey4Color), height: 1.5)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(grey10Color))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total setelah transaksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                Text('Rp ${NumberHelper.thousands(_totalAfterSubmit)}', style: const TextStyle(fontSize: 9.5, color: Color(grey4Color))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(warningColor), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Menunggu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(whiteColor))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(color: Color(whiteColor), border: Border(top: BorderSide(color: Color(grey10Color)))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: customButton(() => Navigator.of(context).maybePop(true), 'Kembali ke Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 20, color: Color(blue2Color)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isResubmit ? 'Perbaiki Reserve Order' : 'Top Up Pembayaran',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(blue2Color)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.unitName} · ${widget.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(blackColor).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _statusLine('Status saat ini', widget.currentStatus, valueColor: widget.statusColor),
          const SizedBox(height: 8),
          _statusLine('Total dibayar sejauh ini', 'Rp ${NumberHelper.thousands(widget.totalPaidSoFar)}'),
        ],
      ),
    );
  }

  Widget _statusLine(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(grey1Color))),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? const Color(blue2Color)),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(grey1Color)));
  }

  Widget _buildJenisChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _paymentTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final type = _paymentTypes[i];
          return _selectablePill(
            label: type,
            selected: type == _jenisPembayaran,
            onTap: () => setState(() => _jenisPembayaran = type),
          );
        },
      ),
    );
  }

  Widget _selectablePill({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(roSelectedBgColor) : const Color(whiteColor),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? const Color(primaryColor) : const Color(grey7Color), width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(primaryColor) : const Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBlock(int index) {
    final block = _blocks[index];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(roCardBgColor),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(grey10Color), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metode Pembayaran ${index + 1}',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(grey4Color), letterSpacing: 0.3),
              ),
              if (_blocks.length > 1)
                InkWell(
                  onTap: () => setState(() {
                    _blocks[index].dispose();
                    _blocks.removeAt(index);
                  }),
                  child: const Text(
                    '✕ Hapus',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(redColor)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _payToggleButton(
                  icon: '💵',
                  label: 'Tunai',
                  selected: block.mode == _PayMode.cash,
                  onTap: () => setState(() => block.mode = _PayMode.cash),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _payToggleButton(
                  icon: '🏦',
                  label: 'Non Tunai',
                  selected: block.mode == _PayMode.transfer,
                  onTap: () => setState(() => block.mode = _PayMode.transfer),
                ),
              ),
            ],
          ),
          if (block.mode == _PayMode.transfer) ...[
            const SizedBox(height: 10),
            _buildProofRow(block),
          ],
          const SizedBox(height: 12),
          _buildFieldLabel('Nominal'),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickAmounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                final amount = _quickAmounts[i];
                return _selectablePill(
                  label: _fmtAmt(amount),
                  selected: block.amount == amount,
                  onTap: () => setState(() {
                    block.amount = amount;
                    block.amountController.text = NumberHelper.thousands(amount);
                    block.amountController.selection = TextSelection.collapsed(offset: block.amountController.text.length);
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: block.amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsInputFormatter()],
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              setState(() => block.amount = digits.isEmpty ? 0 : int.parse(digits));
            },
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(blue2Color)),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(blue2Color)),
              filled: true,
              fillColor: const Color(grey11Color),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(grey7Color))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(grey7Color))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(primaryColor))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payToggleButton({required String icon, required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(roSelectedBgColor) : const Color(whiteColor),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? const Color(primaryColor) : const Color(grey7Color), width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? const Color(primaryColor) : const Color(grey1Color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofRow(_PaymentBlock block) {
    final uploaded = block.proof != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await CustomFilePicker.show(context);
        if (!mounted || result == null) return;
        setState(() => block.proof = result);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: uploaded ? const Color(successColor) : const Color(grey10Color)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(roIconBgColor), borderRadius: BorderRadius.circular(10)),
              child: const Text('🧾', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'Bukti Non Tunai ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color))),
                        TextSpan(text: '· Wajib', style: TextStyle(fontSize: 10, color: Color(grey4Color))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploaded ? block.proof!.name : 'Ketuk untuk upload',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: uploaded ? const Color(grey4Color) : const Color(primaryColor)),
                  ),
                ],
              ),
            ),
            if (uploaded) const Icon(Icons.check_circle, size: 18, color: Color(successColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => setState(() => _blocks.add(_PaymentBlock(mode: _PayMode.cash, amount: 2000000))),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: const Color(primaryColor), radius: 11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('+ Bayar Lagi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(primaryColor))),
        ),
      ),
    );
  }

  Widget _buildCatatanField() {
    return TextField(
      controller: _catatanController,
      maxLines: 3,
      style: const TextStyle(fontSize: 13, color: Color(blue2Color)),
      decoration: InputDecoration(
        hintText: 'Catatan tambahan...',
        hintStyle: const TextStyle(fontSize: 12, color: Color(grey4Color)),
        filled: true,
        fillColor: const Color(whiteColor),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(grey7Color))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(grey7Color))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(primaryColor))),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: customButton(
        _isSubmitting ? null : _submit,
        _isSubmitting
            ? 'Mengajukan...'
            : '${widget.isResubmit ? 'Submit Ulang' : 'Ajukan Top Up'} (Rp ${NumberHelper.thousands(_total)})',
      ),
    );
  }

  String _fmtAmt(int value) {
    final jt = value / 1000000;
    final isWhole = jt == jt.roundToDouble();
    final label = isWhole ? jt.toInt().toString() : jt.toStringAsFixed(1).replaceAll('.', ',');
    return '${label}jt';
  }

  Future<void> _submit() async {
    final missingProof = _blocks.any((b) => b.mode == _PayMode.transfer && b.proof == null);
    if (missingProof) {
      showSnackbar(context, 'Setiap transaksi Non Tunai wajib upload bukti pembayaran.', isError: true);
      return;
    }
    if (_total <= 0) {
      showSnackbar(context, 'Nominal top up belum diisi.', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final methodsLabel = _blocks.map((b) => '${b.mode == _PayMode.cash ? 'Tunai' : 'Non Tunai'} Rp ${NumberHelper.thousands(b.amount)}').join(' + ');
    setState(() {
      _isSubmitting = false;
      _totalAfterSubmit = widget.totalPaidSoFar + _total;
      _successText = '$_jenisPembayaran — ${_blocks.length} metode pembayaran ($methodsLabel) untuk ${widget.unitName} sedang diverifikasi.';
      _showSuccess = true;
    });
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final formatted = NumberHelper.thousands(int.parse(digits));
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = _dashPath(Path()..addRRect(rrect), dashLength: 5, gapLength: 4);
    canvas.drawPath(path, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          dashed.addPath(metric.extractPath(distance, math.min(distance + length, metric.length)), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
