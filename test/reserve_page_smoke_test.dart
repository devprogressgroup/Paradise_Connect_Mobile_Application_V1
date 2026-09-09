// Smoke test flow Reserve Order (mockup reserve-order-sales-final_12.html, Bagian 2):
// memastikan kelima layar — Data Pembeli, Dokumen & Bukti Bayar, Pilih Unit, Review, Sukses —
// bisa dirender di ukuran layar HP tanpa error layout (overflow / unbounded height), validasi
// tiap step menahan langkah berikutnya, dokumen & rincian pembayarannya terkirim ke
// `POST /api/reserve/doc-payment` (pakai `reserve_order_id` dari `POST /api/reserve`) saat submit,
// dan hasilnya sampai ke kartu di halaman menu.
// Analyzer tidak bisa menangkap error layout, jadi ini satu-satunya pengaman otomatisnya.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
// Dependency transitif dari file_picker — dipakai hanya untuk mixin mock platform interface.
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/data/datasources/ktp_ocr_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/ktp_ocr_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/index.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/reserve.dart';
import 'package:progress_group/features/reserve-order/presentation/state/ktp_ocr/ktp_ocr_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_unit/reserve_unit_cubit.dart';

class _FakeKtpOcr implements KtpOcrRemoteDataSource {
  @override
  Future<KtpOcrModel> scanKtp({required Uint8List bytes, required String fileName}) async =>
      const KtpOcrModel(nama: 'SAKUM', nik: '3273051290000012');
}

/// "Jenis Transaksi" (step Dokumen) & "Cara Pembayaran" (step Data Pembeli) di form Reserve dibaca
/// dari sini — `GET /api/reserve-filter` (sama dengan chip filter menu List) &
/// `GET /api/reserve/cara-bayar`. `filterCalls`/`caraBayarCalls` dipakai membuktikan cubit-nya
/// nge-cache, bukan fetch ulang tiap `ReservePage` dibuka.
class _FakeReserveOrders implements ReserveOrderRemoteDataSource {
  int filterCalls = 0;
  int caraBayarCalls = 0;
  final List<CreateReserveParams> createCalls = [];
  bool failCreate = false;

  /// Id yang dikembalikan [createReserve] — dipakai `_onSubmit` sebagai
  /// `DocPaymentParams.reserveOrderId` di [submitDocPayment].
  int nextReserveOrderId = 12;

  final List<DocPaymentParams> docPaymentCalls = [];
  bool failDocPayment = false;

  @override
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds = const [],
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
    int? contactId,
  }) async {
    throw UnimplementedError('tidak dipakai di test flow Reserve');
  }

  @override
  Future<List<ReserveFilterOption>> getReserveFilters() async {
    filterCalls++;
    return const [
      ReserveFilterOption(statusReserveId: 2, name: 'Reserve'),
      ReserveFilterOption(statusReserveId: 1, name: 'Booking Reserve (langsung)'),
    ];
  }

  @override
  Future<List<CaraBayarOption>> getCaraBayarOptions() async {
    caraBayarCalls++;
    return const [
      CaraBayarOption(caraBayarId: 1, name: 'Cash Keras'),
      CaraBayarOption(caraBayarId: 2, name: 'Cash Bertahap 3X'),
      CaraBayarOption(caraBayarId: 3, name: 'Cash Bertahap 6X'),
      CaraBayarOption(caraBayarId: 4, name: 'Cash Bertahap 12X'),
      CaraBayarOption(caraBayarId: 5, name: 'KPR'),
    ];
  }

  @override
  Future<int> createReserve(CreateReserveParams params) async {
    if (failCreate) throw Exception('koneksi terputus');
    createCalls.add(params);
    return nextReserveOrderId;
  }

  @override
  Future<void> submitDocPayment(DocPaymentParams params) async {
    if (failDocPayment) throw Exception('koneksi terputus');
    docPaymentCalls.add(params);
  }

  @override
  Future<ReserveCustomerDetail> getReserveCustomer(int reserveOrderId) async {
    throw UnimplementedError('tidak dipakai di test flow Reserve');
  }
}

/// Step "Pilih Unit" — `GET /api/reserve/unit-status?contact_id=…`. Filter `search`-nya meniru
/// pencarian client-side lama (clusterName/productName/propertyName/displayLabel, case-insensitive)
/// supaya test pencarian yang sudah ada tetap berlaku sama persis walau sumbernya kini server.
class _FakeReserveUnits implements ReserveUnitRemoteDataSource {
  List<SelectedUnit> units = const [];
  int calls = 0;
  String? lastSearch;

  @override
  Future<ReserveUnitsPage> getUnits({
    required int contactId,
    String? search,
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
  }) async {
    calls++;
    lastSearch = search;
    final q = (search ?? '').trim().toLowerCase();
    final items = q.isEmpty
        ? units
        : units.where((u) {
            return u.clusterName.toLowerCase().contains(q) ||
                (u.productName?.toLowerCase().contains(q) ?? false) ||
                (u.propertyName?.toLowerCase().contains(q) ?? false) ||
                u.displayLabel.toLowerCase().contains(q);
          }).toList();

    return ReserveUnitsPage(items: items, page: page, hasMore: false);
  }
}

// FilePicker.platform bisa ditukar, jadi jalur "Dokumen" di CustomFilePicker bisa dijalankan di
// test tanpa plugin asli — dipakai untuk melampirkan KTP & bukti bayar.
class _FakeFilePicker extends Fake with MockPlatformInterfaceMixin implements FilePicker {
  int calls = 0;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    return FilePickerResult([
      PlatformFile(name: 'dokumen-$calls.pdf', size: 4, bytes: Uint8List.fromList([1, 2, 3, 4])),
    ]);
  }
}

/// Unit di step "Pilih Unit" diambil dari kavling yang sudah menempel di kontak, bukan dari
/// pencarian ke server.
SelectedUnit _unit(int propertyId, String? propertyName) => SelectedUnit(
      townshipId: 7,
      companyId: 3,
      clusterId: 3,
      clusterName: 'PAR2',
      productId: 5,
      productName: 'Ecoscape',
      propertyId: propertyId,
      propertyName: propertyName,
      isWaitingList: propertyName == null,
    );

ContactEntity _contact() => ContactEntity(
      contactId: 1,
      dealId: 99,
      fullName: 'Sakum',
      primaryPhone: '0812-1111-2222',
      noKtp: '3273051290000012',
      ktpAddress: 'JL. MERDEKA NO. 45',
      lastProject: 'Paradise Serpong City',
      lastProjectId: 7,
      units: [_unit(19, 'Blok E1 No. 19'), _unit(21, 'Blok E1 No. 21'), _unit(0, null)],
    );

late _FakeReserveOrders source;
late _FakeReserveUnits unitsSource;

// Satu instance per test (bukan dibuat baru tiap `_wrap`) — dipakai bareng, sama seperti provider
// aslinya di main.dart, supaya cache filter-nya ([ReserveOrderListCubit.ensureFilters]) kepakai
// beneran kalau `_wrap` dipanggil berkali-kali dalam satu test. `ReserveUnitCubit` juga singleton
// di `main.dart` asli, jadi diperlakukan sama di sini.
late ReserveOrderListCubit reserveOrderListCubit;
late ReserveUnitCubit reserveUnitCubit;

Widget _wrap(Widget child) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => KtpOcrCubit(_FakeKtpOcr())),
        BlocProvider.value(value: reserveOrderListCubit),
        BlocProvider.value(value: reserveUnitCubit),
      ],
      child: child,
    );

/// Periksa pesan validasi, lalu habiskan SnackBar-nya. SnackBar bertahan 4 detik dan
/// DIANTREKAN oleh ScaffoldMessenger — tanpa ini, pesan validasi berikutnya tidak tampil.
Future<void> _expectSnack(WidgetTester tester, String message) async {
  expect(find.text(message), findsOneWidget);
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Cari `TextField` lewat hint-nya — lebih aman dari index kalau urutan field di step berubah.
Finder _fieldWithHint(String hint) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == hint);

/// Lampirkan file lewat sheet pilih sumber (jalur "Dokumen" → FilePicker palsu).
Future<void> _attachVia(WidgetTester tester, Finder row) async {
  await tester.tap(row);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dokumen').last);
  await tester.pumpAndSettle();
}

/// Step 1 → 3: isi dokumen wajib & nominal (dua bukti bayar, buat membuktikan
/// `bukti_transfer` boleh lebih dari 1 file), lalu pilih satu unit.
Future<void> _fillUntilUnitPicked(WidgetTester tester) async {
  await tester.tap(find.text('Lanjut ke Dokumen'));
  await tester.pumpAndSettle();
  await _attachVia(tester, find.textContaining('KTP', findRichText: true).first);
  await _attachVia(tester, find.text('+ Tambah Bukti Bayar Lain'));
  await _attachVia(tester, find.text('+ Tambah Bukti Bayar Lain'));
  await tester.enterText(find.byType(TextField).first, '2000000');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lanjut ke Pilih Unit'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Blok E1 No. 19'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lanjut ke Review'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    FilePicker.platform = _FakeFilePicker();
    source = _FakeReserveOrders();
    reserveOrderListCubit = ReserveOrderListCubit(source);
    unitsSource = _FakeReserveUnits()..units = _contact().units ?? const [];
    reserveUnitCubit = ReserveUnitCubit(unitsSource);
  });

  testWidgets('4 step + layar sukses render tanpa error layout & validasinya jalan', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();

    // ── Step 1/4: Data Pembeli ──
    expect(find.text('Reserve Order — Sakum'), findsOneWidget);
    expect(find.text('0812-1111-2222'), findsOneWidget);
    expect(find.text('📷  Scan KTP'), findsOneWidget);
    expect(find.text('Nama Lengkap (sesuai KTP)'), findsOneWidget);
    expect(find.text('Tempat, Tanggal Lahir'), findsOneWidget);
    expect(find.text('Cara Pembayaran'), findsOneWidget);
    expect(find.text('Sakum'), findsOneWidget); // prefill dari kontak
    expect(find.text('Lanjut ke Dokumen'), findsOneWidget);

    // Picker "Status Pernikahan" membuka sheet pilihan.
    await tester.tap(find.text('Pilih status pernikahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kawin').last);
    await tester.pumpAndSettle();
    expect(find.text('Kawin'), findsOneWidget);

    // Picker "Cara Pembayaran" isinya dari `GET /api/reserve/cara-bayar` (bukan daftar hardcode
    // lama ['KPR', 'Cash', 'Cash Bertahap', 'Inhouse']) — yang tampil di sheet & di picker-nya
    // tetap `name`, id-nya (`cara_bayar_id`) cuma disimpan di balik layar.
    await tester.tap(find.text('Pilih cara pembayaran'));
    await tester.pumpAndSettle();
    expect(find.text('Cash Bertahap 3X'), findsOneWidget);
    expect(find.text('Cash Bertahap 6X'), findsOneWidget);
    expect(find.text('Inhouse'), findsNothing);
    await tester.tap(find.text('KPR').last);
    await tester.pumpAndSettle();
    expect(find.text('KPR'), findsOneWidget);

    // ── Step 1 → 2 ──
    await tester.tap(find.text('Lanjut ke Dokumen'));
    await tester.pumpAndSettle();
    expect(find.text('Dokumen Identitas'), findsOneWidget);
    expect(find.text('Bukti Bayar'), findsOneWidget);
    expect(find.text('+ Tambah Bukti Bayar Lain'), findsOneWidget);
    expect(find.text('Booking Reserve (langsung)'), findsOneWidget);
    expect(find.text('Nominal Pembayaran'), findsOneWidget);

    // Belum ada lampiran → ditahan di step Dokumen.
    await tester.tap(find.text('Lanjut ke Pilih Unit'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Dokumen KTP wajib dilampirkan');

    // Lampirkan KTP → pesan bergeser ke bukti bayar.
    await _attachVia(tester, find.textContaining('KTP', findRichText: true).first);
    expect(find.textContaining('Terupload · '), findsOneWidget);
    await tester.tap(find.text('Lanjut ke Pilih Unit'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Bukti bayar wajib dilampirkan minimal 1');

    // Lampirkan bukti bayar → tinggal nominal yang kosong.
    await _attachVia(tester, find.text('+ Tambah Bukti Bayar Lain'));
    await tester.tap(find.text('Lanjut ke Pilih Unit'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Nominal pembayaran wajib diisi');

    // Nominal: angka mentah diformat jadi ribuan.
    await tester.enterText(find.byType(TextField).first, '2000000');
    await tester.pumpAndSettle();
    expect(find.text('2.000.000'), findsOneWidget);

    // ── Step 2 → 3: Pilih Unit (kavling yang menempel di kontak) ──
    await tester.tap(find.text('Lanjut ke Pilih Unit'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Unit'), findsOneWidget);
    expect(find.text('Blok E1 No. 19'), findsOneWidget);
    expect(find.text('PAR2 · Ecoscape'), findsNWidgets(2));
    expect(find.text('Waiting list'), findsOneWidget);
    expect(find.text('0 unit dipilih'), findsOneWidget);

    // Belum ada unit dipilih → ditahan.
    await tester.tap(find.text('Lanjut ke Review'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Pilih minimal 1 unit');

    await tester.tap(find.text('Blok E1 No. 19'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blok E1 No. 21'));
    await tester.pumpAndSettle();
    expect(find.text('2 unit dipilih'), findsOneWidget);

    // Pencarian menyaring daftar.
    await tester.enterText(find.byType(TextField).first, '19');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Blok E1 No. 21'), findsNothing);
    expect(find.text('Blok E1 No. 19'), findsOneWidget);
    expect(find.text('2 unit dipilih'), findsOneWidget); // pilihan tidak hilang saat menyaring

    // ── Step 3 → 4: Review ──
    await tester.tap(find.text('Lanjut ke Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review Reserve Order'), findsOneWidget);
    expect(find.text('Kontak'), findsOneWidget);
    expect(find.text('Lengkap ✓'), findsOneWidget);
    expect(find.text('Jenis Transaksi'), findsOneWidget);
    expect(find.text('Rp 2.000.000 ✓'), findsOneWidget);
    expect(find.textContaining('Bukti Bayar ✓'), findsOneWidget);

    // ── Step 4 → Sukses ──
    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();
    expect(find.text('Reserve Order Berhasil Diajukan'), findsOneWidget);
    expect(find.textContaining('a.n. Sakum sedang diproses.'), findsOneWidget);
    expect(find.text('Diproses'), findsOneWidget);
    expect(find.text('Lihat di Reserve Order'), findsOneWidget);
    expect(find.text('Kembali ke Kontak'), findsOneWidget);
  });

  testWidgets('submit mengirim KTP, bukti bayar & rincian pembayaran ke doc-payment', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);

    // Sebelum submit belum ada request yang dikirim.
    expect(source.docPaymentCalls, isEmpty);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();
    expect(find.text('Reserve Order Berhasil Diajukan'), findsOneWidget);

    // Satu request `doc-payment`, pakai `reserve_order_id` dari response `createReserve`. NPWP
    // tidak dilampirkan, jadi tidak ikut dikirim. Dua bukti bayar ikut terkirim semuanya (bukan
    // cuma yang pertama) — `bukti_transfer` boleh lebih dari 1 file.
    expect(source.docPaymentCalls.length, 1);
    final params = source.docPaymentCalls.single;
    expect(params.reserveOrderId, source.nextReserveOrderId);
    expect(params.statusReserveId, 2); // "Reserve" (default `_jenisTransaksi`)
    expect(params.ttsAmountRp, 2000000);
    expect(params.ktpFileNames, ['dokumen-1.pdf']);
    expect(params.ktpBytes.length, 1);
    expect(params.npwpBytes, isNull);
    expect(params.buktiTransferFileNames, ['dokumen-2.pdf', 'dokumen-3.pdf']);
    expect(params.buktiTransferBytes.length, 2);
  });

  testWidgets('doc-payment gagal menahan di Review dengan pesan errornya', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    source.failDocPayment = true;

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();

    expect(find.text('Reserve Order Berhasil Diajukan'), findsNothing);
    expect(find.text('Review Reserve Order'), findsOneWidget);
    expect(find.textContaining('koneksi terputus'), findsOneWidget);
  });

  testWidgets('hasil submit sampai ke kartu Reserve di halaman menu', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final args = ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve Order');
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ReserveOrderPage(args: args),
          routes: [
            GoRoute(
              name: 'reserveOrderReserve',
              path: 'reserve',
              builder: (_, state) => ReservePage(args: state.extra as ContactDetailArgs),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(_wrap(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    // Menu awal: belum ada rincian & centang.
    expect(find.text('Reserve'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.drive_file_rename_outline), findsNWidgets(3));

    // Jalankan flow sampai sukses.
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);
    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();

    // "Lihat di Reserve Order" mengembalikan hasilnya ke halaman menu.
    await tester.tap(find.text('Lihat di Reserve Order'));
    await tester.pumpAndSettle();

    expect(find.text('Topup'), findsOneWidget);
    expect(find.text('Blok E1 No. 19 Ecoscape PAR2'), findsOneWidget);
    expect(find.text('Rp 2.000.000'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('unit tidak sellable pudar & tidak bisa dicentang; harga & badge status tampil', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Ganti dari data `_contact()` (dari `GET /api/reserve/unit-status`, format desain terbaru):
    // harga (`deal_value`), badge status (`status_name`), dan unit yang tidak sellable.
    unitsSource.units = [
      SelectedUnit(
        dealId: 1,
        townshipId: 1,
        clusterId: 660,
        clusterName: 'PAR2',
        productId: 5,
        productName: 'Ecoscape',
        propertyId: 19,
        propertyName: 'Blok E1 No. 19',
        statusName: 'Available',
        dealValue: 450000000,
      ),
      SelectedUnit(
        dealId: 2,
        townshipId: 1,
        clusterId: 660,
        clusterName: 'PAR2',
        productId: 5,
        productName: 'Ecoscape',
        propertyId: 20,
        propertyName: 'Blok E1 No. 20',
        statusName: 'Reserve',
        dealValue: 465000000,
        isPropertySellable: false,
      ),
    ];

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut ke Dokumen'));
    await tester.pumpAndSettle();
    await _attachVia(tester, find.textContaining('KTP', findRichText: true).first);
    await _attachVia(tester, find.text('+ Tambah Bukti Bayar Lain'));
    await tester.enterText(find.byType(TextField).first, '2000000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut ke Pilih Unit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rp 450.000.000'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Reserve'), findsOneWidget); // badge status baris kedua, bukan chip step Dokumen

    // Unit tidak sellable (is_property_sellable: false) tidak bisa dicentang.
    await tester.tap(find.text('Blok E1 No. 20'));
    await tester.pumpAndSettle();
    expect(find.text('0 unit dipilih'), findsOneWidget);

    // Unit sellable tetap bisa dicentang seperti biasa.
    await tester.tap(find.text('Blok E1 No. 19'));
    await tester.pumpAndSettle();
    expect(find.text('1 unit dipilih'), findsOneWidget);
  });

  testWidgets('"Jenis Transaksi" pakai master status dari reserve-filter & di-cache di cubit', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<void> openReserveAndReachDokumen() async {
      // Root-nya diganti tipe dulu (bukan langsung pumpWidget MaterialApp lagi) supaya elemen
      // `ReservePage` sebelumnya benar-benar di-dispose — pumpWidget dengan tree yang bentuknya
      // sama (tipe+key sama) cuma REBUILD elemen lama, bukan mount ulang, jadi `_step` dkk ikut
      // kebawa dari sesi sebelumnya kalau tidak dipaksa lepas dulu.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_wrap(MaterialApp(
        home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Dokumen'));
      await tester.pumpAndSettle();
    }

    await openReserveAndReachDokumen();
    // Dari `getReserveFilters()` (bukan lagi daftar hardcode di app).
    expect(find.text('Booking Reserve (langsung)'), findsOneWidget);
    expect(source.filterCalls, 1);

    // `ReserveOrderListCubit` yang sama dipakai lagi (cubit-nya provider bersama di app asli) —
    // dibuka kedua kalinya tidak fetch ulang, tinggal pakai cache di state cubit.
    await openReserveAndReachDokumen();
    expect(find.text('Booking Reserve (langsung)'), findsOneWidget);
    expect(source.filterCalls, 1);
  });

  testWidgets('submit bikin baris customer dulu lewat POST /api/reserve, baru kirim doc-payment', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();

    // Tempat/Tanggal Lahir diisi manual (tanpa scan KTP) — dites kalau parse balik dari teksnya
    // ("Tempat, dd MMMM yyyy", sesuai hint field-nya) jalan buat `cust_birth_place`/`cust_birth_date`.
    await tester.enterText(_fieldWithHint('Jakarta, 01 Januari 1990'), 'Jakarta, 09 Januari 1990');
    await tester.enterText(_fieldWithHint('Wiraswasta'), 'Pedagang');

    await tester.tap(find.text('Pilih status pernikahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kawin').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih cara pembayaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KPR').last);
    await tester.pumpAndSettle();

    await _fillUntilUnitPicked(tester);

    expect(source.createCalls, isEmpty);
    expect(source.docPaymentCalls, isEmpty);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();

    expect(find.text('Reserve Order Berhasil Diajukan'), findsOneWidget);
    expect(source.createCalls.length, 1);

    final params = source.createCalls.single;
    expect(params.contactId, 1);
    expect(params.custName, 'Sakum');
    expect(params.custKtp, '3273051290000012');
    expect(params.custBirthPlace, 'Jakarta');
    expect(params.custBirthDate, DateTime(1990, 1, 9));
    expect(params.custMaritalStatus, 'KAWIN');
    expect(params.custOccupation, 'Pedagang');
    expect(params.custAddress1, 'JL. MERDEKA NO. 45');
    expect(params.caraBayarId, 5); // KPR
    expect(params.custTelpMobile1, '0812-1111-2222');
    // Belum ada input manual buat keduanya (cuma keisi dari hasil scan KTP, tidak dites di sini).
    expect(params.custGenderIsMale, isNull);
    expect(params.custReligion, isNull);

    expect(params.toJson()['cust_birth_date'], '1990-01-09');

    // Dokumen & pembayaran baru dikirim ke doc-payment setelah baris customer-nya berhasil dibuat,
    // pakai `reserve_order_id` dari response `createReserve` itu.
    expect(source.docPaymentCalls, isNotEmpty);
    expect(source.docPaymentCalls.single.reserveOrderId, source.nextReserveOrderId);
  });

  testWidgets('POST /api/reserve gagal menahan di Review, doc-payment tidak ikut dikirim', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    source.failCreate = true;

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();

    expect(find.text('Review Reserve Order'), findsOneWidget);
    expect(find.textContaining('koneksi terputus'), findsOneWidget);
    expect(source.createCalls, isEmpty);
    expect(source.docPaymentCalls, isEmpty);
  });
}
