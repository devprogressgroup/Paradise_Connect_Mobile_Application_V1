import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/reject_banner.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/widgets/reference_date_field.dart';

enum _PayMode { cash, transfer }

class _PaymentBlock {
  _PayMode mode;
  int amount;
  PickedFileResult? proof;

  /// Tanggal bukti transfer (`reference_date`) — wajib untuk Non Tunai.
  DateTime? referenceDate;
  final TextEditingController amountController;

  _PaymentBlock({this.mode = _PayMode.transfer, this.amount = 2000000})
    : amountController = TextEditingController(
        text: NumberHelper.thousands(amount),
      );

  void dispose() => amountController.dispose();
}

/// Halaman "Top Up Pembayaran" — diakses dari tombol "+ Top Up Pembayaran" di tab
/// Timeline detail Reserve Order. Struktur & interaksi mengikuti bagian PAYMENT pada
/// prototype `reserve-order-prototype (1).html` (mode topup).
class TopupReserveOrderPage extends StatefulWidget {
  final int reserveOrderId;
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
    required this.reserveOrderId,
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
  static const _quickAmounts = [
    2000000,
    3000000,
    5000000,
    10000000,
    15000000,
    20000000,
    25000000,
    50000000,
  ];

  final _catatanController = TextEditingController();
  int? _paymentTypeId;
  String? _paymentTypeName;
  late final List<_PaymentBlock> _blocks;
  bool _isSubmitting = false;
  bool _showValidation = false;
  bool _showSuccess = false;
  String _successText = '';
  int _totalAfterSubmit = 0;

  int get _total => _blocks.fold(0, (sum, b) => sum + b.amount);

  @override
  void initState() {
    super.initState();
    context.read<PaymentTypeBloc>().add(const FetchPaymentTypesEvent());
    _blocks = [
      _PaymentBlock(
        mode: _PayMode.transfer,
        amount: widget.isResubmit
            ? (widget.suggestedAmount ?? 50000000)
            : 3000000,
      ),
    ];
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
                      RejectBanner(
                        title: 'Ditolak — Perlu Revisi',
                        reason: widget.rejectReason ?? '',
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    const SizedBox(height: 4),
                    _fieldLabel('Catatan'),
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
                      decoration: const BoxDecoration(
                        color: Color(roSuccessBgColor),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(successColor),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isResubmit
                          ? 'Reserve Order Berhasil Diajukan Ulang'
                          : 'Top Up Berhasil Diajukan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _successText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(grey4Color),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(grey10Color)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total setelah transaksi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Rp ${NumberHelper.thousands(_totalAfterSubmit)}',
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
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(warningColor),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Menunggu',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(whiteColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(whiteColor),
                border: Border(top: BorderSide(color: Color(grey10Color))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: customButton(
                  () => Navigator.of(context).maybePop(true),
                  'Kembali ke Detail',
                ),
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
                  widget.isResubmit
                      ? 'Perbaiki Reserve Order'
                      : 'Top Up Pembayaran',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(blue2Color),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.unitName} · ${widget.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          BoxShadow(
            color: const Color(blackColor).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _statusLine(
            'Status saat ini',
            widget.currentStatus,
            valueColor: widget.statusColor,
          ),
          const SizedBox(height: 8),
          _statusLine(
            'Total dibayar sejauh ini',
            'Rp ${NumberHelper.thousands(widget.totalPaidSoFar)}',
          ),
        ],
      ),
    );
  }

  Widget _statusLine(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(grey1Color)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(blue2Color),
          ),
        ),
      ],
    );
  }

  // ===== UI kartu pembayaran — disamakan dengan "Pembayaran per Unit" di Create Reserve Order =====

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(color: Color(grey1Color)),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(redColor)),
            ),
        ],
      ),
    ),
  );

  Widget _errorText(bool show, {String message = 'Wajib diisi'}) => show
      ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: Color(redColor)),
          ),
        )
      : const SizedBox.shrink();

  InputBorder _fieldBorder({bool focused = false}) => UnderlineInputBorder(
    borderSide: BorderSide(
      color: focused ? const Color(primaryColor) : const Color(grey7Color),
    ),
  );

  Widget _buildPaymentCard() {
    final jenisError = _showValidation && _paymentTypeId == null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(roCardBgColor),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(grey10Color), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Jenis Pembayaran', required: true),
          SizedBox(
            height: 40,
            child: BlocBuilder<PaymentTypeBloc, PaymentTypeState>(
              builder: (context, state) {
                final options = state.items;
                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final opt = options[i];
                      final selected = _paymentTypeId == opt.paymentTypeId;
                      return ChoiceChip(
                        label: Text(
                          opt.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? const Color(primaryColor)
                                : const Color(grey1Color),
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _paymentTypeId = opt.paymentTypeId;
                          _paymentTypeName = opt.name;
                        }),
                        selectedColor: const Color(roSelectedBgColor),
                        backgroundColor: const Color(whiteColor),
                        side: BorderSide(
                          color: selected
                              ? const Color(primaryColor)
                              : jenisError
                              ? const Color(redColor)
                              : const Color(grey7Color),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _errorText(jenisError, message: 'Pilih jenis pembayaran'),
          const SizedBox(height: 12),
          for (var i = 0; i < _blocks.length; i++) _buildPaymentBlock(i),
          Text(
            'Total Pembayaran: Rp ${NumberHelper.thousands(_total)}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(successColor),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(
              () => _blocks.add(
                _PaymentBlock(mode: _PayMode.cash, amount: 2000000),
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              foregroundColor: const Color(primaryColor),
              side: const BorderSide(color: Color(primaryColor)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '+ Bayar Lagi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payModeButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(roSelectedBgColor)
              : const Color(whiteColor),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? const Color(primaryColor)
                : const Color(grey7Color),
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? const Color(primaryColor)
                : const Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBlock(int index) {
    final block = _blocks[index];
    final proofError =
        _showValidation &&
        block.mode == _PayMode.transfer &&
        block.proof == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey10Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Metode Pembayaran ${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(grey4Color),
                  ),
                ),
              ),
              if (_blocks.length > 1)
                GestureDetector(
                  onTap: () => setState(() {
                    _blocks[index].dispose();
                    _blocks.removeAt(index);
                  }),
                  child: const Text(
                    '✕ Hapus',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(redColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _payModeButton(
                  '💵 Tunai',
                  block.mode == _PayMode.cash,
                  () => setState(() => block.mode = _PayMode.cash),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _payModeButton(
                  '🏦 Non Tunai',
                  block.mode == _PayMode.transfer,
                  () => setState(() => block.mode = _PayMode.transfer),
                ),
              ),
            ],
          ),
          if (block.mode == _PayMode.transfer) ...[
            const SizedBox(height: 10),
            _buildProofRow(block, isError: proofError),
            ReferenceDateField(
              value: block.referenceDate,
              onChanged: (d) => setState(() => block.referenceDate = d),
              isError: _showValidation && block.referenceDate == null,
            ),
          ],
          const SizedBox(height: 4),
          _fieldLabel('Nominal'),
          SizedBox(
            height: 46,
            child: Scrollbar(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: _quickAmounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final amount = _quickAmounts[i];
                  final selected = block.amount == amount;
                  return ChoiceChip(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    label: Text(
                      _fmtAmt(amount),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(primaryColor)
                            : const Color(grey1Color),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      block.amount = amount;
                      block.amountController.text = NumberHelper.thousands(
                        amount,
                      );
                      block.amountController.selection =
                          TextSelection.collapsed(
                            offset: block.amountController.text.length,
                          );
                    }),
                    selectedColor: const Color(roSelectedBgColor),
                    backgroundColor: const Color(whiteColor),
                    side: BorderSide(
                      color: selected
                          ? const Color(primaryColor)
                          : const Color(grey7Color),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: block.amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsInputFormatter()],
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              setState(
                () => block.amount = digits.isEmpty ? 0 : int.parse(digits),
              );
            },
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(grey11Color),
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(focused: true),
            ),
          ),
        ],
      ),
    );
  }

  /// Sama dengan `_docRow` Bukti Non Tunai di Create Reserve Order (preview file + tombol hapus).
  Widget _buildProofRow(_PaymentBlock block, {bool isError = false}) {
    final file = block.proof;
    final uploaded = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await CustomFilePicker.show(context);
          if (!mounted || result == null) return;
          setState(() => block.proof = result);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError ? const Color(redColor) : const Color(grey10Color),
            ),
          ),
          child: Row(
            children: [
              if (uploaded)
                FilePreviewWidget(
                  file: file,
                  size: 44,
                  onRemove: () => setState(() => block.proof = null),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(grey11Color),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text('🧾', style: TextStyle(fontSize: 18)),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: 'Bukti Non Tunai'),
                          TextSpan(
                            text: ' · Wajib',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(grey4Color),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      uploaded ? 'Terupload' : 'Ketuk untuk upload',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: uploaded
                            ? const Color(grey4Color)
                            : const Color(primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (uploaded)
                const Icon(
                  Icons.check_circle,
                  color: Color(successColor),
                  size: 18,
                ),
            ],
          ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(grey7Color)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(grey7Color)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(primaryColor)),
        ),
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
    final label = isWhole
        ? jt.toInt().toString()
        : jt.toStringAsFixed(1).replaceAll('.', ',');
    return '${label}jt';
  }

  Future<void> _submit() async {
    final missingPaymentType = _paymentTypeId == null;
    final missingProof = _blocks.any(
      (b) => b.mode == _PayMode.transfer && b.proof == null,
    );
    final missingReferenceDate = _blocks.any(
      (b) => b.mode == _PayMode.transfer && b.referenceDate == null,
    );
    if (missingPaymentType || missingProof || missingReferenceDate) {
      setState(() => _showValidation = true);
      showSnackbar(
        context,
        missingPaymentType
            ? 'Jenis Pembayaran wajib dipilih.'
            : missingProof
            ? 'Setiap transaksi Non Tunai wajib upload bukti pembayaran.'
            : 'Tanggal Bukti Transfer wajib diisi untuk setiap transaksi Non Tunai.',
        isError: true,
      );
      return;
    }
    if (_total <= 0) {
      showSnackbar(context, 'Nominal top up belum diisi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final params = TopupReserveOrderParams(
      paymentTypeId: _paymentTypeId,
      note: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
      payments: _blocks
          .map(
            (b) => TopupReserveOrderPaymentParams(
              paymentMethod: b.mode == _PayMode.cash ? 'cash' : 'transfer',
              amount: b.amount.toDouble(),
              proofBytes: b.proof?.bytes,
              proofFileName: b.proof?.name,
              referenceDate: b.mode == _PayMode.transfer
                  ? b.referenceDate
                  : null,
            ),
          )
          .toList(),
    );

    final error = await context.read<ReserveOrderDetailCubit>().topup(
      widget.reserveOrderId,
      params,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _isSubmitting = false);
      showSnackbar(context, error, isError: true);
      return;
    }

    final methodsLabel = _blocks
        .map(
          (b) =>
              '${b.mode == _PayMode.cash ? 'Tunai' : 'Non Tunai'} Rp ${NumberHelper.thousands(b.amount)}',
        )
        .join(' + ');
    setState(() {
      _isSubmitting = false;
      _totalAfterSubmit = widget.totalPaidSoFar + _total;
      _successText =
          '${_paymentTypeName ?? 'Top Up'} — ${_blocks.length} metode pembayaran ($methodsLabel) untuk ${widget.unitName} sedang diverifikasi.';
      _showSuccess = true;
    });
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final formatted = NumberHelper.thousands(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
