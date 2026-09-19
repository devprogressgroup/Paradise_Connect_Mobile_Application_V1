import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_unit_dummy_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_unit_option.dart';

class CreateReserveOrderPage extends StatefulWidget {
  final String? contactName;
  final String? contactPhone;
  final String? salesChannel;
  final String? salesChannelDetail;

  const CreateReserveOrderPage({
    super.key,
    this.contactName,
    this.contactPhone,
    this.salesChannel,
    this.salesChannelDetail,
  });

  @override
  State<CreateReserveOrderPage> createState() => _CreateReserveOrderPageState();
}

class _CreateReserveOrderPageState extends State<CreateReserveOrderPage> {
  final _unitDataSource = const ReserveUnitDummyDataSource();

  int _step = 1;
  int _resetKey = 0;

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

  PickedFileResult? _ktpFile;
  PickedFileResult? _npwpFile;

  String? _selectedProject;
  String _unitTab = 'contact';
  List<ReserveUnitOption> _selectedUnits = [];
  List<_UnitPaymentDraft> _unitDrafts = [];

  String _customerNameSnapshot = '';

  List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  List<String> _maritalOptions = ['Menikah', 'Belum Menikah', 'Cerai'];
  List<String> _jobCategoryOptions = ['Wiraswasta', 'Pegawai', 'Profesional'];
  List<String> _paymentMethodOptions = ['KPR', 'Cash Keras', 'Cash Bertahap', 'Lainnya'];
  List<String> _paymentTypeOptions = ['Reserve', 'Top up Reserve', 'RB', 'Top up RB', 'SP', 'Top up SP'];
  List<double> _amountPresets = [2000000, 3000000, 5000000, 10000000, 15000000];


  @override
  void initState() {
    super.initState();
    if (widget.contactName != null) _namaCtrl.text = widget.contactName!;
    if (widget.contactPhone != null) _hpCtrl.text = widget.contactPhone!;
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
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: _goBack),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Color(grey4Color))),
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
              final color = idx < step ? Color(successColor) : (idx == step ? Color(primaryColor) : Color(grey9Color));
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
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
                  textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center),
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
      decoration: BoxDecoration(color: Color(whiteColor), border: Border(top: BorderSide(color: Color(grey10Color)))),
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
        child: Text(text, style: TextStyle(fontSize: 11, color: Color(grey4Color), fontWeight: FontWeight.w600)),
      );

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            children: [
              TextSpan(text: text, style: TextStyle(color: Color(grey1Color))),
              if (required) TextSpan(text: ' *', style: TextStyle(color: Color(redColor))),
            ],
          ),
        ),
      );

InputBorder _fieldBorder(bool isError, {bool focused = false}) => UnderlineInputBorder(
      borderSide: BorderSide(
        color: isError 
            ? Color(redColor) 
            : (focused ? Color(primaryColor) : Color(grey7Color)),
      ),
    );
  Widget _errorText(bool show) =>
      show ? Padding(padding: const EdgeInsets.only(top: 4), child: Text('Wajib diisi', style: TextStyle(fontSize: 11, color: Color(redColor)))) : const SizedBox.shrink();

  /// Bingkai field underline — gaya sama seperti `EditCustomerReserveOrderPage` (border cuma di
  /// bawah, bukan kotak grey11 terpisah). Dipakai khusus field-field step Customer; step lain
  /// (Unit/Dokumen) tetap pakai gaya kotak `_fieldBorder` yang sudah ada.
  Widget _underlineFieldFrame(Widget child, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(width: 1, color: isError ? Color(redColor) : Color(grey9Color))),
      ),
      child: child,
    );
  }

  /// Sheet pilihan teks polos — dipasangkan dengan field "pilihan" underline (dropdown/tanggal),
  /// gaya sama seperti `EditCustomerReserveOrderPage._showOptionSheet`.
  void _showOptionSheet({required String title, required List<String> items, required String? selected, required ValueChanged<String> onPicked}) {
    showCustomBottomSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(blackColor))),
          ),
          for (final item in items)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPicked(item);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Color(blackColor)))),
                    if (item == selected) const Icon(Icons.check, size: 18, color: Color(primaryColor)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Label + bintang merah kalau [required] — dipakai bareng field underline (text/picker) biar
  /// tetap kelihatan wajib walau desainnya sudah tidak pakai kotak `_fieldLabel` yang lama.
  Widget _requiredLabel(String text, {required bool required, required TextStyle style}) {
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          if (required) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Baris "pilihan" underline (dropdown/tanggal) — label kecil di atas nilai kalau sudah terisi,
  /// atau label besar sebagai placeholder kalau masih kosong, + panah dropdown di kanan. Gaya sama
  /// seperti `EditCustomerReserveOrderPage._buildPickerField`.
  Widget _pickerFieldRow({required String label, required String? value, required VoidCallback onTap, bool isError = false, bool required = false}) {
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
                      if (!isEmpty) _requiredLabel(label, required: required, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor)),
                      isEmpty
                          ? _requiredLabel(label, required: required, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor))
                          : Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blackColor))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28, color: Color(grey4Color)),
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
    final isError = _showCustomerValidation && required && controller.text.trim().isEmpty;
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blackColor)),
            onChanged: required ? (_) => setState(() {}) : null,
            decoration: InputDecoration(
              isDense: true,
              label: _requiredLabel(label, required: required, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor)),
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
      onTap: () => _showOptionSheet(title: label, items: items, selected: value, onPicked: (v) => setState(() => onChanged(v))),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool required = false,
  }) {
    final isError = _showCustomerValidation && required && value == null;
    final displayValue = value == null ? null : DateFormat('dd MMMM yyyy', 'id_ID').format(value);
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

  /// Baris underline read-only (tanpa interaksi) — dipakai buat Sales Channel/Detail yang cuma
  /// ditampilkan, bukan diedit di halaman ini. Border-bawahnya dipertegas (`grey7Color`) & nilainya
  /// dibuat lebih kebaca (`grey1Color`) biar tidak nyatu sama garis pembatasnya.
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(grey2Color))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(grey1Color))),
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
  }) {
    final uploaded = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isError ? Color(redColor) : Color(grey10Color)),
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
                  decoration: BoxDecoration(color: Color(grey11Color), borderRadius: BorderRadius.circular(9)),
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                        children: [
                          TextSpan(text: title),
                          TextSpan(text: ' · $subtitle', style: TextStyle(fontSize: 10.5, color: Color(grey4Color), fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(uploaded ? 'Terupload' : 'Ketuk untuk upload', style: TextStyle(fontSize: 10.5, color: uploaded ? Color(grey4Color) : Color(primaryColor))),
                  ],
                ),
              ),
              if (uploaded) Icon(Icons.check_circle, color: Color(successColor), size: 18),
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

  Widget _checkbox(bool checked) => Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: checked ? Color(primaryColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: checked ? Color(primaryColor) : Color(grey7Color), width: 1.5),
        ),
        child: checked ? Icon(Icons.check, size: 13, color: Color(whiteColor)) : null,
      );

  Widget _availabilityBadge(bool available) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Color(available ? availableColor : reserveColor), borderRadius: BorderRadius.circular(20)),
        child: Text(
          available ? 'Available' : 'Not Available',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(available ? roAvailableTextColor : roUnavailableTextColor)),
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
      const SnackBar(content: Text('Foto KTP tersimpan sebagai dokumen KTP Pemohon. Lengkapi data di bawah secara manual.')),
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
                            side: BorderSide(color: Color(primaryColor), width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          ),
                          child: const Text('📷 Ambil Foto KTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        if (_ktpFile != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              FilePreviewWidget(file: _ktpFile!, size: 52, onRemove: () => setState(() => _ktpFile = null)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Foto KTP tersimpan sebagai dokumen KTP Pemohon', style: TextStyle(fontSize: 11, color: Color(successColor))),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  _textField(label: 'Nama Lengkap (sesuai KTP)', controller: _namaCtrl, required: true),
                  _textField(
                    label: 'No. KTP',
                    controller: _ktpCtrl,
                    required: true,
                    hint: '16 digit NIK',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                  ),
                  _textField(label: 'Tempat Lahir', controller: _tempatLahirCtrl, required: true),
                  _dateField(label: 'Tanggal Lahir', value: _tglLahir, required: true, onChanged: (v) => _tglLahir = v),
                  _dropdownField(label: 'Jenis Kelamin', value: _gender, items: _genderOptions, required: true, onChanged: (v) => _gender = v),
                  _textField(label: 'Alamat (sesuai KTP)', controller: _alamatCtrl, required: true, maxLines: 2),
                  _textField(label: 'No. HP', controller: _hpCtrl, required: true, keyboardType: TextInputType.phone),
                  _dropdownField(
                    label: 'Status Pernikahan',
                    value: _statusPernikahan,
                    items: _maritalOptions,
                    required: true,
                    onChanged: (v) => _statusPernikahan = v,
                  ),
                  if (_statusPernikahan == 'Menikah') _textField(label: 'Nama Pasangan', controller: _pasanganCtrl, required: true, hint: 'Nama pasangan…'),
                  _dropdownField(
                    label: 'Kategori Pekerjaan',
                    value: _kategoriPekerjaan,
                    items: _jobCategoryOptions,
                    required: true,
                    onChanged: (v) => _kategoriPekerjaan = v,
                  ),
                  _textField(label: 'Pekerjaan', controller: _pekerjaanCtrl, required: true),
                  _dropdownField(
                    label: 'Cara Pembayaran',
                    value: _caraBayar,
                    items: _paymentMethodOptions,
                    required: true,
                    onChanged: (v) => _caraBayar = v,
                  ),
                  if (_caraBayar == 'Lainnya') _textField(label: 'Cara Pembayaran Lainnya', controller: _caraBayarLainnyaCtrl, required: true, hint: 'Tulis cara pembayaran…'),
                  _readOnlyFieldRow('Sales Channel', widget.salesChannel ?? '-'),
                  _readOnlyFieldRow('Sales Channel Detail', widget.salesChannelDetail ?? '-'),
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
    final requiredOk = _namaCtrl.text.trim().isNotEmpty &&
        _ktpCtrl.text.trim().isNotEmpty &&
        _tempatLahirCtrl.text.trim().isNotEmpty &&
        _tglLahir != null &&
        _gender != null &&
        _alamatCtrl.text.trim().isNotEmpty &&
        _hpCtrl.text.trim().isNotEmpty &&
        _statusPernikahan != null &&
        (_statusPernikahan != 'Menikah' || _pasanganCtrl.text.trim().isNotEmpty) &&
        _kategoriPekerjaan != null &&
        _pekerjaanCtrl.text.trim().isNotEmpty &&
        _caraBayar != null &&
        (_caraBayar != 'Lainnya' || _caraBayarLainnyaCtrl.text.trim().isNotEmpty);

    if (!requiredOk) {
      setState(() => _showCustomerValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi dahulu data yang wajib diisi.')));
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
        const SnackBar(content: Text('Unit ini belum tersedia. Silakan hubungi admin untuk membuka unit ini.')),
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

  Widget _unitTabButton(String label, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? Color(primaryColor) : Color(grey11Color), borderRadius: BorderRadius.circular(9)),
          child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Color(whiteColor) : Color(grey1Color))),
        ),
      );

  Widget _infoNotice(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: const Color(roNoticeInfoBgColor), borderRadius: BorderRadius.circular(11)),
        child: Text(text, style: const TextStyle(fontSize: 11, color: Color(roNoticeInfoTextColor), height: 1.4)),
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
              color: selected ? const Color(roSelectedBgColor) : Color(whiteColor),
              border: Border.all(color: selected ? Color(primaryColor) : Color(grey10Color), width: 1.4),
            ),
            child: Row(
              children: [
                _checkbox(selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text(u.context, style: TextStyle(fontSize: 10, color: Color(grey4Color))),
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
          decoration: BoxDecoration(color: selected ? const Color(roSelectedBgColor) : null, borderRadius: BorderRadius.circular(9)),
          child: Row(
            children: [
              _checkbox(selected),
              const SizedBox(width: 10),
              Text(
                u.name,
                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: isWaiting ? Color(warningColor) : Color(grey4Color)),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => _toggleUnit(u),
        borderRadius: BorderRadius.circular(9),
        child: Opacity(
          opacity: u.available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(color: selected ? const Color(roSelectedBgColor) : null, borderRadius: BorderRadius.circular(9)),
            child: Row(
              children: [
                _checkbox(selected),
                const SizedBox(width: 10),
                Expanded(child: Text(u.name, style: const TextStyle(fontSize: 12.5))),
                if (!u.available) _availabilityBadge(false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clusterHeader(String cluster) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(cluster, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      );

  Widget _tipeHeader(String tipe, String sub) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(color: Color(grey11Color), borderRadius: BorderRadius.circular(9)),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
            children: [
              TextSpan(text: tipe),
              TextSpan(text: '  $sub', style: TextStyle(fontSize: 9.5, color: Color(grey4Color), fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      );

  Widget _otherUnitsList(String project) {
    final groups = _unitDataSource.getOtherUnitGroups(project);
    final term = _unitSearchCtrl.text.trim().toLowerCase();
    final widgets = <Widget>[];
    String? lastCluster;
    for (final g in groups) {
      final matchGroup = term.isEmpty || g.cluster.toLowerCase().contains(term) || g.tipe.toLowerCase().contains(term);
      final kavlings = g.kavlings.where((k) => matchGroup || (!k.special && k.name.toLowerCase().contains(term))).toList();
      if (kavlings.isEmpty) continue;
      if (g.cluster != lastCluster) {
        widgets.add(_clusterHeader(g.cluster));
        lastCluster = g.cluster;
      }
      widgets.add(_tipeHeader(g.tipe, g.tipeSub));
      final contextLabel = '$project · ${g.cluster} · ${g.tipe} · ${g.tipeSub}';
      for (final k in kavlings) {
        final withContext = k.copyWith(context: contextLabel);
        widgets.add(k.special ? _specialRow(withContext) : _kavlingRow(withContext));
      }
    }
    if (widgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('Tidak ada cluster/tipe/kavling yang cocok.', style: TextStyle(fontSize: 12, color: Color(grey4Color))),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _unit() {
    final project = _selectedProject;
    final countText =
        _selectedUnits.isEmpty ? 'Belum ada unit dipilih' : '${_selectedUnits.length} unit dipilih: ${_selectedUnits.map((u) => u.name).join(', ')}';
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
                  _fieldLabel('Pilih Project', required: true),
                  DropdownButtonFormField<String>(
                    key: ValueKey('project-$_resetKey'),
                    initialValue: _selectedProject,
                    isExpanded: true,
                    hint: const Text('Pilih project', style: TextStyle(fontSize: 13)),
                    items: _unitDataSource.getProjects().map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() {
                      _selectedProject = v;
                      _selectedUnits = [];
                    }),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Color(grey11Color),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      border: _fieldBorder(false),
                      enabledBorder: _fieldBorder(_showUnitValidation && project == null),
                      focusedBorder: _fieldBorder(false, focused: true),
                    ),
                  ),
                  _errorText(_showUnitValidation && project == null),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _unitTabButton('Unit dari Contact', _unitTab == 'contact', () => setState(() => _unitTab = 'contact'))),
                      const SizedBox(width: 8),
                      Expanded(child: _unitTabButton('Pilih Unit Lain', _unitTab == 'other', () => setState(() => _unitTab = 'other'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_unitTab == 'contact')
                    if (project == null)
                      _infoNotice('Pilih project terlebih dahulu.')
                    else if (_unitDataSource.getContactUnits(project).isEmpty)
                      _infoNotice('Belum ada unit dari Contact untuk project ini. Coba tab "Pilih Unit Lain".')
                    else
                      Column(children: [for (final u in _unitDataSource.getContactUnits(project)) _contactUnitRow(u)])
                  else ...[
                    TextField(
                      controller: _unitSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Color(grey11Color),
                        hintText: '🔍 Cari cluster, tipe, atau kavling…',
                        hintStyle: TextStyle(color: Color(grey5Color), fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: _fieldBorder(false),
                        enabledBorder: _fieldBorder(false),
                        focusedBorder: _fieldBorder(false, focused: true),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (project == null) _infoNotice('Pilih project terlebih dahulu.') else _otherUnitsList(project),
                  ],
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Color(whiteColor), border: Border(top: BorderSide(color: Color(grey10Color)))),
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
                        child: Text(countText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 unit / kavling terlebih dahulu.')));
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
          border: Border.all(color: selected ? Color(primaryColor) : Color(grey7Color), width: 1.3),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Color(primaryColor) : Color(grey1Color))),
      ),
    );
  }

  Widget _txBlock(_UnitPaymentDraft draft, int t) {
    final tx = draft.tx[t];
    final proofError = _showDocumentValidation && tx.mode == _PaymentMode.transfer && tx.proof == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Color(whiteColor), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(grey10Color))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Metode Pembayaran ${t + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(grey4Color)))),
              if (draft.tx.length > 1)
                GestureDetector(
                  onTap: () => setState(() {
                    draft.tx[t].dispose();
                    draft.tx.removeAt(t);
                  }),
                  child: Text('✕ Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(redColor))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _payModeButton('💵 Tunai', tx.mode == _PaymentMode.cash, () => setState(() => tx.mode = _PaymentMode.cash))),
              const SizedBox(width: 8),
              Expanded(child: _payModeButton('🏦 Non Tunai', tx.mode == _PaymentMode.transfer, () => setState(() => tx.mode = _PaymentMode.transfer))),
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
                  label: Text(_formatAmountShort(amt), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Color(primaryColor) : Color(grey1Color))),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    tx.amount = amt;
                    tx.amountCtrl.text = _formatRupiah(amt);
                  }),
                  selectedColor: const Color(roSelectedBgColor),
                  backgroundColor: Color(whiteColor),
                  side: BorderSide(color: selected ? Color(primaryColor) : Color(grey7Color)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              Expanded(child: Text('🏠 ${draft.unit.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              if (draft.unit.price != null) Text(_formatRupiah(draft.unit.price!), style: TextStyle(fontSize: 10.5, color: Color(grey4Color))),
            ],
          ),
          if (draft.unit.context.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 2, bottom: 10), child: Text('📍 ${draft.unit.context}', style: TextStyle(fontSize: 10, color: Color(grey4Color)))),
          _fieldLabel('Jenis Pembayaran'),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paymentTypeOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final opt = _paymentTypeOptions[i];
                final selected = draft.paymentType == opt;
                return ChoiceChip(
                  label: Text(opt, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Color(primaryColor) : Color(grey1Color))),
                  selected: selected,
                  onSelected: (_) => setState(() => draft.paymentType = opt),
                  selectedColor: const Color(roSelectedBgColor),
                  backgroundColor: Color(whiteColor),
                  side: BorderSide(color: selected ? Color(primaryColor) : Color(grey7Color)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          for (int t = 0; t < draft.tx.length; t++) _txBlock(draft, t),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Total Pembayaran Unit Ini: ${_formatRupiah(draft.total)}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(successColor))),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => draft.tx.add(_PaymentTxDraft())),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              foregroundColor: Color(primaryColor),
              side: BorderSide(color: Color(primaryColor)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('+ Bayar Lagi untuk Unit Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _document() {
    final unitLabel = _selectedUnits.length == 1 ? _selectedUnits.first.name : '${_selectedUnits.length} unit';
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
                    onTap: () => _pickDocument((f) => _ktpFile = f),
                    onRemove: () => setState(() => _ktpFile = null),
                    isError: _showDocumentValidation && _ktpFile == null,
                  ),
                  _docRow(
                    icon: '📄',
                    title: 'NPWP',
                    subtitle: 'Opsional',
                    file: _npwpFile,
                    onTap: () => _pickDocument((f) => _npwpFile = f),
                    onRemove: () => setState(() => _npwpFile = null),
                  ),
                  const SizedBox(height: 6),
                  _sectionLabel('Pembayaran per Unit'),
                  for (int i = 0; i < _unitDrafts.length; i++) _unitPaymentCard(i),
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
                      hintText: 'Mis: customer transfer DP awal, dokumen menyusul',
                      hintStyle: TextStyle(color: Color(grey5Color), fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
    final missingProof = _unitDrafts.any((d) => d.tx.any((t) => t.mode == _PaymentMode.transfer && t.proof == null));
    if (_ktpFile == null || missingProof) {
      setState(() => _showDocumentValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ktpFile == null ? 'KTP Pemohon wajib diupload.' : 'Bukti Non Tunai wajib diupload untuk semua pembayaran Non Tunai.')),
      );
      return;
    }
    setState(() => _step = 4);
  }

  // ---------------------------------------------------------------------
  // STEP 4 — Review
  // ---------------------------------------------------------------------

  Widget _reviewLine(String label, String value, {Color? valueColor, bool isLast = false, String? suffix}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Color(grey10Color)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Color(grey1Color))),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? Color(blackColor)),
                children: [
                  TextSpan(text: value),
                  if (suffix != null) TextSpan(text: ' $suffix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(grey4Color))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewUnitCard(_UnitPaymentDraft d) {
    final modes = d.tx.map((t) => t.mode == _PaymentMode.cash ? 'Tunai' : 'Non Tunai').toSet().join(' + ');
    final priceLine = d.unit.price != null ? '${_formatRupiah(d.unit.price!)} · ' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color(whiteColor), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(grey10Color))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏠 ${d.unit.name}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('$priceLine${d.unit.context}', style: TextStyle(fontSize: 11, color: Color(grey4Color)))),
          _reviewLine('Cara Bayar', modes),
          _reviewLine('Jenis Pembayaran', d.paymentType),
          _reviewLine('Nominal Dibayar', _formatRupiah(d.total), valueColor: Color(successColor), isLast: true),
        ],
      ),
    );
  }

  Widget _review() {
    final grandTotal = _unitDrafts.fold<double>(0, (s, d) => s + d.total);
    final hasTransfer = _unitDrafts.any((d) => d.tx.any((t) => t.mode == _PaymentMode.transfer));
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
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(grey10Color))),
                    child: Column(
                      children: [
                        _reviewLine('Nama Customer', _customerNameSnapshot),
                        _reviewLine('Sales Channel', widget.salesChannel ?? '-'),
                        _reviewLine('Sales Channel Detail', widget.salesChannelDetail ?? '-'),
                        _reviewLine('General Manager',  '-'),
                        _reviewLine('Sales Manager',  '-'),
                        _reviewLine('Sales Supervisor',  '-'),
                        _reviewLine('Sales Executive',  '-'),
                        _reviewLine(
                          'Dokumen Identitas',
                          'KTP ✓${hasTransfer ? ' · Bukti Bayar ✓' : ''}',
                          valueColor: Color(successColor),
                          suffix: '(1x, semua unit)',
                        ),
                        _reviewLine('Jumlah Unit', '${_unitDrafts.length} unit'),
                        _reviewLine('Total Semua Unit', '${_formatRupiah(grandTotal)} ✓', valueColor: Color(successColor), isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final d in _unitDrafts) _reviewUnitCard(d),
                ],
              ),
            ),
          ),
          _footer('Submit Reserve Order', _submitReserveOrder),
        ],
      ),
    );
  }

  void _submitReserveOrder() {
    setState(() => _step = 5);
  }

  // ---------------------------------------------------------------------
  // STEP 5 — Success
  // ---------------------------------------------------------------------

  void _goToReserveOrderList() {
    Navigator.of(context).maybePop();
  }

  void _resetForm() {
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
      _resetKey += 1;
      _showCustomerValidation = false;
      _showUnitValidation = false;
      _showDocumentValidation = false;
      _tglLahir = null;
      _gender = null;
      _statusPernikahan = null;
      _kategoriPekerjaan = null;
      _caraBayar = null;
      _ktpFile = null;
      _npwpFile = null;
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
                      decoration: const BoxDecoration(color: Color(roSuccessBgColor), shape: BoxShape.circle),
                      child: Icon(Icons.check, color: Color(successColor), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('Reserve Order Berhasil Diajukan', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(grey4Color), height: 1.5)),
                    const SizedBox(height: 16),
                    for (final d in _unitDrafts)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(grey10Color))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.unit.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  Text(_customerNameSnapshot, style: TextStyle(fontSize: 9.5, color: Color(grey4Color))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Color(warningColor), borderRadius: BorderRadius.circular(20)),
                              child: Text('Diproses', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(whiteColor))),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Color(whiteColor), border: Border(top: BorderSide(color: Color(grey10Color)))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    customButton(_goToReserveOrderList, 'Lihat di Reserve Order'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: Color(grey1Color),
                          side: BorderSide(color: Color(grey7Color)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Buat Reserve Order Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
  final label = isWhole ? jt.toInt().toString() : jt.toStringAsFixed(1).replaceAll('.', ',');
  return '${label}jt';
}

class _PaymentTxDraft {
  _PaymentMode mode = _PaymentMode.transfer;
  double amount = 3000000;
  PickedFileResult? proof;
  final TextEditingController amountCtrl;

  _PaymentTxDraft() : amountCtrl = TextEditingController(text: _formatRupiah(3000000));

  void dispose() => amountCtrl.dispose();
}

class _UnitPaymentDraft {
  final ReserveUnitOption unit;
  String paymentType = 'Reserve';
  final List<_PaymentTxDraft> tx;

  _UnitPaymentDraft({required this.unit}) : tx = [_PaymentTxDraft()];

  double get total => tx.fold(0, (s, t) => s + t.amount);

  void dispose() {
    for (final t in tx) {
      t.dispose();
    }
  }
}
