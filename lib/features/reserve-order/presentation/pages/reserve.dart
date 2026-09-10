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
  final tempatLahirTC = TextEditingController();
  final alamatTC = TextEditingController();
  final pekerjaanTC = TextEditingController();
  String? _statusPernikahan;
  String? _caraPembayaran;
  int? _caraBayarId;

  // `POST /api/reserve` (bikin baris customer-nya) sekarang dipanggil begitu lepas dari step
  // Dokumen (lihat `_onNextDokumen`) — BUKAN saat submit di Review — karena `POST /api/reserve-unit`
  // (step Unit → Review, `_onNextUnit`) butuh `customer_id` dari situ. Submit di Review (`_onSubmit`)
  // tinggal kirim `POST /api/reserve/doc-payment` pakai `_reserveOrderId` yang sudah ada.
  int? _reserveOrderId;
  int? _customerId;
  bool _creatingReserve = false;
  bool _savingUnit = false;
  bool _submittingDocPayment = false;

  KtpOcrModel? _ocr;
  PickedFileResult? _ktpFile;

  DateTime? _birthDate;

  late final List<_DocSlot> _identityDocs;
  final List<PickedFileResult> _paymentProofs = [];

  // Fallback selagi `_loadTransactionTypes()` (endpoint yang sama dengan chip filter list —
  // `GET /api/reserve-filter`) belum kembali / gagal, supaya form tetap bisa disubmit.
  List<String> _transactionTypes = const ['Reserve', 'Booking Reserve (langsung)'];
  // Opsi asli (nama + `status_reserve_id`) dari `GET /api/reserve-filter` — dipakai [_statusReserveIdOf]
  // buat cari id-nya. Kosong berarti masih pakai fallback [_transactionTypes] di atas.
  List<ReserveFilterOption> _transactionTypeOptions = const [];
  String _jenisTransaksi = 'Reserve';
  final nominalTC = TextEditingController();
  final catatanTC = TextEditingController();

  final searchTC = TextEditingController();
  Timer? _searchDebounce;
  final Map<String, SelectedUnit> _selectedUnits = {};
  final ScrollController _unitScroll = ScrollController();

  // Fallback selagi/kalau `_loadCaraBayarOptions()` (`GET /api/reserve/cara-bayar`) belum kembali
  // atau gagal, supaya picker tetap bisa dipilih — id-nya (`_caraBayarId`) cuma null di kasus itu.
  List<String> _paymentMethods = const ['KPR', 'Cash', 'Cash Bertahap', 'Inhouse'];
  List<CaraBayarOption> _caraBayarOptions = const [];


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

    _identityDocs = [
      _DocSlot(title: 'KTP', icon: Icons.badge_outlined, required: true),
      _DocSlot(title: 'NPWP', icon: Icons.description_outlined),
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
      _transactionTypeOptions = types;
      _transactionTypes = types.map((t) => t.name).toList();
      if (!_transactionTypes.contains(_jenisTransaksi)) _jenisTransaksi = _transactionTypes.first;
    });
  }

  /// [name] label "Jenis Transaksi" yang dipilih user; dicari `status_reserve_id`-nya dari master
  /// yang sama dipakai buat isi chip-nya. Null kalau lagi pakai fallback lokal (endpoint gagal/belum
  /// kembali) — tidak ada id aslinya, sama seperti [_caraBayarIdOf].
  int? _statusReserveIdOf(String name) {
    for (final option in _transactionTypeOptions) {
      if (option.name == name) return option.statusReserveId;
    }
    return null;
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

  /// Daftar step "Pilih Unit" — `GET /api/reserve/unit-status?contact_id=…`, dimuat lebih awal
  /// (bareng "Jenis Transaksi"/"Cara Pembayaran") supaya sudah siap begitu user sampai step Unit,
  /// bukan menunggu sampai step-nya baru dibuka.
  void _loadUnits() {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;
    context.read<ReserveUnitCubit>().load(contactId: contactId);
  }

  @override
  void dispose() {
    namaTC.dispose();
    nikTC.dispose();
    tempatLahirTC.dispose();
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
    // Selagi submit (bikin reserve order / simpan unit / kirim dokumen) sedang berjalan, mundur
    // akan menyisakan proses itu separuh jalan.
    if (_creatingReserve || _savingUnit || _submittingDocPayment) return;

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
      showSnackbar(context, 'KTP data read successfully. Please review it.');
    } else if (ocrState.status == KtpOcrStatus.error) {
      showSnackbar(context, ocrState.error ?? 'Failed to read KTP', isError: true);
    } else {
      showSnackbar(context, 'KTP data could not be read. Please fill in manually.', isError: true);
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
      showSnackbar(context, 'Full name is required', isError: true);
      return;
    }
    if (nikTC.text.trim().length != 16) {
      showSnackbar(context, 'KTP No. must be 16 digits', isError: true);
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

  /// Begitu lolos validasi Dokumen, baris `m_customer_reserve` dibuat lewat `POST /api/reserve` —
  /// hasilnya (`_reserveOrderId`/`_customerId`) dibutuhkan step Unit buat `POST /api/reserve-unit`
  /// ([_onNextUnit]) dan step Review buat `POST /api/reserve/doc-payment` ([_onSubmit]). Dokumen
  /// sendiri tetap ditahan lokal sampai submit di Review — cuma baris customer & unitnya yang mulai
  /// tersimpan lebih awal.
  Future<void> _onNextDokumen() async {
    if (_creatingReserve) return;

    if (_identityDocs.first.file == null) {
      showSnackbar(context, 'KTP document is required', isError: true);
      return;
    }
    if (_paymentProofs.isEmpty) {
      showSnackbar(context, 'At least 1 payment proof is required', isError: true);
      return;
    }
    final nominal = _nominal;
    if (nominal == null || nominal <= 0) {
      showSnackbar(context, 'Payment amount is required', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_dokumen_next');

    // Sudah pernah berhasil dibuat (mis. user mundur dari Unit lalu maju lagi) — tidak usah bikin
    // baris baru lagi, tinggal lanjut ke Unit dengan id yang sama.
    if (_reserveOrderId != null && _customerId != null) {
      setState(() => _step = ReserveStep.unit);
      return;
    }

    final contact = widget.args.dataContact;
    final contactId = contact?.contactId;
    if (contactId == null) {
      showSnackbar(context, 'Contact not recognized, reserve order cannot be created', isError: true);
      return;
    }

    final dataSource = context.read<ReserveOrderListCubit>().dataSource;
    setState(() => _creatingReserve = true);
    try {
      final result = await dataSource.createReserve(_buildCreateReserveParams(contactId));
      if (!mounted) return;
      setState(() {
        _creatingReserve = false;
        _reserveOrderId = result.reserveOrderId;
        _customerId = result.customerId;
        _step = ReserveStep.unit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingReserve = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
    }
  }


  void _onUnitScroll() {
    if (!_unitScroll.hasClients) return;
    // Ambil halaman berikutnya sebelum benar-benar mentok supaya scroll-nya tidak tersendat.
    if (_unitScroll.position.pixels >= _unitScroll.position.maxScrollExtent - 240) {
      context.read<ReserveUnitCubit>().loadMore();
    }
  }

  /// Pencarian unit sekarang jalan di server (`GET /api/reserve/unit-status?search=…`), bukan
  /// filter lokal — di-debounce 300ms sama seperti pencarian lain di app ini supaya tidak nembak
  /// API tiap ketikan.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<ReserveUnitCubit>().setSearch(value);
    });
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

  /// Menautkan tiap unit yang dipilih ke customer yang barusan dibuat ([_onNextDokumen]) lewat
  /// `POST /api/reserve-unit` (`deal_id` + `customer_id`), satu request per unit. Unit yang tidak
  /// punya `dealId` (mis. dari sumber selain `GET /api/reserve/unit-status`) dilewati — tidak ada
  /// deal yang bisa ditautkan.
  Future<void> _onNextUnit() async {
    if (_savingUnit) return;

    if (_selectedUnits.isEmpty) {
      showSnackbar(context, 'Select at least 1 unit', isError: true);
      return;
    }
    final customerId = _customerId;
    if (customerId == null) {
      showSnackbar(context, 'Buyer data not saved yet, please start over', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_step_unit_next');

    final dataSource = context.read<ReserveOrderListCubit>().dataSource;
    setState(() => _savingUnit = true);
    try {
      for (final unit in _selectedUnits.values) {
        final dealId = unit.dealId;
        if (dealId == null) continue;
        await dataSource.saveReserveUnit(dealId: dealId, customerId: customerId);
      }
      if (!mounted) return;
      setState(() {
        _savingUnit = false;
        _step = ReserveStep.review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingUnit = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
    }
  }


  /// Dokumen ditahan lokal sepanjang 3 step pertama, baru dikirim di sini — jadi kalau flow-nya
  /// ditinggal di tengah jalan tidak ada dokumen/pembayaran nyangkut di reserve order manapun.
  /// Baris customer & unitnya sendiri sudah dibuat lebih awal ([_onNextDokumen]/[_onNextUnit]),
  /// jadi submit di sini tinggal kirim dokumen (KTP/NPWP/bukti bayar) + rincian pembayaran lewat
  /// `POST /api/reserve/doc-payment` pakai `_reserveOrderId` yang sudah ada.
  Future<void> _onSubmit() async {
    if (_submittingDocPayment) return;

    final reserveOrderId = _reserveOrderId;
    if (reserveOrderId == null) {
      showSnackbar(context, 'Reserve order not saved yet, please start over', isError: true);
      return;
    }

    final statusReserveId = _statusReserveIdOf(_jenisTransaksi);
    if (statusReserveId == null) {
      showSnackbar(context, 'Transaction type not recognized, please try again', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_submit');
    final cubit = context.read<ReserveOrderListCubit>();
    final dataSource = cubit.dataSource;

    setState(() => _submittingDocPayment = true);

    final ktpFile = _identityDocs[0].file;
    final npwpFile = _identityDocs.length > 1 ? _identityDocs[1].file : null;
    final buktiTransferProofs = _paymentProofs.where((f) => f.bytes != null).toList();
    final catatan = catatanTC.text.trim();

    try {
      final reserveOrderTtsId = await dataSource.submitDocPayment(DocPaymentParams(
        reserveOrderId: reserveOrderId,
        statusReserveId: statusReserveId,
        ttsAmountRp: _nominal ?? 0,
        note: catatan.isEmpty ? null : catatan,
        ktpBytes: [if (ktpFile?.bytes != null) ktpFile!.bytes!],
        ktpFileNames: [if (ktpFile?.bytes != null) ktpFile!.name],
        npwpBytes: npwpFile?.bytes,
        npwpFileName: npwpFile?.name,
        buktiTransferBytes: [for (final proof in buktiTransferProofs) proof.bytes!],
        buktiTransferFileNames: [for (final proof in buktiTransferProofs) proof.name],
      ));
      // Disimpan supaya tab "Attachment" di halaman Detail bisa memanggil `GET
      // /api/reserve/attachment` — endpoint itu butuh `reserve_order_tts_id`, yang tidak ada di
      // `GET /api/reserve` (list) sama sekali. Lihat `ReserveOrderListCubit.rememberTtsId`.
      cubit.rememberTtsId(reserveOrderId, reserveOrderTtsId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingDocPayment = false);
      showSnackbar(context, cleanErrorMessage(e), isError: true);
      return;
    }
    if (!mounted) return;

    setState(() {
      _submittingDocPayment = false;
      _step = ReserveStep.sukses;
    });
  }

  /// Payload `POST /api/reserve`. Jenis kelamin & agama cuma terisi kalau ada hasil scan KTP
  /// (belum ada input manual buat keduanya di form ini).
  CreateReserveParams _buildCreateReserveParams(int contactId) {
    final birthPlace = tempatLahirTC.text.trim();

    return CreateReserveParams(
      contactId: contactId,
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
      custReligion: _ocr?.agama,
      custOccupation: pekerjaanTC.text.trim(),
      custAddress1: alamatTC.text.trim(),
      caraBayarId: _caraBayarId,
      custTelpMobile1: widget.args.dataContact?.primaryPhone,
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
      ReserveStep.unit => 'Select Unit',
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
    const labels = ['Buyer', 'Documents', 'Unit', 'Review'];

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
      ReserveStep.pembeli => [customButton(_onNextPembeli, "Continue to Documents")],
      ReserveStep.dokumen => [
          roPrimaryButton(
            _creatingReserve ? "Creating reserve order..." : "Continue to Select Unit",
            _onNextDokumen,
            loading: _creatingReserve,
          ),
        ],
      ReserveStep.unit => const <Widget>[],
      ReserveStep.review => [
          roPrimaryButton(
            _submittingDocPayment ? "Uploading documents..." : "Submit Reserve Order",
            _onSubmit,
            loading: _submittingDocPayment,
          ),
        ],
      ReserveStep.sukses => [
          customButton(() => context.pop(_result), "View in Reserve Order"),
          SizedBox(height: 8),
          customButton(
            _backToContact,
            "Back to Contact",
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
                Text("Reading KTP data...", style: TextStyle(fontSize: 13, color: Color(grey2Color))),
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
            _ktpFile == null ? "📷  Scan KTP" : "📷  Scan KTP Again",
            _showScanSourceSheet,
          ),
          SizedBox(height: 6),
          Text(
            _ktpFile == null
                ? "Automatically fills the fields below"
                : "KTP photo attached (${_fileSize(_ktpFile!)}) — also used in the Documents step",
            style: TextStyle(fontSize: 10, color: Color(grey4Color)),
          ),
          SizedBox(height: 12),
          _label("Full Name (as per KTP)"),
          _input(namaTC, hint: "Name as per KTP"),
          _label("KTP No."),
          _input(
            nikTC,
            hint: "16-digit NIK",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
          ),
          _label("Place of Birth"),
          _input(tempatLahirTC, hint: "Jakarta"),
          _label("Date of Birth"),
          roPickerRow(
            value: _birthDate == null ? null : DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate!),
            hint: "Select date of birth",
            onTap: _pickBirthDate,
          ),
          _label("Address (as per KTP)"),
          _input(alamatTC, hint: "e.g. Street Name No. 1…", maxLines: 2),
          _label("Marital Status"),
          roPickerRow(
            value: _statusPernikahan,
            hint: "Select marital status",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Marital Status",
              items: roMaritalStatusItems,
              selected: _statusPernikahan,
              onPicked: (v) => setState(() => _statusPernikahan = v),
            ),
          ),
          _label("Occupation"),
          _input(pekerjaanTC, hint: "Self-employed"),
          _label("Payment Plan"),
          roPickerRow(
            value: _caraPembayaran,
            hint: "Select payment plan",
            onTap: () => roShowOptionSheet(
              context: context,
              title: "Payment Plan",
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
          _sectionLabel("Identity Documents"),
          for (final doc in _identityDocs)
            _docRow(
              icon: doc.icon,
              name: doc.title,
              badge: doc.required ? "· Required" : "· Optional",
              file: doc.file,
              onTap: () => _pickIdentityDoc(doc),
              onRemove: doc.file == null ? null : () => setState(() => doc.file = null),
            ),
          SizedBox(height: 14),
          _sectionLabel("Payment Proof"),
          if (_paymentProofs.isEmpty)
            _docRow(
              icon: Icons.receipt_long_outlined,
              name: "Transfer Proof",
              badge: "· Required*",
              file: null,
              onTap: _addPaymentProof,
            )
          else
            for (var i = 0; i < _paymentProofs.length; i++)
              _docRow(
                icon: Icons.receipt_long_outlined,
                name: _paymentProofs[i].name,
                badge: i == 0 ? "· Required*" : null,
                file: _paymentProofs[i],
                onTap: _addPaymentProof,
                onRemove: () => setState(() => _paymentProofs.removeAt(i)),
              ),
          _ghostButton("+ Add Another Payment Proof", _addPaymentProof),
          SizedBox(height: 12),
          _label("Transaction Type"),
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
          _label("Payment Amount"),
          _input(
            nominalTC,
            hint: "0",
            prefixText: "Rp ",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, const ThousandsInputFormatter()],
          ),
          _label("Notes"),
          _input(catatanTC, hint: "E.g.: customer transferred initial down payment, documents to follow", maxLines: 3),
        ],
      ),
    );
  }


  Widget _buildUnit() {
    return BlocBuilder<ReserveUnitCubit, ReserveUnitState>(
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: _input(
              searchTC,
              hint: "Search block / unit no.…",
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
                Text(
                  "${_selectedUnits.length} unit(s) selected",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                ),
                SizedBox(height: 8),
                roPrimaryButton(
                  _savingUnit ? "Saving unit..." : "Continue to Review",
                  _onNextUnit,
                  loading: _savingUnit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Daftar unit dari `ReserveUnitCubit` (`GET /api/reserve/unit-status`) — loading di awal/pas
  /// nyari, error dengan tombol coba lagi, kosong, atau daftarnya + spinner kecil di baris terakhir
  /// selagi [ReserveUnitState.loadingMore] (dipicu [_onUnitScroll] saat mendekati bawah).
  Widget _buildUnitList(ReserveUnitState state) {
    if (state.status == ReserveUnitStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ReserveUnitStatus.error && state.items.isEmpty) {
      return _emptyInfo(state.error ?? 'Failed to load units', action: 'Retry', onAction: _loadUnits);
    }
    if (state.items.isEmpty) {
      final q = searchTC.text.trim();
      return _emptyInfo(q.isEmpty ? "No units available for this contact." : "Unit \"$q\" not found.");
    }

    return ListView.builder(
      controller: _unitScroll,
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _contactUnitRow(state.items[index]);
      },
    );
  }

  String _unitRowTitle(SelectedUnit unit) {
    if (unit.propertyName != null && unit.propertyName!.trim().isNotEmpty) {
      return unit.propertyName!.trim();
    }
 
    return unit.isWaitingList ? 'Waiting list' : 'Lot not yet determined';
  }

  String _unitRowSubtitle(SelectedUnit unit) {
    if (unit.propertyName != null && unit.propertyName!.trim().isNotEmpty) {
      final names = [
        if (unit.clusterName.trim().isNotEmpty) unit.clusterName.trim(),
        if ((unit.productName ?? '').trim().isNotEmpty) unit.productName!.trim(),
        if ((unit.dealValue ?? 0) > 0) 'Rp ${NumberHelper.thousands(unit.dealValue!)}',
      ];
      return names.join(' · ');
    }
    return '';
  }

  /// "Available"/"Reserve" ("hijau"/"kuning" neon, lihat `UnitStatusBadge`) butuh teks gelap supaya
  /// terbaca — status lain (Hold/RBA/RBB/SP) sudah cukup gelap latarnya buat teks putih default.
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
    final selected = _selectedUnits.containsKey(unit.key);
    final sellable = unit.isPropertySellable;
    final title = _unitRowTitle(unit);
    final subtitle = _unitRowSubtitle(unit);
    final statusName = (unit.statusName ?? '').trim();

    return Opacity(
      opacity: sellable ? 1 : 0.5,
      child: InkWell(
        // Unit yang tidak sellable (mis. sudah SP/akad di kontak lain) tetap tampil pudar, tapi
        // tidak bisa dicentang — sama seperti unit picker contact-add yang sudah ada.
        onTap: sellable ? () => _toggleSelectedUnit(unit) : null,
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
                _reviewLine("Contact", contact?.fullName ?? namaTC.text.trim()),
                _reviewLine("Buyer Data", "Complete ✓", ok: true),
                _reviewLine(
                  "Documents",
                  "KTP ✓ · Payment Proof ✓ ${proofCount > 1 ? '($proofCount)' : ''}".trim(),
                  ok: true,
                ),
                _reviewLine("Transaction Type", _jenisTransaksi),
                _reviewLine(
                  "Amount & Notes",
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
            "Reserve Order Successfully Submitted",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
          SizedBox(height: 6),
          Text(
            unitLabel == null
                ? "The submission on behalf of $nama is being processed."
                : "$unitLabel on behalf of $nama is being processed.",
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
                    "Processing",
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(whiteColor)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Documents & payment details have been sent to this reserve order.",
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
                    file == null ? "Tap to upload" : "Uploaded · ${_fileSize(file)}",
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
