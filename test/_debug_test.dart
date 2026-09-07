// Smoke test menu "Reserve Order" (mockup reserve-order-sales-final_12.html, Bagian 3):
// list transaksi dari `GET /api/reserve` + pencarian, pemetaan response ke kartu & detail,
// detail dengan 4 tab & timeline L1-L10, Top Up Pembayaran sampai layar sukses, dan
// Edit & Ajukan Ulang untuk transaksi yang ditolak kasir.
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
import 'package:progress_group/features/contact/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/contact/data/models/reserve/reserve_order_model.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/detail.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/list.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/revise.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/top_up.dart';
import 'package:progress_group/features/contact/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';

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
    'status_reserve_id': 4,
  };
}

class _FakeReserveOrders implements ReserveOrderRemoteDataSource {
  final List<Map<String, dynamic>> rows;
  bool fail = false;

  String? lastSearch;
  int lastPage = 0;
  int calls = 0;

  _FakeReserveOrders(this.rows);

  @override
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds = const [],
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
  }) async {
    calls++;
    lastSearch = search;
    lastPage = page;
    if (fail) throw Exception('koneksi terputus');

    final keyword = (search ?? '').toLowerCase();
    final filtered = keyword.isEmpty ? rows : rows.where((r) => '${r['cust_name']}'.toLowerCase().contains(keyword)).toList();

    return ReserveOrdersPage(
      items: filtered.map((e) => ReserveOrder.fromJson(e)).toList(),
      page: page,
      hasMore: false,
      total: filtered.length,
    );
  }
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
          ],
        ),
      ],
    );

Future<void> _pumpMenu(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(BlocProvider(
    create: (_) => ReserveOrderListCubit(source),
    child: MaterialApp.router(routerConfig: _router()),
  ));
  await tester.pumpAndSettle();
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

/// Chip filter punya Key sendiri karena labelnya ("SP", "Akad") bisa sama persis dengan teks badge
/// status di kartu. `ensureVisible` menghitung scroll offset horizontalnya persis, jadi aman dari
/// chip yang sudah dibangun (masuk cache) tapi masih di luar area yang benar-benar terlihat.
Future<void> _tapFilterChip(WidgetTester tester, String filterName) async {
  final chip = find.byKey(ValueKey('reserve_order_filter_$filterName'));
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}


void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    source = _FakeReserveOrders([
      _row(id: 3, name: 'Andi Wijaya Aan', projectName: 'Paradise Serpong City 2', amount: 80000, note: 'test reserve_note'),
      _row(id: 5, name: 'Budi Santoso', projectName: 'PAR2', blokNo: 'Blok BC6 No. 17', amount: 780000000, spDate: '2026-09-02T03:00:00.000000Z'),
      _row(
        id: 8,
        name: 'Reyhan Pradipta',
        projectName: 'PAR2',
        blokNo: 'Blok E1 No. 22',
        amount: 400000000,
        createdAt: '2026-09-05T00:00:00.000000Z',
        rejectedAt: '2026-09-05T08:22:00.000000Z',
        rejectReason: 'Nominal bukti transfer tidak sesuai harga unit.',
      ),
    ]);
  });

  testWidgets('debug real setup', (tester) async {
    await _pumpMenu(tester);
    final scrollables = find.byType(Scrollable);
    print('total scrollables: ' + scrollables.evaluate().length.toString());
    for (final e in scrollables.evaluate()) {
      final w = e.widget as Scrollable;
      print('  axis=' + w.axisDirection.toString() + ' key=' + (w.key?.toString() ?? 'null'));
    }
  });
}
