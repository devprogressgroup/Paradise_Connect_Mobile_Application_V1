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

  /// Bikin baris `m_customer_reserve` baru — `POST /api/reserve`. Dipanggil saat Submit di step
  /// Review form Reserve, sebelum dokumen (KTP/bukti bayar) diunggah ke attachment kontak.
  Future<void> createReserve(CreateReserveParams params);
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
  Future<void> createReserve(CreateReserveParams params) async {
    try {
      final response = await dio.post('/reserve', data: params.toJson());
      final body = response.data;

      if (body is Map && body['status'] == true) return;
      throw Exception(body is Map ? (body['message'] ?? 'Gagal membuat reserve order') : 'Gagal membuat reserve order');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal membuat reserve order'));
    }
  }
}
