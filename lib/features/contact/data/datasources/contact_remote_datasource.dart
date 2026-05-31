

import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/activity/activitty_prospect_status._model.dart';
import 'package:progress_group/features/contact/data/models/activity/activity_api_model.dart';
import 'package:progress_group/features/contact/data/models/activity/whatsapp_activity_model.dart';
import 'package:progress_group/features/contact/data/models/attachment/attachment_model.dart';
import 'package:progress_group/features/contact/data/models/attachment/attachment_type_model.dart';
import 'package:progress_group/features/contact/data/models/contact/contact_model.dart';
import 'package:progress_group/features/contact/data/models/contact/contact_property_model.dart';
import 'package:progress_group/features/contact/data/models/contact/contact_response_model.dart';
import 'package:progress_group/features/contact/data/models/dropdown/prospect_status_model.dart';
import 'package:progress_group/features/contact/data/models/info_source/info_source_model.dart';
import 'package:progress_group/features/contact/data/models/lost_reason/lost_reason_model.dart';
import 'package:progress_group/features/contact/data/models/property/property_unit_model.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_params.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';

abstract class ContactRemoteDataSource {
  Future<ContactResponseModel> getContacts({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds});

  Future<ContactModel> getContactDetail(int id);

  Future<List<InfoSourceModel>> getInfoSources({int? type});

  Future<List<ProspectStatusModel>> getProspectStatuses({String? type});
  Future<List<LostReasonModel>> getLostReasons();

  Future<List<ContactPropertyGroupModel>> getContactProperties();

  Future<ContactModel> createContact(CreateContactParams params);

  Future<void> updateContact(int id, CreateContactParams params);

  Future<void> deleteContact(int id);

  Future<ActivityResponseModel> getActivities({int? contactId, int? dealId, String? activityType, String? followUpStartDate, String? followUpEndDate, int page = 1, int perPage = 15});

  Future<void> createActivityVisit(CreateVisitParams params);

  Future<void> createActivity(CreateActivityParams params);

  Future<void> postStatusFollow(List<int> activityIds);

  Future<List<ActivityProspectStatusModel>> getActivityProspectStatus(int contactId);
  
  Future<List<WhatsappUnreadSummaryModel>> getWhatsappUnreadSummary(int contactId);

  Future<List<AttachmentTypeModel>> getAttachmentTypes();

  Future<void> uploadAttachment(UploadAttachmentParams params);

  Future<List<ContactAttachmentModel>> getAttachments({required int contactId, int? dealId});

  Future<void> deleteAttachment({required int contactId, required int attachmentId});

  Future<void> updateAttachment({required int contactId, required int attachmentId, required UploadAttachmentParams params});

  Future<List<PropertyUnitClusterModel>> getPropertyUnits({required int townshipId});
  Future<List<PropertyUnitClusterModel>> getPropertyCommercialUnits({required int townshipId});
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final Dio dio;

  ContactRemoteDataSourceImpl(this.dio);

 

  @override
  Future<ContactResponseModel> getContacts({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds}) async {
    try {
      final response = await dio.get(
        '/contacts',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
          if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
          if (ownerIds != null && ownerIds.isNotEmpty) 'sales_executive_id': ownerIds.join(','),
          if (statusProspectIds != null && statusProspectIds.isNotEmpty) 'status_prospect_id': statusProspectIds.join(','),
        },
      );

      if (response.data['status'] == true) {
        return ContactResponseModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load contacts');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load contacts'));
    }
  }

  @override
  Future<ContactModel> getContactDetail(int id) async {
    try {
      final response = await dio.get('/contacts/$id');

      if (response.data['status'] == true) {
        return ContactModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load contact details');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load contact details'));
    }
  }

  @override
  Future<List<InfoSourceModel>> getInfoSources({int? type}) async {
    try {
      final response = await dio.get(
        '/sumber-informasi',
        queryParameters: {
          if (type != null) 'type': type,
        },
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => InfoSourceModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat sumber informasi');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat sumber informasi'));
    }
  }
  
  @override
  Future<List<ProspectStatusModel>> getProspectStatuses({String? type}) async {
    try {
      final url = type != null ? '/sales/statuses/$type' : '/sales/statuses';
      final response = await dio.get(url);

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];

        return data.map((json) => ProspectStatusModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load prospect statuses');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load prospect statuses'));
    }
  }

  @override
  Future<List<LostReasonModel>> getLostReasons() async {
    try {
      final response = await dio.get('/lost-reasons');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];

        return data
            .map((json) => LostReasonModel.fromJson(json))
            .toList();
      }

      throw Exception(
          response.data['message'] ?? 'Failed to load lost reasons');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load lost reasons'));
    }
  }

  @override
  Future<List<ContactPropertyGroupModel>> getContactProperties() async {
    try {
      final response = await dio.get('/contacts/properties');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];

        return data.map((json) => ContactPropertyGroupModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load contact properties');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load contact properties'));
    }
  }

  FormData _buildFormData(CreateContactParams params) {
    final data = <String, dynamic>{};

    // Scalar contact fields
    params.toJson().forEach((key, value) {
      if (key == 'properties_json' || key == 'properties' || value == null) return;
      if (value is List || value is Map) return;
      data[key] = value;
    });

    // Build properties_json list — Dio's FormData.fromMap serializes List<Map>
    // into properties_json[0][property_id], properties_json[0][property_value], etc.
    // which is exactly what the backend service expects.
    final propertiesList = <Map<String, dynamic>>[];

    for (final entry in (params.propertiesJson ?? [])) {
      propertiesList.add({
        'property_id': entry['property_id'],
        'property_value': entry['property_value'],
      });
    }

    params.propertyFileBytes?.forEach((propId, bytes) {
      final name = params.propertyFileNames?[propId] ?? 'file';
      propertiesList.add({
        'property_id': propId,
        'property_value': MultipartFile.fromBytes(bytes, filename: name),
      });
    });

    if (propertiesList.isNotEmpty) {
      data['properties_json'] = propertiesList;
    }

    print('[FormData] data keys: ${data.keys.toList()}');
    print('[FormData] properties_json: $propertiesList');

    return FormData.fromMap(data);
  }

  Future<ContactModel> createContact(CreateContactParams params) async {
    try {
      final response = await dio.post('/contacts/create', data: _buildFormData(params));

      if (response.data['status'] == true) {
        return ContactModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create contact');
    } on DioException catch (e) {
      print("error create contact: ${e.response?.data}");
      throw Exception(getErrorMessage(e, 'Failed to create contact'));
    }
  }

  @override
  Future<void> updateContact(int id, CreateContactParams params) async {
    try {
      final response = await dio.patch('/contacts/$id', data: _buildFormData(params));

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update contact');
      }
    } on DioException catch (e) {
      print("error update contact: ${e.response?.data}");
      print("error detail: ${e.response?.data}");
      throw Exception(getErrorMessage(e, 'Failed to update contact'));
    }
  }

  @override
  Future<void> deleteContact(int id) async {
    try {
      final response = await dio.delete('/contacts/delete/$id');

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete contact');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to delete contact'));
    }
  }

  @override
  Future<ActivityResponseModel> getActivities({int? contactId, int? dealId, String? activityType, String? followUpStartDate, String? followUpEndDate, int page = 1, int perPage = 15}) async {
    try {
      final response = await dio.get(
        '/activities',
        queryParameters: {
          if (contactId != null) 'contact_id': contactId,
          if (dealId != null) 'deal_id': dealId,
          if (activityType != null) 'activity_type': activityType,
          if (followUpStartDate != null) 'follow_up_start_date': followUpStartDate,
          if (followUpEndDate != null) 'follow_up_end_date': followUpEndDate,
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.data['status'] == true) {
        return ActivityResponseModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load activities');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load activities'));
    }
  }

  @override
  Future<void> createActivityVisit(CreateVisitParams params) async {
    try {
      final formData = FormData.fromMap({
        'contact_id': params.contactId,
        'status_prospect_id': params.statusProspectId,
        'visit_count': params.visitCount,
        'activity_date': params.activityDate,
        'notes': params.notes,
        if (params.filesBytesData != null && params.filesBytesData!.isNotEmpty)
          'files[]': params.filesBytesData!
              .asMap()
              .entries
              .map((e) => MultipartFile.fromBytes(e.value, filename: 'photo_${e.key}.jpg'))
              .toList()
        else if (params.files != null && params.files!.isNotEmpty)
          'files[]': await Future.wait(
            params.files!.map((file) => MultipartFile.fromFile(file.path)).toList(),
          ),
      });

      final response = await dio.post(
        '/activities/visit',
        data: formData,
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed create visit');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed create visit'));
    }
  }

  @override
  Future<void> createActivity(CreateActivityParams params) async {
    try {
      final response = await dio.post(
        '/activities/create',
        data: params.toJson(),
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to create activity');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to create activity'));
    }
  }

  @override
  Future<void> postStatusFollow(List<int> activityIds) async {
    try {
      final response = await dio.post(
        '/activities/statusfollow',
        data: {'activity_ids': activityIds, 'status_follow': 1},
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update status follow');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to update status follow'));
    }
  }

  @override
  Future<List<ActivityProspectStatusModel>> getActivityProspectStatus(int contactId) async {
    try {
      final response = await dio.get('/activities/$contactId/status-prospect');

      if (response.data['status'] == true) {
        final List data = response.data['data'];

        return data.map((e) => ActivityProspectStatusModel.fromJson(e)).toList();
      }

      throw Exception(response.data['message'] ?? 'An error occurred');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'An error occurred'));
    }
  }

  @override
  Future<List<WhatsappUnreadSummaryModel>> getWhatsappUnreadSummary(int contactId) async {
    try {
      final response = await dio.get(
        '/whatsapp/unread-summary',
        queryParameters: {
          'contact_id': contactId,
        },
      );

      if (response.data['status'] == true) {
        final List data = response.data['data'];

        return data
            .map((e) => WhatsappUnreadSummaryModel.fromJson(e))
            .toList();
      }

      throw Exception(response.data['message'] ?? 'An error occurred');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'An error occurred'));
    }
  }

  @override
  Future<List<AttachmentTypeModel>> getAttachmentTypes() async {
    try {
      final response = await dio.get('/contacts/attachment-types');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];

        return data.map((json) => AttachmentTypeModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load attachment types');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load attachment types'));
    }
  }

  @override
  Future<void> uploadAttachment(UploadAttachmentParams params) async {
    try {
      final formData = FormData.fromMap({
        if (params.dealId != null) 'deal_id': params.dealId,
        if (params.activityId != null) 'activity_id': params.activityId,
        'attachment_type_id': params.attachmentTypeId,
        if (params.attachmentNote != null) 'attachment_note': params.attachmentNote,
        if (params.fileBytes != null)
          'file': MultipartFile.fromBytes(params.fileBytes!, filename: params.fileName ?? 'file')
        else if (params.file != null && params.file!.path.isNotEmpty)
          'file': await MultipartFile.fromFile(params.file!.path),
      });

      final response = await dio.post(
        '/contacts/${params.contactId}/attachments',
        data: formData,
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to upload attachment');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to upload attachment'));
    }
  }

  @override
  Future<List<ContactAttachmentModel>> getAttachments({required int contactId, int? dealId}) async {
    try {
      final response = await dio.get(
        '/contacts/$contactId/attachments',
        queryParameters: {
          if (dealId != null) 'deal_id': dealId,
        },
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];

        return data.map((json) => ContactAttachmentModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load attachments');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load attachments'));
    }
  }

  @override
  Future<void> deleteAttachment({required int contactId, required int attachmentId}) async {
    try {
      final response = await dio.delete('/contacts/$contactId/attachments/$attachmentId');

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete attachment');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to delete attachment'));
    }
  }

  @override
  Future<void> updateAttachment({required int contactId, required int attachmentId, required UploadAttachmentParams params}) async {
    try {
      final formData = FormData.fromMap({
        if (params.dealId != null) 'deal_id': params.dealId,
        if (params.activityId != null) 'activity_id': params.activityId,
        'attachment_type_id': params.attachmentTypeId,
        if (params.attachmentNote != null) 'attachment_note': params.attachmentNote,
        if (params.fileBytes != null)
          'file': MultipartFile.fromBytes(params.fileBytes!, filename: params.fileName ?? 'file')
        else if (params.file != null && params.file!.path.isNotEmpty)
          'file': await MultipartFile.fromFile(params.file!.path),
      });

      final response = await dio.patch(
        '/contacts/$contactId/attachments/$attachmentId',
        data: formData,
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update attachment');
      }
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to update attachment'));
    }
  }

  @override
  Future<List<PropertyUnitClusterModel>> getPropertyUnits({required int townshipId}) async {
    try {
      final response = await dio.get(
        '/property/units/cluster/$townshipId',
        queryParameters: {'page': 1, 'per_page': 100},
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data']['data'];
        return data.map((json) => PropertyUnitClusterModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      throw Exception(response.data['message'] ?? 'Gagal memuat data produk');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat data produk'));
    }
  }

  @override
  Future<List<PropertyUnitClusterModel>> getPropertyCommercialUnits({required int townshipId}) async {
    try {
      final response = await dio.get(
        '/property/units/commercial/$townshipId',
        queryParameters: {'page': 1, 'per_page': 100},
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data']['data'];
        return data.map((json) => PropertyUnitClusterModel.fromCommercialJson(json as Map<String, dynamic>)).toList();
      }

      throw Exception(response.data['message'] ?? 'Gagal memuat data produk');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat data produk'));
    }
  }
}