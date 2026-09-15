import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
//
class ReserveOrderEditCustomerPage extends StatefulWidget {
  final ReserveOrder order;



  final String? highlightKey;

  const ReserveOrderEditCustomerPage({super.key, required this.order, this.highlightKey});

  @override
  State<ReserveOrderEditCustomerPage> createState() => _ReserveOrderEditCustomerPageState();
}

class _Field {
  final String key;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field(this.key, this.label, {this.hint, this.keyboardType, this.maxLines = 1});
}

class _ReserveOrderEditCustomerPageState extends State<ReserveOrderEditCustomerPage> {
  late ReserveCustomerDetail _detail;
  final Map<String, TextEditingController> _tc = {};

  DateTime? _birthDate;
  DateTime? _spouseBirthDate;
  DateTime? _mateBirthDate;

  bool? _genderIsMale;
  bool? _currentAddressSimilarKtp;

  String? _maritalStatus;
  String? _religion;
  String? _workCategory;






  int? _caraBayarSelectedId;
  List<CaraBayarOption> _caraBayarOptions = const [];



  final Map<String, int?> _areaSelectedId = {};
  List<AreaOption> _areaOptions = const [];
  static const _areaKeys = [
    'cust_area',
    'current_area',
    'mailing_area',
    'mate_ktp_area',
    'mate_current_area',
    'mate_mailing_area',
    'work_area',
    'spouse_area',
  ];



  String? _highlightedKey;
  final Map<String, GlobalKey> _fieldKeys = {};






  bool _ready = false;

  bool _submitting = false;

  ReserveOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_edit_customer');
    _detail = order.customerDetail ?? ReserveCustomerDetail(raw: {'cust_name': order.customerName});

    _birthDate = _parseDate('cust_birth_date');
    _spouseBirthDate = _parseDate('spouse_birth_date');
    _mateBirthDate = _parseDate('mate_birth_date');

    _genderIsMale = _detail.raw['cust_gender_is_male'] as bool?;
    _currentAddressSimilarKtp = _detail.raw['current_address_similar_ktp'] as bool?;

    _maritalStatus = _initial('cust_marital_status').isEmpty ? null : _initial('cust_marital_status');
    _religion = _initial('cust_religion').isEmpty ? null : _initial('cust_religion');
    _workCategory = _initial('work_category').isEmpty ? null : _initial('work_category');
    _caraBayarSelectedId = _detail.caraBayarId;
    for (final key in _areaKeys) {
      final raw = _detail.raw[key];
      _areaSelectedId[key] = raw is int ? raw : int.tryParse('$raw');
    }
    _loadCaraBayarOptions();
    _loadAreaOptions();

    _highlightedKey = widget.highlightKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      if (_highlightedKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToHighlight();
          // Sama seperti `ContactFormPage`: highlight-nya sementara, hilang sendiri — bukan
          // ditunggu sampai user menyentuh layar.
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _highlightedKey = null);
          });
        });
      }
    });
  }

  GlobalKey _keyFor(String key) => _fieldKeys.putIfAbsent(key, () => GlobalKey());

  void _scrollToHighlight() {
    final targetContext = _highlightedKey == null ? null : _fieldKeys[_highlightedKey]?.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }









  /// Bingkai field underline bersama, dipakai semua builder field — highlight-nya (dari
  /// [_highlightedKey], dipicu tautan "field" dari tab Customer di halaman Detail) menyatu ke
  /// border-bawah + tint field itu sendiri, gaya sama seperti `ContactFormPage._buildField`,
  /// bukan kotak terpisah yang membungkus field.
  Widget _fieldFrame(
    String key,
    bool highlighted,
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
  }) {
    return Container(
      key: key == widget.highlightKey ? _keyFor(key) : null,
      padding: padding,
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: highlighted ? const Color(primaryColor).withValues(alpha: 0.06) : const Color(whiteColor),
        border: Border(
          bottom: BorderSide(
            width: highlighted ? 2 : 1,
            color: highlighted ? const Color(primaryColor) : const Color(grey9Color),
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _initial(String key) {
    final value = _detail.raw[key];
    return value == null ? '' : '$value';
  }

  DateTime? _parseDate(String key) {
    final value = _detail.raw[key];
    return value == null ? null : DateTime.tryParse('$value');
  }

  TextEditingController _c(String key) => _tc.putIfAbsent(key, () => TextEditingController(text: _initial(key)));



  Future<void> _loadCaraBayarOptions() async {
    final options = await context.read<ReserveOrderListCubit>().ensureCaraBayarOptions();
    if (!mounted) return;
    setState(() => _caraBayarOptions = options);
  }




  String? get _caraBayarName {
    final id = _caraBayarSelectedId;
    if (id == null) return null;
    for (final option in _caraBayarOptions) {
      if (option.caraBayarId == id) return option.name;
    }
    return null;
  }



  Future<void> _loadAreaOptions() async {
    final options = await context.read<ReserveOrderListCubit>().ensureAreaOptions();
    if (!mounted) return;
    setState(() => _areaOptions = options);
  }




  String? _areaLabelFor(String key) {
    final id = _areaSelectedId[key];
    if (id == null) return null;
    for (final option in _areaOptions) {
      if (option.locationId == id) return option.label;
    }
    return '$id';
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
              _buildHeader(),
              Expanded(
                child: !_ready
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Data Pembeli', [
                        _textField(const _Field('cust_name', 'Nama Lengkap (sesuai KTP)', hint: 'Nama sesuai KTP')),
                        _textField(const _Field(
                          'cust_ktp',
                          'No. KTP',
                          hint: 'NIK 16 digit',
                          keyboardType: TextInputType.number,
                        )),
                        _textField(const _Field('cust_npwp', 'No. NPWP', hint: '00.000.000.0-000.000')),
                        _textField(const _Field('cust_birth_place', 'Tempat Lahir', hint: 'Jakarta')),
                        _dateField('cust_birth_date', 'Tanggal Lahir', _birthDate, (v) => setState(() => _birthDate = v)),
                        _yesNoField(
                          'cust_gender_is_male',
                          'Jenis Kelamin',
                          _genderIsMale,
                          'Laki-laki',
                          'Perempuan',
                          (v) => setState(() => _genderIsMale = v),
                        ),
                        _optionField(
                          key: 'cust_marital_status',
                          label: 'Status Pernikahan',
                          value: _maritalStatus,
                          sheetTitle: 'Status Pernikahan',
                          items: roMaritalStatusItems,
                          onPicked: (v) => setState(() => _maritalStatus = v),
                        ),
                        _optionField(
                          key: 'work_category',
                          label: 'Kategori Pekerjaan',
                          value: _workCategory,
                          sheetTitle: 'Kategori Pekerjaan',
                          items: roWorkCategoryItems,
                          onPicked: (v) => setState(() => _workCategory = v),
                        ),
                        _textField(const _Field('cust_occupation', 'Pekerjaan', hint: 'Wiraswasta')),
                        _optionField(
                          key: 'cara_bayar_id',
                          label: 'Tujuan Pembayaran',
                          value: _caraBayarName,
                          sheetTitle: 'Tujuan Pembayaran',
                          items: _caraBayarOptions.map((e) => e.name).toList(),
                          onPicked: (v) => setState(() {
                            for (final option in _caraBayarOptions) {
                              if (option.name == v) _caraBayarSelectedId = option.caraBayarId;
                            }
                          }),
                        ),
                        _optionField(
                          key: 'cust_religion',
                          label: 'Agama',
                          value: _religion,
                          sheetTitle: 'Agama',
                          items: roReligionItems,
                          onPicked: (v) => setState(() => _religion = v),
                        ),
                        _textField(const _Field('cust_education', 'Pendidikan', hint: 'S1')),
                        _textField(const _Field('cust_telp_home', 'Telepon Rumah', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_home2', 'Telepon Rumah 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile1', 'No. HP 1', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile2', 'No. HP 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile3', 'No. HP 3', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_email1', 'Email 1', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('cust_email2', 'Email 2', keyboardType: TextInputType.emailAddress)),
                      ]),
                      _section('Calon Pasangan', [
                        _textField(const _Field('spouse_name', 'Nama Pasangan')),
                        _textField(const _Field('spouse_birth_place', 'Tempat Lahir Pasangan')),
                        _dateField('spouse_birth_date', 'Tanggal Lahir Pasangan', _spouseBirthDate, (v) => setState(() => _spouseBirthDate = v)),
                        _textField(const _Field('spouse_email', 'Email Pasangan', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('spouse_telp_mobile', 'No. HP Pasangan', keyboardType: TextInputType.phone)),
                      ]),
                      _section('Data Anak', [
                        _textField(const _Field('child1_name', 'Nama Anak 1')),
                        _textField(const _Field('child2_name', 'Nama Anak 2')),
                        _textField(const _Field('child3_name', 'Nama Anak 3')),
                        _textField(const _Field('child4_name', 'Nama Anak 4')),
                      ]),
                      _section('Kontak Darurat (Tidak Tinggal Bersama)', [
                        _textField(const _Field('em_contact_name', 'Nama Kontak')),
                        _textField(const _Field('em_hubungan', 'Hubungan')),
                        _textField(const _Field('em_hp1', 'Telepon 1', keyboardType: TextInputType.phone)),
                        _textField(const _Field('em_hp2', 'Telepon 2', keyboardType: TextInputType.phone)),
                      ]),
                      _section('Data Alamat Pembeli', [
                        _textField(const _Field('cust_address1', 'Alamat (sesuai KTP)', hint: 'mis. Nama Jalan No. 1…', maxLines: 2)),
                        _areaField('Kode Area (sesuai KTP)', 'cust_area'),
                        _textField(const _Field('nama_kota', 'Kota (sesuai KTP)')),
                        _textField(const _Field('postal_code', 'Kode Pos (sesuai KTP)', keyboardType: TextInputType.number)),
                        _yesNoField(
                          'current_address_similar_ktp',
                          'Sama dengan Alamat KTP?',
                          _currentAddressSimilarKtp,
                          'Ya',
                          'Tidak',
                          (v) => setState(() => _currentAddressSimilarKtp = v),
                        ),
                        _textField(const _Field('current_address', 'Alamat Saat Ini', maxLines: 2)),
                        _areaField('Kode Area Saat Ini', 'current_area'),
                        _textField(const _Field('current_city', 'Kota Saat Ini')),
                        _textField(const _Field('current_postal_code', 'Kode Pos Saat Ini', keyboardType: TextInputType.number)),
                        _textField(const _Field('mailing_address', 'Alamat Surat-Menyurat', maxLines: 2)),
                        _areaField('Kode Area Surat-Menyurat', 'mailing_area'),
                        _textField(const _Field('mailing_city', 'Kota Surat-Menyurat')),
                        _textField(const _Field('mailing_postal_code', 'Kode Pos Surat-Menyurat', keyboardType: TextInputType.number)),
                      ]),
                      _section('Alamat Calon Pasangan (Pembeli Bersama)', [
                        _textField(const _Field('mate_name', 'Nama')),
                        _textField(const _Field('mate_telp_mobile', 'No. HP', keyboardType: TextInputType.phone)),
                        _textField(const _Field('mate_birth_place', 'Tempat Lahir')),
                        _dateField('mate_birth_date', 'Tanggal Lahir', _mateBirthDate, (v) => setState(() => _mateBirthDate = v)),
                        _textField(const _Field('mate_email', 'Email', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('mate_ktp_address', 'Alamat KTP', maxLines: 2)),
                        _areaField('Kode Area KTP', 'mate_ktp_area'),
                        _textField(const _Field('mate_ktp_city', 'Kota KTP')),
                        _textField(const _Field('mate_ktp_postal_code', 'Kode Pos KTP', keyboardType: TextInputType.number)),
                        _textField(const _Field('mate_current_address', 'Alamat Saat Ini', maxLines: 2)),
                        _areaField('Kode Area Saat Ini', 'mate_current_area'),
                        _textField(const _Field('mate_current_city', 'Kota Saat Ini')),
                        _textField(const _Field('mate_current_postal_code', 'Kode Pos Saat Ini', keyboardType: TextInputType.number)),
                        _textField(const _Field('mate_mailing_address', 'Alamat Surat-Menyurat', maxLines: 2)),
                        _areaField('Kode Area Surat-Menyurat', 'mate_mailing_area'),
                        _textField(const _Field('mate_mailing_city', 'Kota Surat-Menyurat')),
                        _textField(const _Field('mate_mailing_postal_code', 'Kode Pos Surat-Menyurat', keyboardType: TextInputType.number)),
                      ]),
                      _section('Data Pekerjaan Pembeli', [
                        _textField(const _Field('cust_company_name', 'Nama Perusahaan')),
                        _textField(const _Field('cust_office_building', 'Gedung Kantor')),
                        _textField(const _Field('cust_work_address', 'Alamat Kantor', maxLines: 2)),
                        _areaField('Kode Area Kantor', 'work_area'),
                        _textField(const _Field('cust_work_city', 'Kota Kantor')),
                        _textField(const _Field('cust_telp_work', 'Telepon Kantor', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_work2', 'Telepon Kantor 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_work_fax', 'Fax Kantor', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_job_title', 'Jabatan')),
                        _textField(const _Field('cust_income', 'Penghasilan Bulanan', hint: 'Rp 0', keyboardType: TextInputType.number)),
                      ]),
                      _section('Data Pekerjaan Calon Pasangan', [
                        _textField(const _Field('spouse_occupation', 'Pekerjaan')),
                        _textField(const _Field('spouse_company_name', 'Nama Perusahaan')),
                        _textField(const _Field('spouse_office_building', 'Gedung Kantor')),
                        _textField(const _Field('spouse_work_address', 'Alamat Kantor', maxLines: 2)),
                        _areaField('Kode Area Kantor', 'spouse_area'),
                        _textField(const _Field('spouse_work_city', 'Kota Kantor')),
                        _textField(const _Field('spouse_telp_work', 'Telepon Kantor', keyboardType: TextInputType.phone)),
                        _textField(const _Field('spouse_work_fax', 'Fax Kantor', keyboardType: TextInputType.phone)),
                        _textField(const _Field('spouse_job_title', 'Jabatan')),
                        _textField(const _Field('spouse_income', 'Penghasilan Bulanan', hint: 'Rp 0', keyboardType: TextInputType.number)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header ala "Edit Contact" (`ContactFormPage._headerContact`) — bar putih polos, tombol
  /// kembali kiri, tombol "Simpan" inline kanan (bukan bar aksi terpisah di bawah).
  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(whiteColor),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Edit Data Pembeli',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _submitting ? null : _onSubmit,
            child: Container(
              height: 36,
              width: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(blue3Color)),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor)),
                    )
                  : const Text('Simpan', style: TextStyle(color: Color(whiteColor), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Section ala "Edit Contact" (`CustomDropdownGroupContact`, dipakai langsung — widget bersama,
  /// bukan diduplikasi) — bar abu-abu polos dengan judul + chevron, tanpa kartu/rounded box.
  Widget _section(String title, List<Widget> children) {
    return CustomDropdownGroupContact(hint: title, child: Column(children: children));
  }

  /// Field teks underline + label mengambang, gaya `ContactFormPage._buildField` — border cuma di
  /// bawah, label jadi hint saat kosong lalu mengambang ke atas begitu diisi/difokus.
  Widget _textField(_Field f) {
    final highlighted = _highlightedKey == f.key;
    final labelColor = highlighted ? const Color(primaryColor) : const Color(grey2Color);
    return _fieldFrame(
      f.key,
      highlighted,
      TextField(
        controller: _c(f.key),
        keyboardType: f.keyboardType,
        inputFormatters: f.key == 'cust_ktp'
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)]
            : null,
        minLines: f.maxLines > 1 ? f.maxLines : null,
        maxLines: null,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlighted ? const Color(primaryColor) : const Color(blackColor)),
        decoration: InputDecoration(
          isDense: true,
          label: Text(f.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor)),
          floatingLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor),
          hintText: f.hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(grey5Color)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _yesNoField(String key, String label, bool? value, String yesLabel, String noLabel, ValueChanged<bool> onChanged) {
    final current = value == null ? null : (value ? yesLabel : noLabel);
    return _buildPickerField(
      fieldKey: key,
      label: label,
      value: current,
      onTap: () => roShowOptionSheet(
        context: context,
        title: label,
        items: [yesLabel, noLabel],
        selected: current,
        onPicked: (v) => onChanged(v == yesLabel),
      ),
    );
  }

  Widget _dateField(String key, String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    return _buildPickerField(
      fieldKey: key,
      label: label,
      value: value == null ? null : DateFormat('dd MMMM yyyy', 'id_ID').format(value),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 30, now.month, now.day),
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  Widget _optionField({
    required String key,
    required String label,
    required String? value,
    required String sheetTitle,
    required List<String> items,
    required ValueChanged<String> onPicked,
  }) {
    return _buildPickerField(
      fieldKey: key,
      label: label,
      value: value,
      onTap: () => roShowOptionSheet(
        context: context,
        title: sheetTitle,
        items: items,
        selected: value,
        onPicked: onPicked,
      ),
    );
  }

  /// Field "pilihan" underline (tanggal/opsi/ya-tidak) — gaya `ContactFormPage._buildFieldDown`:
  /// label kecil di atas nilai kalau sudah terisi, atau label besar sebagai placeholder kalau
  /// masih kosong, + panah dropdown di kanan. Tetap buka bottom sheet ([roShowOptionSheet]) atau
  /// date picker saat ditekan — cuma tampilannya yang disamakan, bukan alur navigasinya.
  Widget _buildPickerField({required String fieldKey, required String label, required String? value, required VoidCallback onTap}) {
    final highlighted = _highlightedKey == fieldKey;
    final labelColor = highlighted ? const Color(primaryColor) : const Color(grey2Color);
    final isEmpty = value == null || value.isEmpty;
    return _fieldFrame(
      fieldKey,
      highlighted,
      InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEmpty) Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor)),
                  isEmpty
                      ? Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor))
                      : Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlighted ? const Color(primaryColor) : const Color(blackColor))),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 28, color: Color(grey4Color)),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }




  Widget _areaField(String label, String key) {
    return _optionField(
      key: key,
      label: label,
      value: _areaLabelFor(key),
      sheetTitle: label,
      items: _areaOptions.map((e) => e.label).toList(),
      onPicked: (v) => setState(() {
        for (final option in _areaOptions) {
          if (option.label == v) {
            _areaSelectedId[key] = option.locationId;
            break;
          }
        }
      }),
    );
  }




  static const _textKeys = [
    'cust_name',
    'cust_ktp',
    'cust_npwp',
    'cust_birth_place',
    'cust_occupation',
    'cust_education',
    'cust_telp_home',
    'cust_telp_home2',
    'cust_telp_mobile1',
    'cust_telp_mobile2',
    'cust_telp_mobile3',
    'cust_email1',
    'cust_email2',
    'spouse_name',
    'spouse_birth_place',
    'spouse_email',
    'spouse_telp_mobile',
    'child1_name',
    'child2_name',
    'child3_name',
    'child4_name',
    'em_contact_name',
    'em_hubungan',
    'em_hp1',
    'em_hp2',
    'cust_address1',
    'nama_kota',
    'postal_code',
    'current_address',
    'current_city',
    'current_postal_code',
    'mailing_address',
    'mailing_city',
    'mailing_postal_code',
    'mate_name',
    'mate_telp_mobile',
    'mate_birth_place',
    'mate_email',
    'mate_ktp_address',
    'mate_ktp_city',
    'mate_ktp_postal_code',
    'mate_current_address',
    'mate_current_city',
    'mate_current_postal_code',
    'mate_mailing_address',
    'mate_mailing_city',
    'mate_mailing_postal_code',
    'cust_company_name',
    'cust_office_building',
    'cust_work_address',
    'cust_work_city',
    'cust_telp_work',
    'cust_telp_work2',
    'cust_work_fax',
    'cust_job_title',
    'cust_income',
    'spouse_occupation',
    'spouse_company_name',
    'spouse_office_building',
    'spouse_work_address',
    'spouse_work_city',
    'spouse_telp_work',
    'spouse_work_fax',
    'spouse_job_title',
    'spouse_income',
  ];

  static const _numericKeys = {
    'cust_income',
    'spouse_income',
  };

  Future<void> _onSubmit() async {
    if (_c('cust_name').text.trim().isEmpty) {
      showSnackbar(context, 'Nama lengkap wajib diisi', isError: true);
      return;
    }

    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) {
      showSnackbar(context, 'Gagal memperbarui data pembeli', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_edit_customer_submit');
    setState(() => _submitting = true);

    final updated = ReserveCustomerDetail(raw: _buildRaw());
    try {
      await context.read<ReserveOrderListCubit>().dataSource.updateReserveCustomer(
            reserveOrderId: reserveOrderId,
            data: updated.raw,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
      return;
    }
    if (!mounted) return;

    order.applyCustomerDetail(updated, _caraBayarOptions);
    setState(() => _submitting = false);

    // Snackbar-nya ditampilkan dari halaman Detail (lewat nilai balik `pop`), bukan di sini — kalau
    // ditampilkan sebelum `pop()`, keburu ketutup transisi halaman & nyaris tidak sempat kelihatan.
    context.pop(true);
  }

  Map<String, dynamic> _buildRaw() {
    final raw = Map<String, dynamic>.of(_detail.raw);

    for (final key in _textKeys) {
      final text = _c(key).text.trim();
      if (text.isEmpty) {
        raw[key] = null;
      } else if (_numericKeys.contains(key)) {
        raw[key] = num.tryParse(text);
      } else {
        raw[key] = text;
      }
    }

    raw['cust_birth_date'] = _birthDate?.toIso8601String().split('T').first;
    raw['spouse_birth_date'] = _spouseBirthDate?.toIso8601String().split('T').first;
    raw['mate_birth_date'] = _mateBirthDate?.toIso8601String().split('T').first;
    raw['cust_gender_is_male'] = _genderIsMale;
    raw['current_address_similar_ktp'] = _currentAddressSimilarKtp;
    raw['cust_marital_status'] = _maritalStatus;
    raw['cust_religion'] = _religion;
    raw['work_category'] = _workCategory;
    raw['cara_bayar_id'] = _caraBayarSelectedId;
    for (final key in _areaKeys) {
      raw[key] = _areaSelectedId[key];
    }

    raw.remove('customer_id');

    return raw;
  }
}
