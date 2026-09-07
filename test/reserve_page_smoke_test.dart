// Smoke test flow Reserve Order (mockup reserve-order-sales-final_12.html, Bagian 2):
// memastikan kelima layar — Data Pembeli, Dokumen & Bukti Bayar, Pilih Unit, Review, Sukses —
// bisa dirender di ukuran layar HP tanpa error layout (overflow / unbounded height), validasi
// tiap step menahan langkah berikutnya, dokumennya terkirim ke endpoint attachment kontak saat
// submit, dan hasilnya sampai ke kartu di halaman menu.
// Analyzer tidak bisa menangkap error layout, jadi ini satu-satunya pengaman otomatisnya.
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
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
import 'package:progress_group/features/contact/data/datasources/ktp_ocr_remote_datasource.dart';
import 'package:progress_group/features/contact/data/models/ktp/ktp_ocr_model.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_type.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/repositories/contact_repository.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/get_attachment_types_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/upload_attachment_usecase.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/index.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/reserve.dart';
import 'package:progress_group/features/contact/presentation/state/ktp_ocr/ktp_ocr_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/reserve_attachment/reserve_attachment_cubit.dart';

class _FakeKtpOcr implements KtpOcrRemoteDataSource {
  @override
  Future<KtpOcrModel> scanKtp({required Uint8List bytes, required String fileName}) async =>
      const KtpOcrModel(nama: 'SAKUM', nik: '3273051290000012');
}

/// Menampung request `POST /contacts/{id}/attachments` yang dikirim saat Submit Reserve Order,
/// plus master attachment type yang namanya dicocokkan cubit-nya.
class _FakeContactRepository extends Fake implements ContactRepository {
  final List<UploadAttachmentParams> uploads = [];
  bool failUpload = false;

  @override
  Future<Either<String, List<AttachmentType>>> getAttachmentTypes() async => Right([
        AttachmentType(id: 1, name: 'Lainnya'),
        AttachmentType(id: 3, name: 'KTP'),
        AttachmentType(id: 4, name: 'NPWP'),
        AttachmentType(id: 7, name: 'Bukti Transfer'),
      ]);

  @override
  Future<Either<String, void>> uploadAttachment(UploadAttachmentParams params) async {
    if (failUpload) return const Left('koneksi terputus');
    uploads.add(params);
    return const Right(null);
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

late _FakeContactRepository repo;

Widget _wrap(Widget child) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => KtpOcrCubit(_FakeKtpOcr())),
        BlocProvider(
          create: (_) => ReserveAttachmentCubit(
            GetAttachmentTypesUseCase(repo),
            UploadAttachmentUseCase(repo),
          ),
        ),
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

/// Lampirkan file lewat sheet pilih sumber (jalur "Dokumen" → FilePicker palsu).
Future<void> _attachVia(WidgetTester tester, Finder row) async {
  await tester.tap(row);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dokumen').last);
  await tester.pumpAndSettle();
}

/// Step 1 → 3: isi dokumen wajib & nominal, lalu pilih satu unit.
Future<void> _fillUntilUnitPicked(WidgetTester tester) async {
  await tester.tap(find.text('Lanjut ke Dokumen'));
  await tester.pumpAndSettle();
  await _attachVia(tester, find.textContaining('KTP', findRichText: true).first);
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
    repo = _FakeContactRepository();
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

  testWidgets('submit mengirim KTP & bukti bayar ke attachment kontak', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);

    // Sebelum submit belum ada request yang dikirim.
    expect(repo.uploads, isEmpty);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();
    expect(find.text('Reserve Order Berhasil Diajukan'), findsOneWidget);

    // Dua request: KTP dan bukti bayar. NPWP tidak dilampirkan, jadi tidak ikut dikirim.
    expect(repo.uploads.length, 2);

    final ktp = repo.uploads.first;
    expect(ktp.contactId, 1);
    expect(ktp.dealId, 99);
    expect(ktp.attachmentTypeId, 3); // dicocokkan dari nama tipe "KTP"
    expect(ktp.fileNames, ['dokumen-1.pdf']);
    expect(ktp.filesBytesList?.length, 1);
    expect(ktp.attachmentNote, contains('Reserve Order'));
    expect(ktp.attachmentNote, contains('Blok E1 No. 19'));

    final bukti = repo.uploads.last;
    expect(bukti.attachmentTypeId, 7); // dicocokkan dari nama tipe "Bukti Transfer"
    expect(bukti.fileNames, ['dokumen-2.pdf']);
  });

  testWidgets('upload gagal menahan di Review dengan pesan errornya', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repo.failUpload = true;

    await tester.pumpWidget(_wrap(MaterialApp(
      home: ReservePage(args: ContactDetailArgs(dataContact: _contact(), namePage: 'Reserve')),
    )));
    await tester.pumpAndSettle();
    await _fillUntilUnitPicked(tester);

    await tester.tap(find.text('Submit Reserve Order'));
    await tester.pumpAndSettle();

    expect(find.text('Reserve Order Berhasil Diajukan'), findsNothing);
    expect(find.text('Review Reserve Order'), findsOneWidget);
    expect(find.textContaining('Gagal mengunggah KTP'), findsOneWidget);
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
}
