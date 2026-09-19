import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_state.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_unit_option.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/create_reserve_order/create_reserve_order_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/create_reserve_order/create_reserve_order_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/payment_type/payment_type_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/select_unit/select_unit_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/select_unit/select_unit_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/select_unit/select_unit_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/work_category/work_category_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/work_category/work_category_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/work_category/work_category_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_state.dart';

class CreateReserveOrderPage extends StatefulWidget {
  /// contactId Contact — wajib diisi, dipakai buat panggil endpoint
  /// `/reserve-order/select-unit` (`ReserveOrderController::selectUnit`) yang isi tab "Unit dari
  /// Contact". Wizard ini cuma bisa dibuka lewat Contact Detail atau lewat
  /// `SelectContactForReserveOrderPage` (dari FAB list Reserve Order) — keduanya selalu punya
  /// contact yang dipilih lebih dulu.
  final int contactId;
  final String? contactName;
  final String? contactPhone;
  final String? contactKtpNumber;
  final String? contactAddress;
  final String? contactGender;
  final String? salesChannel;
  final String? salesChannelDetail;

  /// Township id project default Contact (`last_project_id`/`first_project_id` dari
  /// `GET /contacts/:id` — PK-nya sama dengan `id` di `GET /property/townships`). Dipakai buat
  /// auto-select "Pilih Project" dengan dicocokkan by ID ke daftar township yang sudah dimuat —
  /// TANPA fetch ulang township list (sudah di-fetch sekali di level app, lihat `main.dart`).
  /// Kalau id-nya tidak ketemu di daftar yang dimuat, "Pilih Project" dibiarkan kosong (bukan
  /// ditebak dari nama teks) — user pilih manual lewat [_openProjectPicker].
  final int? contactProjectId;

  /// Riwayat unit milik Contact (dari `ContactEntity.units`) — cuma dipakai buat banner info di
  /// step Unit; isi tab "Unit dari Contact" sendiri datang dari [SelectUnitBloc]
  /// (`/reserve-order/select-unit`), lihat [_fetchSelectUnitFor].
  final List<SelectedUnit>? contactUnits;

  final String? existingKtpAttachmentUrl;
  final String? existingNpwpAttachmentUrl;

  /// `contact_attachment_id` dari lampiran yang sama (kalau ada) — dipakai submit reserve order
  /// supaya bisa reuse lampiran ini (`documents.ktp.existing_attachment_id`) TANPA upload ulang.
  final int? existingKtpAttachmentId;
  final int? existingNpwpAttachmentId;

  /// Hirarki sales milik Contact ini (id + nama sudah di-resolve backend, lihat
  /// `GET /contacts/{id}` — `ContactService::getContactDetails`). Dipakai apa adanya di step
  /// Review & dikirim ke `POST /reserve-order/create` — TIDAK ditebak dari user yang login,
  /// supaya reserve order tetap tercatat di bawah sales team yang memang menangani Contact ini.
  final int? salesExecutiveId;
  final String? salesExecutiveName;
  final int? salesSupervisorId;
  final String? salesSupervisorName;
  final int? salesManagerId;
  final String? salesManagerName;
  final int? salesGeneralManagerId;
  final String? salesGeneralManagerName;
  final int? salesTeamId;
  final String? salesTeamName;

  const CreateReserveOrderPage({
    super.key,
    required this.contactId,
    this.contactName,
    this.contactPhone,
    this.contactKtpNumber,
    this.contactAddress,
    this.contactGender,
    this.salesChannel,
    this.salesChannelDetail,
    this.contactProjectId,
    this.contactUnits,
    this.existingKtpAttachmentUrl,
    this.existingNpwpAttachmentUrl,
    this.existingKtpAttachmentId,
    this.existingNpwpAttachmentId,
    this.salesExecutiveId,
    this.salesExecutiveName,
    this.salesSupervisorId,
    this.salesSupervisorName,
    this.salesManagerId,
    this.salesManagerName,
    this.salesGeneralManagerId,
    this.salesGeneralManagerName,
    this.salesTeamId,
    this.salesTeamName,
  });

  @override
  State<CreateReserveOrderPage> createState() => _CreateReserveOrderPageState();
}

class _CreateReserveOrderPageState extends State<CreateReserveOrderPage> {
  int _step = 1;

  bool _showCustomerValidation = false;
  bool _showUnitValidation = false;
  bool _showDocumentValidation = false;

  final _namaCtrl = TextEditingController();
  final _ktpCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _pasanganCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();
  final _caraBayarLainnyaCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _unitSearchCtrl = TextEditingController();

  DateTime? _tglLahir;
  String? _gender;
  String? _statusPernikahan;
  String? _kategoriPekerjaan;
  String? _caraBayar;
  int? _caraBayarId;

  PickedFileResult? _ktpFile;
  PickedFileResult? _npwpFile;
  String? _existingKtpUrl;
  String? _existingNpwpUrl;
  int? _existingKtpAttachmentId;
  int? _existingNpwpAttachmentId;

  String? _selectedProject;
  int? _selectedProjectId;
  String _unitTab = 'contact';
  List<ReserveUnitOption> _selectedUnits = [];
  List<_UnitPaymentDraft> _unitDrafts = [];
  Timer? _otherUnitsSearchDebounce;

  String _customerNameSnapshot = '';

  List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  List<String> _maritalOptions = ['Menikah', 'Belum Menikah', 'Cerai'];
  List<double> _amountPresets = [2000000, 3000000, 5000000, 10000000, 15000000];

  @override
  void initState() {
    super.initState();
    if (widget.contactName != null) _namaCtrl.text = widget.contactName!;
    if (widget.contactPhone != null) _hpCtrl.text = widget.contactPhone!;
    if (widget.contactKtpNumber != null)
      _ktpCtrl.text = widget.contactKtpNumber!;
    if (widget.contactAddress != null)
      _alamatCtrl.text = widget.contactAddress!;
    if (widget.contactGender != null &&
        _genderOptions.contains(widget.contactGender)) {
      _gender = widget.contactGender;
    }
    _existingKtpUrl = widget.existingKtpAttachmentUrl;
    _existingNpwpUrl = widget.existingNpwpAttachmentUrl;
    _existingKtpAttachmentId = widget.existingKtpAttachmentId;
    _existingNpwpAttachmentId = widget.existingNpwpAttachmentId;
    if (widget.contactUnits != null && widget.contactUnits!.isEmpty) {
      _unitTab = 'other';
    }
    // Township sudah di-fetch sekali di level app (lihat `main.dart`) — jangan fetch ulang di
    // sini, cuma cocokkan ke daftar yang sudah dimuat kalau memang sudah ada. Kalau belum dimuat
    // (jarang terjadi), biarkan kosong; fetch baru dipicu saat user beneran buka picker-nya
    // sendiri lewat `_openProjectPicker`.
    if (widget.contactProjectId != null) {
      final townshipState = context.read<TownshipBloc>().state;
      if (townshipState is TownshipLoaded) {
        final match = townshipState.townships.where(
          (t) => t.id == widget.contactProjectId,
        );
        if (match.isNotEmpty) {
          _onProjectChanged(match.first.name, id: match.first.id);
        }
      }
    }
    context.read<CaraBayarBloc>().add(const FetchCaraBayarEvent());
    context.read<WorkCategoryBloc>().add(const FetchWorkCategoryEvent());
    context.read<PaymentTypeBloc>().add(const FetchPaymentTypesEvent());
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _ktpCtrl.dispose();
    _tempatLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _hpCtrl.dispose();
    _pasanganCtrl.dispose();
    _pekerjaanCtrl.dispose();
    _caraBayarLainnyaCtrl.dispose();
    _catatanCtrl.dispose();
    _unitSearchCtrl.dispose();
    _otherUnitsSearchDebounce?.cancel();
    for (final d in _unitDrafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _goBack() {
    if (_step > 1) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step > 1) setState(() => _step -= 1);
      },
      child: switch (_step) {
        1 => _customer(),
        2 => _unit(),
        3 => _document(),
        4 => _review(),
        _ => _success(),
      },
    );
  }

  // ---------------------------------------------------------------------
  // Shared chrome
  // ---------------------------------------------------------------------

  Widget _appBar(String title, String? subtitle) {
    return Container(
      color: Color(whiteColor),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: _goBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(grey4Color),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step) {
    const labels = ['Customer', 'Unit', 'Dokumen', 'Review'];
    return Container(
      color: Color(whiteColor),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (i) {
              final idx = i + 1;
              final color = idx < step
                  ? Color(successColor)
                  : (idx == step ? Color(primaryColor) : Color(grey9Color));
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (i) {
              final idx = i + 1;
              final isCurrent = idx == step;
              return Expanded(
                child: Text(
                  isCurrent ? '$idx/4 ${labels[i]}' : labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : (i == 3 ? TextAlign.right : TextAlign.center),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isCurrent ? Color(primaryColor) : Color(grey4Color),
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _footer(String label, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: customButton(onPressed, label),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Color(grey4Color),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        children: [
          TextSpan(
            text: text,
            style: TextStyle(color: Color(grey1Color)),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: Color(redColor)),
            ),
        ],
      ),
    ),
  );

  InputBorder _fieldBorder(bool isError, {bool focused = false}) =>
      UnderlineInputBorder(
        borderSide: BorderSide(
          color: isError
              ? Color(redColor)
              : (focused ? Color(primaryColor) : Color(grey7Color)),
        ),
      );
  Widget _errorText(bool show) => show
      ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Wajib diisi',
            style: TextStyle(fontSize: 11, color: Color(redColor)),
          ),
        )
      : const SizedBox.shrink();

  Widget _underlineFieldFrame(Widget child, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: isError ? Color(redColor) : Color(grey9Color),
          ),
        ),
      ),
      child: child,
    );
  }

  void _showOptionSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onPicked,
  }) {
    showCustomBottomSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(blackColor),
              ),
            ),
          ),
          for (final item in items)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPicked(item);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(blackColor),
                        ),
                      ),
                    ),
                    if (item == selected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Color(primaryColor),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _requiredLabel(
    String text, {
    required bool required,
    required TextStyle style,
  }) {
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(redColor),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _pickerFieldRow({
    required String label,
    required String? value,
    required VoidCallback onTap,
    bool isError = false,
    bool required = false,
  }) {
    final labelColor = isError ? Color(redColor) : Color(grey2Color);
    final isEmpty = value == null || value.isEmpty;
    return _underlineFieldFrame(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEmpty)
                        _requiredLabel(
                          label,
                          required: required,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      isEmpty
                          ? _requiredLabel(
                              label,
                              required: required,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                              ),
                            )
                          : Text(
                              value,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(blackColor),
                              ),
                            ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 28,
                  color: Color(grey4Color),
                ),
              ],
            ),
          ),
          _errorText(isError),
        ],
      ),
      isError: isError,
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isError =
        _showCustomerValidation && required && controller.text.trim().isEmpty;
    final labelColor = isError ? Color(redColor) : Color(grey2Color);
    return _underlineFieldFrame(
      isError: isError,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            minLines: maxLines > 1 ? maxLines : null,
            maxLines: null,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(blackColor),
            ),
            onChanged: required ? (_) => setState(() {}) : null,
            decoration: InputDecoration(
              isDense: true,
              label: _requiredLabel(
                label,
                required: required,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12, color: Color(grey5Color)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          _errorText(isError),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    final isError = _showCustomerValidation && required && value == null;
    return _pickerFieldRow(
      label: label,
      value: value,
      isError: isError,
      required: required,
      onTap: () => _showOptionSheet(
        title: label,
        items: items,
        selected: value,
        onPicked: (v) => setState(() => onChanged(v)),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool required = false,
  }) {
    final isError = _showCustomerValidation && required && value == null;
    final displayValue = value == null
        ? null
        : DateFormat('dd MMMM yyyy', 'id_ID').format(value);
    return _pickerFieldRow(
      label: label,
      value: displayValue,
      isError: isError,
      required: required,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 25),
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (picked != null) setState(() => onChanged(picked));
      },
    );
  }

  Widget _readOnlyFieldRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(width: 1, color: Color(grey7Color))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(grey2Color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(grey1Color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow({
    required String icon,
    required String title,
    required String subtitle,
    required PickedFileResult? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    bool isError = false,
    String? existingUrl,
    VoidCallback? onViewExisting,
  }) {
    final uploaded = file != null;
    final hasExisting =
        !uploaded && existingUrl != null && existingUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: hasExisting ? onViewExisting : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError ? Color(redColor) : Color(grey10Color),
            ),
          ),
          child: Row(
            children: [
              if (uploaded)
                FilePreviewWidget(file: file, size: 44, onRemove: onRemove)
              else
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(grey11Color),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: title),
                          TextSpan(
                            text: ' · $subtitle',
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
                      uploaded
                          ? 'Terupload'
                          : hasExisting
                          ? 'Sudah ada di data Contact · Ketuk untuk lihat'
                          : 'Ketuk untuk upload',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: uploaded || hasExisting
                            ? Color(grey4Color)
                            : Color(primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (uploaded || hasExisting)
                Icon(Icons.check_circle, color: Color(successColor), size: 18),
              if (hasExisting) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 28),
                  ),
                  child: Text(
                    'Ganti',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(primaryColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(ValueChanged<PickedFileResult> onPicked) async {
    final result = await CustomFilePicker.show(context);
    if (result != null) setState(() => onPicked(result));
  }

  void _openExistingAttachment(String? url) {
    if (url == null || url.isEmpty) return;
    context.pushNamed('attachmentWebView', extra: url);
  }

  Widget _checkbox(bool checked) => Container(
    width: 19,
    height: 19,
    decoration: BoxDecoration(
      color: checked ? Color(primaryColor) : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: checked ? Color(primaryColor) : Color(grey7Color),
        width: 1.5,
      ),
    ),
    child: checked
        ? Icon(Icons.check, size: 13, color: Color(whiteColor))
        : null,
  );

  Widget _availabilityBadge(bool available) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Color(available ? availableColor : reserveColor),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available ? 'Available' : 'Not Available',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: Color(available ? roAvailableTextColor : roUnavailableTextColor),
      ),
    ),
  );

  // ---------------------------------------------------------------------
  // STEP 1 — Customer
  // ---------------------------------------------------------------------

  Future<void> _pickKtpPhoto() async {
    final result = await CustomFilePicker.show(context, allowDocuments: false);
    if (result == null) return;
    setState(() => _ktpFile = result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Foto KTP tersimpan sebagai dokumen KTP Pemohon. Lengkapi data di bawah secara manual.',
        ),
      ),
    );
  }

  Widget _customer() {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: Column(
        children: [
          _appBar('Reserve Order — Customer Baru', 'Data Customer'),
          _stepIndicator(1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton(
                          onPressed: _pickKtpPhoto,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            foregroundColor: Color(primaryColor),
                            side: BorderSide(
                              color: Color(primaryColor),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            '📷 Ambil Foto KTP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_ktpFile != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              FilePreviewWidget(
                                file: _ktpFile!,
                                size: 52,
                                onRemove: () => setState(() => _ktpFile = null),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Foto KTP tersimpan sebagai dokumen KTP Pemohon',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(successColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  _textField(
                    label: 'Nama Lengkap (sesuai KTP)',
                    controller: _namaCtrl,
                    required: true,
                  ),
                  _textField(
                    label: 'No. KTP',
                    controller: _ktpCtrl,
                    required: true,
                    hint: '16 digit NIK',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                  ),
                  _textField(
                    label: 'Tempat Lahir',
                    controller: _tempatLahirCtrl,
                    required: true,
                  ),
                  _dateField(
                    label: 'Tanggal Lahir',
                    value: _tglLahir,
                    required: true,
                    onChanged: (v) => _tglLahir = v,
                  ),
                  _dropdownField(
                    label: 'Jenis Kelamin',
                    value: _gender,
                    items: _genderOptions,
                    required: true,
                    onChanged: (v) => _gender = v,
                  ),
                  _textField(
                    label: 'Alamat (sesuai KTP)',
                    controller: _alamatCtrl,
                    required: true,
                    maxLines: 2,
                  ),
                  _textField(
                    label: 'No. HP',
                    controller: _hpCtrl,
                    required: true,
                    keyboardType: TextInputType.phone,
                  ),
                  _dropdownField(
                    label: 'Status Pernikahan',
                    value: _statusPernikahan,
                    items: _maritalOptions,
                    required: true,
                    onChanged: (v) => _statusPernikahan = v,
                  ),
                  if (_statusPernikahan == 'Menikah')
                    _textField(
                      label: 'Nama Pasangan',
                      controller: _pasanganCtrl,
                      required: true,
                      hint: 'Nama pasangan…',
                    ),
                  BlocBuilder<WorkCategoryBloc, WorkCategoryState>(
                    builder: (context, state) => _dropdownField(
                      label: 'Kategori Pekerjaan',
                      value: _kategoriPekerjaan,
                      items: state.items,
                      required: true,
                      onChanged: (v) => _kategoriPekerjaan = v,
                    ),
                  ),
                  _textField(
                    label: 'Pekerjaan',
                    controller: _pekerjaanCtrl,
                    required: true,
                  ),
                  BlocBuilder<CaraBayarBloc, CaraBayarState>(
                    builder: (context, state) => _dropdownField(
                      label: 'Cara Pembayaran',
                      value: _caraBayar,
                      items: state.items.map((e) => e.name).toList(),
                      required: true,
                      onChanged: (v) {
                        _caraBayar = v;
                        final match = state.items.where((e) => e.name == v);
                        _caraBayarId = match.isEmpty
                            ? null
                            : match.first.caraBayarId;
                      },
                    ),
                  ),
                  if (_caraBayar == 'Lainnya')
                    _textField(
                      label: 'Cara Pembayaran Lainnya',
                      controller: _caraBayarLainnyaCtrl,
                      required: true,
                      hint: 'Tulis cara pembayaran…',
                    ),
                  _readOnlyFieldRow(
                    'Sales Channel',
                    widget.salesChannel ?? '-',
                  ),
                  _readOnlyFieldRow(
                    'Sales Channel Detail',
                    widget.salesChannelDetail ?? '-',
                  ),
                ],
              ),
            ),
          ),
          _footer('Lanjut ke Pilih Unit', _submitCustomer),
        ],
      ),
    );
  }

  void _submitCustomer() {
    final requiredOk =
        _namaCtrl.text.trim().isNotEmpty &&
        _ktpCtrl.text.trim().isNotEmpty &&
        _tempatLahirCtrl.text.trim().isNotEmpty &&
        _tglLahir != null &&
        _gender != null &&
        _alamatCtrl.text.trim().isNotEmpty &&
        _hpCtrl.text.trim().isNotEmpty &&
        _statusPernikahan != null &&
        (_statusPernikahan != 'Menikah' ||
            _pasanganCtrl.text.trim().isNotEmpty) &&
        _kategoriPekerjaan != null &&
        _pekerjaanCtrl.text.trim().isNotEmpty &&
        _caraBayar != null &&
        (_caraBayar != 'Lainnya' ||
            _caraBayarLainnyaCtrl.text.trim().isNotEmpty);

    if (!requiredOk) {
      setState(() => _showCustomerValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi dahulu data yang wajib diisi.')),
      );
      return;
    }
    _customerNameSnapshot = _namaCtrl.text.trim();
    setState(() => _step = 2);
  }

  // ---------------------------------------------------------------------
  // STEP 2 — Unit (dummy data — belum konek API)
  // ---------------------------------------------------------------------

  void _toggleUnit(ReserveUnitOption u) {
    if (!u.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unit ini belum tersedia. Silakan hubungi admin untuk membuka unit ini.',
          ),
        ),
      );
      return;
    }
    setState(() {
      final idx = _selectedUnits.indexWhere((x) => x.id == u.id);
      if (idx > -1) {
        _selectedUnits = List.of(_selectedUnits)..removeAt(idx);
      } else {
        _selectedUnits = [..._selectedUnits, u];
      }
    });
  }

  bool _isUnitSelected(String id) => _selectedUnits.any((u) => u.id == id);

  /// Buka picker "Pilih Project" — pola yang sama seperti field "Project" di ContactFormPage
  /// (`context.pushNamed('detailContactDropdown', ...)`, lihat contact-form/index.dart): halaman
  /// terpisah dengan search, bukan `DropdownButtonFormField` inline. Ini juga menghindari risiko
  /// assertion Flutter kalau `_selectedProject` belum/tidak lagi cocok dengan salah satu item
  /// saat widget di-rebuild.
  Future<void> _openProjectPicker() async {
    final townshipState = context.read<TownshipBloc>().state;
    if (townshipState is! TownshipLoaded) {
      context.read<TownshipBloc>().add(GetTownshipsEvent());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Memuat data project...')));
      return;
    }

    final items = townshipState.townships
        .map((t) => OwnerDropdownItem(id: t.id, name: t.name))
        .toList();

    final result = await context.pushNamed(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Pilih Project',
        items: items,
        selectedId: _selectedProjectId,
      ),
    );

    if (result is OwnerDropdownItem) {
      setState(() => _onProjectChanged(result.name, id: result.id));
    }
  }

  /// Ambil unit riwayat Contact dari endpoint `/reserve-order/select-unit`
  /// (`ReserveOrderController::selectUnit`) untuk project yang lagi dipilih
  /// ([_selectedProjectId], sudah di-set duluan oleh [_onProjectChanged]).
  void _fetchSelectUnitFor() {
    final townshipId = _selectedProjectId;
    if (townshipId == null) {
      context.read<SelectUnitBloc>().add(const ResetSelectUnitEvent());
      return;
    }
    context.read<SelectUnitBloc>().add(
      FetchSelectUnitEvent(contactId: widget.contactId, townshipId: townshipId),
    );
  }

  /// Petakan hasil `/reserve-order/select-unit` ke [ReserveUnitOption] buat ditampilkan lewat
  /// widget baris unit yang sudah ada (`_contactUnitRow`/`_specialRow`/`_kavlingRow`). Status
  /// ketersediaan dibaca langsung dari `display_status_name` ("Available"/"Not Available") yang
  /// sudah disederhanakan backend — bukan resolve `status_id` manual di client.
  ReserveUnitOption _toReserveUnitOption(SelectUnitEntity u) {
    final contextLabel = [
      u.clusterName,
      u.productDisplayName,
    ].where((e) => (e ?? '').isNotEmpty).map((e) => e!).join(' · ');
    return ReserveUnitOption(
      id: 'deal-${u.dealId}',
      name:
          u.propertyName ??
          (u.isWaitingList ? 'Waiting list' : 'Belum tentukan kavling'),
      context: contextLabel,
      available: u.isAvailable,
      special: u.propertyId == null,
      dealId: u.dealId,
      townshipId: u.townshipId,
      companyId: u.companyId,
      clusterId: u.clusterId,
      productId: u.productId,
      propertyId: u.propertyId,
      isWaitingList: u.isWaitingList,
    );
  }

  /// Dipanggil setiap kali project berubah (lewat picker manual — selalu bawa [id] dari
  /// `OwnerDropdownItem` — maupun auto-select dari Contact di [initState]) — reset unit terpilih,
  /// muat ulang hierarki "Pilih Unit Lain", dan fetch ulang "Unit dari Contact" untuk project itu.
  /// Default tab ("contact" vs "other") diterapkan reaktif lewat listener [SelectUnitBloc] di
  /// [_unit] begitu hasil fetch-nya datang.
  void _onProjectChanged(String? project, {int? id}) {
    _selectedProject = project;
    _selectedProjectId = id;
    _selectedUnits = [];
    _unitSearchCtrl.clear();
    if (project == null) {
      _unitTab = 'other';
      return;
    }
    if (id != null) {
      context.read<UnitPickerCubit>().init(id, townshipName: project);
    }
    _fetchSelectUnitFor();
  }

  /// Debounce pencarian di tab "Pilih Unit Lain" — hierarki cluster/tipe difilter server-side
  /// (`?search=` di `GetUnitHierarchyUseCase`), bukan filter lokal seperti dummy sebelumnya.
  void _onOtherUnitsSearchChanged(String value) {
    _otherUnitsSearchDebounce?.cancel();
    _otherUnitsSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<UnitPickerCubit>().setSearch(value.trim());
    });
  }

  Widget _unitTabButton(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Color(primaryColor) : Color(grey11Color),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? Color(whiteColor) : Color(grey1Color),
            ),
          ),
        ),
      );

  Widget _infoNotice(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(roNoticeInfoBgColor),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(roNoticeInfoTextColor),
        height: 1.4,
      ),
    ),
  );

  Widget _contactUnitRow(ReserveUnitOption u) {
    final selected = _isUnitSelected(u.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleUnit(u),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: u.available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? const Color(roSelectedBgColor)
                  : Color(whiteColor),
              border: Border.all(
                color: selected ? Color(primaryColor) : Color(grey10Color),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                _checkbox(selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        u.context,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(grey4Color),
                        ),
                      ),
                    ],
                  ),
                ),
                _availabilityBadge(u.available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _specialRow(ReserveUnitOption u) {
    final selected = _isUnitSelected(u.id);
    final isWaiting = u.id.contains('waiting');
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => _toggleUnit(u),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(roSelectedBgColor) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _checkbox(selected),
              const SizedBox(width: 10),
              Text(
                u.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: isWaiting ? Color(warningColor) : Color(grey4Color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kavlingRow(ReserveUnitOption u) {
    final selected = _isUnitSelected(u.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () => _toggleUnit(u),
        borderRadius: BorderRadius.circular(9),
        child: Opacity(
          opacity: u.available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(roSelectedBgColor) : null,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                _checkbox(selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(u.name, style: const TextStyle(fontSize: 12.5)),
                ),
                _availabilityBadge(u.available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clusterHeader(String cluster) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 2),
    child: Text(
      cluster,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
  );

  Widget _tipeHeader(String tipe, String sub) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Color(grey11Color),
      borderRadius: BorderRadius.circular(9),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: tipe),
          TextSpan(
            text: '  $sub',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(grey4Color),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );

  /// Baris header cluster yang bisa di-tap buat expand/collapse — dipasangkan dengan
  /// [_clusterHeader] (label statis) di tab "Pilih Unit Lain" yang datanya dari
  /// `GET /property/units/hierarchy?township_id=` ([UnitPickerCubit]/`GetUnitHierarchyUseCase`).
  Widget _otherClusterHeaderTile(
    bool expanded,
    String name,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: expanded ? Color(primaryColor) : Color(grey5Color),
            ),
            const SizedBox(width: 2),
            Expanded(child: _clusterHeader(name)),
          ],
        ),
      ),
    );
  }

  /// Baris header tipe/produk yang bisa di-tap buat expand/collapse — saat diexpand pertama
  /// kali, [UnitPickerCubit.toggleProduct] otomatis fetch kavlingnya lewat
  /// `GET /property/units/hierarchy?product_id=&township_id=` ([GetUnitLotsUseCase]).
  Widget _otherProductHeaderTile(
    bool expanded,
    String tipe,
    String sub,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Row(
        children: [
          Icon(
            expanded ? Icons.expand_more : Icons.chevron_right,
            size: 16,
            color: expanded ? Color(primaryColor) : Color(grey5Color),
          ),
          const SizedBox(width: 2),
          Expanded(child: _tipeHeader(tipe, sub)),
        ],
      ),
    );
  }

  List<Widget> _otherProductTiles(
    UnitPickerCubit cubit,
    UnitPickerState state,
    String project,
    UnitCluster cluster,
    UnitProduct product,
  ) {
    final pkey = UnitPickerCubit.productKey(product);
    final expanded = state.expandedProducts.contains(pkey);
    final loadingLots = state.loadingProductIds.contains(pkey);
    final lots = state.lotsByProduct[pkey] ?? const [];
    final contextLabel = [
      project,
      cluster.projectName,
      product.displayName,
    ].where((e) => e.isNotEmpty).join(' · ');
    return [
      _otherProductHeaderTile(
        expanded,
        product.displayName,
        product.spec ?? '',
        () => cubit.toggleProduct(product),
      ),
      if (expanded) ...[
        _specialRow(
          ReserveUnitOption(
            id: 'undecided-${cluster.projectId}-${product.productId}',
            name: 'Belum menentukan kavling',
            context: contextLabel,
            special: true,
            townshipId: cluster.townshipId,
            companyId: cluster.companyId,
            clusterId: cluster.projectId,
            productId: product.productId,
          ),
        ),
        _specialRow(
          ReserveUnitOption(
            id: 'waiting-${cluster.projectId}-${product.productId}',
            name: 'Waiting list',
            context: contextLabel,
            special: true,
            townshipId: cluster.townshipId,
            companyId: cluster.companyId,
            clusterId: cluster.projectId,
            productId: product.productId,
            isWaitingList: true,
          ),
        ),
        if (loadingLots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          for (final lot in lots)
            _kavlingRow(
              ReserveUnitOption(
                id: 'lot-${cluster.projectId}-${product.productId}-${lot.propertyId}',
                name: lot.propertyName,
                context: contextLabel,
                available: (lot.displayStatusName ?? 'Available') == 'Available',
                townshipId: cluster.townshipId,
                companyId: cluster.companyId,
                clusterId: cluster.projectId,
                productId: product.productId,
                propertyId: lot.propertyId,
              ),
            ),
      ],
    ];
  }

  List<Widget> _otherClusterTiles(
    UnitPickerCubit cubit,
    UnitPickerState state,
    String project,
    UnitCluster cluster,
  ) {
    final expanded = state.expandedClusters.contains(cluster.projectId);
    return [
      Container(
        padding: EdgeInsets.only(bottom: 5),
        child: _otherClusterHeaderTile(
          expanded,
          cluster.projectName,
          () => cubit.toggleCluster(cluster.projectId),
        ),
      ),
      if (expanded)
        for (final product in cluster.products)
          ..._otherProductTiles(cubit, state, project, cluster, product),
    ];
  }

  /// Tab "Pilih Unit Lain" — hierarki cluster → tipe → kavling dari
  /// `GET /property/units/hierarchy?township_id=` (`ReserveOrderController` belum ada
  /// endpoint sendiri buat ini, jadi reuse [UnitPickerCubit] yang sudah dipakai fitur Contact).
  /// Kavling per tipe baru di-fetch (`?product_id=&township_id=`) saat tipenya diexpand.
  Widget _otherUnitsTree(String project) {
    return BlocBuilder<UnitPickerCubit, UnitPickerState>(
      builder: (context, state) {
        if (state.status == UnitPickerStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == UnitPickerStatus.error) {
          return _infoNotice(state.errorMessage ?? 'Gagal memuat unit.');
        }
        if (state.clusters.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Tidak ada cluster/tipe/kavling yang cocok.',
              style: TextStyle(fontSize: 12, color: Color(grey4Color)),
            ),
          );
        }
        final cubit = context.read<UnitPickerCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final cluster in state.clusters)
              ..._otherClusterTiles(cubit, state, project, cluster),
          ],
        );
      },
    );
  }

  Widget _unit() {
    final project = _selectedProject;
    final countText = _selectedUnits.isEmpty
        ? 'Belum ada unit dipilih'
        : '${_selectedUnits.length} unit dipilih: ${_selectedUnits.map((u) => u.name).join(', ')}';
    return Scaffold(
      backgroundColor: Color(whiteColor),
      // Fallback pasif kalau township belum dimuat saat halaman ini pertama kali dibuka (jarang
      // — lihat komentar di `initState`) — cuma nyimak state yang SUDAH di-fetch di level app,
      // TIDAK dispatch fetch baru sendiri.
      body: BlocListener<TownshipBloc, TownshipState>(
        listenWhen: (prev, curr) =>
            curr is TownshipLoaded &&
            _selectedProject == null &&
            widget.contactProjectId != null,
        listener: (context, state) {
          if (state is TownshipLoaded) {
            final match = state.townships.where(
              (t) => t.id == widget.contactProjectId,
            );
            if (match.isNotEmpty) {
              setState(
                () => _onProjectChanged(match.first.name, id: match.first.id),
              );
            }
          }
        },
        child: Column(
          children: [
            _appBar('Pilih Unit', _customerNameSnapshot),
            _stepIndicator(2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((widget.contactUnits ?? []).isNotEmpty) ...[
                      _infoNotice(
                        'Riwayat unit dari Contact: ${widget.contactUnits!.map((u) => u.label).join(', ')}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    _pickerFieldRow(
                      label: 'Pilih Project',
                      value: _selectedProject,
                      required: true,
                      isError: _showUnitValidation && project == null,
                      onTap: _openProjectPicker,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _unitTabButton(
                            'Unit dari Contact',
                            _unitTab == 'contact',
                            () => setState(() => _unitTab = 'contact'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _unitTabButton(
                            'Pilih Unit Lain',
                            _unitTab == 'other',
                            () => setState(() => _unitTab = 'other'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_unitTab == 'contact')
                      if (project == null)
                        _infoNotice('Pilih project terlebih dahulu.')
                      else
                        BlocBuilder<SelectUnitBloc, SelectUnitState>(
                          builder: (context, state) {
                            if (state.status == SelectUnitStatus.loading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (state.status == SelectUnitStatus.error) {
                              return _infoNotice(
                                state.errorMessage ??
                                    'Gagal memuat unit dari Contact.',
                              );
                            }
                            final options = state.items
                                .map(_toReserveUnitOption)
                                .toList();
                            if (options.isEmpty) {
                              return _infoNotice(
                                'Belum ada unit dari Contact untuk project ini. Coba tab "Pilih Unit Lain".',
                              );
                            }
                            return Column(
                              children: [
                                for (final u in options) _contactUnitRow(u),
                              ],
                            );
                          },
                        )
                    else ...[
                      TextField(
                        controller: _unitSearchCtrl,
                        onChanged: _onOtherUnitsSearchChanged,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Color(grey11Color),
                          hintText: '🔍 Cari cluster, tipe, atau kavling…',
                          hintStyle: TextStyle(
                            color: Color(grey5Color),
                            fontSize: 12.5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: _fieldBorder(false),
                          enabledBorder: _fieldBorder(false),
                          focusedBorder: _fieldBorder(false, focused: true),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (project == null)
                        _infoNotice('Pilih project terlebih dahulu.')
                      else
                        _otherUnitsTree(project),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(whiteColor),
                border: Border(top: BorderSide(color: Color(grey10Color))),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            countText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      customButton(_submitUnit, 'Lanjut ke Dokumen'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitUnit() {
    if (_selectedUnits.isEmpty) {
      setState(() => _showUnitValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 unit / kavling terlebih dahulu.'),
        ),
      );
      return;
    }
    final existing = {for (final d in _unitDrafts) d.unit.id: d};
    final next = <_UnitPaymentDraft>[];
    for (final u in _selectedUnits) {
      final prev = existing.remove(u.id);
      next.add(prev ?? _UnitPaymentDraft(unit: u));
    }
    for (final leftover in existing.values) {
      leftover.dispose();
    }
    setState(() {
      _unitDrafts = next;
      _step = 3;
    });
  }

  // ---------------------------------------------------------------------
  // STEP 3 — Dokumen
  // ---------------------------------------------------------------------

  Widget _payModeButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(roSelectedBgColor) : Color(whiteColor),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? Color(primaryColor) : Color(grey7Color),
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Color(primaryColor) : Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _txBlock(_UnitPaymentDraft draft, int t) {
    final tx = draft.tx[t];
    final proofError =
        _showDocumentValidation &&
        tx.mode == _PaymentMode.transfer &&
        tx.proof == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(grey10Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Metode Pembayaran ${t + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(grey4Color),
                  ),
                ),
              ),
              if (draft.tx.length > 1)
                GestureDetector(
                  onTap: () => setState(() {
                    draft.tx[t].dispose();
                    draft.tx.removeAt(t);
                  }),
                  child: Text(
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
                  tx.mode == _PaymentMode.cash,
                  () => setState(() => tx.mode = _PaymentMode.cash),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _payModeButton(
                  '🏦 Non Tunai',
                  tx.mode == _PaymentMode.transfer,
                  () => setState(() => tx.mode = _PaymentMode.transfer),
                ),
              ),
            ],
          ),
          if (tx.mode == _PaymentMode.transfer) ...[
            const SizedBox(height: 10),
            _docRow(
              icon: '🧾',
              title: 'Bukti Non Tunai',
              subtitle: 'Wajib',
              file: tx.proof,
              onTap: () => _pickDocument((f) => tx.proof = f),
              onRemove: () => setState(() => tx.proof = null),
              isError: proofError,
            ),
          ],
          const SizedBox(height: 4),
          _fieldLabel('Nominal'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _amountPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final amt = _amountPresets[i];
                final selected = tx.amount == amt;
                return ChoiceChip(
                  label: Text(
                    _formatAmountShort(amt),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Color(primaryColor) : Color(grey1Color),
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    tx.amount = amt;
                    tx.amountCtrl.text = _formatRupiah(amt);
                  }),
                  selectedColor: const Color(roSelectedBgColor),
                  backgroundColor: Color(whiteColor),
                  side: BorderSide(
                    color: selected ? Color(primaryColor) : Color(grey7Color),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: tx.amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            onChanged: (v) => setState(() => tx.amount = _parseRupiah(v)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Color(grey11Color),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: _fieldBorder(false),
              enabledBorder: _fieldBorder(false),
              focusedBorder: _fieldBorder(false, focused: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitPaymentCard(int index) {
    final draft = _unitDrafts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(roCardBgColor),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(grey10Color), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🏠 ${draft.unit.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (draft.unit.price != null)
                Text(
                  _formatRupiah(draft.unit.price!),
                  style: TextStyle(fontSize: 10.5, color: Color(grey4Color)),
                ),
            ],
          ),
          if (draft.unit.context.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Text(
                '📍 ${draft.unit.context}',
                style: TextStyle(fontSize: 10, color: Color(grey4Color)),
              ),
            ),
          _fieldLabel('Jenis Pembayaran'),
          SizedBox(
            height: 34,
            child: BlocBuilder<PaymentTypeBloc, PaymentTypeState>(
              builder: (context, state) {
                final options = state.items;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final opt = options[i];
                    final selected = draft.paymentTypeId == opt.paymentTypeId;
                    return ChoiceChip(
                      label: Text(
                        opt.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Color(primaryColor)
                              : Color(grey1Color),
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        draft.paymentType = opt.name;
                        draft.paymentTypeId = opt.paymentTypeId;
                      }),
                      selectedColor: const Color(roSelectedBgColor),
                      backgroundColor: Color(whiteColor),
                      side: BorderSide(
                        color: selected
                            ? Color(primaryColor)
                            : Color(grey7Color),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          for (int t = 0; t < draft.tx.length; t++) _txBlock(draft, t),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Pembayaran Unit Ini: ${_formatRupiah(draft.total)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(successColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => draft.tx.add(_PaymentTxDraft())),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              foregroundColor: Color(primaryColor),
              side: BorderSide(color: Color(primaryColor)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '+ Bayar Lagi untuk Unit Ini',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _document() {
    final unitLabel = _selectedUnits.length == 1
        ? _selectedUnits.first.name
        : '${_selectedUnits.length} unit';
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: Column(
        children: [
          _appBar('Reserve Order', '$_customerNameSnapshot · $unitLabel'),
          _stepIndicator(3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Dokumen Identitas Customer'),
                  _docRow(
                    icon: '🪪',
                    title: 'KTP Pemohon',
                    subtitle: 'Wajib',
                    file: _ktpFile,
                    existingUrl: _existingKtpUrl,
                    onViewExisting: () =>
                        _openExistingAttachment(_existingKtpUrl),
                    onTap: () => _pickDocument((f) {
                      _ktpFile = f;
                      _existingKtpUrl = null;
                      _existingKtpAttachmentId = null;
                    }),
                    onRemove: () => setState(() => _ktpFile = null),
                    isError:
                        _showDocumentValidation &&
                        _ktpFile == null &&
                        _existingKtpUrl == null,
                  ),
                  _docRow(
                    icon: '📄',
                    title: 'NPWP',
                    subtitle: 'Opsional',
                    file: _npwpFile,
                    existingUrl: _existingNpwpUrl,
                    onViewExisting: () =>
                        _openExistingAttachment(_existingNpwpUrl),
                    onTap: () => _pickDocument((f) {
                      _npwpFile = f;
                      _existingNpwpUrl = null;
                      _existingNpwpAttachmentId = null;
                    }),
                    onRemove: () => setState(() => _npwpFile = null),
                  ),
                  const SizedBox(height: 6),
                  _sectionLabel('Pembayaran per Unit'),
                  for (int i = 0; i < _unitDrafts.length; i++)
                    _unitPaymentCard(i),
                  const SizedBox(height: 4),
                  _fieldLabel('Catatan'),
                  TextFormField(
                    controller: _catatanCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Color(grey11Color),
                      hintText:
                          'Mis: customer transfer DP awal, dokumen menyusul',
                      hintStyle: TextStyle(
                        color: Color(grey5Color),
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: _fieldBorder(false),
                      enabledBorder: _fieldBorder(false),
                      focusedBorder: _fieldBorder(false, focused: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _footer('Lanjut ke Review', _submitDocument),
        ],
      ),
    );
  }

  void _submitDocument() {
    final hasKtp =
        _ktpFile != null ||
        (_existingKtpUrl != null && _existingKtpUrl!.isNotEmpty);
    final missingProof = _unitDrafts.any(
      (d) =>
          d.tx.any((t) => t.mode == _PaymentMode.transfer && t.proof == null),
    );
    if (!hasKtp || missingProof) {
      setState(() => _showDocumentValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !hasKtp
                ? 'KTP Pemohon wajib diupload.'
                : 'Bukti Non Tunai wajib diupload untuk semua pembayaran Non Tunai.',
          ),
        ),
      );
      return;
    }
    setState(() => _step = 4);
  }

  // ---------------------------------------------------------------------
  // STEP 4 — Review
  // ---------------------------------------------------------------------

  Widget _reviewLine(
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Color(grey1Color))),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Color(blackColor),
                ),
                children: [
                  TextSpan(text: value),
                  if (suffix != null)
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(grey4Color),
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

  Widget _reviewUnitCard(_UnitPaymentDraft d) {
    final modes = d.tx
        .map((t) => t.mode == _PaymentMode.cash ? 'Tunai' : 'Non Tunai')
        .toSet()
        .join(' + ');
    final priceLine = d.unit.price != null
        ? '${_formatRupiah(d.unit.price!)} · '
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(grey10Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏠 ${d.unit.name}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$priceLine${d.unit.context}',
              style: TextStyle(fontSize: 11, color: Color(grey4Color)),
            ),
          ),
          _reviewLine('Cara Bayar', modes),
          _reviewLine('Jenis Pembayaran', d.paymentType),
          _reviewLine(
            'Nominal Dibayar',
            _formatRupiah(d.total),
            valueColor: Color(successColor),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _review() {
    final grandTotal = _unitDrafts.fold<double>(0, (s, d) => s + d.total);
    final hasTransfer = _unitDrafts.any(
      (d) => d.tx.any((t) => t.mode == _PaymentMode.transfer),
    );
    return BlocConsumer<CreateReserveOrderCubit, CreateReserveOrderState>(
      listener: (context, state) {
        if (state is CreateReserveOrderError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is CreateReserveOrderSuccess) {
          setState(() => _step = 5);
        }
      },
      builder: (context, state) {
        final submitting = state is CreateReserveOrderSubmitting;
        return _reviewScaffold(grandTotal, hasTransfer, submitting);
      },
    );
  }

  Widget _reviewScaffold(double grandTotal, bool hasTransfer, bool submitting) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: Column(
        children: [
          _appBar('Review Reserve Order', null),
          _stepIndicator(4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(grey10Color)),
                    ),
                    child: Column(
                      children: [
                        _reviewLine('Nama Customer', _customerNameSnapshot),
                        _reviewLine(
                          'Sales Channel',
                          widget.salesChannel ?? '-',
                        ),
                        _reviewLine(
                          'Sales Channel Detail',
                          widget.salesChannelDetail ?? '-',
                        ),
                        _reviewLine(
                          'General Manager',
                          widget.salesGeneralManagerName ?? '-',
                        ),
                        _reviewLine(
                          'Sales Manager',
                          widget.salesManagerName ?? '-',
                        ),
                        _reviewLine(
                          'Sales Supervisor',
                          widget.salesSupervisorName ?? '-',
                        ),
                        _reviewLine(
                          'Sales Executive',
                          widget.salesExecutiveName ?? '-',
                        ),
                        _reviewLine('Sales Team', widget.salesTeamName ?? '-'),
                        _reviewLine(
                          'Dokumen Identitas',
                          'KTP ✓${hasTransfer ? ' · Bukti Bayar ✓' : ''}',
                          valueColor: Color(successColor),
                          suffix: '(1x, semua unit)',
                        ),
                        _reviewLine(
                          'Jumlah Unit',
                          '${_unitDrafts.length} unit',
                        ),
                        _reviewLine(
                          'Total Semua Unit',
                          '${_formatRupiah(grandTotal)} ✓',
                          valueColor: Color(successColor),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final d in _unitDrafts) _reviewUnitCard(d),
                ],
              ),
            ),
          ),
          _footer(
            submitting ? 'Mengirim...' : 'Submit Reserve Order',
            submitting ? () {} : _submitReserveOrder,
          ),
        ],
      ),
    );
  }

  void _submitReserveOrder() {
    final custBirthDate = _tglLahir != null
        ? DateFormat('yyyy-MM-dd').format(_tglLahir!)
        : null;

    final customer = <String, dynamic>{
      'cust_name': _namaCtrl.text.trim(),
      'cust_ktp': _ktpCtrl.text.trim(),
      'cust_birth_place': _tempatLahirCtrl.text.trim(),
      'cust_birth_date': custBirthDate,
      'cust_gender_is_male': _gender == 'Laki-laki',
      'cust_address1': _alamatCtrl.text.trim(),
      'cust_telp_mobile1': _hpCtrl.text.trim(),
      'cust_marital_status': _statusPernikahan,
      'work_category': _kategoriPekerjaan,
      'cust_occupation': _pekerjaanCtrl.text.trim(),
      'cara_bayar_id': _caraBayarId,
      if (_pasanganCtrl.text.trim().isNotEmpty)
        'spouse_name': _pasanganCtrl.text.trim(),
    };

    // "Cara Pembayaran Lainnya" tidak punya kolom sendiri di backend — dilipat ke reserve_note
    // biar tetap tercatat, digabung dengan catatan bebas dari step Dokumen.
    final caraBayarLainnya = _caraBayar == 'Lainnya'
        ? _caraBayarLainnyaCtrl.text.trim()
        : '';
    final catatan = _catatanCtrl.text.trim();
    final reserveNote = [
      if (caraBayarLainnya.isNotEmpty) 'Cara bayar lainnya: $caraBayarLainnya',
      if (catatan.isNotEmpty) catatan,
    ].join(' — ');

    final ktp = _ktpFile != null
        ? CreateReserveOrderFile(bytes: _ktpFile!.bytes, fileName: _ktpFile!.name)
        : (_existingKtpAttachmentId != null
              ? CreateReserveOrderFile(
                  existingAttachmentId: _existingKtpAttachmentId,
                )
              : null);
    final npwp = _npwpFile != null
        ? CreateReserveOrderFile(
            bytes: _npwpFile!.bytes,
            fileName: _npwpFile!.name,
          )
        : (_existingNpwpAttachmentId != null
              ? CreateReserveOrderFile(
                  existingAttachmentId: _existingNpwpAttachmentId,
                )
              : null);

    final units = _unitDrafts
        .map(
          (d) => CreateReserveOrderUnitParams(
            dealId: d.unit.dealId,
            companyId: d.unit.companyId,
            productId: d.unit.productId,
            propertyId: d.unit.propertyId,
            propertyName: d.unit.name,
            paymentType: d.paymentType,
            paymentTypeId: d.paymentTypeId,
            payments: d.tx
                .map(
                  (t) => CreateReserveOrderPaymentParams(
                    paymentMethod: t.mode == _PaymentMode.cash
                        ? 'cash'
                        : 'transfer',
                    amount: t.amount,
                    proofBytes: t.proof?.bytes,
                    proofFileName: t.proof?.name,
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    final params = CreateReserveOrderParams(
      contactId: widget.contactId,
      reserveNote: reserveNote.isEmpty ? null : reserveNote,
      customer: customer,
      ktp: ktp,
      npwp: npwp,
      salesExecutiveId: widget.salesExecutiveId,
      salesSupervisorId: widget.salesSupervisorId,
      salesManagerId: widget.salesManagerId,
      salesGeneralManagerId: widget.salesGeneralManagerId,
      salesTeamId: widget.salesTeamId,
      units: units,
    );

    context.read<CreateReserveOrderCubit>().submit(params);
  }

  // ---------------------------------------------------------------------
  // STEP 5 — Success
  // ---------------------------------------------------------------------

  void _goToReserveOrderList() {
    Navigator.of(context).maybePop();
  }

  void _resetForm() {
    context.read<CreateReserveOrderCubit>().reset();
    _namaCtrl.clear();
    _ktpCtrl.clear();
    _tempatLahirCtrl.clear();
    _alamatCtrl.clear();
    _hpCtrl.clear();
    _pasanganCtrl.clear();
    _pekerjaanCtrl.clear();
    _caraBayarLainnyaCtrl.clear();
    _catatanCtrl.clear();
    _unitSearchCtrl.clear();
    for (final d in _unitDrafts) {
      d.dispose();
    }
    setState(() {
      _step = 1;
      _showCustomerValidation = false;
      _showUnitValidation = false;
      _showDocumentValidation = false;
      _tglLahir = null;
      _gender = null;
      _statusPernikahan = null;
      _kategoriPekerjaan = null;
      _caraBayar = null;
      _caraBayarId = null;
      _ktpFile = null;
      _npwpFile = null;
      _existingKtpAttachmentId = widget.existingKtpAttachmentId;
      _existingNpwpAttachmentId = widget.existingNpwpAttachmentId;
      _selectedProject = null;
      _unitTab = 'contact';
      _selectedUnits = [];
      _unitDrafts = [];
      _customerNameSnapshot = '';
    });
  }

  Widget _success() {
    final multi = _unitDrafts.length > 1;
    final unitNames = _unitDrafts.map((d) => d.unit.name).join(', ');
    final text = multi
        ? '${_unitDrafts.length} Reserve Order ($unitNames) a.n. $_customerNameSnapshot sedang diproses. Dokumen identitas cukup diupload sekali untuk semuanya.'
        : '$unitNames a.n. $_customerNameSnapshot sedang diproses.';
    return Scaffold(
      backgroundColor: Color(whiteColor),
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
                      child: Icon(
                        Icons.check,
                        color: Color(successColor),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reserve Order Berhasil Diajukan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(grey4Color),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final d in _unitDrafts)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(grey10Color)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.unit.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _customerNameSnapshot,
                                    style: TextStyle(
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
                                color: Color(warningColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Diproses',
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
              decoration: BoxDecoration(
                color: Color(whiteColor),
                border: Border(top: BorderSide(color: Color(grey10Color))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    customButton(
                      _goToReserveOrderList,
                      'Lihat di Reserve Order',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: Color(grey1Color),
                          side: BorderSide(color: Color(grey7Color)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Buat Reserve Order Baru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PaymentMode { cash, transfer }

String _formatRupiah(num value) => 'Rp ${NumberHelper.thousands(value)}';

double _parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : double.parse(digits);
}

String _formatAmountShort(double v) {
  final jt = v / 1000000;
  final isWhole = jt == jt.roundToDouble();
  final label = isWhole
      ? jt.toInt().toString()
      : jt.toStringAsFixed(1).replaceAll('.', ',');
  return '${label}jt';
}

class _PaymentTxDraft {
  _PaymentMode mode = _PaymentMode.transfer;
  double amount = 3000000;
  PickedFileResult? proof;
  final TextEditingController amountCtrl;

  _PaymentTxDraft()
    : amountCtrl = TextEditingController(text: _formatRupiah(3000000));

  void dispose() => amountCtrl.dispose();
}

class _UnitPaymentDraft {
  final ReserveUnitOption unit;
  String paymentType = 'Reserve';
  int? paymentTypeId;
  final List<_PaymentTxDraft> tx;

  _UnitPaymentDraft({required this.unit}) : tx = [_PaymentTxDraft()];

  double get total => tx.fold(0, (s, t) => s + t.amount);

  void dispose() {
    for (final t in tx) {
      t.dispose();
    }
  }
}
