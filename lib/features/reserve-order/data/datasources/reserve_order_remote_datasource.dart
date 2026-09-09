import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';

/// Payload `POST /api/reserve` — bikin baris `m_customer_reserve` baru. Field selain
/// [contactId]/[custName] opsional karena sebagian belum ada input UI-nya sendiri (mis. jenis
/// kelamin/agama cuma terisi kalau dari hasil scan KTP).
class CreateReserveParams {
  final int contactId;
  final String custName;
  final String? custKtp;
  final String? custBirthPlace;
  final DateTime? custBirthDate;
  final bool? custGenderIsMale;
  final String? custMaritalStatus;
  final String? custReligion;
  final String? custOccupation;
  final String? custAddress1;
  final int? caraBayarId;
  final String? custTelpMobile1;

  const CreateReserveParams({
    required this.contactId,
    required this.custName,
    this.custKtp,
    this.custBirthPlace,
    this.custBirthDate,
    this.custGenderIsMale,
    this.custMaritalStatus,
    this.custReligion,
    this.custOccupation,
    this.custAddress1,
    this.caraBayarId,
    this.custTelpMobile1,
  });

  Map<String, dynamic> toJson() => {
        'contact_id': contactId,
        'cust_name': custName,
        if (custKtp != null && custKtp!.isNotEmpty) 'cust_ktp': custKtp,
        if (custBirthPlace != null && custBirthPlace!.isNotEmpty) 'cust_birth_place': custBirthPlace,
        if (custBirthDate != null) 'cust_birth_date': DateFormat('yyyy-MM-dd').format(custBirthDate!),
        if (custGenderIsMale != null) 'cust_gender_is_male': custGenderIsMale,
        if (custMaritalStatus != null && custMaritalStatus!.isNotEmpty) 'cust_marital_status': custMaritalStatus,
        if (custReligion != null && custReligion!.isNotEmpty) 'cust_religion': custReligion,
        if (custOccupation != null && custOccupation!.isNotEmpty) 'cust_occupation': custOccupation,
        if (custAddress1 != null && custAddress1!.isNotEmpty) 'cust_address1': custAddress1,
        if (caraBayarId != null) 'cara_bayar_id': caraBayarId,
        if (custTelpMobile1 != null && custTelpMobile1!.isNotEmpty) 'cust_telp_mobile1': custTelpMobile1,
      };
}

/// Payload `POST /api/reserve/doc-payment` — kirim dokumen (KTP/NPWP/bukti transfer) + rincian
/// pembayaran untuk reserve order yang sudah dibuat lewat [CreateReserveParams]. `ktp` & `bukti_transfer`
/// boleh lebih dari 1 file; `npwp` cuma 1. Nama field `ktp[]` dikirim dengan kurung (array), tapi
/// `bukti_transfer` TETAP tanpa kurung walau isinya array juga — sesuai instruksi eksplisit,
/// beda dari `ktp[]`. Lihat catatan gotcha `FormData`+kurung array file di
/// `ReserveOrderRemoteDataSourceImpl.submitDocPayment`.
class DocPaymentParams {
  final int reserveOrderId;
  final int statusReserveId;
  final num ttsAmountRp;
  final String? note;
  final List<Uint8List> ktpBytes;
  final List<String> ktpFileNames;
  final Uint8List? npwpBytes;
  final String? npwpFileName;
  final List<Uint8List> buktiTransferBytes;
  final List<String> buktiTransferFileNames;

  const DocPaymentParams({
    required this.reserveOrderId,
    required this.statusReserveId,
    required this.ttsAmountRp,
    this.note,
    this.ktpBytes = const [],
    this.ktpFileNames = const [],
    this.npwpBytes,
    this.npwpFileName,
    this.buktiTransferBytes = const [],
    this.buktiTransferFileNames = const [],
  });
}

/// Hasil `POST /api/reserve` — `reserveOrderId` dibutuhkan [DocPaymentParams.reserveOrderId]
/// (lewat [ReserveOrderRemoteDataSource.submitDocPayment]), `customerId` dibutuhkan
/// [ReserveOrderRemoteDataSource.saveReserveUnit] buat menautkan unit yang dipilih ke customer ini.
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

  /// Master status reserve buat chip filter di atas list — `GET /api/reserve-filter`.
  Future<List<ReserveFilterOption>> getReserveFilters();

  /// Master "Cara Pembayaran" di form Reserve — `GET /api/reserve/cara-bayar`.
  Future<List<CaraBayarOption>> getCaraBayarOptions();

  /// Bikin baris `m_customer_reserve` baru — `POST /api/reserve`. Dipanggil begitu lepas dari step
  /// Dokumen form Reserve (sebelum step Pilih Unit), supaya `customer_id`-nya sudah ada waktu
  /// [saveReserveUnit] dipanggil. Mengembalikan `reserve_order_id` (dipakai
  /// [DocPaymentParams.reserveOrderId] lewat [submitDocPayment]) & `customer_id` dari
  /// `data.reserve_order`.
  Future<CreateReserveResult> createReserve(CreateReserveParams params);

  /// Menautkan satu unit (deal) ke customer yang baru dibuat [createReserve] — `POST
  /// /api/reserve-unit`. Dipanggil sekali per unit begitu lepas dari step Pilih Unit form Reserve.
  Future<void> saveReserveUnit({required int dealId, required int customerId});

  /// Kirim dokumen + rincian pembayaran ke reserve order yang barusan dibuat —
  /// `POST /api/reserve/doc-payment`. Wajib dipanggil setelah [createReserve]. Mengembalikan
  /// `data.tts.reserve_order_tts_id` — dibutuhkan sebagai param [getReserveAttachments] kalau mau
  /// menampilkan lagi dokumen yang baru dikirim ini.
  Future<int> submitDocPayment(DocPaymentParams params);

  /// Detail customer satu reserve order — `GET /api/reserve/customer?reserve_order_id=…`. Dipanggil
  /// dari halaman Detail buat melengkapi tab "Data Pembeli" (No. KTP, alamat, status pernikahan,
  /// cara bayar) yang tidak ada di response `GET /api/reserve` (list).
  Future<ReserveCustomerDetail> getReserveCustomer(int reserveOrderId);

  /// Dokumen yang tersimpan lewat [submitDocPayment] untuk satu TTS —
  /// `GET /api/reserve/attachment?reserve_order_id=…&reserve_order_tts_id=…`. Dipanggil dari tab
  /// "Attachment" di halaman Detail.
  Future<List<ReserveOrderAttachment>> getReserveAttachments({
    required int reserveOrderId,
    required int reserveOrderTtsId,
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
        // Server menerima daftar id dipisah koma: `status_reserve_id=1,2`.
        if (statusReserveIds.isNotEmpty) 'status_reserve_id': statusReserveIds.join(','),
        'sort': sort,
        'page': page,
        'per_page': perPage,
        // Diisi saat daftar dibuka dari "Reserve Order" milik satu kontak (Log Activity), supaya
        // hanya transaksi kontak itu yang kembali.
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
          // `next_page_url` null artinya sudah halaman terakhir — dipakai daripada menghitung
          // sendiri dari total/per_page supaya tetap benar kalau server mengubah paginasinya.
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
  Future<List<ReserveFilterOption>> getReserveFilters() async {
    try {
      final response = await dio.get('/reserve-filter');
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => ReserveFilterOption.fromJson(Map<String, dynamic>.from(e as Map)))
            // `is_active` 0 berarti status itu tidak dipakai lagi — tidak usah muncul jadi chip.
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
  Future<CreateReserveResult> createReserve(CreateReserveParams params) async {
    try {
      final response = await dio.post('/reserve', data: params.toJson());
      final body = response.data;

      if (body is Map && body['status'] == true) {
        final data = body['data'];
        final reserveOrder = data is Map ? data['reserve_order'] : null;
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

  @override
  Future<void> saveReserveUnit({required int dealId, required int customerId}) async {
    try {
      final response = await dio.post('/reserve-unit', data: {'deal_id': dealId, 'customer_id': customerId});
      final body = response.data;

      if (body is Map && body['status'] == true) return;
      throw Exception(body is Map ? (body['message'] ?? 'Gagal menyimpan unit') : 'Gagal menyimpan unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal menyimpan unit'));
    }
  }

  // `filename` cukup buat Dio nebak `contentType`-nya sendiri (lewat ekstensinya) — lihat
  // `MultipartFile.fromBytes`.
  MultipartFile _multipart(Uint8List bytes, String? fileName) =>
      MultipartFile.fromBytes(bytes, filename: fileName ?? 'file');

  @override
  Future<int> submitDocPayment(DocPaymentParams params) async {
    try {
      final data = <String, dynamic>{
        'reserve_order_id': params.reserveOrderId,
        'status_reserve_id': params.statusReserveId,
        'tts_amount_rp': params.ttsAmountRp,
        if (params.note != null && params.note!.isNotEmpty) 'note': params.note,
        // Key literal `ktp[]` (bukan `ktp`) — `FormData.fromMap` TIDAK menambahkan tanda kurung
        // otomatis buat list berisi `MultipartFile` (beda dari list Map/List biasa), jadi kalau
        // key-nya cuma `ktp` yang terkirim adalah beberapa field literal bernama `ktp` (tanpa
        // kurung) yang oleh Laravel tidak dianggap array — persis bunyi error "ktp field must be
        // an array" yang pernah muncul. Harus disamakan persis dengan koleksi Postman.
        if (params.ktpBytes.isNotEmpty)
          'ktp[]': [
            for (var i = 0; i < params.ktpBytes.length; i++)
              _multipart(params.ktpBytes[i], i < params.ktpFileNames.length ? params.ktpFileNames[i] : null),
          ],
        if (params.npwpBytes != null) 'npwp': _multipart(params.npwpBytes!, params.npwpFileName),
        // `bukti_transfer` boleh >1 file (beda dari contoh Postman awal yang cuma 1) — TAPI
        // key-nya tetap literal tanpa kurung, tidak seperti `ktp[]`. Mekanismenya sama: Dio
        // mengirim beberapa part dengan nama field yang PERSIS sama untuk tiap elemen List, jadi
        // menaruh key tanpa kurung di sini otomatis menghasilkan beberapa `bukti_transfer` (bukan
        // `bukti_transfer[]`) — bukan bug, ini yang diminta.
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
  Future<List<ReserveOrderAttachment>> getReserveAttachments({
    required int reserveOrderId,
    required int reserveOrderTtsId,
  }) async {
    try {
      final response = await dio.get('/reserve/attachment', queryParameters: {
        'reserve_order_id': reserveOrderId,
        'reserve_order_tts_id': reserveOrderTtsId,
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
}
