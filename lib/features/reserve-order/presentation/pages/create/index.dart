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
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/detail/index.dart';
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
import 'package:progress_group/features/reserve-order/presentation/widgets/reference_date_field.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_state.dart';

class CreateReserveOrderPage extends StatefulWidget {
  final int contactId;
  final String? contactName;
  final String? contactPhone;
  final String? contactKtpNumber;
  final String? contactAddress;
  final String? contactGender;
  final String? salesChannel;
  final String? salesChannelDetail;

  final int? contactProjectId;

  final List<SelectedUnit>? contactUnits;

  final String? existingKtpAttachmentUrl;
  final String? existingNpwpAttachmentUrl;

  final int? existingKtpAttachmentId;
  final int? existingNpwpAttachmentId;

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

  /// Data customer dari Reserve Order sebelumnya (key `cust_*` sama dengan `customer[...]` di
  /// `POST /reserve-order/create`) — dipakai buat isi otomatis form saat buat RO baru dari
  /// customer reserve yang sudah ada.
  final Map<String, dynamic>? initialCustomer;

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
    this.initialCustomer,
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

  // Cek No. KTP (GET /reserve-order/check-ktp): pasangan KTP+nama terakhir yg sudah dicek (biar
  // dialog gak muncul berulang tiap ketik), dan nama pemilik lama kalau KTP ini ternyata milik
  // orang lain (null = aman) — dipakai utk pesan error di field KTP & cegat tombol Lanjut.
  String? _checkedKtpKey;
  String? _ktpOwnerConflict;
  bool _checkingKtp = false;

  String? _selectedProject;
  int? _selectedProjectId;
  String _unitTab = 'contact';
  List<ReserveUnitOption> _selectedUnits = [];
  List<_UnitPaymentDraft> _unitDrafts = [];
  Timer? _otherUnitsSearchDebounce;

  String _customerNameSnapshot = '';
  CreateReserveOrderResultEntity? _createResult;

  List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  List<String> _maritalOptions = ['Menikah', 'Belum Menikah', 'Cerai'];
  List<double> _amountPresets = [2000000, 3000000, 5000000, 10000000, 15000000,20000000,25000000,50000000];

  @override
  void initState() {
    super.initState();
    if (widget.contactName != null) _namaCtrl.text = widget.contactName!;
    if (widget.contactPhone != null) _hpCtrl.text = widget.contactPhone!;
    if (widget.contactKtpNumber != null) _ktpCtrl.text = widget.contactKtpNumber!;
    if (widget.contactAddress != null) _alamatCtrl.text = widget.contactAddress!;
    if (widget.contactGender != null &&
        _genderOptions.contains(widget.contactGender)) {
      _gender = widget.contactGender;
    }
    if (widget.initialCustomer != null) {
      _applyInitialCustomer(widget.initialCustomer!);
    }
    _existingKtpUrl = widget.existingKtpAttachmentUrl;
    _existingNpwpUrl = widget.existingNpwpAttachmentUrl;
    _existingKtpAttachmentId = widget.existingKtpAttachmentId;
    _existingNpwpAttachmentId = widget.existingNpwpAttachmentId;
    if (widget.contactUnits != null && widget.contactUnits!.isEmpty) {
      _unitTab = 'other';
    }
    if (widget.contactProjectId != null) {
      final townshipState = context.read<TownshipBloc>().state;
      if (townshipState is TownshipLoaded) {
        _applyContactProject(townshipState);
      } else if (townshipState is! TownshipLoading) {
        context.read<TownshipBloc>().add(GetTownshipsEvent());
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

  void _applyInitialCustomer(Map<String, dynamic> c) {
    String? text(String key) {
      final v = c[key];
      if (v == null) return null;
      final s = '$v'.trim();
      return s.isEmpty ? null : s;
    }

    void fill(TextEditingController ctrl, String key) {
      final v = text(key);
      if (v != null) ctrl.text = v;
    }

    fill(_namaCtrl, 'cust_name');
    fill(_ktpCtrl, 'cust_ktp');
    fill(_tempatLahirCtrl, 'cust_birth_place');
    fill(_alamatCtrl, 'cust_address1');
    fill(_hpCtrl, 'cust_telp_mobile1');
    fill(_pasanganCtrl, 'spouse_name');
    fill(_pekerjaanCtrl, 'cust_occupation');
    fill(_caraBayarLainnyaCtrl, 'cara_bayar_lainnya');

    final birth = text('cust_birth_date');
    if (birth != null) _tglLahir = DateTime.tryParse(birth);

    final isMale = c['cust_gender_is_male'];
    if (isMale is bool) {
      _gender = isMale ? 'Laki-laki' : 'Perempuan';
    } else if (isMale is num) {
      _gender = isMale != 0 ? 'Laki-laki' : 'Perempuan';
    }

    final marital = text('cust_marital_status');
    if (marital != null) {
      final m = marital.toUpperCase();
      if (_maritalOptions.contains(marital)) {
        _statusPernikahan = marital;
      } else if (m.contains('BELUM')) {
        _statusPernikahan = 'Belum Menikah';
      } else if (m.contains('KAWIN') || m.contains('MENIKAH')) {
        _statusPernikahan = 'Menikah';
      } else if (m.contains('CERAI')) {
        _statusPernikahan = 'Cerai';
      }
    }

    _kategoriPekerjaan = text('work_category') ?? _kategoriPekerjaan;
    final caraBayarId = c['cara_bayar_id'];
    if (caraBayarId is num) _caraBayarId = caraBayarId.toInt();
    _caraBayar = text('cara_bayar_name') ?? _caraBayar;
  }

  /// Pilih otomatis project terakhir contact kalau user belum memilih project.
  void _applyContactProject(TownshipLoaded state) {
    if (_selectedProject != null || widget.contactProjectId == null) return;
    final match = state.townships.where((t) => t.id == widget.contactProjectId);
    if (match.isNotEmpty) {
      _onProjectChanged(match.first.name, id: match.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TownshipBloc, TownshipState>(
      listenWhen: (prev, curr) =>
          curr is TownshipLoaded &&
          _selectedProject == null &&
          widget.contactProjectId != null,
      listener: (context, state) {
        if (state is TownshipLoaded) {
          setState(() => _applyContactProject(state));
        }
      },
      child: PopScope(
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
      ),
    );
  }


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
  Widget _errorText(bool show, {String message = 'Wajib diisi'}) => show ? Padding( padding: const EdgeInsets.only(top: 4), child: Text( message, style: TextStyle(fontSize: 11, color: Color(redColor)), ), ) : const SizedBox.shrink();

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
    int? exactLength,
    ValueChanged<String>? onChanged,
    String? extraError,
  }) {
    final text = controller.text.trim();
    final isEmptyError = _showCustomerValidation && required && text.isEmpty;
    final isLengthError = _showCustomerValidation &&
        exactLength != null &&
        text.isNotEmpty &&
        text.length != exactLength;
    final isError = isEmptyError || isLengthError || extraError != null;
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
            onChanged: required || exactLength != null || onChanged != null
                ? (v) {
                    setState(() {});
                    onChanged?.call(v);
                  }
                : null,
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
          _errorText(
            isError,
            message: extraError ??
                (isLengthError ? 'Harus $exactLength digit' : 'Wajib diisi'),
          ),
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
      color: Color(available ? availableColor : holdColor),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available ? 'Available' : 'Not Available',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(available ? whiteColor : whiteColor),
      ),
    ),
  );


  Future<void> _pickKtpPhoto() async {
    final result = await CustomFilePicker.show(context, allowDocuments: false);
    if (result == null) return;
    setState(() => _ktpFile = result);
    if (!mounted) return;

    if (result.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi foto KTP tidak ditemukan.')),
      );
      return;
    }

    final cubit = context.read<CreateReserveOrderCubit>();
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? response;
    Object? error;
    try {
      response = await cubit.processOcrKtp(result.bytes!, filename: result.name);
    } catch (e) {
      error = e;
    } finally {
      navigator.pop();
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
      return;
    }

    if (response != null && response['fields'] != null) {
      final fields = response['fields'];
      setState(() {
        _namaCtrl.text = fields['cust_name'] ?? _namaCtrl.text;
        _ktpCtrl.text = fields['cust_ktp'] ?? _ktpCtrl.text;
        _tempatLahirCtrl.text = fields['cust_birth_place'] ?? _tempatLahirCtrl.text;
        
        if (fields['cust_birth_date'] != null) {
          try {
            _tglLahir = DateTime.parse(fields['cust_birth_date']);
          } catch (_) {}
        }
        if (fields['cust_gender_is_male'] != null) {
          _gender = fields['cust_gender_is_male'] == true ? 'Laki-laki' : 'Perempuan';
        }
        if (fields['cust_marital_status'] != null) {
          final s = fields['cust_marital_status'].toString().toUpperCase();
          if (s.contains('BELUM')) {
            _statusPernikahan = 'Belum Menikah';
          } else if (s.contains('KAWIN')) {
            _statusPernikahan = 'Menikah';
          } else if (s.contains('CERAI')) {
            _statusPernikahan = 'Cerai';
          }
        }
        if (fields['cust_occupation'] != null) {
          _pekerjaanCtrl.text = fields['cust_occupation'] ?? _pekerjaanCtrl.text;
        }
        
        final addr1 = fields['cust_address1'] ?? '';
        final addr2 = fields['cust_address2'] ?? '';
        if (addr1.toString().isNotEmpty || addr2.toString().isNotEmpty) {
          _alamatCtrl.text = '$addr1 $addr2'.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data KTP berhasil dibaca. Mohon periksa kembali.'),
        ),
      );
      // Hasil scan langsung dicek juga — sales gak perlu tahu ada langkah "cek NIK".
      if (_ktpCtrl.text.trim().length == 16) _checkKtp();
    }
  }

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _onKtpChanged(String value) {
    final ktp = value.trim();
    if (ktp.length == 16) {
      _checkKtp();
    } else if (_ktpOwnerConflict != null) {
      setState(() => _ktpOwnerConflict = null);
    }
  }

  /// Cek No. KTP ke server & tampilkan dialog kalau sudah terdaftar. Balik `true` kalau boleh
  /// lanjut ke step Unit. Gagal koneksi → dianggap boleh (server tetap validasi saat simpan).
  /// [force] = tetap cek walau pasangan KTP+nama ini sudah pernah dicek (dipakai tombol Lanjut
  /// selama masih ada bentrok, supaya dialognya muncul lagi).
  Future<bool> _checkKtp({bool force = false}) async {
    final ktp = _ktpCtrl.text.trim();
    final name = _namaCtrl.text.trim();
    if (ktp.length != 16 || _checkingKtp) return _ktpOwnerConflict == null;
    final key = '$ktp|${name.toLowerCase()}';
    if (!force && key == _checkedKtpKey) return _ktpOwnerConflict == null;

    _checkingKtp = true;
    final res = await context.read<CreateReserveOrderCubit>().checkKtp(
          ktp,
          custName: name.isEmpty ? null : name,
        );
    _checkingKtp = false;
    if (!mounted || res == null) return true;
    // KTP sudah diganti lagi selama request jalan → hasil ini basi.
    if (_ktpCtrl.text.trim() != ktp) return _ktpOwnerConflict == null;
    _checkedKtpKey = key;

    // Customer milik sales lain (di luar scope) → server TIDAK kirim datanya, jadi cuma kasih tau
    // & sales isi sendiri. Nama beda tetap ditahan (pasti ditolak saat simpan), tapi nama pemilik
    // tidak ditampilkan — '' = bentrok dgn nama yg disembunyikan.
    if (res['found'] == true && res['in_scope'] == false) {
      final nameMatch = res['name_match'] as bool?;
      await _showOtherSalesDialog(
        handledBy: '${res['handled_by'] ?? ''}'.trim(),
        nameMismatch: nameMatch == false,
      );
      if (!mounted) return false;
      final blocked = nameMatch == false;
      setState(() => _ktpOwnerConflict = blocked ? '' : null);
      return !blocked;
    }

    final customer = res['customer'] as Map<String, dynamic>?;
    if (res['found'] != true || customer == null) {
      if (_ktpOwnerConflict != null) setState(() => _ktpOwnerConflict = null);
      return true;
    }

    final ownerName = '${customer['cust_name'] ?? ''}'.trim();
    final nameMatch = res['name_match'] as bool?; // null = nama belum diisi
    final orders = (res['reserve_orders'] as List?) ?? const [];
    final docs = (res['documents'] as Map?) ?? const {};
    final hasOldKtpPhoto = docs['ktp'] != null && _ktpFile == null;

    final useOldData = await _showKtpFoundDialog(
      ownerName: ownerName,
      typedName: name,
      nameMatch: nameMatch,
      units: [
        for (final o in orders)
          if ('${(o as Map)['property_name'] ?? ''}'.trim().isNotEmpty)
            '${o['property_name']}'.trim(),
      ],
      unitCount: orders.length,
      hasOldKtpPhoto: hasOldKtpPhoto,
    );
    if (!mounted) return false;

    if (useOldData == true) {
      setState(() {
        _applyInitialCustomer(customer);
        _applyOldDocuments(docs);
        _ktpOwnerConflict = null;
        _checkedKtpKey = '$ktp|${ownerName.toLowerCase()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data customer sudah diisi otomatis. Cek lagi ya sebelum lanjut.'),
        ),
      );
      return true;
    }

    // Nama cocok tapi sales pilih isi sendiri → boleh; nama beda / "bukan orang ini" → tahan.
    final blocked = nameMatch != true;
    setState(() => _ktpOwnerConflict = blocked ? ownerName : null);
    return !blocked;
  }

  /// Pakai foto KTP/NPWP yang dulu pernah diupload — KECUALI sales barusan foto yang baru.
  void _applyOldDocuments(Map docs) {
    final ktp = docs['ktp'] as Map?;
    if (ktp != null && _ktpFile == null) {
      _existingKtpUrl = ktp['attachment_path'] as String?;
      _existingKtpAttachmentId = (ktp['contact_attachment_id'] as num?)?.toInt();
    }
    final npwp = docs['npwp'] as Map?;
    if (npwp != null && _npwpFile == null) {
      _existingNpwpUrl = npwp['attachment_path'] as String?;
      _existingNpwpAttachmentId = (npwp['contact_attachment_id'] as num?)?.toInt();
    }
  }

  /// Dialog "No. KTP sudah terdaftar" — bahasa awam, satu tombol utama. Balik true = pakai data
  /// lama (isi otomatis), false/null = tidak.
  /// Dialog "Customer ini dipegang sales lain" — cuma pemberitahuan (1 tombol), tanpa data
  /// customer apa pun krn memang tidak dikirim server.
  Future<void> _showOtherSalesDialog({
    required String handledBy,
    required bool nameMismatch,
  }) {
    const bodyStyle = TextStyle(fontSize: 13, height: 1.45, color: Color(blackColor));
    const bold = TextStyle(fontWeight: FontWeight.w700);
    final salesText = handledBy.isEmpty ? 'sales lain' : handledBy;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(whiteColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Color(warningColor), size: 26),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Customer ini dipegang sales lain',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  const TextSpan(text: 'No. KTP ini sudah terdaftar dan ditangani oleh '),
                  TextSpan(text: salesText, style: bold),
                  const TextSpan(text: ', jadi datanya tidak bisa diisi otomatis.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nameMismatch
                  ? 'Nama yang kamu isi tidak sama dengan data yang terdaftar. Cek lagi nama & No. KTP sesuai KTP customer.'
                  : 'Kamu tetap bisa lanjut dengan mengisi data customer sendiri sesuai KTP.',
              style: bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: nameMismatch ? Color(redColor) : Color(blackColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kalau ada yang janggal, hubungi $salesText atau admin.',
              style: TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(primaryColor),
                foregroundColor: Color(whiteColor),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showKtpFoundDialog({
    required String ownerName,
    required String typedName,
    required bool? nameMatch,
    required List<String> units,
    required int unitCount,
    required bool hasOldKtpPhoto,
  }) {
    final isConflict = nameMatch == false;
    final title = nameMatch == true
        ? 'Customer lama ditemukan'
        : (isConflict ? 'No. KTP ini sudah dipakai' : 'No. KTP ini sudah terdaftar');
    final unitText = unitCount == 0
        ? ''
        : ' dan sudah pernah reserve $unitCount unit'
            '${units.isEmpty ? '' : ' (${units.take(3).join(', ')}${units.length > 3 ? ', …' : ''})'}';
    const bodyStyle = TextStyle(fontSize: 13, height: 1.45, color: Color(blackColor));
    const bold = TextStyle(fontWeight: FontWeight.w700);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(whiteColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Row(
          children: [
            Icon(
              isConflict ? Icons.error_outline : Icons.person_search_outlined,
              color: Color(isConflict ? warningColor : primaryColor),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  const TextSpan(text: 'No. KTP ini terdaftar atas nama '),
                  TextSpan(text: ownerName, style: bold),
                  TextSpan(text: '$unitText.'),
                  if (isConflict) ...[
                    const TextSpan(text: '\n\nNama yang kamu isi: '),
                    TextSpan(text: typedName, style: bold),
                    const TextSpan(text: '.'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nameMatch == true
                  ? 'Mau datanya diisi otomatis? Kamu tinggal cek lalu lanjut.'
                  : 'Apakah ini orang yang sama?',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            if (hasOldKtpPhoto) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Color(successColor)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Foto KTP lama juga dipakai, tidak perlu foto ulang.',
                      style: TextStyle(fontSize: 12, color: Color(successColor)),
                    ),
                  ),
                ],
              ),
            ],
            if (isConflict) ...[
              const SizedBox(height: 10),
              Text(
                'Kalau bukan, cek lagi No. KTP-nya — satu No. KTP hanya untuk satu orang.',
                style: TextStyle(fontSize: 12, color: Color(grey2Color)),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(primaryColor),
                foregroundColor: Color(whiteColor),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(
                nameMatch == true
                    ? 'Isi Otomatis'
                    : 'Ya, pakai data $ownerName',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: Color(grey2Color)),
              child: Text(
                nameMatch == true ? 'Isi Sendiri' : 'Bukan, cek No. KTP lagi',
              ),
            ),
          ),
        ],
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
                    onChanged: (v) {
                      // Nama sudah dibetulkan jadi nama pemilik KTP → peringatan hilang sendiri.
                      if ((_ktpOwnerConflict ?? '').isNotEmpty &&
                          _sameName(v, _ktpOwnerConflict!)) {
                        setState(() => _ktpOwnerConflict = null);
                      }
                    },
                  ),
                  _textField(
                    label: 'No. KTP',
                    controller: _ktpCtrl,
                    required: true,
                    hint: '16 digit NIK',
                    exactLength: 16,
                    onChanged: _onKtpChanged,
                    extraError: _ktpOwnerConflict == null
                        ? null
                        : (_ktpOwnerConflict!.isEmpty
                            ? 'No. KTP ini sudah terdaftar dengan nama lain. Pastikan nama sesuai KTP.'
                            : 'No. KTP ini sudah terdaftar atas nama $_ktpOwnerConflict'),
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

  Future<void> _submitCustomer() async {
    final requiredOk =
        _namaCtrl.text.trim().isNotEmpty &&
        _ktpCtrl.text.trim().length == 16 &&
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
    // Cek ulang No. KTP (nama bisa sudah diganti sejak dicek) — kalau masih bentrok, dialog
    // muncul lagi di sini, BUKAN baru ketahuan di step Review saat simpan.
    final ktpOk = await _checkKtp(force: _ktpOwnerConflict != null);
    if (!mounted || !ktpOk) return;
    _customerNameSnapshot = _namaCtrl.text.trim();
    setState(() => _step = 2);
  }


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
            ],
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

  Widget _otherClusterHeaderTile(
    bool expanded,
    String name,
    int totalAvailable,
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
            const SizedBox(width: 8),
            _availableCount(totalAvailable),
          ],
        ),
      ),
    );
  }

  Widget _availableCount(int total) => Text(
    '$total tersedia',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: total > 0 ? Color(primaryColor) : Color(grey5Color),
    ),
  );

  Widget _otherProductHeaderTile(
    bool expanded,
    String tipe,
    String sub,
    int totalAvailable,
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
          const SizedBox(width: 8),
          _availableCount(totalAvailable),
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
        product.totalAvailable,
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
          for (final lot in lots.where(
            (l) => (l.displayStatusName ?? 'Available') == 'Available',
          ))
            _kavlingRow(
              ReserveUnitOption(
                id: 'lot-${cluster.projectId}-${product.productId}-${lot.propertyId}',
                name: lot.propertyName,
                context: contextLabel,
                available: true,
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
          cluster.totalAvailable,
          () => cubit.toggleCluster(cluster.projectId),
        ),
      ),
      if (expanded)
        for (final product in cluster.products)
          ..._otherProductTiles(cubit, state, project, cluster, product),
    ];
  }

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
      body: Column(
          children: [
            _appBar('Pilih Unit', _customerNameSnapshot),
            _stepIndicator(2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ReferenceDateField(
              value: tx.referenceDate,
              onChanged: (d) => setState(() => tx.referenceDate = d),
              isError: _showDocumentValidation && tx.referenceDate == null,
            ),
          ],
          const SizedBox(height: 4),
          _fieldLabel('Nominal'),
          SizedBox(
            height: 46,
            width: 300,
            child: Scrollbar(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: _amountPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final amt = _amountPresets[i];
                  final selected = tx.amount == amt;
                  return ChoiceChip(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                      final selected = draft.paymentTypeId == opt.paymentTypeId;
                      final isError =
                          _showDocumentValidation && draft.paymentTypeId == null;
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
                              : isError
                              ? Color(redColor)
                              : Color(grey7Color),
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
          _errorText(
            _showDocumentValidation && draft.paymentTypeId == null,
            message: 'Pilih jenis pembayaran',
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
                    onViewExisting: () =>_openExistingAttachment(_existingKtpUrl),
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
    final hasKtp = _hasKtp;
    final missingPaymentType = _unitDrafts.any((d) => d.paymentTypeId == null);
    final missingProof = _unitDrafts.any(
      (d) =>
          d.tx.any((t) => t.mode == _PaymentMode.transfer && t.proof == null),
    );
    final missingReferenceDate = _unitDrafts.any(
      (d) => d.tx.any(
        (t) => t.mode == _PaymentMode.transfer && t.referenceDate == null,
      ),
    );
    if (!hasKtp || missingPaymentType || missingProof || missingReferenceDate) {
      setState(() => _showDocumentValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !hasKtp
                ? 'KTP Pemohon wajib diupload.'
                : missingPaymentType
                ? 'Jenis Pembayaran wajib dipilih untuk semua unit.'
                : missingProof
                ? 'Bukti Non Tunai wajib diupload untuk semua pembayaran Non Tunai.'
                : 'Tanggal Bukti Transfer wajib diisi untuk semua pembayaran Non Tunai.',
          ),
        ),
      );
      return;
    }
    setState(() => _step = 4);
  }


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

  bool get _hasKtp =>
      _ktpFile != null || (_existingKtpUrl != null && _existingKtpUrl!.isNotEmpty);

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
          setState(() {
            _createResult = state.result;
            _step = 5;
          });
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
                          _hasKtp
                              ? 'KTP ✓${hasTransfer ? ' · Bukti Bayar ✓' : ''}'
                              : 'KTP belum diupload',
                          valueColor: _hasKtp
                              ? Color(successColor)
                              : Color(redColor),
                          suffix: _hasKtp ? '(1x, semua unit)' : null,
                        ),
                        _reviewLine(
                          'Jumlah Unit',
                          '${_unitDrafts.length} unit',
                        ),
                        _reviewLine(
                          'Total Semua Unit',
                          '${_formatRupiah(grandTotal)} ✓',
                          valueColor: Color(successColor),
                        ),
                        _reviewLine(
                          'Catatan',
                          _catatanCtrl.text.trim().isEmpty
                              ? '-'
                              : _catatanCtrl.text.trim(),
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
    if (!_hasKtp) {
      setState(() {
        _step = 3;
        _showDocumentValidation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dokumen KTP Pemohon belum ada — silakan upload ulang.',
          ),
        ),
      );
      return;
    }

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
      if (_caraBayar == 'Lainnya' && _caraBayarLainnyaCtrl.text.trim().isNotEmpty)
        'cara_bayar_lainnya': _caraBayarLainnyaCtrl.text.trim(),
      if (_pasanganCtrl.text.trim().isNotEmpty)
        'spouse_name': _pasanganCtrl.text.trim(),
    };

    final reserveNote = _catatanCtrl.text.trim();

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
                    referenceDate: t.mode == _PaymentMode.transfer
                        ? t.referenceDate
                        : null,
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


  void _goToReserveOrderList() {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    navigator.popUntil((route) => route.isFirst);
    router.goNamed('reserve_order');
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
      _existingKtpUrl = widget.existingKtpAttachmentUrl;
      _existingKtpAttachmentId = widget.existingKtpAttachmentId;
      _existingNpwpUrl = widget.existingNpwpAttachmentUrl;
      _existingNpwpAttachmentId = widget.existingNpwpAttachmentId;
      _checkedKtpKey = null;
      _ktpOwnerConflict = null;
      _selectedProject = null;
      _unitTab = 'contact';
      _selectedUnits = [];
      _unitDrafts = [];
      _customerNameSnapshot = '';
      _createResult = null;
    });
  }

  void _openReserveOrderDetail(int reserveOrderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReserveOrderDetailPage(reserveOrderId: reserveOrderId),
      ),
    );
  }

  Widget _successOrderCard(CreateReserveOrderItemEntity o, String custName) {
    final sub = [
      custName,
      if (o.ttsNumber.isNotEmpty) 'TTS ${o.ttsNumber}',
      if (o.amountRp > 0) _formatRupiah(o.amountRp),
    ].where((e) => e.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openReserveOrderDetail(o.reserveOrderId),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      o.propertyName ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(fontSize: 9.5, color: Color(grey4Color)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Color(grey5Color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _success() {
    final orders = _createResult?.orders ?? const <CreateReserveOrderItemEntity>[];
    final custName = (_createResult?.custName ?? '').isNotEmpty
        ? _createResult!.custName
        : _customerNameSnapshot;
    final multi = orders.length > 1;
    final unitNames = orders.map((o) => o.propertyName ?? '-').join(', ');
    final text = multi
        ? '${orders.length} Reserve Order ($unitNames) a.n. $custName sedang diproses. Dokumen identitas cukup diupload sekali untuk semuanya.'
        : '$unitNames a.n. $custName sedang diproses.';
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
                    for (final o in orders) _successOrderCard(o, custName),
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
                      orders.length == 1
                          ? () => _openReserveOrderDetail(
                              orders.first.reserveOrderId,
                            )
                          : _goToReserveOrderList,
                      orders.length == 1
                          ? 'Lihat Detail Reserve Order'
                          : 'Lihat di Reserve Order',
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

  /// Tanggal bukti transfer (`reference_date`) — wajib untuk Non Tunai.
  DateTime? referenceDate;
  final TextEditingController amountCtrl;

  _PaymentTxDraft()
    : amountCtrl = TextEditingController(text: _formatRupiah(3000000));

  void dispose() => amountCtrl.dispose();
}

class _UnitPaymentDraft {
  final ReserveUnitOption unit;
  String paymentType = '';
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
