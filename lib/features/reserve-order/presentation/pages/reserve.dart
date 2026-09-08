import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/helpers/image_compress_helper.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/widget/thousands_input_formatter.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/ktp_ocr_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/ktp_ocr/ktp_ocr_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/ktp_ocr/ktp_ocr_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_attachment/reserve_attachment_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_attachment/reserve_attachment_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
enum ReserveStep { pembeli, dokumen, unit, review, sukses }
class ReserveResult {
  final List<SelectedUnit> units;
  final num? amount;
  final String transactionType;
  final String customerName;

  final KtpOcrModel? ktpOcr;

  const ReserveResult({
    required this.units,
    this.amount,
    this.transactionType = 'Reserve',
    this.customerName = '',
    this.ktpOcr,
  });

  String get unitLabel => units.map((u) => u.displayLabel).join(', ');
}

class ReservePage extends StatefulWidget {
  final ContactDetailArgs args;

  const ReservePage({super.key, required this.args});

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  ReserveStep _step = ReserveStep.pembeli;

  final namaTC = TextEditingController();
  final nikTC = TextEditingController();
  final ttlTC = TextEditingController();
  final alamatTC = TextEditingController();
  final pekerjaanTC = TextEditingController();
  String? _statusPernikahan;
  String? _caraPembayaran;
  int? _caraBayarId;

  // Loading terpisah dari `ReserveAttachmentCubit.state.isLoading` — `POST /api/reserve` (bikin
  // baris customer-nya) dipanggil dulu, baru dokumen diunggah kalau itu sukses.
  bool _creatingReserve = false;

  KtpOcrModel? _ocr;
  PickedFileResult? _ktpFile;

  String? _birthPlace;
  DateTime? _birthDate;

  late final List<_DocSlot> _identityDocs;
  final List<PickedFileResult> _paymentProofs = [];

  // Fallback selagi `_loadTransactionTypes()` (endpoint yang sama dengan chip filter list —
  // `GET /api/reserve-filter`) belum kembali / gagal, supaya form tetap bisa disubmit.
  List<String> _transactionTypes = const ['Reserve', 'Booking Reserve (langsung)'];
  String _jenisTransaksi = 'Reserve';
  final nominalTC = TextEditingController();
  final catatanTC = TextEditingController();

  final searchTC = TextEditingController();
  Timer? _searchDebounce;
  final Map<String, SelectedUnit> _selectedUnits = {};
  final ScrollController _unitScroll = ScrollController();

  static const List<String> _maritalItems = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

  // Fallback selagi/kalau `_loadCaraBayarOptions()` (`GET /api/reserve/cara-bayar`) belum kembali
  // atau gagal, supaya picker tetap bisa dipilih — id-nya (`_caraBayarId`) cuma null di kasus itu.
  List<String> _paymentMethods = const ['KPR', 'Cash', 'Cash Bertahap', 'Inhouse'];
  List<CaraBayarOption> _caraBayarOptions = const [];

  /// Nama attachment type untuk bukti bayar dicari berurutan dari yang paling spesifik, karena
  /// penamaannya di master data CRM belum tentu sama persis.
  static const List<String> _paymentTypeKeywords = ['bukti bayar', 'bukti transfer', 'bukti pembayaran', 'bukti', 'pembayaran'];

  static const Color _iconBg = Color(0xFFE6F1FB);
  static const Color _selectedBg = Color(0xFFE8F2FE);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_reserve');
    context.read<KtpOcrCubit>().reset();
    context.read<ReserveAttachmentCubit>().reset();
    _loadTransactionTypes();
    _loadCaraBayarOptions();

    final contact = widget.args.dataContact;
    namaTC.text = contact?.fullName ?? '';
    nikTC.text = (contact?.noKtp ?? '').replaceAll(RegExp(r'\D'), '');
    alamatTC.text = contact?.ktpAddress ?? '';

    _identityDocs = [
      _DocSlot(title: 'KTP', icon: Icons.badge_outlined, typeKeywords: const ['ktp'], required: true),
      _DocSlot(title: 'NPWP', icon: Icons.description_outlined, typeKeywords: const ['npwp']),
    ];

    _unitScroll.addListener(_onUnitScroll);
  }

  /// "Jenis Transaksi" pakai master status reserve yang sama dengan chip filter di menu List
  /// (`GET /api/reserve-filter`) — lewat `ReserveOrderListCubit.ensureFilters()`, provider yang
  /// sama dengan menu List, jadi kalau endpoint-nya sudah pernah dipanggil (mis. sales sempat buka
  /// menu List duluan) di sini tinggal pakai cache-nya, tidak fetch ulang. Gagal/kosong dibiarkan
  /// pakai [_transactionTypes] fallback di atas supaya form tetap bisa disubmit.
  Future<void> _loadTransactionTypes() async {
    final types = await context.read<ReserveOrderListCubit>().ensureFilters();
    if (!mounted || types.isEmpty) return;
    setState(() {
      _transactionTypes = types.map((t) => t.name).toList();
      if (!_transactionTypes.contains(_jenisTransaksi)) _jenisTransaksi = _transactionTypes.first;
    });
  }

  /// "Cara Pembayaran" pakai master `GET /api/reserve/cara-bayar` — `cara_bayar_id` yang disimpan
  /// ([_caraBayarId]), `name` yang ditampilkan di picker ([_caraPembayaran]/[_paymentMethods]).
  /// Sama seperti [_loadTransactionTypes], lewat cache di `ReserveOrderListCubit` supaya endpoint
  /// ini tidak fetch ulang tiap form Reserve dibuka.
  Future<void> _loadCaraBayarOptions() async {
    final options = await context.read<ReserveOrderListCubit>().ensureCaraBayarOptions();
    if (!mounted || options.isEmpty) return;
    setState(() {
      _caraBayarOptions = options;
      _paymentMethods = options.map((o) => o.name).toList();
      if (_caraPembayaran != null && !_paymentMethods.contains(_caraPembayaran)) {
        _caraPembayaran = null;
        _caraBayarId = null;
      }
    });
  }

  /// [name] adalah label yang ditampilkan; dicari `cara_bayar_id`-nya dari opsi yang sudah dimuat.
  /// Null kalau lagi pakai fallback lokal (endpoint gagal/belum kembali) — tidak ada id aslinya.
  int? _caraBayarIdOf(String name) {
    for (final option in _caraBayarOptions) {
      if (option.name == name) return option.caraBayarId;
    }
    return null;
  }

  @override
  void dispose() {
    namaTC.dispose();
    nikTC.dispose();
    ttlTC.dispose();
    alamatTC.dispose();
    pekerjaanTC.dispose();
    nominalTC.dispose();
    catatanTC.dispose();
    searchTC.dispose();
    _searchDebounce?.cancel();
    _unitScroll.removeListener(_onUnitScroll);
    _unitScroll.dispose();
    super.dispose();
  }


  static const List<ReserveStep> _numberedSteps = [
    ReserveStep.pembeli,
    ReserveStep.dokumen,
    ReserveStep.unit,
    ReserveStep.review,
  ];

  void _goToPreviousStep() {
    if (_step == ReserveStep.sukses) return;
    // Selagi dokumen sedang diunggah, mundur akan menyisakan upload separuh jalan.
    if (context.read<ReserveAttachmentCubit>().state.isLoading) return;

    final index = _numberedSteps.indexOf(_step);
    if (index > 0) setState(() => _step = _numberedSteps[index - 1]);
  }

  void _onBack() {
    if (_step != ReserveStep.pembeli && _step != ReserveStep.sukses) {
      _goToPreviousStep();
      return;
    }
    AnalyticsService.logEvent('reserve_order_reserve_back');
    context.pop();
  }


  void _showScanSourceSheet() {
    AnalyticsService.logEvent('reserve_order_scan_ktp');
    showCustomBottomSheet(
      context: context,
      child: Column(
        children: [
          customButton(() {
            Navigator.pop(context);
            _pickAndScan(fromCamera: true);
          }, "Camera"),
          SizedBox(height: 12),
          customButton(() {
            Navigator.pop(context);
            _pickAndScan(fromCamera: false);
          }, "Upload", colorBg: Color(whiteColor), colorText: Color(primaryColor)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<PickedFileResult> _compressIfImage(PickedFileResult picked) async {
    if (!picked.isImage || picked.bytes == null) return picked;

    final compressed = kIsWeb
        ? await compressImageBytes(picked.bytes!, maxSide: 1600)
        : (picked.path != null ? await compressImageFile(picked.path!) : picked.bytes!);
    if (compressed.isEmpty) return picked;

    return PickedFileResult(
      path: picked.path,
      bytes: compressed,
      name: picked.name,
      isImage: true,
      isPdf: false,
    );
  }

  Future<void> _pickAndScan({required bool fromCamera}) async {
    final picked = fromCamera ? await CustomFilePicker.pickCamera() : await CustomFilePicker.pickGallery();
    if (picked == null || picked.bytes == null) return;
    if (!mounted) return;

    final file = await _compressIfImage(picked);
    if (!mounted) return;

    setState(() {
      _ktpFile = file;
      _identityDocs.first.file ??= file;
    });

    final cubit = context.read<KtpOcrCubit>();
    await cubit.scan(bytes: file.bytes!, fileName: file.name);
    if (!mounted) return;

    final ocrState = cubit.state;
    final result = ocrState.result;

    if (ocrState.status == KtpOcrStatus.loaded && result != null && !result.isEmpty) {
      _applyOcr(result);
      showSnackbar(context, 'Data KTP berhasil dibaca. Mohon periksa kembali.');
    } else if (ocrState.status == KtpOcrStatus.error) {
      showSnackbar(context, ocrState.error ?? 'Gagal membaca KTP', isError: true);
    } else {
      showSnackbar(context, 'Data KTP tidak terbaca. Silakan isi manual.', isError: true);
    }
  }

  void _applyOcr(KtpOcrModel r) {
    setState(() {
      _ocr = r;
      if (r.nama != null) namaTC.text = r.nama!;
      if (r.nik != null) nikTC.text = r.nik!.replaceAll(RegExp(r'\D'), '');
      if (r.alamat != null) alamatTC.text = r.alamat!;
      if (r.pekerjaan != null) pekerjaanTC.text = r.pekerjaan!;

      _birthPlace = r.tempatLahir ?? _birthPlace;
      _birthDate = _parseOcrDate(r.tanggalLahir) ?? _birthDate;
      final ttl = _formatBirth();
      if (ttl != null) ttlTC.text = ttl;

      _statusPernikahan = _matchOption(r.statusPerkawinan, _maritalItems) ?? _statusPernikahan;
    });
  }

  String? _formatBirth() {
    final place = _birthPlace;
    final date = _birthDate;
    final parts = [
      if (place != null && place.isNotEmpty) place,
      if (date != null) DateFormat('dd MMMM yyyy', 'id_ID').format(date),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  DateTime? _parseOcrDate(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final pattern in ['dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(value);
      } catch (_) {
        continue;
      }
    }
    return DateTime.tryParse(value);
  }

  String? _matchOption(String? value, List<String> items) {
    if (value == null || value.isEmpty) return null;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = norm(value);
    for (final item in items) {
      if (norm(item) == target) return item;
    }
    return null;
  }

  void _onNextPembeli() {
    if (namaTC.text.trim().isEmpty) {
      showSnackbar(context, 'Nama lengkap wajib diisi', isError: true);
      return;
    }
    if (nikTC.text.trim().length != 16) {
      showSnackbar(context, 'No. KTP harus 16 digit', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_pembeli_next');
    setState(() => _step = ReserveStep.dokumen);
  }


  Future<void> _pickIdentityDoc(_DocSlot doc) async {
    AnalyticsService.logEvent('reserve_order_upload_dokumen');
    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData) return;
    if (!mounted) return;

    final result = await _compressIfImage(picked);
    if (!mounted) return;
    setState(() => doc.file = result);
  }

  Future<void> _addPaymentProof() async {
    AnalyticsService.logEvent('reserve_order_upload_bukti_bayar');
    final picked = await CustomFilePicker.show(context);
    if (picked == null || !picked.hasData) return;
    if (!mounted) return;

    final result = await _compressIfImage(picked);
    if (!mounted) return;
    setState(() => _paymentProofs.add(result));
  }

  num? get _nominal {
    final digits = nominalTC.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return num.tryParse(digits);
  }

  void _onNextDokumen() {
    if (_identityDocs.first.file == null) {
      showSnackbar(context, 'Dokumen KTP wajib dilampirkan', isError: true);
      return;
    }
    if (_paymentProofs.isEmpty) {
      showSnackbar(context, 'Bukti bayar wajib dilampirkan minimal 1', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Nominal pembayaran wajib diisi', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_dokumen_next');
    setState(() => _step = ReserveStep.unit);
  }


  void _onUnitScroll() {
    if (!_unitScroll.hasClients) return;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  List<SelectedUnit> _filteredContactUnits() {
    final all = widget.args.dataContact?.units ?? [];
    final q = searchTC.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((u) {
      return (u.clusterName.toLowerCase().contains(q)) ||
          (u.productName?.toLowerCase().contains(q) ?? false) ||
          (u.propertyName?.toLowerCase().contains(q) ?? false) ||
          u.displayLabel.toLowerCase().contains(q);
    }).toList();
  }

  void _toggleSelectedUnit(SelectedUnit unit) {
    setState(() {
      if (_selectedUnits.containsKey(unit.key)) {
        _selectedUnits.remove(unit.key);
      } else {
        _selectedUnits[unit.key] = unit;
      }
    });
  }

  void _onNextUnit() {
    if (_selectedUnits.isEmpty) {
      showSnackbar(context, 'Pilih minimal 1 unit', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_unit_next');
    setState(() => _step = ReserveStep.review);
  }


  /// Dokumen ditahan lokal sepanjang 3 step pertama, baru diunggah di sini — jadi kalau flow-nya
  /// ditinggal di tengah jalan tidak ada attachment nyangkut di kontak. Baris customer-nya
  /// (`POST /api/reserve`) dibuat dulu sebelum dokumen diunggah — gagal di sini menahan di Review,
  /// tidak lanjut upload.
  Future<void> _onSubmit() async {
    final cubit = context.read<ReserveAttachmentCubit>();
    if (cubit.state.isLoading || _creatingReserve) return;

    final contact = widget.args.dataContact;
    final contactId = contact?.contactId;
    if (contactId == null) {
      showSnackbar(context, 'Kontak tidak dikenali, dokumen tidak bisa diunggah', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_submit');

    setState(() => _creatingReserve = true);
    try {
      await context.read<ReserveOrderListCubit>().dataSource.createReserve(_buildCreateReserveParams(contactId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingReserve = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _creatingReserve = false);

    final ok = await cubit.submit(
      contactId: contactId,
      dealId: contact?.dealId,
      note: _attachmentNote,
      groups: [
        for (final doc in _identityDocs)
          _attachmentGroup(doc.title, doc.typeKeywords, [if (doc.file != null) doc.file!]),
        _attachmentGroup('Bukti Bayar', _paymentTypeKeywords, _paymentProofs),
      ],
    );
    if (!mounted) return;

    if (!ok) {
      showSnackbar(context, cubit.state.error ?? 'Gagal mengunggah dokumen', isError: true);
      return;
    }

    setState(() => _step = ReserveStep.sukses);
  }

  /// Payload `POST /api/reserve`. Jenis kelamin & agama cuma terisi kalau ada hasil scan KTP
  /// (belum ada input manual buat keduanya di form ini). Tempat/tanggal lahir diambil dari
  /// [_birthPlace]/[_birthDate] (hasil OCR) — kalau usernya isi manual di field "Tempat, Tanggal
  /// Lahir" tanpa scan, di-parse balik dari teksnya (format sesuai hint: "Tempat, dd MMMM yyyy").
  CreateReserveParams _buildCreateReserveParams(int contactId) {
    final (birthPlace, birthDate) = _resolvedBirth();

    return CreateReserveParams(
      contactId: contactId,
      custName: namaTC.text.trim(),
      custKtp: nikTC.text.trim(),
      custBirthPlace: birthPlace,
      custBirthDate: birthDate,
      custGenderIsMale: switch (_ocr?.jenisKelamin) {
        'Laki-laki' => true,
        'Perempuan' => false,
        _ => null,
      },
      custMaritalStatus: _statusPernikahan?.toUpperCase(),
      custReligion: _ocr?.agama,
      custOccupation: pekerjaanTC.text.trim(),
      custAddress1: alamatTC.text.trim(),
      caraBayarId: _caraBayarId,
      custTelpMobile1: widget.args.dataContact?.primaryPhone,
    );
  }

  /// [_birthPlace]/[_birthDate] cuma keisi kalau dari hasil scan KTP ([_applyOcr]) — field
  /// "Tempat, Tanggal Lahir" sendiri teks bebas, jadi kalau usernya ngetik manual (tanpa scan),
  /// di-parse balik di sini dari `ttlTC.text` ("Tempat, dd MMMM yyyy", sesuai hint field-nya).
  (String?, DateTime?) _resolvedBirth() {
    if (_birthPlace != null || _birthDate != null) return (_birthPlace, _birthDate);

    final text = ttlTC.text.trim();
    if (text.isEmpty) return (null, null);

    final idx = text.lastIndexOf(',');
    if (idx == -1) return (text, null);

    final place = text.substring(0, idx).trim();
    DateTime? date;
    try {
      date = DateFormat('dd MMMM yyyy', 'id_ID').parseStrict(text.substring(idx + 1).trim());
    } catch (_) {
      date = null;
    }
    return (place.isEmpty ? null : place, date);
  }

  ReserveAttachmentGroup _attachmentGroup(String label, List<String> keywords, List<PickedFileResult> files) {
    final usable = files.where((f) => f.bytes != null).toList();

    return ReserveAttachmentGroup(
      label: label,
      typeKeywords: keywords,
      bytes: [for (final file in usable) file.bytes!],
      fileNames: [for (final file in usable) file.name],
    );
  }

  /// Menempel di tiap attachment supaya di halaman Attachment kontak kelihatan dokumen ini datang
  /// dari transaksi yang mana.
  String get _attachmentNote {
    final units = _selectedUnits.values.map((u) => u.displayLabel).join(', ');
    final nominal = _nominal;

    return [
      'Reserve Order',
      _jenisTransaksi,
      if (units.isNotEmpty) units,
      if (nominal != null) 'Rp ${NumberHelper.thousands(nominal)}',
    ].join(' · ');
  }

  ReserveResult get _result => ReserveResult(
        units: _selectedUnits.values.toList(),
        amount: _nominal,
        transactionType: _jenisTransaksi,
        customerName: namaTC.text.trim(),
        ktpOcr: _ocr,
      );


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KtpOcrCubit, KtpOcrState>(
      builder: (context, ocrState) {
        return PopScope(
          canPop: _step == ReserveStep.pembeli || _step == ReserveStep.sukses,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _goToPreviousStep();
          },
          child: Scaffold(
            backgroundColor: Color(whiteColor),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (_step != ReserveStep.sukses) ...[
                        _buildAppBar(),
                        _buildStepper(),
                      ],
                      Expanded(child: _buildBody()),
                      _buildFooter(),
                    ],
                  ),
                  if (ocrState.isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      ReserveStep.pembeli => _buildPembeli(),
      ReserveStep.dokumen => _buildDokumen(),
      ReserveStep.unit => _buildUnit(),
      ReserveStep.review => _buildReview(),
      ReserveStep.sukses => _buildSukses(),
    };
  }

  Widget _buildAppBar() {
    final contact = widget.args.dataContact;
    final withContact = _step == ReserveStep.pembeli || _step == ReserveStep.dokumen;
    final title = switch (_step) {
      ReserveStep.unit => 'Pilih Unit',
      ReserveStep.review => 'Review Reserve Order',
      _ => 'Reserve Order — ${contact?.fullName ?? '-'}',
    };
    final subtitle = withContact ? (contact?.primaryPhone ?? contact?.whatsappNumber) : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _onBack,
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(grey1Color)),
            ),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle,
                      style: TextStyle(fontSize: 10.5, color: Color(grey4Color)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final currentIndex = _numberedSteps.indexOf(_step);
    const labels = ['Pembeli', 'Dokumen', 'Unit', 'Review'];

    return Container(
      color: Color(whiteColor),
      padding: EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < currentIndex
                          ? Color(successColor)
                          : (i == currentIndex ? Color(primaryColor) : Color(grey10Color)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < labels.length; i++)
                i == currentIndex
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${i + 1}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(primaryColor)),
                            ),
                            TextSpan(text: '/4 ${labels[i]}'),
                          ],
                        ),
                        style: TextStyle(fontSize: 9.5, color: Color(primaryColor)),
                      )
                    : Text(labels[i], style: TextStyle(fontSize: 9.5, color: Color(grey4Color))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final buttons = switch (_step) {
      ReserveStep.pembeli => [customButton(_onNextPembeli, "Lanjut ke Dokumen")],
      ReserveStep.dokumen => [customButton(_onNextDokumen, "Lanjut ke Pilih Unit")],
      ReserveStep.unit => const <Widget>[],
      ReserveStep.review => [
          BlocBuilder<ReserveAttachmentCubit, ReserveAttachmentState>(
            builder: (context, state) => roPrimaryButton(
              _creatingReserve
                  ? "Membuat reserve order..."
                  : state.isLoading
                      ? "Mengunggah dokumen ${state.uploaded}/${state.total}..."
                      : "Submit Reserve Order",
              _onSubmit,
              loading: _creatingReserve || state.isLoading,
            ),
          ),
        ],
      ReserveStep.sukses => [
          customButton(() => context.pop(_result), "Lihat di Reserve Order"),
          SizedBox(height: 8),
          customButton(
            _backToContact,
            "Kembali ke Kontak",
            colorBg: Color(whiteColor),
            colorText: Color(grey1Color),
          ),
        ],
    };

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: Column(children: buttons),
    );
  }

  void _backToContact() {
    final router = GoRouter.of(context);
    router.pop(_result);
    if (router.canPop()) router.pop();
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Color(blackColor).withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text("Membaca data KTP...", style: TextStyle(fontSize: 13, color: Color(grey2Color))),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPembeli() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ghostButton(
            _ktpFile == null ? "📷  Scan KTP" : "📷  Scan KTP ulang",
            _showScanSourceSheet,
          ),
          SizedBox(height: 6),
          Text(
            _ktpFile == null
                ? "Otomatis isi field di bawah"
                : "Foto KTP terlampir (${_fileSize(_ktpFile!)}) — sekaligus dipakai di step Dokumen",
            style: TextStyle(fontSize: 10, color: Color(grey4Color)),
          ),
          SizedBox(height: 12),
          _label("Nama Lengkap (sesuai KTP)"),
          _input(namaTC, hint: "Nama sesuai KTP"),
          _label("No. KTP"),
          _input(
            nikTC,
            hint: "16 digit NIK",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
          ),
          _label("Tempat, Tanggal Lahir"),
          _input(ttlTC, hint: "Jakarta, 01 Januari 1990"),
          _label("Alamat sesuai KTP"),
          _input(alamatTC, hint: "Jl. Contoh No. 1…", maxLines: 2),
          _label("Status Pernikahan"),
          _pickerRow(
            value: _statusPernikahan,
            hint: "Pilih status pernikahan",
            onTap: () => _showOptionSheet(
              title: "Status Pernikahan",
              items: _maritalItems,
              selected: _statusPernikahan,
              onPicked: (v) => setState(() => _statusPernikahan = v),
            ),
          ),
          _label("Pekerjaan"),
          _input(pekerjaanTC, hint: "Wiraswasta"),
          _label("Cara Pembayaran"),
          _pickerRow(
            value: _caraPembayaran,
            hint: "Pilih cara pembayaran",
            onTap: () => _showOptionSheet(
              title: "Cara Pembayaran",
              items: _paymentMethods,
              selected: _caraPembayaran,
              onPicked: (v) => setState(() {
                _caraPembayaran = v;
                _caraBayarId = _caraBayarIdOf(v);
              }),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDokumen() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("Dokumen Identitas"),
          for (final doc in _identityDocs)
            _docRow(
              icon: doc.icon,
              name: doc.title,
              badge: doc.required ? "· Wajib" : "· Opsional",
              file: doc.file,
              onTap: () => _pickIdentityDoc(doc),
              onRemove: doc.file == null ? null : () => setState(() => doc.file = null),
            ),
          SizedBox(height: 14),
          _sectionLabel("Bukti Bayar"),
          if (_paymentProofs.isEmpty)
            _docRow(
              icon: Icons.receipt_long_outlined,
              name: "Bukti Transfer",
              badge: "· Wajib*",
              file: null,
              onTap: _addPaymentProof,
            )
          else
            for (var i = 0; i < _paymentProofs.length; i++)
              _docRow(
                icon: Icons.receipt_long_outlined,
                name: _paymentProofs[i].name,
                badge: i == 0 ? "· Wajib*" : null,
                file: _paymentProofs[i],
                onTap: _addPaymentProof,
                onRemove: () => setState(() => _paymentProofs.removeAt(i)),
              ),
          _ghostButton("+ Tambah Bukti Bayar Lain", _addPaymentProof),
          SizedBox(height: 12),
          _label("Jenis Transaksi"),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in _transactionTypes)
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: _chip(type, _jenisTransaksi == type, () => setState(() => _jenisTransaksi = type)),
                  ),
              ],
            ),
          ),
          _label("Nominal Pembayaran"),
          _input(
            nominalTC,
            hint: "0",
            prefixText: "Rp ",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, const ThousandsInputFormatter()],
          ),
          _label("Catatan"),
          _input(catatanTC, hint: "Mis: customer transfer DP awal, dokumen menyusul", maxLines: 3),
        ],
      ),
    );
  }


  Widget _buildUnit() {
    final units = _filteredContactUnits();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: _input(
            searchTC,
            hint: "Cari blok / no. unit…",
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildContactUnitList(units)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14, 10, 14, 16),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            border: Border(top: BorderSide(color: Color(grey10Color))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_selectedUnits.length} unit dipilih",
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(blue2Color)),
              ),
              SizedBox(height: 8),
              customButton(_onNextUnit, "Lanjut ke Review"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactUnitList(List<SelectedUnit> units) {
    if (units.isEmpty) {
      final q = searchTC.text.trim();
      return _emptyInfo(
        q.isEmpty ? "Belum ada unit untuk project ini." : "Unit \"$q\" tidak ditemukan.",
      );
    }

    return ListView.builder(
      controller: _unitScroll,
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: units.length,
      itemBuilder: (context, index) => _contactUnitRow(units[index]),
    );
  }

  String _unitRowTitle(SelectedUnit unit) {
    if (unit.propertyName != null && unit.propertyName!.trim().isNotEmpty) {
      return unit.propertyName!.trim();
    }
 
    return unit.isWaitingList ? 'Waiting list' : 'Belum tentukan kavling';
  }

  String _unitRowSubtitle(SelectedUnit unit) {
    if (unit.propertyName != null && unit.propertyName!.trim().isNotEmpty) {
      final names = [
        if (unit.clusterName.trim().isNotEmpty) unit.clusterName.trim(),
        if ((unit.productName ?? '').trim().isNotEmpty) unit.productName!.trim(),
      ];
      return names.join(' · ');
    }
    return '';
  }

  Widget _unitHookBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Hook',
        style: TextStyle(fontSize: 9, color: Color(0xFFB26A00), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _contactUnitRow(SelectedUnit unit) {
    final selected = _selectedUnits.containsKey(unit.key);
    final title = _unitRowTitle(unit);
    final subtitle = _unitRowSubtitle(unit);

    return InkWell(
      onTap: () => _toggleSelectedUnit(unit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? _selectedBg : Color(whiteColor),
          border: Border.all(color: selected ? Color(primaryColor) : Color(grey10Color), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Color(primaryColor) : Color(whiteColor),
                border: Border.all(color: selected ? Color(primaryColor) : Color(grey7Color), width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: selected ? Icon(Icons.check, size: 12, color: Color(whiteColor)) : null,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                        ),
                      ),
                      if (unit.isTipeHoek) _unitHookBadge(),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 10, color: Color(grey4Color))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildReview() {
    final contact = widget.args.dataContact;
    final nominal = _nominal;
    final catatan = catatanTC.text.trim();
    final proofCount = _paymentProofs.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              border: Border.all(color: Color(grey10Color)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _reviewLine("Kontak", contact?.fullName ?? namaTC.text.trim()),
                _reviewLine("Data Pembeli", "Lengkap ✓", ok: true),
                _reviewLine(
                  "Dokumen",
                  "KTP ✓ · Bukti Bayar ✓ ${proofCount > 1 ? '($proofCount)' : ''}".trim(),
                  ok: true,
                ),
                _reviewLine("Jenis Transaksi", _jenisTransaksi),
                _reviewLine(
                  "Nominal & Catatan",
                  nominal == null ? '-' : 'Rp ${NumberHelper.thousands(nominal)} ✓',
                  ok: nominal != null,
                  isLast: catatan.isEmpty,
                ),
                if (catatan.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(catatan, style: TextStyle(fontSize: 11, color: Color(grey4Color))),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),
          for (final unit in _selectedUnits.values)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Color(grey10Color)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _unitRowTitle(unit),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                        ),
                      ),
                      if (unit.isTipeHoek) _unitHookBadge(),
                    ],
                  ),
                  if (_unitRowSubtitle(unit).isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(_unitRowSubtitle(unit), style: TextStyle(fontSize: 11, color: Color(grey4Color))),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewLine(String label, String value, {bool ok = false, bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Color(grey1Color))),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ok ? Color(successColor) : Color(blue2Color),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSukses() {
    final unit = _selectedUnits.values.isEmpty ? null : _selectedUnits.values.first;
    final unitLabel = unit == null ? null : _unitRowTitle(unit);
    final nama = namaTC.text.trim().isEmpty ? (widget.args.dataContact?.fullName ?? '-') : namaTC.text.trim();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 36, 20, 10),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Color(0xFFE7F9EE), shape: BoxShape.circle),
            child: Icon(Icons.check, size: 32, color: Color(successColor)),
          ),
          SizedBox(height: 16),
          Text(
            "Reserve Order Berhasil Diajukan",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
          SizedBox(height: 6),
          Text(
            unitLabel == null
                ? "Pengajuan a.n. $nama sedang diproses."
                : "$unitLabel a.n. $nama sedang diproses.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.6, color: Color(grey4Color)),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey10Color)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              unit == null ? '-' : _unitRowTitle(unit),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                            ),
                          ),
                          if (unit?.isTipeHoek == true) _unitHookBadge(),
                        ],
                      ),
                      Text(nama, style: TextStyle(fontSize: 9.5, color: Color(grey4Color))),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(warningColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Diproses",
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(whiteColor)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Dokumen sudah tersimpan di Attachment kontak. Rincian transaksinya masih tersimpan di aplikasi ini saja — endpoint reserve order di server belum tersedia.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(grey5Color)),
          ),
        ],
      ),
    );
  }


  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(grey1Color)),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 11, color: Color(grey4Color))),
    );
  }

  Widget _input(
    TextEditingController controller, {
    String? hint,
    String? prefixText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(fontSize: 12.5, color: Color(blue2Color)),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Color(grey11Color),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.5, color: Color(grey5Color)),
        prefixText: prefixText,
        prefixStyle: TextStyle(fontSize: 12.5, color: Color(blue2Color)),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 16, color: Color(grey5Color)),
        prefixIconConstraints: BoxConstraints(minWidth: 34, minHeight: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Color(grey7Color)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Color(grey7Color)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Color(primaryColor)),
        ),
      ),
    );
  }

  Widget _pickerRow({required String? value, required String hint, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: Color(grey10Color), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: value == null ? Color(grey5Color) : Color(blue2Color),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Color(grey4Color)),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Color(primaryColor), width: 1.5, style: BorderStyle.solid),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(primaryColor)),
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Color(primaryColor) : Color(whiteColor),
          border: Border.all(color: selected ? Color(primaryColor) : Color(grey7Color)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? Color(whiteColor) : Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _docRow({
    required IconData icon,
    required String name,
    String? badge,
    required PickedFileResult? file,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Color(grey10Color)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: Color(primaryColor)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                      children: [
                        if (badge != null)
                          TextSpan(
                            text: ' $badge',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w400, color: Color(grey4Color)),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    file == null ? "Ketuk untuk upload" : "Terupload · ${_fileSize(file)}",
                    style: TextStyle(
                      fontSize: 10,
                      color: file == null ? Color(primaryColor) : Color(grey4Color),
                    ),
                  ),
                ],
              ),
            ),
            if (file != null) ...[
              Icon(Icons.check, size: 16, color: Color(successColor)),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, size: 15, color: Color(grey5Color)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyInfo(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(grey4Color)),
        ),
      ),
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
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(blue2Color)),
            ),
          ),
          for (final item in items)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPicked(item);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item, style: TextStyle(fontSize: 13, color: Color(blue2Color))),
                    ),
                    if (item == selected) Icon(Icons.check, size: 18, color: Color(primaryColor)),
                  ],
                ),
              ),
            ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fileSize(PickedFileResult file) {
    final bytes = file.bytes?.lengthInBytes ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
class _DocSlot {
  final String title;
  final IconData icon;
  final bool required;

  /// Kata kunci untuk mencari attachment type-nya saat diunggah ke kontak.
  final List<String> typeKeywords;

  PickedFileResult? file;

  _DocSlot({
    required this.title,
    required this.icon,
    required this.typeKeywords,
    this.required = false,
  });
}
