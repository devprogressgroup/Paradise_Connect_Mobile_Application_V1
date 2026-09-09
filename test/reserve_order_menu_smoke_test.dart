// Smoke test menu "Reserve Order" (mockup reserve-order-sales-final_12.html, Bagian 3):
// list transaksi dari `GET /api/reserve` + pencarian, pemetaan response ke kartu & detail,
// detail dengan 4 tab & timeline L1-L10, Top Up Pembayaran sampai layar sukses, dan
// Edit & Resubmit untuk transaksi yang ditolak kasir.
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
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/detail.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/list.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/revise.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/top_up.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';

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
      PlatformFile(name: 'bukti-$calls.pdf', size: 4, bytes: Uint8List.fromList([1, 2, 3, 4])),
    ]);
  }
}

/// Baris `GET /api/reserve` seperti aslinya — sengaja JSON mentah supaya `ReserveOrder.fromJson`
/// ikut teruji, bukan cuma widget-nya.
Map<String, dynamic> _row({
  required int id,
  required String name,
  String? projectName,
  String? blokNo,
  num? amount,
  String? createdAt,
  String? spDate,
  String? rejectedAt,
  String? rejectReason,
  String? note,
  int statusReserveId = 2,
}) {
  return {
    'reserve_order_id': id,
    'cust_name': name,
    'contact_name': name.split(' ').first.toLowerCase(),
    'phone_number': '081234567890',
    'property_name': null,
    'deal_blok_no': blokNo,
    'deal_project_name': projectName,
    'owner_name': 'Nadilla Qurnia Ramadhan',
    'amount_rp': amount,
    'created_datetime': createdAt ?? '2026-09-07T06:52:58.000000Z',
    'rb_date': null,
    'sp_date': spDate,
    'kasir_rejected_datetime': rejectedAt,
    'kasir_rejected_reason': rejectReason,
    'sa_rejected_datetime': null,
    'sa_rejected_reason': null,
    'reserve_note': note,
    'contact_id': 112192,
    'deal_id': 112664,
    'status_reserve_id': statusReserveId,
  };
}

/// Master status reserve seperti aslinya (`GET /api/reserve-filter`).
List<Map<String, dynamic>> _filterRows() => const [
      {'status_reserve_id': 1, 'status_reserve_name': 'RBB', 'is_active': 1, 'id': 1, 'name': null},
      {'status_reserve_id': 2, 'status_reserve_name': 'Reserve', 'is_active': 1, 'id': 2, 'name': null},
      {'status_reserve_id': 3, 'status_reserve_name': 'RKB', 'is_active': 1, 'id': 3, 'name': null},
      {'status_reserve_id': 4, 'status_reserve_name': 'Reserve Batal', 'is_active': 1, 'id': 4, 'name': null},
      {'status_reserve_id': 5, 'status_reserve_name': 'Waitinglist', 'is_active': 1, 'id': 5, 'name': null},
      {'status_reserve_id': 6, 'status_reserve_name': 'SP', 'is_active': 1, 'id': 6, 'name': null},
      {'status_reserve_id': 7, 'status_reserve_name': 'RBA', 'is_active': 1, 'id': 7, 'name': null},
      {'status_reserve_id': 8, 'status_reserve_name': 'SP Batal', 'is_active': 0, 'id': 8, 'name': null},
    ];

class _FakeReserveOrders implements ReserveOrderRemoteDataSource {
  final List<Map<String, dynamic>> rows;
  bool fail = false;

  String? lastSearch;
  int lastPage = 0;
  List<int> lastStatusIds = const [];
  int calls = 0;

  _FakeReserveOrders(this.rows);

  @override
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds = const [],
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
    int? contactId,
  }) async {
    calls++;
    lastSearch = search;
    lastPage = page;
    lastStatusIds = statusReserveIds;
    if (fail) throw Exception('koneksi terputus');

    final keyword = (search ?? '').toLowerCase();
    var filtered = keyword.isEmpty ? rows : rows.where((r) => '${r['cust_name']}'.toLowerCase().contains(keyword)).toList();
    if (statusReserveIds.isNotEmpty) {
      filtered = filtered.where((r) => statusReserveIds.contains(r['status_reserve_id'])).toList();
    }

    return ReserveOrdersPage(
      items: filtered.map((e) => ReserveOrder.fromJson(e)).toList(),
      page: page,
      hasMore: false,
      total: filtered.length,
    );
  }

  @override
  Future<List<ReserveFilterOption>> getReserveFilters() async {
    return _filterRows().map((e) => ReserveFilterOption.fromJson(e)).where((f) => f.isActive).toList();
  }

  @override
  Future<List<CaraBayarOption>> getCaraBayarOptions() async => const [];

  @override
  Future<CreateReserveResult> createReserve(CreateReserveParams params) async =>
      const CreateReserveResult(reserveOrderId: 0, customerId: 0);

  @override
  Future<void> saveReserveUnit({required int dealId, required int customerId}) async {}

  @override
  Future<int> submitDocPayment(DocPaymentParams params) async => 0;

  @override
  Future<ReserveCustomerDetail> getReserveCustomer(int reserveOrderId) async {
    final row = rows.firstWhere((r) => r['reserve_order_id'] == reserveOrderId);
    return ReserveCustomerDetail(custName: '${row['cust_name']}');
  }

  /// Diisi manual per test lewat key `(reserve_order_id, reserve_order_tts_id)` — default kosong.
  Map<(int, int), List<ReserveOrderAttachment>> attachmentsByKey = {};

  @override
  Future<List<ReserveOrderAttachment>> getReserveAttachments({
    required int reserveOrderId,
    required int reserveOrderTtsId,
  }) async =>
      attachmentsByKey[(reserveOrderId, reserveOrderTtsId)] ?? const [];
}

late _FakeReserveOrders source;

/// Susunan route yang sama dengan router aplikasi supaya `pushNamed` dari halaman list & detail
/// menemukan tujuannya. `detailContact` diwakili halaman kosong — di app aslinya itu Contact Detail.
GoRouter _router() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const ReserveOrderListPage(),
          routes: [
            GoRoute(
              name: 'reserveOrderDetail',
              path: 'detail',
              builder: (_, state) => ReserveOrderDetailPage(order: state.extra as ReserveOrder),
              routes: [
                GoRoute(
                  name: 'reserveOrderTopUp',
                  path: 'top-up',
                  builder: (_, state) => ReserveOrderTopUpPage(order: state.extra as ReserveOrder),
                ),
                GoRoute(
                  name: 'reserveOrderRevise',
                  path: 'revise',
                  builder: (_, state) => ReserveOrderRevisePage(order: state.extra as ReserveOrder),
                ),
              ],
            ),
            GoRoute(
              name: 'detailContact',
              path: 'contact',
              builder: (_, __) => Scaffold(
                appBar: AppBar(title: const Text('Contact Detail')),
                body: const Center(child: Text('Contact Detail')),
              ),
            ),
            // Halaman asli (`AttachmentWebViewPage`) pakai webview_flutter/iframe platform —
            // diwakili halaman kosong di sini, sama seperti `detailContact`, cukup buat
            // membuktikan navigasinya jalan dengan URL yang benar.
            GoRoute(
              name: 'attachmentWebView',
              path: 'attachment-web-view',
              builder: (_, state) => Scaffold(
                appBar: AppBar(title: const Text('Preview Attachment')),
                body: Center(child: Text('url: ${state.extra}')),
              ),
            ),
          ],
        ),
      ],
    );

/// [width] dilebarkan dari lebar HP normal (390) buat test yang perlu semua chip filter tampil
/// sekaligus tanpa gulir horizontal — drag scroll di widget test rapuh untuk baris chip pendek.
/// [cubit] opsional — dipakai test yang perlu memanggil `rememberTtsId()` SEBELUM widget-nya
/// dibangun (tab Attachment); kalau tidak diisi, cubit baru dibuat seperti biasa.
Future<ReserveOrderListCubit> _pumpMenu(WidgetTester tester, {double width = 390, ReserveOrderListCubit? cubit}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final resolvedCubit = cubit ?? ReserveOrderListCubit(source);
  await tester.pumpWidget(BlocProvider.value(
    value: resolvedCubit,
    child: MaterialApp.router(routerConfig: _router()),
  ));
  await tester.pumpAndSettle();
  return resolvedCubit;
}

/// Periksa pesan validasi, lalu habiskan SnackBar-nya supaya pesan berikutnya tidak terantre.
Future<void> _expectSnack(WidgetTester tester, String message) async {
  expect(find.text(message), findsOneWidget);
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Lampirkan file lewat sheet pilih sumber (jalur "Dokumen" → FilePicker palsu).
Future<void> _attachVia(WidgetTester tester, Finder row) async {
  await tester.tap(row);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dokumen').last);
  await tester.pumpAndSettle();
}

/// Kartu di luar layar belum dibangun ListView, jadi digulir dulu sebelum ditekan.
Future<void> _openDetail(WidgetTester tester, String customerName) async {
  final card = find.text(customerName);
  if (card.evaluate().isEmpty) {
    await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).last);
  }
  await tester.tap(card);
  await tester.pumpAndSettle();
}

/// Menunggu debounce pencarian (400 ms) sebelum request-nya jalan.
Future<void> _search(WidgetTester tester, String keyword) async {
  await tester.enterText(find.byType(TextFormField), keyword);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Chip filter di-key pakai `status_reserve_id` ("semua" buat chip reset) — labelnya ("SP") bisa
/// sama persis dengan teks badge status di kartu, jadi key numerik yang dipakai, bukan teks.
/// `scrollUntilVisible` (bukan `ensureVisible`) karena chip di luar cache extent belum tentu
/// sudah dibangun — `ensureVisible` butuh elemennya sudah ada, `scrollUntilVisible` yang
/// menggulir sampai kebangun.
Future<void> _showFilterChip(WidgetTester tester, String key) async {
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey('reserve_order_filter_list')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(find.byKey(ValueKey('reserve_order_filter_$key')), 60, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> _tapFilterChip(WidgetTester tester, String key) async {
  await _showFilterChip(tester, key);
  await tester.tap(find.byKey(ValueKey('reserve_order_filter_$key')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    FilePicker.platform = _FakeFilePicker();
    source = _FakeReserveOrders([
      _row(id: 3, name: 'Andi Wijaya Aan', projectName: 'Paradise Serpong City 2', amount: 80000, note: 'test reserve_note', statusReserveId: 2),
      _row(id: 5, name: 'Budi Santoso', projectName: 'PAR2', blokNo: 'Blok BC6 No. 17', amount: 780000000, spDate: '2026-09-02T03:00:00.000000Z', statusReserveId: 6),
      _row(
        id: 8,
        name: 'Reyhan Pradipta',
        projectName: 'PAR2',
        blokNo: 'Blok E1 No. 22',
        amount: 400000000,
        createdAt: '2026-09-05T00:00:00.000000Z',
        rejectedAt: '2026-09-05T08:22:00.000000Z',
        rejectReason: 'Nominal bukti transfer tidak sesuai harga unit.',
        statusReserveId: 4,
      ),
    ]);
  });

  testWidgets('list memetakan response API ke kartu & pencarian dikirim ke server', (tester) async {
    // Dilebarkan supaya semua chip filter kebangun sekaligus (dipakai assert "SP" di bawah).
    await _pumpMenu(tester, width: 900);

    expect(find.text('Reserve Order'), findsOneWidget);
    expect(find.text('3 transactions'), findsOneWidget);

    // Baris pertama: property_name & deal_blok_no kosong → unitnya ditulis apa adanya.
    expect(find.text('Andi Wijaya Aan'), findsOneWidget);
    expect(find.textContaining('Unit not yet determined', findRichText: true), findsOneWidget);
    expect(find.textContaining('Paradise Serpong City 2', findRichText: true), findsOneWidget);
    expect(find.text('Nadilla Qurnia Ramadhan'), findsNWidgets(3));
    expect(find.text('Rp 80.000'), findsOneWidget);
    expect(find.textContaining('Reserve: 07 Sep'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);

    // Nominal besar diringkas seperti mockup, dan tahapnya ikut sp_date / penolakan kasir. Chip
    // filter "SP" (dari GET /api/reserve-filter) ikut kebangun di baris atas (viewport dilebarkan
    // di _pumpMenu), jadi teksnya sengaja dicek 2 (chip + badge kartu).
    expect(find.text('Rp 780M'), findsOneWidget);
    expect(find.text('SP'), findsNWidgets(2));
    expect(find.text('Rejected'), findsOneWidget);

    // Pencarian: kata kuncinya sampai ke datasource, bukan disaring di aplikasi.
    await _search(tester, 'budi');
    expect(source.lastSearch, 'budi');
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Andi Wijaya Aan'), findsNothing);
    expect(find.text('1 transaction'), findsOneWidget);

    await _search(tester, 'zzz');
    expect(find.textContaining('No transactions matching'), findsOneWidget);
  });

  testWidgets('chip filter dari GET /api/reserve-filter mengirim status_reserve_id ke server', (tester) async {
    await _pumpMenu(tester, width: 900);

    // Master status yang `is_active: 0` (SP Batal) tidak ikut tampil jadi chip.
    expect(find.text('SP Batal'), findsNothing);

    // Chip "SP" (status_reserve_id 6) cuma menyisakan Budi — dikirim ke server, bukan disaring
    // di app, jadi total header ikut berubah.
    await _tapFilterChip(tester, '6');
    expect(source.lastStatusIds, [6]);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Andi Wijaya Aan'), findsNothing);
    expect(find.text('Reyhan Pradipta'), findsNothing);
    expect(find.text('1 transaction'), findsOneWidget);

    // Chip "Reserve" (id 2) cuma menyisakan Andi.
    await _tapFilterChip(tester, '2');
    expect(source.lastStatusIds, [2]);
    expect(find.text('Andi Wijaya Aan'), findsOneWidget);
    expect(find.text('Reyhan Pradipta'), findsNothing);
    expect(find.text('Budi Santoso'), findsNothing);

    // Chip yang tidak ada transaksinya tetap bisa dipilih, pesan kosongnya beda dari pencarian.
    await _tapFilterChip(tester, '7'); // RBA
    expect(find.text('No transactions for filter "RBA".'), findsOneWidget);

    await _tapFilterChip(tester, 'semua');
    expect(source.lastStatusIds, isEmpty);
    expect(find.text('Andi Wijaya Aan'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Reyhan Pradipta'), findsOneWidget);
  });

  testWidgets('gagal memuat menampilkan pesan + tombol coba lagi', (tester) async {
    source.fail = true;
    await _pumpMenu(tester);

    expect(find.text('Retry'), findsOneWidget);

    source.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Andi Wijaya Aan'), findsOneWidget);
  });

  testWidgets('detail merender timeline L1-L10 & keempat tabnya', (tester) async {
    await _pumpMenu(tester);
    await _openDetail(tester, 'Andi Wijaya Aan');

    expect(find.text('Andi Wijaya Aan'), findsOneWidget);
    expect(find.text('Unit not yet determined · Paradise Serpong City 2'), findsOneWidget);
    expect(find.text('Full Profile & History ›'), findsOneWidget);

    // Timeline lengkap, chip gembok, dan penanda tujuan akhir.
    expect(find.text('L1 Leads'), findsOneWidget);
    expect(find.text('L4 Reserve'), findsOneWidget);
    expect(find.text('L10 AKAD'), findsOneWidget);
    expect(find.text('Final Goal'), findsOneWidget);
    expect(find.text('Progress Only'), findsNWidgets(3)); // L7, L8, L9
    expect(find.textContaining('Submitted 07 Sep 2026 · Rp 80.000 · under verification'), findsOneWidget);

    // Tautan profil membuka halaman Contact Detail memakai contact_id dari response.
    await tester.tap(find.text('Full Profile & History ›'));
    await tester.pumpAndSettle();
    expect(find.text('Contact Detail'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buyer Data'));
    await tester.pumpAndSettle();
    expect(find.text('081234567890'), findsWidgets);

    // Attachment butuh `reserve_order_tts_id` (dari `ReserveOrderListCubit.rememberTtsId`, diisi
    // pas submit doc-payment di form Reserve) yang tidak diketahui di sini — jadi tampil pesan
    // "belum bisa ditampilkan", bukan "belum ada dokumen". Catatan diisi dari `reserve_note`.
    await tester.tap(find.text('Attachment'));
    await tester.pumpAndSettle();
    expect(find.text('Documents for this transaction cannot be shown here yet.'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('test reserve_note'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Sudah saya follow up ke customer');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sudah saya follow up ke customer'), findsOneWidget);
  });

  testWidgets('tab Attachment menampilkan dokumen kalau reserve_order_tts_id sudah diketahui, & bisa dibuka', (tester) async {
    // `rememberTtsId` mensimulasikan reserve order yang doc-payment-nya baru saja disubmit lewat
    // form Reserve di sesi app yang sama (lihat reserve.dart `_onSubmit`) — beda dari test
    // "detail merender..." yang membuka reserve order TANPA tts id yang diketahui.
    final cubit = ReserveOrderListCubit(source)..rememberTtsId(5, 42);
    source.attachmentsByKey[(5, 42)] = [
      ReserveOrderAttachment(
        contactAttachmentId: 316,
        attachmentUrl: 'https://drive.google.com/file/d/14nOjb__5bibGU9ts6bk8M0UoDQtp60fV/view?usp=drivesdk',
        attachmentTypeName: 'Bukti Transfer',
        attachmentNote: 'Reserve Order #5 · TTS #42',
        createDatetime: DateTime(2026, 9, 9),
        createUserName: 'iman',
      ),
    ];

    await _pumpMenu(tester, cubit: cubit);
    await _openDetail(tester, 'Budi Santoso');

    await tester.tap(find.text('Attachment'));
    await tester.pumpAndSettle();

    expect(find.text('Bukti Transfer'), findsOneWidget);
    expect(find.textContaining('Uploaded by iman'), findsOneWidget);
    expect(find.textContaining('09 Sep 2026'), findsOneWidget);

    // Tap kartunya membuka preview lewat route `attachmentWebView`, bawa `attachment_url`-nya.
    await tester.tap(find.text('Bukti Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Preview Attachment'), findsOneWidget);
    expect(find.textContaining('drive.google.com'), findsOneWidget);
  });

  testWidgets('top up: validasi, pengajuan, lalu layar sukses & jejaknya di timeline', (tester) async {
    await _pumpMenu(tester);
    await _openDetail(tester, 'Andi Wijaya Aan');

    await tester.ensureVisible(find.text('+ Top Up Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Top Up Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Top Up Payment'), findsOneWidget);
    expect(find.text('Total Paid So Far'), findsOneWidget);
    expect(find.text('Rp 80.000'), findsOneWidget);

    await tester.tap(find.text('Submit Top Up'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Top up transfer proof is required');

    await _attachVia(tester, find.textContaining('Upload new transfer proof', findRichText: true));
    expect(find.textContaining('Uploaded · '), findsOneWidget);

    await tester.tap(find.text('Submit Top Up'));
    await tester.pumpAndSettle();
    await _expectSnack(tester, 'Top up amount is required');

    await tester.enterText(find.byType(TextField).first, '3000000');
    await tester.pumpAndSettle();
    expect(find.text('3.000.000'), findsOneWidget);

    await tester.tap(find.text('Submit Top Up'));
    await tester.pumpAndSettle();
    expect(find.text('Top Up Successfully Submitted'), findsOneWidget);
    expect(find.text('Rp 80.000 + Rp 3.000.000'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.text('Back to Reserve Order'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Top Up Booking Reserve Rp 3.000.000 submitted', findRichText: true), findsOneWidget);
  });

  testWidgets('transaksi ditolak: banner, ajukan ulang, lalu balik ke Diproses', (tester) async {
    await _pumpMenu(tester);
    await _openDetail(tester, 'Reyhan Pradipta');

    expect(find.text('Rejected — Needs Revision'), findsOneWidget); // banner
    expect(find.text('Rejected - Needs Revision'), findsOneWidget); // kotak status
    expect(find.textContaining('Nominal bukti transfer tidak sesuai'), findsWidgets);

    await tester.tap(find.text('Edit & Resubmit'));
    await tester.pumpAndSettle();

    expect(find.text('Fix Reserve Order'), findsOneWidget);
    expect(find.text('400.000.000'), findsOneWidget); // prefill dari nominal yang ditolak

    await tester.tap(find.text('Resubmit'));
    await tester.pumpAndSettle();

    // Balik ke detail: banner hilang, statusnya kembali menunggu verifikasi.
    expect(find.text('Fix Reserve Order'), findsNothing);
    expect(find.text('Still Processing'), findsNWidgets(3)); // kotak status + 2 chip gembok (L5, L6)
    expect(find.text('Edit & Resubmit'), findsNothing);
    expect(find.textContaining('Reserve Order resubmitted with an amount', findRichText: true), findsOneWidget);
  });
}
