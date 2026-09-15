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
import 'package:progress_group/core/utils/widget/unit_status_badge.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/ktp_ocr_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/ktp_ocr/ktp_ocr_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/ktp_ocr/ktp_ocr_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_unit/reserve_unit_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_unit/reserve_unit_state.dart';
enum ReserveStep { pembeli, unit, dokumen, review, sukses }
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
  final tempatLahirTC = TextEditingController();
  final alamatTC = TextEditingController();
  final noHpTC = TextEditingController();
  final pekerjaanTC = TextEditingController();
  String? _statusPernikahan;
  String? _agama;
  String? _kategoriPekerjaan;
  String? _caraPembayaran;
  int? _caraBayarId;

  bool _submitting = false;

  KtpOcrModel? _ocr;
  PickedFileResult? _ktpFile;

  DateTime? _birthDate;

  late final List<_DocSlot> _identityDocs;
  final List<PickedFileResult> _paymentProofs = [];

  List<ReserveFilterOption> _transactionTypeOptions = const [];
  String _jenisTransaksi = 'Reserve';
  final nominalTC = TextEditingController();
  final catatanTC = TextEditingController();

  final searchTC = TextEditingController();
  Timer? _searchDebounce;
  final Map<String, SelectedUnit> _selectedUnits = {};
  final Set<String> _autoSelectedUnitKeys = {};
  bool _existingUnitsErrorShown = false;

  
  List<CaraBayarOption> _caraBayarOptions = [];
  List<String> _transactionTypes = [];



  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_reserve');
    context.read<KtpOcrCubit>().reset();
    _loadTransactionTypes();
    _loadCaraBayarOptions();
    _loadUnits();

    final contact = widget.args.dataContact;
    namaTC.text = contact?.fullName ?? '';
    nikTC.text = (contact?.noKtp ?? '').replaceAll(RegExp(r'\D'), '');
    alamatTC.text = contact?.ktpAddress ?? '';
    noHpTC.text = contact?.primaryPhone ?? '';

    _identityDocs = [
      _DocSlot(title: 'KTP', icon: Icons.badge_outlined, required: true),
      _DocSlot(title: 'NPWP', icon: Icons.description_outlined),
    ];
  }

  Future<void> _loadTransactionTypes() async {
    final types = await context.read<ReserveOrderListCubit>().ensureTransactionTypeFilters();
    if (!mounted || types.isEmpty) return;
    setState(() {
      _transactionTypeOptions = types;
      _transactionTypes = types.map((t) => t.name).toList();
      if (!_transactionTypes.contains(_jenisTransaksi)) _jenisTransaksi = _transactionTypes.first;
    });
  }

  int? _statusReserveIdOf(String name) {
    for (final option in _transactionTypeOptions) {
      if (option.name == name) return option.statusReserveId;
    }
    return null;
  }

  Future<void> _loadCaraBayarOptions() async {
    final options = await context.read<ReserveOrderListCubit>().ensureCaraBayarOptions();
    if (!mounted || options.isEmpty) return;
    setState(() {
      _caraBayarOptions = options;
    });
  }

  int? _caraBayarIdOf(String name) {
    for (final option in _caraBayarOptions) {
      if (option.name == name) return option.caraBayarId;
    }
    return null;
  }

  // Dipanggil dari `initState` (lihat komentar di [_ReservePageState]) — waktu itu `_buildUnit()`
  // belum ke-mount sama sekali (masih di step Pembeli), jadi `BlocConsumer.listener` di situ TIDAK
  // akan kebagian transisi loading->loaded ini kalau fetch-nya keburu selesai duluan sebelum user
  // sampai step Unit (listener flutter_bloc cuma nangkep transisi SESUDAH widget-nya subscribe,
  // bukan state yang sudah jadi final duluan). Makanya auto-centang-nya dipicu langsung di sini
  // juga begitu `load()` selesai, tidak cuma mengandalkan listener itu.
  void _loadUnits() {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;
    final cubit = context.read<ReserveUnitCubit>();
    cubit.load(contactId: contactId).then((_) {
      if (mounted) _autoSelectAlreadyChosenUnits(cubit.state);
    });
  }

  @override
  void dispose() {
    namaTC.dispose();
    nikTC.dispose();
    tempatLahirTC.dispose();
    alamatTC.dispose();
    noHpTC.dispose();
    pekerjaanTC.dispose();
    nominalTC.dispose();
    catatanTC.dispose();
    searchTC.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }


  static const List<ReserveStep> _numberedSteps = [
    ReserveStep.pembeli,
    ReserveStep.unit,
    ReserveStep.dokumen,
    ReserveStep.review,
  ];

  void _goToPreviousStep() {
    if (_step == ReserveStep.sukses) return;
    if (_submitting) return;

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
          }, "Kamera"),
          SizedBox(height: 12),
          customButton(() {
            Navigator.pop(context);
            _pickAndScan(fromCamera: false);
          }, "Unggah", colorBg: Color(whiteColor), colorText: Color(primaryColor)),
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
      showSnackbar(context, 'Data KTP berhasil dibaca. Silakan periksa kembali.');
    } else if (ocrState.status == KtpOcrStatus.error) {
      showSnackbar(context, ocrState.error ?? 'Gagal membaca KTP', isError: true);
    } else {
      showSnackbar(context, 'Data KTP tidak dapat dibaca. Silakan isi manual.', isError: true);
    }
  }

  void _applyOcr(KtpOcrModel r) {
    setState(() {
      _ocr = r;
      if (r.nama != null) namaTC.text = r.nama!;
      if (r.nik != null) nikTC.text = r.nik!.replaceAll(RegExp(r'\D'), '');
      if (r.alamat != null) alamatTC.text = r.alamat!;
      if (r.pekerjaan != null) pekerjaanTC.text = r.pekerjaan!;
      if (r.tempatLahir != null) tempatLahirTC.text = r.tempatLahir!;
      _birthDate = _parseOcrDate(r.tanggalLahir) ?? _birthDate;

      _statusPernikahan = _matchOption(r.statusPerkawinan, roMaritalStatusItems) ?? _statusPernikahan;
      _agama = _matchOption(r.agama, roReligionItems) ?? _agama;
    });
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
    setState(() => _step = ReserveStep.unit);
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
      showSnackbar(context, 'Dokumen KTP wajib diunggah', isError: true);
      return;
    }
    if (_paymentProofs.isEmpty) {
      showSnackbar(context, 'Minimal 1 bukti pembayaran wajib diunggah', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Nominal pembayaran wajib diisi', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_dokumen_next');
    setState(() => _step = ReserveStep.review);
  }


  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<ReserveUnitCubit>().setSearch(value);
    });
  }

  /// Cocok/tidaknya [a] dan [b] posisinya di tree (cluster/produk/kavling/waiting-list) — dipakai
  /// buat mencocokkan unit yang sudah ada (`SelectedUnit.key` berbasis `deal:$dealId`) dengan baris
  /// katalog di tree (`key` berbasis `clusterId|productId|propertyId|waiting`), karena dua skema key
  /// itu beda walau menunjuk unit fisik yang sama.
  bool _samePosition(SelectedUnit a, SelectedUnit b) =>
      a.clusterId == b.clusterId &&
      a.productId == b.productId &&
      (a.propertyId ?? 0) == (b.propertyId ?? 0) &&
      a.isWaitingList == b.isWaitingList;

  bool _isUnitPicked(SelectedUnit unit) =>
      _selectedUnits.containsKey(unit.key) || _selectedUnits.values.any((picked) => _samePosition(picked, unit));

  void _toggleSelectedUnit(SelectedUnit unit) {
    setState(() {
      if (_selectedUnits.containsKey(unit.key)) {
        _selectedUnits.remove(unit.key);
        return;
      }
      // Baris ini kelihatan tercentang karena cocok posisinya sama salah satu unit yang sudah ADA
      // (key deal-based) — tap-nya berarti mau di-uncheck, jadi hapus entri ASLINYA, bukan nambah
      // entri baru dengan key katalog (yang bakal bikin dua entri buat unit fisik yang sama).
      final existingKeys =
          _selectedUnits.entries.where((e) => _samePosition(e.value, unit)).map((e) => e.key).toList();
      if (existingKeys.isNotEmpty) {
        for (final k in existingKeys) {
          _selectedUnits.remove(k);
        }
      } else {
        _selectedUnits[unit.key] = unit;
      }
    });
  }

  void _removeSelectedUnit(String key) {
    setState(() => _selectedUnits.remove(key));
  }

  // Cuma boleh 1 unit terpilih — `POST /api/reserve` yang baru cuma nerima satu `deal_id` sekaligus
  // (bukan lagi array unit lewat `POST /api/reserve-unit` terpisah per unit), lihat
  // `_buildCreateReserveParams`.
  void _onNextUnit() {
    if (_selectedUnits.isEmpty) {
      showSnackbar(context, 'Pilih 1 unit', isError: true);
      return;
    }
    if (_selectedUnits.length > 1) {
      showSnackbar(context, 'Hanya boleh pilih 1 unit', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_unit_next');
    setState(() => _step = ReserveStep.dokumen);
  }


  /// Satu request multipart `POST /api/reserve` — bikin customer, tautkan SATU unit (`deal_id`),
  /// dan kirim dokumen + rincian pembayaran sekaligus. Menggantikan alur lama 3 request berurutan
  /// (`createReserve` → `saveReserveUnit` per unit → `submitDocPayment`) — sesuai instruksi
  /// eksplisit, karena step "Pilih Unit" sekarang cuma boleh 1 unit terpilih (lihat `_onNextUnit`).
  Future<void> _onSubmit() async {
    if (_submitting) return;

    final statusReserveId = _statusReserveIdOf(_jenisTransaksi);
    if (statusReserveId == null) {
      showSnackbar(context, 'Jenis transaksi tidak dikenali, silakan coba lagi', isError: true);
      return;
    }
    final contact = widget.args.dataContact;
    final contactId = contact?.contactId;
    if (contactId == null) {
      showSnackbar(context, 'Kontak tidak dikenali, reserve order tidak dapat dibuat', isError: true);
      return;
    }
    final unit = _selectedUnits.values.isEmpty ? null : _selectedUnits.values.first;
    if (unit == null) {
      showSnackbar(context, 'Pilih 1 unit', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_submit');
    final dataSource = context.read<ReserveOrderListCubit>().dataSource;

    setState(() => _submitting = true);

    try {
      await dataSource.createReserve(
        _buildCreateReserveParams(contactId: contactId, dealId: unit.dealId, companyId: unit.companyId, statusReserveId: statusReserveId),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
      return;
    }
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _step = ReserveStep.sukses;
    });
  }

  CreateReserveParams _buildCreateReserveParams({
    required int contactId,
    required int? dealId,
    required int companyId,
    required int statusReserveId,
  }) {
    final birthPlace = tempatLahirTC.text.trim();
    final ktpFile = _identityDocs[0].file;
    final npwpFile = _identityDocs.length > 1 ? _identityDocs[1].file : null;
    final buktiTransferProofs = _paymentProofs.where((f) => f.bytes != null).toList();
    final catatan = catatanTC.text.trim();

    return CreateReserveParams(
      contactId: contactId,
      dealId: dealId,
      companyId: companyId,
      custName: namaTC.text.trim(),
      custKtp: nikTC.text.trim(),
      custBirthPlace: birthPlace.isEmpty ? null : birthPlace,
      custBirthDate: _birthDate,
      custGenderIsMale: switch (_ocr?.jenisKelamin) {
        'Laki-laki' => true,
        'Perempuan' => false,
        _ => null,
      },
      custMaritalStatus: _statusPernikahan?.toUpperCase(),
      custReligion: _agama,
      workCategory: _kategoriPekerjaan,
      custOccupation: pekerjaanTC.text.trim(),
      custAddress1: alamatTC.text.trim(),
      caraBayarId: _caraBayarId,
      custTelpMobile1: noHpTC.text.trim(),
      statusReserveId: statusReserveId,
      amountRp: _nominal ?? 0,
      reserveNote: catatan.isEmpty ? null : catatan,
      ktpBytes: [if (ktpFile?.bytes != null) ktpFile!.bytes!],
      ktpFileNames: [if (ktpFile?.bytes != null) ktpFile!.name],
      npwpBytes: npwpFile?.bytes,
      npwpFileName: npwpFile?.name,
      buktiTransferBytes: [for (final proof in buktiTransferProofs) proof.bytes!],
      buktiTransferFileNames: [for (final proof in buktiTransferProofs) proof.name],
    );
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
      ReserveStep.unit => _buildUnit(),
      ReserveStep.dokumen => _buildDokumen(),
      ReserveStep.review => _buildReview(),
      ReserveStep.sukses => _buildSukses(),
    };
  }

  Widget _buildAppBar() {
    final contact = widget.args.dataContact;
    final withContact = _step == ReserveStep.pembeli || _step == ReserveStep.dokumen;
    final title = switch (_step) {
      ReserveStep.unit => 'Pilih Unit',
      ReserveStep.review => 'Tinjau Transaction',
      _ => 'Transaction — ${contact?.fullName ?? '-'}',
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
    const labels = ['Pembeli', 'Unit', 'Dokumen', 'Tinjau'];

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
      ReserveStep.pembeli => [customButton(_onNextPembeli, "Lanjut ke Pilih Unit")],
      ReserveStep.unit => const <Widget>[],
      ReserveStep.dokumen => [customButton(_onNextDokumen, "Lanjut ke Tinjau")],
      ReserveStep.review => [
          roPrimaryButton(
            _submitting ? "Mengirim transaksi..." : "Ajukan Transaction",
            _onSubmit,
            loading: _submitting,
          ),
        ],
      ReserveStep.sukses => [
          customButton(() => context.pop(_result), "Lihat di Transaction"),
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
            _ktpFile == null ? "📷  Pindai KTP" : "📷  Pindai KTP Lagi",
            _showScanSourceSheet,
          ),
          SizedBox(height: 6),
          Text(
            _ktpFile == null
                ? "Otomatis mengisi kolom di bawah"
                : "Foto KTP terlampir (${_fileSize(_ktpFile!)}) — juga dipakai di step Dokumen",
            style: TextStyle(fontSize: 10, color: Color(grey4Color)),
          ),
          SizedBox(height: 12),
          _label("Nama Lengkap (sesuai KTP)"),
          _input(namaTC, hint: "Nama sesuai KTP"),
          _label("No. KTP"),
          _input(
            nikTC,
            hint: "NIK 16 digit",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
          ),
          _label("Tempat Lahir"),
          _input(tempatLahirTC, hint: "Pilih Tempat Lahir"),
          _label("Tanggal Lahir"),
          roPickerRow(
            value: _birthDate == null ? null : DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate!),
            hint: "Pilih tanggal lahir",
            onTap: _pickBirthDate,
          ),
          _label("Agama"),
          roPickerRow(
            value: _agama,
            hint: "Pilih agama",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Agama",
              items: roReligionItems,
              selected: _agama,
              onPicked: (v) => setState(() => _agama = v),
            ),
          ),
          _label("Alamat (sesuai KTP)"),
          _input(alamatTC, hint: "mis. Nama Jalan No. 1…", maxLines: 2),
          _label("No. HP"),
          _input(
            noHpTC,
            hint: "08xxxxxxxxxx",
            keyboardType: TextInputType.phone,
          ),
          _label("Status Pernikahan"),
          roPickerRow(
            value: _statusPernikahan,
            hint: "Pilih status pernikahan",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Status Pernikahan",
              items: roMaritalStatusItems,
              selected: _statusPernikahan,
              onPicked: (v) => setState(() => _statusPernikahan = v),
            ),
          ),
          _label("Kategori Pekerjaan"),
          roPickerRow(
            value: _kategoriPekerjaan,
            hint: "Pilih kategori pekerjaan",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Kategori Pekerjaan",
              items: roWorkCategoryItems,
              selected: _kategoriPekerjaan,
              onPicked: (v) => setState(() => _kategoriPekerjaan = v),
            ),
          ),
          _label("Pekerjaan"),
          _input(pekerjaanTC, hint: "Pekerjaan"),
          _label("Tujuan Pembayaran"),
          roPickerRow(
            value: _caraPembayaran,
            hint: "Pilih Tujuan Pembayaran",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Tujuan Pembayaran",
              items: _caraBayarOptions.map((o) => o.name).toList(),
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
          _sectionLabel("Bukti Pembayaran"),
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
          _ghostButton("+ Tambah Bukti Pembayaran Lain", _addPaymentProof),
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
          SizedBox(height: 8),
          _nominalPresetRow(),
          _label("Catatan"),
          _input(catatanTC, hint: "mis.: customer sudah transfer DP awal, dokumen menyusul", maxLines: 3),
        ],
      ),
    );
  }

  static final List<int> _nominalPresets = [for (var jt = 2; jt <= 25; jt++) jt * 1000000];

  Widget _nominalPresetRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final amount in _nominalPresets)
            Padding(
              padding: EdgeInsets.only(right: 6),
              child: _chip(
                'Rp ${amount ~/ 1000000}jt',
                _nominal == amount,
                () => setState(() => nominalTC.text = NumberHelper.thousands(amount)),
              ),
            ),
        ],
      ),
    );
  }


  /// Semua baris dari `GET /api/reserve/product-select` ([ReserveUnitState.existingUnits]) memang
  /// deal yang sudah ada buat kontak ini — beda dari katalog [ReserveUnitState.clusters] yang cuma
  /// pilihan yang BISA dipilih. Jadi begitu dimuat, semuanya langsung dicentang otomatis.
  void _autoSelectAlreadyChosenUnits(ReserveUnitState state) {
    if (state.status != ReserveUnitStatus.loaded) return;
    var touched = false;
    for (final unit in state.existingUnits) {
      if (_autoSelectedUnitKeys.contains(unit.key)) continue;
      touched = true;
      _autoSelectedUnitKeys.add(unit.key);
      _selectedUnits.putIfAbsent(unit.key, () => unit);
      // Expand cluster/produknya di tree katalog juga (kalau ketemu) — biar baris yang cocok
      // langsung kelihatan tercentang begitu step-nya dibuka, sama seperti Unit Picker di contact.
      if (unit.productId != null) {
        context.read<ReserveUnitCubit>().expandProductFor(
              clusterId: unit.clusterId,
              companyId: unit.companyId,
              productId: unit.productId!,
            );
      }
    }
    if (touched) setState(() {});

    if (state.existingUnitsError != null && !_existingUnitsErrorShown) {
      _existingUnitsErrorShown = true;
      showSnackbar(context, state.existingUnitsError!, isError: true);
    }
  }

  Widget _buildUnit() {
    return BlocConsumer<ReserveUnitCubit, ReserveUnitState>(
      listener: (context, state) => _autoSelectAlreadyChosenUnits(state),
      builder: (context, state) => Column(
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
          Expanded(child: _buildUnitList(state)),
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
                if (_selectedUnits.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in _selectedUnits.entries)
                          InputChip(
                            label: Text(entry.value.label, style: TextStyle(fontSize: 11.5, color: Color(blue2Color))),
                            backgroundColor: Color(grey11Color),
                            onDeleted: () => _removeSelectedUnit(entry.key),
                            deleteIcon: Icon(Icons.close, size: 14, color: Color(blue2Color)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),
                Text(
                  "${_selectedUnits.length} unit dipilih",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                ),
                SizedBox(height: 8),
                customButton(_onNextUnit, "Lanjut ke Dokumen"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitList(ReserveUnitState state) {
    if (state.status == ReserveUnitStatus.loading && state.clusters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ReserveUnitStatus.error && state.clusters.isEmpty) {
      return _emptyInfo(state.error ?? 'Gagal memuat unit', action: 'Coba Lagi', onAction: _loadUnits);
    }

    final q = searchTC.text.trim();
    if (state.clusters.isEmpty) {
      return _emptyInfo(q.isEmpty ? "Tidak ada unit tersedia." : "Unit \"$q\" tidak ditemukan.");
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        for (final cluster in _clustersExpandedFirst(state)) ..._unitClusterTile(state, cluster),
      ],
    );
  }

  /// Cluster yang lagi expanded (biasanya karena auto-centang unit yang sudah ada, lihat
  /// `_autoSelectAlreadyChosenUnits`) ditaruh paling atas, supaya langsung kelihatan tanpa perlu
  /// scroll cari-cari — urutan relatif di dalam masing-masing grup (expanded/collapsed) dijaga tetap
  /// sama seperti urutan asli dari `state.clusters` (partition manual, bukan `List.sort` yang tidak
  /// dijamin stabil).
  List<UnitCluster> _clustersExpandedFirst(ReserveUnitState state) {
    final expanded = <UnitCluster>[];
    final collapsed = <UnitCluster>[];
    for (final cluster in state.clusters) {
      (state.expandedClusters.contains(cluster.projectId) ? expanded : collapsed).add(cluster);
    }
    return [...expanded, ...collapsed];
  }

  /// Badge kecil "N dipilih" di header cluster/produk — supaya kelihatan cluster/produk mana yang
  /// sudah punya unit terpilih (mis. dari unit yang sudah ada, auto-tercentang) TANPA perlu
  /// expand dulu.
  Widget? _selectedCountBadge(int count) {
    if (count == 0) return null;
    return Container(
      margin: EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: Color(primaryColor), borderRadius: BorderRadius.circular(20)),
      child: Text('$count dipilih', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(whiteColor))),
    );
  }

  List<Widget> _unitClusterTile(ReserveUnitState state, UnitCluster cluster) {
    final expanded = state.expandedClusters.contains(cluster.projectId);
    final selectedCount = _selectedUnits.values.where((u) => u.clusterId == cluster.projectId).length;
    return [
      InkWell(
        onTap: () => context.read<ReserveUnitCubit>().toggleCluster(cluster.projectId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(grey10Color)))),
          child: Row(
            children: [
              Icon(expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20, color: expanded ? Color(primaryColor) : Color(grey7Color)),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cluster.projectName,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(blue2Color))),
                    if ((cluster.townshipName ?? '').trim().isNotEmpty)
                      Text(cluster.townshipName!.trim(), style: TextStyle(fontSize: 10.5, color: Color(grey4Color))),
                  ],
                ),
              ),
              if (_selectedCountBadge(selectedCount) != null) _selectedCountBadge(selectedCount)!,
            ],
          ),
        ),
      ),
      if (expanded)
        for (final product in cluster.products) ..._unitProductTile(state, cluster, product),
    ];
  }

  List<Widget> _unitProductTile(ReserveUnitState state, UnitCluster cluster, UnitProduct product) {
    final key = ReserveUnitCubit.productKey(product);
    final expanded = state.expandedProducts.contains(key);
    final loadingLots = state.loadingProductIds.contains(key);
    final lots = state.lotsByProduct[key] ?? const [];
    final townshipId = product.townshipId != 0 ? product.townshipId : cluster.townshipId;
    final selectedCount = _selectedUnits.values
        .where((u) => u.clusterId == cluster.projectId && u.productId == product.productId)
        .length;

    return [
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: InkWell(
          onTap: () => context.read<ReserveUnitCubit>().toggleProduct(product),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18, color: expanded ? Color(primaryColor) : Color(grey7Color)),
                SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.displayName,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(blue2Color))),
                      if ((product.spec ?? '').trim().isNotEmpty)
                        Text(product.spec!.trim(), style: TextStyle(fontSize: 10.5, color: Color(grey4Color))),
                    ],
                  ),
                ),
                if (_selectedCountBadge(selectedCount) != null) _selectedCountBadge(selectedCount)!,
              ],
            ),
          ),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 2),
          child: Column(
            children: [
              _contactUnitRow(SelectedUnit(
                townshipId: townshipId,
                companyId: product.companyId,
                clusterId: cluster.projectId,
                clusterName: cluster.projectName,
                productId: product.productId,
                productName: product.displayName,
              )),
              _contactUnitRow(SelectedUnit(
                townshipId: townshipId,
                companyId: product.companyId,
                clusterId: cluster.projectId,
                clusterName: cluster.projectName,
                productId: product.productId,
                productName: product.displayName,
                isWaitingList: true,
              )),
              if (loadingLots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (!state.lotsByProduct.containsKey(key))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 15, color: Color(redColor)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text("Gagal memuat kavling", style: TextStyle(fontSize: 11.5, color: Color(redColor))),
                      ),
                      TextButton(
                        onPressed: () => context.read<ReserveUnitCubit>().loadLots(product),
                        style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8), minimumSize: Size(0, 28)),
                        child: Text("Coba lagi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(primaryColor))),
                      ),
                    ],
                  ),
                )
              else
                for (final lot in lots)
                  _contactUnitRow(SelectedUnit(
                    townshipId: townshipId,
                    companyId: product.companyId,
                    clusterId: cluster.projectId,
                    clusterName: cluster.projectName,
                    productId: product.productId,
                    productName: product.displayName,
                    propertyId: lot.propertyId,
                    propertyName: lot.propertyName,
                    isTipeHoek: lot.isTipeHoek,
                    statusName: lot.statusName,
                  )),
            ],
          ),
        ),
    ];
  }

  String _unitRowTitle(SelectedUnit unit) {
    if (unit.propertyName != null && unit.propertyName!.trim().isNotEmpty) {
      return unit.propertyName!.trim();
    }

    return unit.isWaitingList ? 'Daftar Tunggu' : 'Kavling belum ditentukan';
  }

  String _unitRowSubtitle(SelectedUnit unit) {
    if ((unit.dealValue ?? 0) > 0) return 'Rp ${NumberHelper.thousands(unit.dealValue!)}';
    return '';
  }

  Color? _statusBadgeTextColor(String statusName) {
    const bright = {'available', 'reserve'};
    return bright.contains(statusName.toLowerCase()) ? Color(blue2Color) : null;
  }

  Widget _unitHookBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(roAmberBgColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Hook',
        style: TextStyle(fontSize: 9, color: Color(roHookTextColor), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _contactUnitRow(SelectedUnit unit) {
    final selected = _isUnitPicked(unit);
    final sellable = unit.isPropertySellable;
    // Status "HOLD" (dari `status_name` — lihat `UnitLot.statusName`) beneran DISABLE, beda dari
    // `isPropertySellable` di atas yang cuma dipudarkan tapi tetap bisa dicentang (sales yang
    // memutuskan). Kavling HOLD memang tidak boleh dipilih sama sekali, sesuai instruksi eksplisit.
    final isHold = (unit.statusName ?? '').toUpperCase().contains('HOLD');
    final title = _unitRowTitle(unit);
    final subtitle = _unitRowSubtitle(unit);
    final statusName = (unit.statusName ?? '').trim();

    return Opacity(
      opacity: (sellable && !isHold) ? 1 : 0.5,
      child: InkWell(
        onTap: isHold ? null : () => _toggleSelectedUnit(unit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? roSelectedBg : Color(whiteColor),
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
              if (statusName.isNotEmpty) ...[
                SizedBox(width: 8),
                UnitStatusBadge(label: statusName, textColor: _statusBadgeTextColor(statusName)),
              ],
            ],
          ),
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
                _reviewLine("Customer", contact?.fullName ?? namaTC.text.trim()),
                _reviewLine(
                  "Dokumen",
                  "KTP ✓ · Bukti Pembayaran ✓ ${proofCount > 1 ? '($proofCount)' : ''}".trim(),
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
            decoration: BoxDecoration(color: Color(roSuccessBgColor), shape: BoxShape.circle),
            child: Icon(Icons.check, size: 32, color: Color(successColor)),
          ),
          SizedBox(height: 16),
          Text(
            "Transaction Berhasil Diajukan",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
          SizedBox(height: 6),
          Text(
            unitLabel == null
                ? "Pengajuan atas nama $nama sedang diproses."
                : "$unitLabel atas nama $nama sedang diproses.",
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
            "Dokumen & rincian pembayaran telah dikirim ke reserve order ini.",
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
              decoration: BoxDecoration(color: roIconBg, borderRadius: BorderRadius.circular(9)),
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
                    file == null ? "Ketuk untuk mengunggah" : "Terunggah · ${_fileSize(file)}",
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

  Widget _emptyInfo(String message, {String? action, VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(grey4Color)),
            ),
            if (action != null) ...[
              SizedBox(height: 10),
              InkWell(
                onTap: onAction,
                child: Text(
                  action,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(primaryColor)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 17, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
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

  PickedFileResult? file;

  _DocSlot({
    required this.title,
    required this.icon,
    this.required = false,
  });
}
