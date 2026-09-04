import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/image_compress_helper.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_file_picker.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/ktp/ktp_ocr_model.dart';
import 'package:progress_group/features/contact/presentation/state/ktp_ocr/ktp_ocr_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/ktp_ocr/ktp_ocr_state.dart';

enum ReserveStep { scanKtp, dataPembeli }

class ReservePage extends StatefulWidget {
  final ContactDetailArgs args;

  const ReservePage({super.key, required this.args});

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  ReserveStep _step = ReserveStep.scanKtp;

  final namaTC = TextEditingController();
  final nikTC = TextEditingController();
  final tempatLahirTC = TextEditingController();
  final agamaTC = TextEditingController();
  final pekerjaanTC = TextEditingController();
  final alamatTC = TextEditingController();
  final kecamatanTC = TextEditingController();
  final kabupatenTC = TextEditingController();

  DateTime? _tglLahir;
  String? _jenisKelamin;
  String? _maritalStatus;
  String? _kategoriPekerjaan;
  String? _pendidikan;

  // Foto KTP hasil scan/upload disimpan supaya bisa ikut dikirim waktu submit reserve nanti
  // (dan supaya user tidak perlu foto ulang kalau OCR gagal baca).
  PickedFileResult? _ktpFile;

  // Placeholder sampai master data-nya tersedia dari backend. Kalau nanti ada endpoint master
  // (mis. /masters/pendidikan), ganti list ini dengan hasil fetch — labelnya dipakai apa adanya
  // waktu mencocokkan hasil OCR, jadi urutan/isi boleh berubah tanpa menyentuh logika lain.
  static const List<String> _jenisKelaminItems = ['Laki-laki', 'Perempuan'];
  static const List<String> _maritalItems = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];
  static const List<String> _kategoriPekerjaanItems = ['Swasta', 'Negeri / ASN', 'BUMN / BUMD', 'Wirausaha', 'Profesional', 'Lainnya'];
  static const List<String> _pendidikanItems = ['SD', 'SMP', 'SMA / SMK', 'D3', 'D4', 'S1', 'S2', 'S3'];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_reserve');
    context.read<KtpOcrCubit>().reset();

    // Data yang sudah ada di kontak dipakai sebagai nilai awal — hasil OCR nanti menimpanya
    // kalau memang ada isinya.
    final contact = widget.args.dataContact;
    namaTC.text = contact?.fullName ?? '';
    // NIK di data kontak bisa tersimpan dengan spasi/tanda baca, sedangkan field-nya digitsOnly.
    nikTC.text = (contact?.noKtp ?? '').replaceAll(RegExp(r'\D'), '');
    alamatTC.text = contact?.ktpAddress ?? '';
  }

  @override
  void dispose() {
    namaTC.dispose();
    nikTC.dispose();
    tempatLahirTC.dispose();
    agamaTC.dispose();
    pekerjaanTC.dispose();
    alamatTC.dispose();
    kecamatanTC.dispose();
    kabupatenTC.dispose();
    super.dispose();
  }

  String get _stepTitle => _step == ReserveStep.scanKtp ? "Reserve Order" : "Data Pembeli";

  void _onBack() {
    // Dari form balik ke layar scan dulu, bukan langsung keluar dari halaman.
    if (_step != ReserveStep.scanKtp) {
      setState(() => _step = ReserveStep.scanKtp);
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

  Future<void> _pickAndScan({required bool fromCamera}) async {
    final picked = fromCamera ? await CustomFilePicker.pickCamera() : await CustomFilePicker.pickGallery();
    if (picked == null || picked.bytes == null) return;
    if (!mounted) return;

    // Foto WAJIB dikecilkan dulu, bukan sekadar penghematan: request masuk lewat gateway `/px`
    // yang membungkus file jadi base64 di body JSON (kena batas `post_max_size` server) dan
    // menolak request yang umurnya lebih dari 30 detik — foto kamera 4-8 MB gampang kena dua-duanya.
    // 1600px masih jauh di atas kebutuhan Cloud Vision untuk membaca teks KTP.
    final compressed = kIsWeb
        ? await compressImageBytes(picked.bytes!, maxSide: 1600)
        : (picked.path != null ? await compressImageFile(picked.path!) : picked.bytes!);
    final bytes = compressed.isEmpty ? picked.bytes! : compressed;
    if (!mounted) return;

    // Yang disimpan untuk preview adalah versi yang benar-benar dikirim — sekalian menahan
    // pemakaian memori, karena bytes foto asli tidak ikut ditahan di state.
    setState(() => _ktpFile = PickedFileResult(
          path: picked.path,
          bytes: bytes,
          name: picked.name,
          isImage: true,
          isPdf: false,
        ));

    final cubit = context.read<KtpOcrCubit>();
    await cubit.scan(bytes: bytes, fileName: picked.name);
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

    // Berhasil atau gagal, user tetap dibawa ke form — kalau OCR gagal tinggal isi manual.
    setState(() => _step = ReserveStep.dataPembeli);
  }

  void _applyOcr(KtpOcrModel r) {
    setState(() {
      if (r.nama != null) namaTC.text = r.nama!;
      if (r.nik != null) nikTC.text = r.nik!.replaceAll(RegExp(r'\D'), '');
      if (r.tempatLahir != null) tempatLahirTC.text = r.tempatLahir!;
      if (r.agama != null) agamaTC.text = r.agama!;
      if (r.pekerjaan != null) pekerjaanTC.text = r.pekerjaan!;
      if (r.alamat != null) alamatTC.text = r.alamat!;
      if (r.kecamatan != null) kecamatanTC.text = r.kecamatan!;
      if (r.kabupaten != null) kabupatenTC.text = r.kabupaten!;
      _tglLahir = _parseOcrDate(r.tanggalLahir) ?? _tglLahir;
      _jenisKelamin = _matchOption(r.jenisKelamin, _jenisKelaminItems) ?? _jenisKelamin;
      _maritalStatus = _matchOption(r.statusPerkawinan, _maritalItems) ?? _maritalStatus;
    });
  }

  // Format tanggal dari OCR belum pasti: di KTP tercetak dd-MM-yyyy, tapi backend bisa saja
  // menormalkan ke ISO. Dicoba satu-satu, kalau semua gagal biarkan null (user pilih manual).
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

  // Hasil OCR biasanya huruf besar semua ("LAKI-LAKI", "BELUM KAWIN") sedangkan item dropdown
  // ditulis rapi, jadi dicocokkan tanpa memedulikan huruf besar/kecil, spasi, dan tanda hubung.
  String? _matchOption(String? value, List<String> items) {
    if (value == null || value.isEmpty) return null;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = norm(value);
    for (final item in items) {
      if (norm(item) == target) return item;
    }
    return null;
  }

  void _onNext() {
    final nama = namaTC.text.trim();
    final nik = nikTC.text.trim();

    if (nama.isEmpty) {
      showSnackbar(context, 'Nama wajib diisi', isError: true);
      return;
    }
    if (nik.length != 16) {
      showSnackbar(context, 'NIK harus 16 digit', isError: true);
      return;
    }

    AnalyticsService.logEvent('reserve_order_data_pembeli_next');
    showSnackbar(context, 'Data pembeli lengkap. Step berikutnya belum tersedia.');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KtpOcrCubit, KtpOcrState>(
      builder: (context, ocrState) {
        return PopScope(
          canPop: _step == ReserveStep.scanKtp,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() => _step = ReserveStep.scanKtp);
          },
          child: Scaffold(
            backgroundColor: Color(grey11Color),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      customHeader(
                        context,
                        widget.args.namePage ?? "Reserve",
                        isBack: true,
                        colorBack: Color(primaryColor),
                        onBack: _onBack,
                      ),
                      _buildStepBar(),
                      Expanded(
                        child: _step == ReserveStep.scanKtp ? _buildScanKtp() : _buildDataPembeli(),
                      ),
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

  Widget _buildStepBar() {
    return Container(
      width: double.infinity,
      color: Color(whiteColor),
      padding: EdgeInsets.only(left: 20),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _stepTitle,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(primaryColor)),
                  ),
                ),
                Container(height: 3, color: Color(primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanKtp() {
    return Container(
      width: double.infinity,
      color: Color(whiteColor),
      child: Column(
        children: [
          Expanded(child: Center(child: _ktpIllustration())),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Text(
                  "Dengan scan KTP maka beberapa data anda akan terisi otomatis.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(grey2Color)),
                ),
                SizedBox(height: 16),
                customButton(_showScanSourceSheet, "Scan KTP"),
                SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    AnalyticsService.logEvent('reserve_order_isi_manual');
                    setState(() => _step = ReserveStep.dataPembeli);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Text(
                      "Isi manual",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(primaryColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ilustrasi kartu KTP + bracket sudut. Digambar dengan widget, bukan asset, supaya tidak
  // menambah file gambar baru untuk sesuatu yang cuma dekoratif.
  Widget _ktpIllustration() {
    return Container(
      width: 230,
      height: 150,
      decoration: BoxDecoration(
        color: Color(blueShade50Color).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 186,
            height: 112,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Color(blackColor).withValues(alpha: 0.06), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ktpLine(60),
                      _ktpLine(88),
                      _ktpLine(74),
                      _ktpLine(88),
                      _ktpLine(52),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Color(grey9Color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: 10, left: 14, child: _ktpBracket(top: true, left: true)),
          Positioned(top: 10, right: 14, child: _ktpBracket(top: true, left: false)),
          Positioned(bottom: 10, left: 14, child: _ktpBracket(top: false, left: true)),
          Positioned(bottom: 10, right: 14, child: _ktpBracket(top: false, left: false)),
        ],
      ),
    );
  }

  Widget _ktpLine(double width) {
    return Container(
      width: width,
      height: 5,
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Color(grey9Color),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _ktpBracket({required bool top, required bool left}) {
    final side = BorderSide(color: Color(primaryColor), width: 3);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }

  Widget _buildDataPembeli() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_ktpFile != null) _buildKtpPreview(),
                _buildDataPembeliCard(),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: customButton(_onNext, "Next"),
        ),
      ],
    );
  }

  // Preview foto KTP-nya ditampilkan supaya user bisa cek hasil jepretannya sambil membandingkan
  // dengan data yang terisi otomatis — dan bisa ganti foto kalau hasilnya kabur.
  Widget _buildKtpPreview() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FilePreviewWidget(
            file: _ktpFile!,
            size: 64,
            onRemove: () => setState(() => _ktpFile = null),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Foto KTP",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                ),
                SizedBox(height: 2),
                Text(
                  _ktpFile!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Color(grey2Color)),
                ),
                InkWell(
                  onTap: _showScanSourceSheet,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Scan ulang",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(primaryColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPembeliCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Color(blackColor).withValues(alpha: 0.05), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(grey11Color),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Color(primaryColor)),
                SizedBox(width: 8),
                Text(
                  "Data Pembeli",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _textField("Nama", namaTC),
                _textField(
                  "NIK",
                  nikTC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                ),
                _textField("Tempat Lahir", tempatLahirTC),
                _dateField("Tgl Lahir"),
                _dropdownField("Jenis Kelamin", _jenisKelamin, _jenisKelaminItems, (v) => setState(() => _jenisKelamin = v)),
                _dropdownField("Marital Status", _maritalStatus, _maritalItems, (v) => setState(() => _maritalStatus = v)),
                _textField("Agama", agamaTC),
                _dropdownField("Kategori Pekerjaan", _kategoriPekerjaan, _kategoriPekerjaanItems, (v) => setState(() => _kategoriPekerjaan = v)),
                _textField("Pekerjaan", pekerjaanTC),
                _textField("Alamat", alamatTC, maxLines: 2),
                _textField("Kecamatan", kecamatanTC),
                _textField("Kabupaten", kabupatenTC),
                _dropdownField("Pendidikan", _pendidikan, _pendidikanItems, (v) => setState(() => _pendidikan = v), isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldShell({required String label, required Widget child, bool isLast = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Color(grey9Color)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Color(grey5Color))),
          SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  static const TextStyle _valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(blue2Color));
  static const TextStyle _hintStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(grey5Color));

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool isLast = false,
  }) {
    return _fieldShell(
      label: label,
      isLast: isLast,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: _valueStyle,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: "Isi $label",
          hintStyle: _hintStyle,
        ),
      ),
    );
  }

  Widget _dateField(String label, {bool isLast = false}) {
    return _fieldShell(
      label: label,
      isLast: isLast,
      child: InkWell(
        onTap: () async {
          final now = AppTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _tglLahir ?? DateTime(now.year - 30, now.month, now.day),
            firstDate: DateTime(1930),
            lastDate: now,
          );
          if (picked != null) setState(() => _tglLahir = picked);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                _tglLahir == null ? "Pilih $label" : DateFormat('d MMMM yyyy', 'id_ID').format(_tglLahir!),
                style: _tglLahir == null ? _hintStyle : _valueStyle,
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 16, color: Color(grey5Color)),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool isLast = false,
  }) {
    return _fieldShell(
      label: label,
      isLast: isLast,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text("Pilih $label", style: _hintStyle),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(grey5Color)),
          style: _valueStyle,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: _valueStyle))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
