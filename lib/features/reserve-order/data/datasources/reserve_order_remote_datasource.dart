import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/models/cara_bayar_model.dart';
import 'package:progress_group/features/reserve-order/data/models/create_reserve_order_result_model.dart';
import 'package:progress_group/features/reserve-order/data/models/payment_type_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_detail_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_list_item_model.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_status_model.dart';
import 'package:progress_group/features/reserve-order/data/models/select_unit_model.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/edit_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/update_reserve_order_customer_params.dart';

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
  Future<ReserveOrderListResultModel> getReserveOrderList({
    String? search,
    List<int>? statusReserveIds,
    bool? rejected,
    String? sort,
    List<int>? salesChannelIds,
    List<int>? channelDetailIds,
    List<int>? ownerIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? generalManagerIds,
    int page,
    int perPage,
  });
  Future<ReserveOrderDetailModel> getReserveOrderDetail(int reserveOrderId);
  Future<ReserveOrderDetailModel> updateReserveOrderCustomer(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  );
  Future<ReserveOrderDetailModel> topupReserveOrder(
    int reserveOrderId,
    TopupReserveOrderParams params,
  );
  Future<ReserveOrderDetailModel> sendReserveOrderMessage(
    int reserveOrderId,
    String message,
  );
  Future<ReserveOrderDetailModel> editReserveOrder(
    int reserveOrderId,
    EditReserveOrderParams params,
  );
  Future<void> deleteReserveOrder(int reserveOrderId);
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

  @override
  Future<ReserveOrderListResultModel> getReserveOrderList({
    String? search,
    List<int>? statusReserveIds,
    bool? rejected,
    String? sort,
    List<int>? salesChannelIds,
    List<int>? channelDetailIds,
    List<int>? ownerIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? generalManagerIds,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await dio.get(
        '/reserve-order/list',
        queryParameters: {
          if ((search ?? '').isNotEmpty) 'search': search,
          if (statusReserveIds != null && statusReserveIds.isNotEmpty)
            'status_reserve_id': statusReserveIds.join(','),
          if (rejected != null) 'rejected': rejected,
          if (sort != null) 'sort': sort,
          if (salesChannelIds != null && salesChannelIds.isNotEmpty)
            'sales_channel_id': salesChannelIds.join(','),
          if (channelDetailIds != null && channelDetailIds.isNotEmpty)
            'channel_detail_id': channelDetailIds.join(','),
          if (ownerIds != null && ownerIds.isNotEmpty)
            'owner_id': ownerIds.join(','),
          if (salesExecutiveIds != null && salesExecutiveIds.isNotEmpty)
            'sales_executive_id': salesExecutiveIds.join(','),
          if (salesSupervisorIds != null && salesSupervisorIds.isNotEmpty)
            'sales_supervisor_id': salesSupervisorIds.join(','),
          if (salesManagerIds != null && salesManagerIds.isNotEmpty)
            'sales_manager_id': salesManagerIds.join(','),
          if (generalManagerIds != null && generalManagerIds.isNotEmpty)
            'general_manager_id': generalManagerIds.join(','),
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.data['status'] == true) {
        return ReserveOrderListResultModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load reserve order list',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load reserve order list'));
    }
  }

  @override
  Future<ReserveOrderDetailModel> getReserveOrderDetail(
    int reserveOrderId,
  ) async {
    try {
      final response = await dio.get('/reserve-order/detail/$reserveOrderId');

      if (response.data['status'] == true) {
        return ReserveOrderDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load reserve order detail',
      );
    } on DioException catch (e) {
      throw Exception(
        getErrorMessage(e, 'Failed to load reserve order detail'),
      );
    }
  }

  @override
  Future<ReserveOrderDetailModel> updateReserveOrderCustomer(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  ) async {
    try {
      final data = <String, dynamic>{};

      params.customer?.forEach((key, value) {
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

      addDocument('ktp', params.ktp);
      addDocument('npwp', params.npwp);

      final response = await dio.post(
        '/reserve-order/update/$reserveOrderId',
        data: FormData.fromMap(data),
      );

      if (response.data['status'] == true) {
        return ReserveOrderDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to update reserve order',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to update reserve order'));
    }
  }

  @override
  Future<ReserveOrderDetailModel> topupReserveOrder(
    int reserveOrderId,
    TopupReserveOrderParams params,
  ) async {
    try {
      final data = <String, dynamic>{};

      if (params.paymentTypeId != null) {
        data['payment_type_id'] = params.paymentTypeId.toString();
      }
      if ((params.ttsType ?? '').isNotEmpty) {
        data['tts_type'] = params.ttsType;
      }
      if ((params.note ?? '').isNotEmpty) {
        data['note'] = params.note;
      }

      for (var i = 0; i < params.payments.length; i++) {
        final pay = params.payments[i];
        data['payments[$i][payment_method]'] = pay.paymentMethod;
        data['payments[$i][amount]'] = pay.amount.toString();
        if (pay.bankId != null) {
          data['payments[$i][bank_id]'] = pay.bankId.toString();
        }
        if ((pay.bankName ?? '').isNotEmpty) {
          data['payments[$i][bank_name]'] = pay.bankName;
        }
        if ((pay.cardNetwork ?? '').isNotEmpty) {
          data['payments[$i][card_network]'] = pay.cardNetwork;
        }
        if ((pay.referenceNumber ?? '').isNotEmpty) {
          data['payments[$i][reference_number]'] = pay.referenceNumber;
        }
        if (pay.referenceDate != null) {
          data['payments[$i][reference_date]'] = pay.referenceDate!
              .toIso8601String()
              .split('T')
              .first;
        }
        if (pay.proofBytes != null) {
          data['payments[$i][proof]'] = MultipartFile.fromBytes(
            pay.proofBytes!,
            filename: pay.proofFileName ?? 'proof_$i.jpg',
          );
        }
      }

      final response = await dio.post(
        '/reserve-order/topup/$reserveOrderId',
        data: FormData.fromMap(data),
      );

      if (response.data['status'] == true) {
        return ReserveOrderDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to submit reserve order topup',
      );
    } on DioException catch (e) {
      throw Exception(
        getErrorMessage(e, 'Failed to submit reserve order topup'),
      );
    }
  }

  @override
  Future<ReserveOrderDetailModel> sendReserveOrderMessage(
    int reserveOrderId,
    String message,
  ) async {
    try {
      final response = await dio.post(
        '/reserve-order/message/$reserveOrderId',
        data: FormData.fromMap({'message': message}),
      );

      if (response.data['status'] == true) {
        return ReserveOrderDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(response.data['message'] ?? 'Failed to send message');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to send message'));
    }
  }

  @override
  Future<ReserveOrderDetailModel> editReserveOrder(
    int reserveOrderId,
    EditReserveOrderParams params,
  ) async {
    try {
      final data = <String, dynamic>{
        if (params.reserveNote != null) 'reserve_note': params.reserveNote,
        if (params.caraBayarId != null)
          'cara_bayar_id': params.caraBayarId.toString(),
        if (params.propertyId != null)
          'property_id': params.propertyId.toString(),
        if (params.productId != null)
          'product_id': params.productId.toString(),
        if (params.companyId != null)
          'company_id': params.companyId.toString(),
        if ((params.propertyName ?? '').isNotEmpty)
          'property_name': params.propertyName,
      };

      final response = await dio.post(
        '/reserve-order/edit/$reserveOrderId',
        data: FormData.fromMap(data),
      );

      if (response.data['status'] == true) {
        return ReserveOrderDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data['message'] ?? 'Failed to edit reserve order',
      );
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to edit reserve order'));
    }
  }

  @override
  Future<void> deleteReserveOrder(int reserveOrderId) async {
    try {
      final response = await dio.delete('/reserve-order/$reserveOrderId');

      if (response.data['status'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to delete reserve order',
        );
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to delete reserve order'));
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
