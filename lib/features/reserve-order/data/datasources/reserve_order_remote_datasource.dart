import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/models/cara_bayar_model.dart';
import 'package:progress_group/features/reserve-order/data/models/create_reserve_order_result_model.dart';
import 'package:progress_group/features/reserve-order/data/models/payment_type_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_status_model.dart';
import 'package:progress_group/features/reserve-order/data/models/select_unit_model.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';

abstract class ReserveOrderRemoteDataSource {
  Future<List<ReserveStatusModel>> getReserveStatuses();
  Future<List<CaraBayarModel>> getCaraBayar();
  Future<List<String>> getWorkCategory();
  Future<List<PaymentTypeModel>> getPaymentTypes();
  Future<List<SelectUnitModel>> getSelectUnit({
    required int contactId,
    required int townshipId,
  });
  Future<CreateReserveOrderResultModel> createReserveOrder(
    CreateReserveOrderParams params,
  );
}

class ReserveOrderRemoteDataSourceImpl implements ReserveOrderRemoteDataSource {
  final Dio dio;

  ReserveOrderRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ReserveStatusModel>> getReserveStatuses() async {
    try {
      final response = await dio.get('/reserve-order/status');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ReserveStatusModel.fromJson(json)).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load reserve statuses',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load reserve statuses'));
    }
  }

  @override
  Future<List<CaraBayarModel>> getCaraBayar() async {
    try {
      final response = await dio.get('/reserve-order/cara-bayar');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => CaraBayarModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load cara bayar');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load cara bayar'));
    }
  }

  @override
  Future<List<String>> getWorkCategory() async {
    try {
      final response = await dio.get('/reserve-order/work-category');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => e.toString()).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load work category',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load work category'));
    }
  }

  @override
  Future<List<PaymentTypeModel>> getPaymentTypes() async {
    try {
      final response = await dio.get('/reserve-order/payment-types');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PaymentTypeModel.fromJson(json)).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load payment types',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load payment types'));
    }
  }

  @override
  Future<List<SelectUnitModel>> getSelectUnit({
    required int contactId,
    required int townshipId,
  }) async {
    try {
      final response = await dio.get(
        '/reserve-order/select-unit',
        queryParameters: {'contact_id': contactId, 'township_id': townshipId},
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => SelectUnitModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load unit'));
    }
  }

  @override
  Future<CreateReserveOrderResultModel> createReserveOrder(
    CreateReserveOrderParams params,
  ) async {
    try {
      final response = await dio.post(
        '/reserve-order/create',
        data: _buildFormData(params),
      );

      if (response.data['status'] == true) {
        return CreateReserveOrderResultModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to create reserve order',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to create reserve order'));
    }
  }

  /// Bangun `FormData` multipart dengan key bracket-notation persis yang divalidasi
  /// `ReserveOrderController::store` (`customer[cust_name]`, `units[0][payments][0][amount]`,
  /// `documents[ktp]` sbg file, dst) — dibangun manual (bukan lewat auto-nesting `FormData.fromMap`)
  /// supaya bentuknya pasti sama persis dengan yang sudah diuji lewat Postman.
  FormData _buildFormData(CreateReserveOrderParams p) {
    final data = <String, dynamic>{'contact_id': p.contactId.toString()};

    if ((p.reserveNote ?? '').isNotEmpty) {
      data['reserve_note'] = p.reserveNote;
    }

    void putTop(String field, int? value) {
      if (value == null) return;
      data[field] = value.toString();
    }

    putTop('sales_executive_id', p.salesExecutiveId);
    putTop('sales_supervisor_id', p.salesSupervisorId);
    putTop('sales_manager_id', p.salesManagerId);
    putTop('sales_general_manager_id', p.salesGeneralManagerId);
    putTop('sales_team_id', p.salesTeamId);

    p.customer.forEach((key, value) {
      if (value == null) return;
      data['customer[$key]'] = value is bool
          ? (value ? '1' : '0')
          : value.toString();
    });

    void addDocument(String slot, CreateReserveOrderFile? doc) {
      if (doc == null || doc.isEmpty) return;
      if (doc.existingAttachmentId != null) {
        data['documents[$slot][existing_attachment_id]'] =
            doc.existingAttachmentId.toString();
      } else if (doc.bytes != null) {
        data['documents[$slot]'] = MultipartFile.fromBytes(
          doc.bytes!,
          filename: doc.fileName ?? '$slot.jpg',
        );
      }
    }

    addDocument('ktp', p.ktp);
    addDocument('npwp', p.npwp);

    for (var i = 0; i < p.units.length; i++) {
      final u = p.units[i];
      void put(String field, dynamic value) {
        if (value == null) return;
        data['units[$i][$field]'] = value.toString();
      }

      put('deal_id', u.dealId);
      put('company_id', u.companyId);
      put('product_id', u.productId);
      put('property_id', u.propertyId);
      put('property_name', u.propertyName);
      put('payment_type', u.paymentType);
      put('payment_type_id', u.paymentTypeId);
      put('note', u.note);

      for (var j = 0; j < u.payments.length; j++) {
        final pay = u.payments[j];
        data['units[$i][payments][$j][payment_method]'] = pay.paymentMethod;
        data['units[$i][payments][$j][amount]'] = pay.amount.toString();
        if ((pay.bankName ?? '').isNotEmpty) {
          data['units[$i][payments][$j][bank_name]'] = pay.bankName;
        }
        if ((pay.referenceNumber ?? '').isNotEmpty) {
          data['units[$i][payments][$j][reference_number]'] =
              pay.referenceNumber;
        }
        if (pay.proofBytes != null) {
          data['units[$i][payments][$j][proof]'] = MultipartFile.fromBytes(
            pay.proofBytes!,
            filename: pay.proofFileName ?? 'proof_${i}_$j.jpg',
          );
        }
      }
    }

    return FormData.fromMap(data);
  }
}
