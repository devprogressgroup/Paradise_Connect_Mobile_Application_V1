import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';

/// Payload gabungan `POST /api/reserve` (multipart) — bikin baris `m_customer_reserve`, tautkan
/// SATU unit (`dealId`) yang dipilih, DAN kirim dokumen (KTP/NPWP/bukti transfer) + rincian
/// pembayaran sekaligus dalam satu request. Menggantikan alur lama 3 request berurutan
/// (`createReserve` JSON → `saveReserveUnit` per unit → `submitDocPayment` multipart terpisah) —
/// sesuai instruksi eksplisit: cuma boleh 1 unit terpilih di step "Pilih Unit" (lihat
/// `ReservePage._onNextUnit`), jadi tidak perlu lagi endpoint terpisah buat "tautkan banyak unit".
/// `ktp[]` & `bukti_transfer[]` DUA-DUANYA pakai kurung array — beda dari [DocPaymentParams]
/// (`submitDocPayment`) yang `bukti_transfer`-nya sengaja TANPA kurung.
class CreateReserveParams {
  final int contactId;

  /// Null kalau unit yang dipilih belum py deal existing (dipilih baru dari katalog `unit-all`,
  /// belum pernah jadi deal) — field `deal_id` di-OMIT total dari request kalau null, bukan
  /// dikirim `0`/kosong, sesuai instruksi eksplisit.
  final int? dealId;
  final int companyId;
  final String custName;
  final String? custKtp;
  final String? custBirthPlace;
  final DateTime? custBirthDate;
  final bool? custGenderIsMale;
  final String? custMaritalStatus;
  final String? custReligion;
  final String? workCategory;
  final String? custOccupation;
  final String? custAddress1;
  final int? caraBayarId;
  final String? custTelpMobile1;
  final int statusReserveId;
  final num amountRp;
  final String? reserveNote;
  final List<Uint8List> ktpBytes;
  final List<String> ktpFileNames;
  final Uint8List? npwpBytes;
  final String? npwpFileName;
  final List<Uint8List> buktiTransferBytes;
  final List<String> buktiTransferFileNames;

  const CreateReserveParams({
    required this.contactId,
    this.dealId,
    required this.companyId,
    required this.custName,
    this.custKtp,
    this.custBirthPlace,
    this.custBirthDate,
    this.custGenderIsMale,
    this.custMaritalStatus,
    this.custReligion,
    this.workCategory,
    this.custOccupation,
    this.custAddress1,
    this.caraBayarId,
    this.custTelpMobile1,
    required this.statusReserveId,
    required this.amountRp,
    this.reserveNote,
    this.ktpBytes = const [],
    this.ktpFileNames = const [],
    this.npwpBytes,
    this.npwpFileName,
    this.buktiTransferBytes = const [],
    this.buktiTransferFileNames = const [],
  });
}

/// Payload `POST /api/reserve/doc-payment` — kirim dokumen (KTP/NPWP/bukti transfer) + rincian
/// pembayaran untuk reserve order yang sudah dibuat lewat [CreateReserveParams]. `ktp` & `bukti_transfer`
/// boleh lebih dari 1 file; `npwp` cuma 1. Nama field `ktp[]` dikirim dengan kurung (array), tapi
/// `bukti_transfer` TETAP tanpa kurung walau isinya array juga — sesuai instruksi eksplisit,
/// beda dari `ktp[]`. Lihat catatan gotcha `FormData`+kurung array file di
/// `ReserveOrderRemoteDataSourceImpl.submitDocPayment`.
class DocPaymentParams {
  final int reserveOrderId;

  /// Null kalau cuma nambah dokumen pendukung dari tab "Attachment" (bukan submit
  /// pembayaran/transaksi baru) — sesuai instruksi eksplisit, field ini di-OMIT total dari request
  /// (bukan dikirim `0`), lihat [ReserveOrderRemoteDataSourceImpl.submitDocPayment].
  final int? statusReserveId;

  /// Null dengan alasan yang sama seperti [statusReserveId].
  final num? ttsAmountRp;

  /// TTS yang sudah ada, diisi HANYA saat upload dokumen tambahan dari halaman Detail (tab
  /// Attachment) — nilainya diambil dari `reserve_order_tts_id` di respons `GET
  /// /api/reserve/attachment` (lihat `ReserveOrderAttachment.reserveOrderTtsId`). Null di alur
  /// submit awal (`reserve.dart`) & Top Up (`top_up.dart`) karena keduanya bikin TTS baru — di-OMIT
  /// total dari request kalau null, sama seperti [statusReserveId].
  final int? reserveOrderTtsId;
  final String? note;
  final List<Uint8List> ktpBytes;
  final List<String> ktpFileNames;
  final Uint8List? npwpBytes;
  final String? npwpFileName;
  final List<Uint8List> buktiTransferBytes;
  final List<String> buktiTransferFileNames;

  const DocPaymentParams({
    required this.reserveOrderId,
    this.statusReserveId,
    this.ttsAmountRp,
    this.reserveOrderTtsId,
    this.note,
    this.ktpBytes = const [],
    this.ktpFileNames = const [],
    this.npwpBytes,
    this.npwpFileName,
    this.buktiTransferBytes = const [],
    this.buktiTransferFileNames = const [],
  });
}

/// Hasil `POST /api/reserve` — `reserveOrderId`/`customerId` dari `data.reserve_order`. Sudah
/// tidak dipakai lagi buat memicu request susulan (dulu `saveReserveUnit`/`submitDocPayment`
/// terpisah) sejak [CreateReserveParams] mencakup semuanya dalam satu request.
class CreateReserveResult {
  final int reserveOrderId;
  final int customerId;

  const CreateReserveResult({required this.reserveOrderId, required this.customerId});
}

/// Satu halaman hasil `GET /api/reserve`.
class ReserveOrdersPage {
  final List<ReserveOrder> items;
  final int page;
  final bool hasMore;

  /// Total baris se-query, dipakai untuk teks "N transaksi" di judul list.
  final int total;

  const ReserveOrdersPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
  });
}

abstract class ReserveOrderRemoteDataSource {
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds,
    String sort,
    int page,
    int perPage,
    int? contactId,
  });

  /// Master status reserve buat chip filter di atas list — `GET /api/reserve-filter`. [excludeBatal]
  /// mengirim `exclude_batal=1` — dipakai "Jenis Transaksi" di form Reserve supaya status "Batal"
  /// tidak muncul sebagai pilihan jenis transaksi baru; chip filter List tetap minta semua status
  /// apa adanya (`excludeBatal: false`).
  Future<List<ReserveFilterOption>> getReserveFilters({bool excludeBatal = false});

  /// Master "Cara Pembayaran" di form Reserve — `GET /api/reserve/cara-bayar`.
  Future<List<CaraBayarOption>> getCaraBayarOptions();

  /// Bikin baris `m_customer_reserve`, tautkan SATU unit (`dealId`), DAN kirim dokumen + rincian
  /// pembayaran — semuanya dalam SATU request multipart `POST /api/reserve`. Step
  /// Pembeli/Unit/Dokumen form Reserve semuanya cuma validasi lokal; ini baru dipanggil pas submit
  /// di step Review (lihat `ReservePage._onSubmit`). Mengembalikan `reserve_order_id`/`customer_id`
  /// dari `data.reserve_order`.
  Future<CreateReserveResult> createReserve(CreateReserveParams params);

  /// Kirim dokumen + rincian pembayaran ke reserve order yang barusan dibuat —
  /// `POST /api/reserve/doc-payment`. Wajib dipanggil setelah [createReserve]. Mengembalikan
  /// `data.tts.reserve_order_tts_id` — dibutuhkan sebagai param [DocPaymentParams.reserveOrderTtsId]
  /// kalau mau menambah dokumen ke TTS yang sama dari halaman Detail.
  Future<int> submitDocPayment(DocPaymentParams params);

  /// Ajukan Top Up pembayaran — `POST /api/reserve/top-up`. Endpoint TERPISAH dari
  /// [submitDocPayment] (beda payload & tujuan): cuma 4 field (`reserve_order_id`, `amount_rp`,
  /// `reserve_note`, `bukti_transfer[]` — boleh lebih dari 1 file, kurungnya sama seperti
  /// [CreateReserveParams]), dipakai khusus `ReserveOrderTopUpPage`.
  Future<void> topUp({
    required int reserveOrderId,
    required num amountRp,
    String? note,
    required List<Uint8List> buktiTransferBytes,
    required List<String> buktiTransferFileNames,
  });

  /// Detail customer satu reserve order — `GET /api/reserve/customer?reserve_order_id=…`. Dipanggil
  /// dari halaman Detail buat melengkapi tab "Data Pembeli" (No. KTP, alamat, status pernikahan,
  /// cara bayar) yang tidak ada di response `GET /api/reserve` (list).
  Future<ReserveCustomerDetail> getReserveCustomer(int reserveOrderId);

  // Cuma `reserve_order_id` — TANPA `reserve_order_tts_id` (sempat dikirim, dihapus lagi: server
  // menyaring hasilnya cuma untuk TTS itu, jadi dokumen dari TTS lain di reserve order yang sama
  // hilang dari tab Attachment begitu ada TTS lebih baru).
  Future<List<ReserveOrderAttachment>> getReserveAttachments({required int reserveOrderId});

  /// Update profil pembeli — `PATCH /api/reserve/{reserve_order_id}`. Body-nya field backend apa
  /// adanya (`cust_name`, `spouse_income`, `mate_ktp_city`, dst — persis [ReserveCustomerDetail.raw]),
  /// makanya cukup terima map mentah daripada bikin kelas Params baru berisi ~90 field. Dipanggil
  /// dari `ReserveOrderEditCustomerPage`.
  Future<void> updateReserveCustomer({required int reserveOrderId, required Map<String, dynamic> data});

  /// Master "Area" (lokasi/wilayah) buat dropdown Area Code di halaman Edit Customer —
  /// `GET /api/reserve/area`.
  Future<List<AreaOption>> getAreaOptions();

  /// Pesan tab "Notes" (gaya chat) — `GET /api/reserve/notes?reserve_order_id=…`.
  Future<List<ReserveOrderActivityMessage>> getReserveNotes(int reserveOrderId);

  Future<void> sendReserveNote({required int reserveOrderId, required String message});

  Future<List<ReserveOrderTimelineMilestone>> getReserveTimeline({
    required int reserveOrderId,
    required int contactId,
    required int dealId,
  });
}

class ReserveOrderRemoteDataSourceImpl implements ReserveOrderRemoteDataSource {
  final Dio dio;

  ReserveOrderRemoteDataSourceImpl(this.dio);

  @override
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds = const [],
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
    int? contactId,
  }) async {
    try {
      final response = await dio.get('/reserve', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (statusReserveIds.isNotEmpty) 'status_reserve_id': statusReserveIds.join(','),
        'sort': sort,
        'page': page,
        'per_page': perPage,
        if (contactId != null) 'contact_id': contactId,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final items = (data['data'] as List? ?? [])
            .map((e) => ReserveOrder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return ReserveOrdersPage(
          items: items,
          page: data['current_page'] is int ? data['current_page'] as int : page,
          hasMore: data['next_page_url'] != null,
          total: data['total'] is int ? data['total'] as int : items.length,
        );
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat reserve order') : 'Gagal memuat reserve order');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat reserve order'));
    }
  }

  @override
  Future<List<ReserveFilterOption>> getReserveFilters({bool excludeBatal = false}) async {
    try {
      final response = await dio.get('/reserve-filter', queryParameters: {
        if (excludeBatal) 'exclude_batal': 1,
      });
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => ReserveFilterOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((f) => f.isActive)
            .toList();
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat filter reserve order') : 'Gagal memuat filter reserve order');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat filter reserve order'));
    }
  }

  @override
  Future<List<CaraBayarOption>> getCaraBayarOptions() async {
    try {
      final response = await dio.get('/reserve/cara-bayar');
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is List) {
        return (body['data'] as List).map((e) => CaraBayarOption.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat cara pembayaran') : 'Gagal memuat cara pembayaran');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat cara pembayaran'));
    }
  }

  @override
  Future<CreateReserveResult> createReserve(CreateReserveParams p) async {
    try {
      final data = <String, dynamic>{
        'contact_id': p.contactId,
        if (p.dealId != null) 'deal_id': p.dealId,
        'company_id': p.companyId,
        'cust_name': p.custName,
        if (p.custKtp != null && p.custKtp!.isNotEmpty) 'cust_ktp': p.custKtp,
        if (p.custBirthPlace != null && p.custBirthPlace!.isNotEmpty) 'cust_birth_place': p.custBirthPlace,
        if (p.custBirthDate != null) 'cust_birth_date': DateFormat('yyyy-MM-dd').format(p.custBirthDate!),
        if (p.custGenderIsMale != null) 'cust_gender_is_male': p.custGenderIsMale,
        if (p.custMaritalStatus != null && p.custMaritalStatus!.isNotEmpty) 'cust_marital_status': p.custMaritalStatus,
        if (p.custReligion != null && p.custReligion!.isNotEmpty) 'cust_religion': p.custReligion,
        if (p.workCategory != null && p.workCategory!.isNotEmpty) 'work_category': p.workCategory,
        if (p.custOccupation != null && p.custOccupation!.isNotEmpty) 'cust_occupation': p.custOccupation,
        if (p.custAddress1 != null && p.custAddress1!.isNotEmpty) 'cust_address1': p.custAddress1,
        if (p.caraBayarId != null) 'cara_bayar_id': p.caraBayarId,
        if (p.custTelpMobile1 != null && p.custTelpMobile1!.isNotEmpty) 'cust_telp_mobile1': p.custTelpMobile1,
        'status_reserve_id': p.statusReserveId,
        'amount_rp': p.amountRp,
        if (p.reserveNote != null && p.reserveNote!.isNotEmpty) 'reserve_note': p.reserveNote,
        if (p.ktpBytes.isNotEmpty)
          'ktp[]': [
            for (var i = 0; i < p.ktpBytes.length; i++)
              _multipart(p.ktpBytes[i], i < p.ktpFileNames.length ? p.ktpFileNames[i] : null),
          ],
        if (p.npwpBytes != null) 'npwp': _multipart(p.npwpBytes!, p.npwpFileName),
        if (p.buktiTransferBytes.isNotEmpty)
          'bukti_transfer[]': [
            for (var i = 0; i < p.buktiTransferBytes.length; i++)
              _multipart(
                p.buktiTransferBytes[i],
                i < p.buktiTransferFileNames.length ? p.buktiTransferFileNames[i] : null,
              ),
          ],
      };

      final response = await dio.post('/reserve', data: FormData.fromMap(data));
      final body = response.data;

      if (body is Map && body['status'] == true) {
        final resData = body['data'];
        final reserveOrder = resData is Map ? resData['reserve_order'] : null;
        final rawReserveOrderId = reserveOrder is Map ? reserveOrder['reserve_order_id'] : null;
        final rawCustomerId = reserveOrder is Map ? reserveOrder['customer_id'] : null;
        final reserveOrderId = rawReserveOrderId is int ? rawReserveOrderId : int.tryParse('$rawReserveOrderId');
        final customerId = rawCustomerId is int ? rawCustomerId : int.tryParse('$rawCustomerId');
        if (reserveOrderId != null && customerId != null) {
          return CreateReserveResult(reserveOrderId: reserveOrderId, customerId: customerId);
        }
        throw Exception('reserve_order_id/customer_id tidak ditemukan di response');
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal membuat reserve order') : 'Gagal membuat reserve order');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal membuat reserve order'));
    }
  }

  MultipartFile _multipart(Uint8List bytes, String? fileName) =>
      MultipartFile.fromBytes(bytes, filename: fileName ?? 'file');

  @override
  Future<int> submitDocPayment(DocPaymentParams params) async {
    try {
      final data = <String, dynamic>{
        'reserve_order_id': params.reserveOrderId,
        if (params.statusReserveId != null) 'status_reserve_id': params.statusReserveId,
        if (params.ttsAmountRp != null) 'tts_amount_rp': params.ttsAmountRp,
        if (params.reserveOrderTtsId != null) 'reserve_order_tts_id': params.reserveOrderTtsId,
        if (params.note != null && params.note!.isNotEmpty) 'note': params.note,
        if (params.ktpBytes.isNotEmpty)
          'ktp[]': [
            for (var i = 0; i < params.ktpBytes.length; i++)
              _multipart(params.ktpBytes[i], i < params.ktpFileNames.length ? params.ktpFileNames[i] : null),
          ],
        if (params.npwpBytes != null) 'npwp': _multipart(params.npwpBytes!, params.npwpFileName),
        if (params.buktiTransferBytes.isNotEmpty)
          'bukti_transfer': [
            for (var i = 0; i < params.buktiTransferBytes.length; i++)
              _multipart(
                params.buktiTransferBytes[i],
                i < params.buktiTransferFileNames.length ? params.buktiTransferFileNames[i] : null,
              ),
          ],
      };

      final response = await dio.post('/reserve/doc-payment', data: FormData.fromMap(data));
      final body = response.data;

      if (body is Map && body['status'] == true) {
        final data = body['data'];
        final tts = data is Map ? data['tts'] : null;
        final id = tts is Map ? tts['reserve_order_tts_id'] : null;
        final reserveOrderTtsId = id is int ? id : int.tryParse('$id');
        if (reserveOrderTtsId != null) return reserveOrderTtsId;
        throw Exception('reserve_order_tts_id tidak ditemukan di response');
      }
      throw Exception(
        body is Map ? (body['message'] ?? 'Gagal menyimpan dokumen & pembayaran') : 'Gagal menyimpan dokumen & pembayaran',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal menyimpan dokumen & pembayaran'));
    }
  }

  @override
  Future<void> topUp({
    required int reserveOrderId,
    required num amountRp,
    String? note,
    required List<Uint8List> buktiTransferBytes,
    required List<String> buktiTransferFileNames,
  }) async {
    try {
      final data = <String, dynamic>{
        'reserve_order_id': reserveOrderId,
        'amount_rp': amountRp,
        if (note != null && note.isNotEmpty) 'reserve_note': note,
        if (buktiTransferBytes.isNotEmpty)
          'bukti_transfer[]': [
            for (var i = 0; i < buktiTransferBytes.length; i++)
              _multipart(buktiTransferBytes[i], i < buktiTransferFileNames.length ? buktiTransferFileNames[i] : null),
          ],
      };

      final response = await dio.post('/reserve/top-up', data: FormData.fromMap(data));
      final body = response.data;

      if (body is Map && body['status'] == true) return;
      throw Exception(body is Map ? (body['message'] ?? 'Gagal mengajukan top up') : 'Gagal mengajukan top up');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal mengajukan top up'));
    }
  }

  @override
  Future<ReserveCustomerDetail> getReserveCustomer(int reserveOrderId) async {
    try {
      final response = await dio.get('/reserve/customer', queryParameters: {'reserve_order_id': reserveOrderId});
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is Map) {
        return ReserveCustomerDetail.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat data pembeli') : 'Gagal memuat data pembeli');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat data pembeli'));
    }
  }

  @override
  Future<List<ReserveOrderAttachment>> getReserveAttachments({required int reserveOrderId}) async {
    try {
      final response = await dio.get('/reserve/attachment', queryParameters: {
        'reserve_order_id': reserveOrderId,
      });
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => ReserveOrderAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat dokumen') : 'Gagal memuat dokumen');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat dokumen'));
    }
  }

  @override
  Future<void> updateReserveCustomer({required int reserveOrderId, required Map<String, dynamic> data}) async {
    try {
      final response = await dio.patch('/reserve/$reserveOrderId', data: data);
      final body = response.data;

      if (body is Map && body['status'] == true) return;
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memperbarui data pembeli') : 'Gagal memperbarui data pembeli');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memperbarui data pembeli'));
    }
  }

  @override
  Future<List<AreaOption>> getAreaOptions() async {
    try {
      final response = await dio.get('/reserve/area');
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        if (data['data'] is List) {
          return (data['data'] as List).map((e) => AreaOption.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat area') : 'Gagal memuat area');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat area'));
    }
  }

  @override
  Future<List<ReserveOrderActivityMessage>> getReserveNotes(int reserveOrderId) async {
    try {
      final response = await dio.get('/reserve/notes', queryParameters: {'reserve_order_id': reserveOrderId});
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => ReserveOrderActivityMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat pesan') : 'Gagal memuat pesan');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat pesan'));
    }
  }

  @override
  Future<void> sendReserveNote({required int reserveOrderId, required String message}) async {
    try {
      final response = await dio.post('/reserve/notes', data: {
        'reserve_order_id': reserveOrderId,
        'message': message,
      });
      final body = response.data;

      if (body is Map && body['status'] == true) return;
      throw Exception(body is Map ? (body['message'] ?? 'Gagal mengirim pesan') : 'Gagal mengirim pesan');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal mengirim pesan'));
    }
  }

  @override
  Future<List<ReserveOrderTimelineMilestone>> getReserveTimeline({
    required int reserveOrderId,
    required int contactId,
    required int dealId,
  }) async {
    try {
      final response = await dio.get('/reserve/timeline', queryParameters: {
        'reserve_order_id': reserveOrderId,
        'contact_id': contactId,
        'deal_id': dealId,
      });
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        if (data['timeline'] is List) {
          return (data['timeline'] as List)
              .map((e) => ReserveOrderTimelineMilestone.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat timeline') : 'Gagal memuat timeline');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat timeline'));
    }
  }
}
