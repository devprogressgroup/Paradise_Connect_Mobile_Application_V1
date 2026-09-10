import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
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

const _religionItems = ['ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA', 'KONGHUCU'];
const _workCategoryItems = ['Pegawai', 'Profesional', 'Wiraswasta'];

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



  final Set<String> _collapsedSections = {};




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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
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









  Widget _withHighlight(String key, Widget child) {
    if (key != widget.highlightKey) return child;

    final highlighted = _highlightedKey == key;
    return KeyedSubtree(
      key: _keyFor(key),
      child: Listener(
        onPointerDown: (_) {
          if (_highlightedKey == key) setState(() => _highlightedKey = null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(highlighted ? 6 : 0),
          decoration: BoxDecoration(
            color: highlighted ? const Color(primaryColor).withValues(alpha: 0.08) : null,
            border: highlighted ? Border.all(color: const Color(primaryColor), width: 1.5) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
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
              roAppBar(title: 'Edit Customer', subtitle: order.customerName, onBack: () => context.pop()),
              Expanded(
                child: !_ready
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Buyer Data', [
                        _textField(const _Field('cust_name', 'Full Name (as per KTP)', hint: 'Name as per KTP')),
                        _textField(const _Field(
                          'cust_ktp',
                          'KTP No.',
                          hint: '16-digit NIK',
                          keyboardType: TextInputType.number,
                        )),
                        _textField(const _Field('cust_npwp', 'NPWP No.', hint: '00.000.000.0-000.000')),
                        _textField(const _Field('cust_birth_place', 'Place of Birth', hint: 'Jakarta')),
                        _dateField('cust_birth_date', 'Date of Birth', _birthDate, (v) => setState(() => _birthDate = v)),
                        _yesNoField(
                          'cust_gender_is_male',
                          'Gender',
                          _genderIsMale,
                          'Male',
                          'Female',
                          (v) => setState(() => _genderIsMale = v),
                        ),
                        _optionField(
                          key: 'cust_marital_status',
                          label: 'Marital Status',
                          value: _maritalStatus,
                          hint: 'Select marital status',
                          sheetTitle: 'Marital Status',
                          items: roMaritalStatusItems,
                          onPicked: (v) => setState(() => _maritalStatus = v),
                        ),
                        _optionField(
                          key: 'work_category',
                          label: 'Work Category',
                          value: _workCategory,
                          hint: 'Select work category',
                          sheetTitle: 'Work Category',
                          items: _workCategoryItems,
                          onPicked: (v) => setState(() => _workCategory = v),
                        ),
                        _textField(const _Field('cust_occupation', 'Occupation', hint: 'Self-employed')),
                        _optionField(
                          key: 'cara_bayar_id',
                          label: 'Payment Plan',
                          value: _caraBayarName,
                          hint: 'Select payment plan',
                          sheetTitle: 'Payment Plan',
                          items: _caraBayarOptions.isEmpty
                              ? const ['KPR', 'Cash', 'Cash Bertahap', 'Inhouse']
                              : _caraBayarOptions.map((e) => e.name).toList(),
                          onPicked: (v) => setState(() {
                            for (final option in _caraBayarOptions) {
                              if (option.name == v) _caraBayarSelectedId = option.caraBayarId;
                            }
                          }),
                        ),
                        _optionField(
                          key: 'cust_religion',
                          label: 'Religion',
                          value: _religion,
                          hint: 'Select religion',
                          sheetTitle: 'Religion',
                          items: _religionItems,
                          onPicked: (v) => setState(() => _religion = v),
                        ),
                        _textField(const _Field('cust_education', 'Education', hint: 'S1')),
                        _textField(const _Field('cust_telp_home', 'Home Phone', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_home2', 'Home Phone 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile1', 'Mobile Phone 1', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile2', 'Mobile Phone 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_mobile3', 'Mobile Phone 3', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_email1', 'Email 1', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('cust_email2', 'Email 2', keyboardType: TextInputType.emailAddress)),
                      ]),
                      _section('Prospective Spouse', [
                        _textField(const _Field('spouse_name', 'Spouse Name')),
                        _textField(const _Field('spouse_birth_place', 'Spouse Place of Birth')),
                        _dateField('spouse_birth_date', 'Spouse Date of Birth', _spouseBirthDate, (v) => setState(() => _spouseBirthDate = v)),
                        _textField(const _Field('spouse_email', 'Spouse Email', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('spouse_telp_mobile', 'Spouse Mobile Phone', keyboardType: TextInputType.phone)),
                      ]),
                      _section('Children Data', [
                        _textField(const _Field('child1_name', 'Child 1 Name')),
                        _textField(const _Field('child2_name', 'Child 2 Name')),
                        _textField(const _Field('child3_name', 'Child 3 Name')),
                        _textField(const _Field('child4_name', 'Child 4 Name')),
                      ]),
                      _section('Emergency Contact (Not Living Together)', [
                        _textField(const _Field('em_contact_name', 'Contact Name')),
                        _textField(const _Field('em_hubungan', 'Relationship')),
                        _textField(const _Field('em_hp1', 'Phone 1', keyboardType: TextInputType.phone)),
                        _textField(const _Field('em_hp2', 'Phone 2', keyboardType: TextInputType.phone)),
                      ]),
                      _section('Buyer Address Data', [
                        _textField(const _Field('cust_address1', 'Address (as per KTP)', hint: 'e.g. Street Name No. 1…', maxLines: 2)),
                        _areaField('Area Code (as per KTP)', 'cust_area'),
                        _textField(const _Field('nama_kota', 'City (as per KTP)')),
                        _textField(const _Field('postal_code', 'Postal Code (as per KTP)', keyboardType: TextInputType.number)),
                        _yesNoField(
                          'current_address_similar_ktp',
                          'Same as KTP Address?',
                          _currentAddressSimilarKtp,
                          'Yes',
                          'No',
                          (v) => setState(() => _currentAddressSimilarKtp = v),
                        ),
                        _textField(const _Field('current_address', 'Current Address', maxLines: 2)),
                        _areaField('Current Area Code', 'current_area'),
                        _textField(const _Field('current_city', 'Current City')),
                        _textField(const _Field('current_postal_code', 'Current Postal Code', keyboardType: TextInputType.number)),
                        _textField(const _Field('mailing_address', 'Mailing Address', maxLines: 2)),
                        _areaField('Mailing Area Code', 'mailing_area'),
                        _textField(const _Field('mailing_city', 'Mailing City')),
                        _textField(const _Field('mailing_postal_code', 'Mailing Postal Code', keyboardType: TextInputType.number)),
                      ]),
                      _section('Prospective Spouse Address (Co-Buyer)', [
                        _textField(const _Field('mate_name', 'Name')),
                        _textField(const _Field('mate_telp_mobile', 'Mobile Phone', keyboardType: TextInputType.phone)),
                        _textField(const _Field('mate_birth_place', 'Place of Birth')),
                        _dateField('mate_birth_date', 'Date of Birth', _mateBirthDate, (v) => setState(() => _mateBirthDate = v)),
                        _textField(const _Field('mate_email', 'Email', keyboardType: TextInputType.emailAddress)),
                        _textField(const _Field('mate_ktp_address', 'KTP Address', maxLines: 2)),
                        _areaField('KTP Area Code', 'mate_ktp_area'),
                        _textField(const _Field('mate_ktp_city', 'KTP City')),
                        _textField(const _Field('mate_ktp_postal_code', 'KTP Postal Code', keyboardType: TextInputType.number)),
                        _textField(const _Field('mate_current_address', 'Current Address', maxLines: 2)),
                        _areaField('Current Area Code', 'mate_current_area'),
                        _textField(const _Field('mate_current_city', 'Current City')),
                        _textField(const _Field('mate_current_postal_code', 'Current Postal Code', keyboardType: TextInputType.number)),
                        _textField(const _Field('mate_mailing_address', 'Mailing Address', maxLines: 2)),
                        _areaField('Mailing Area Code', 'mate_mailing_area'),
                        _textField(const _Field('mate_mailing_city', 'Mailing City')),
                        _textField(const _Field('mate_mailing_postal_code', 'Mailing Postal Code', keyboardType: TextInputType.number)),
                      ]),
                      _section('Buyer Work Data', [
                        _textField(const _Field('cust_company_name', 'Company Name')),
                        _textField(const _Field('cust_office_building', 'Office Building')),
                        _textField(const _Field('cust_work_address', 'Work Address', maxLines: 2)),
                        _areaField('Work Area Code', 'work_area'),
                        _textField(const _Field('cust_work_city', 'Work City')),
                        _textField(const _Field('cust_telp_work', 'Work Phone', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_telp_work2', 'Work Phone 2', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_work_fax', 'Work Fax', keyboardType: TextInputType.phone)),
                        _textField(const _Field('cust_job_title', 'Job Title')),
                        _textField(const _Field('cust_income', 'Monthly Income', hint: 'Rp 0', keyboardType: TextInputType.number)),
                      ]),
                      _section('Prospective Spouse Work Data', [
                        _textField(const _Field('spouse_occupation', 'Occupation')),
                        _textField(const _Field('spouse_company_name', 'Company Name')),
                        _textField(const _Field('spouse_office_building', 'Office Building')),
                        _textField(const _Field('spouse_work_address', 'Work Address', maxLines: 2)),
                        _areaField('Work Area Code', 'spouse_area'),
                        _textField(const _Field('spouse_work_city', 'Work City')),
                        _textField(const _Field('spouse_telp_work', 'Work Phone', keyboardType: TextInputType.phone)),
                        _textField(const _Field('spouse_work_fax', 'Work Fax', keyboardType: TextInputType.phone)),
                        _textField(const _Field('spouse_job_title', 'Job Title')),
                        _textField(const _Field('spouse_income', 'Monthly Income', hint: 'Rp 0', keyboardType: TextInputType.number)),
                      ]),
                    ],
                  ),
                ),
              ),
              roFooter([roPrimaryButton('Save Changes', _onSubmit, loading: _submitting)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final collapsed = _collapsedSections.contains(title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roCollapsibleSectionHeader(
            title: title,
            collapsed: collapsed,
            onTap: () => setState(() {
              if (collapsed) {
                _collapsedSections.remove(title);
              } else {
                _collapsedSections.add(title);
              }
            }),
          ),
          if (!collapsed) ...children,
        ],
      ),
    );
  }

  Widget _textField(_Field f) {
    return _withHighlight(
      f.key,
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            roFieldLabel(f.label),
            roInput(
              _c(f.key),
              hint: f.hint,
              keyboardType: f.keyboardType,
              inputFormatters: f.key == 'cust_ktp'
                  ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)]
                  : null,
              maxLines: f.maxLines,
            ),
          ],
        ),
      ),
    );
  }

  Widget _yesNoField(String key, String label, bool? value, String yesLabel, String noLabel, ValueChanged<bool> onChanged) {
    return _withHighlight(
      key,
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            roFieldLabel(label),
            Row(
              children: [
                roChip(yesLabel, value == true, () => onChanged(true)),
                const SizedBox(width: 8),
                roChip(noLabel, value == false, () => onChanged(false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String key, String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    return _withHighlight(
      key,
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            roFieldLabel(label),
            roPickerRow(
              value: value == null ? null : DateFormat('dd MMMM yyyy', 'id_ID').format(value),
              hint: 'Select date',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionField({
    required String key,
    required String label,
    required String? value,
    required String hint,
    required String sheetTitle,
    required List<String> items,
    required ValueChanged<String> onPicked,
  }) {
    return _withHighlight(
      key,
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            roFieldLabel(label),
            roPickerRow(
              value: value,
              hint: hint,
              onTap: () => roShowOptionSheet(
                context: context,
                title: sheetTitle,
                items: items,
                selected: value,
                onPicked: onPicked,
              ),
            ),
          ],
        ),
      ),
    );
  }






  Widget _areaField(String label, String key) {
    return _optionField(
      key: key,
      label: label,
      value: _areaLabelFor(key),
      hint: 'Select area',
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
      showSnackbar(context, 'Full name is required', isError: true);
      return;
    }

    final reserveOrderId = int.tryParse(order.id);
    if (reserveOrderId == null) {
      showSnackbar(context, 'Failed to update customer data', isError: true);
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
