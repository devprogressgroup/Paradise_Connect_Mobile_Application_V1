

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import 'package:progress_group/features/contact/data/models/pameran/pameran_aktif_model.dart';
import 'package:progress_group/features/contact/data/models/property/property_unit_model.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_params.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';

abstract class ContactRemoteDataSource {
  Future<ContactResponseModel> getContacts({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds, List<int>? salesChannelIds, List<int>? salesTeamIds, String? apptStartDate, String? apptEndDate, String? visitStartDate, String? visitEndDate, String? reserveStartDate, String? reserveEndDate, String? spStartDate, String? spEndDate});

  Future<List<ContactModel>> getAllContactsForDuplicateCheck();

  Future<ContactModel> getContactDetail(int id);

  Future<ContactModel?> checkDuplicateContact({required int ownerId, required String phone});

  Future<List<InfoSourceModel>> getInfoSources({int? type});

  Future<List<ProspectStatusModel>> getProspectStatuses({String? type});
  Future<List<LostReasonModel>> getLostReasons();

  Future<List<ContactPropertyGroupModel>> getContactProperties();

  Future<ContactModel> createContact(CreateContactParams params);

  Future<ContactModel> updateContact(int id, CreateContactParams params);

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

  
  Future<List<UnitCluster>> getUnitHierarchy({required int townshipId, String? search});
  Future<List<UnitLot>> getUnitLots({required int productId, int? townshipId, int? companyId, String? search});
  Future<List<PameranAktifModel>> getPameranAktif({String? lokasiPameran});
  Future<List<String>> getProductTypes();
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final Dio dio;

  ContactRemoteDataSourceImpl(this.dio);

 

  @override
  Future<ContactResponseModel> getContacts({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds, List<int>? salesChannelIds, List<int>? salesTeamIds, String? apptStartDate, String? apptEndDate, String? visitStartDate, String? visitEndDate, String? reserveStartDate, String? reserveEndDate, String? spStartDate, String? spEndDate}) async {
    try {
      final response = await dio.get(
        '/contacts',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
          if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
          if (ownerIds != null && ownerIds.isNotEmpty) 'owner_id': ownerIds.join(','),
          if (statusProspectIds != null && statusProspectIds.isNotEmpty) 'status_prospect_id': statusProspectIds.join(','),
          if (salesChannelIds != null && salesChannelIds.isNotEmpty) 'sales_channel_id': salesChannelIds.join(','),
          if (salesTeamIds != null && salesTeamIds.isNotEmpty) 'sales_team_id': salesTeamIds.join(','),
          if (apptStartDate != null && apptStartDate.isNotEmpty) 'appt_start_date': apptStartDate,
          if (apptEndDate != null && apptEndDate.isNotEmpty) 'appt_end_date': apptEndDate,
          if (visitStartDate != null && visitStartDate.isNotEmpty) 'visit_start_date': visitStartDate,
          if (visitEndDate != null && visitEndDate.isNotEmpty) 'visit_end_date': visitEndDate,
          if (reserveStartDate != null && reserveStartDate.isNotEmpty) 'reserve_start_date': reserveStartDate,
          if (reserveEndDate != null && reserveEndDate.isNotEmpty) 'reserve_end_date': reserveEndDate,
          if (spStartDate != null && spStartDate.isNotEmpty) 'sp_start_date': spStartDate,
          if (spEndDate != null && spEndDate.isNotEmpty) 'sp_end_date': spEndDate,
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
  Future<List<ContactModel>> getAllContactsForDuplicateCheck() async {
    try {
      final response = await dio.get('/contacts');

      if (response.data['status'] == true) {
        final List<dynamic> list = response.data['data']?['data'] ?? [];
        return list.map((json) => ContactModel.fromJson(json)).toList();
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
  Future<ContactModel?> checkDuplicateContact({required int ownerId, required String phone}) async {
    try {
      final response = await dio.get(
        '/contacts/check-duplicate',
        queryParameters: {'owner_id': ownerId, 'phone': phone},
      );

      debugPrint('[checkDuplicateContact] response: ${response.data}');

      if (response.data['status'] == true) {
        final data = response.data['data'];
        return data == null ? null : ContactModel.fromJson(data);
      }

      throw Exception(response.data['message'] ?? 'Gagal memeriksa duplikat kontak');
    } on DioException catch (e) {
      debugPrint('[checkDuplicateContact] error status: ${e.response?.statusCode}, body: ${e.response?.data}');
      throw Exception(getErrorMessage(e, 'Gagal memeriksa duplikat kontak'));
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

    
    params.toJson().forEach((key, value) {
      if (key == 'properties_json' || key == 'properties' || value == null) return;
      if (value is List || value is Map) return;
      data[key] = value;
    });

    
    
    
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

    return FormData.fromMap(data);
  }

  Future<ContactModel> createContact(CreateContactParams params) async {
    try {
      debugPrint('[createContact] request body: ${jsonEncode(params.toJson())}');
      final response = await dio.post('/contacts/create', data: _buildFormData(params));

      if (response.data['status'] == true) {
        return ContactModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create contact');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to create contact'));
    }
  }

  @override
  Future<ContactModel> updateContact(int id, CreateContactParams params) async {
    try {
      final hasFiles = params.propertyFileBytes?.isNotEmpty == true;
      debugPrint('[updateContact] request body: ${jsonEncode(params.toJson())}');
      final response = await dio.patch(
        '/contacts/$id',
        data: hasFiles ? _buildFormData(params) : params.toJson(),
      );

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update contact');
      }
      return ContactModel.fromJson(response.data['data']);
    } on DioException catch (e) {
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
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('contact_id', params.contactId.toString()),
        MapEntry('status_prospect_id', params.statusProspectId.toString()),
        MapEntry('visit_count', params.visitCount.toString()),
        MapEntry('activity_date', params.activityDate),
        MapEntry('notes', params.notes),
      ]);

      if (params.filesBytesData != null && params.filesBytesData!.isNotEmpty) {
        for (var i = 0; i < params.filesBytesData!.length; i++) {
          formData.files.add(MapEntry(
            'files[]',
            MultipartFile.fromBytes(params.filesBytesData![i], filename: 'photo_$i.jpg'),
          ));
        }
      } else if (params.files != null && params.files!.isNotEmpty) {
        for (var i = 0; i < params.files!.length; i++) {
          formData.files.add(MapEntry(
            'files[]',
            await MultipartFile.fromFile(params.files![i].path, filename: 'photo_$i.jpg'),
          ));
        }
      }

      
      
      
      
      

      final response = await dio.post(
        '/activities/visit',
        data: formData,
        options: Options(extra: {'skipEncryption': true}),
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

  Future<String> _toBase64(UploadAttachmentParams params) async {
    if (params.fileBytes != null) return base64Encode(params.fileBytes!);
    if (params.file != null) return base64Encode(await params.file!.readAsBytes());
    return '';
  }

  String _mimeType(String? fileName) {
    final ext = (fileName ?? '').split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png'           => 'image/png',
      'gif'           => 'image/gif',
      'webp'          => 'image/webp',
      'pdf'           => 'application/pdf',
      'mp4'           => 'video/mp4',
      _               => 'application/octet-stream',
    };
  }

  @override
  Future<void> uploadAttachment(UploadAttachmentParams params) async {
    try {
      
      if (params.filesBytesList != null && params.filesBytesList!.isNotEmpty) {
        final filesDataUris = <String>[];
        final fileNamesArray = <String>[];

        for (int i = 0; i < params.filesBytesList!.length; i++) {
          final bytes = params.filesBytesList![i];
          final fileName = params.fileNames != null && i < params.fileNames!.length
              ? params.fileNames![i]
              : 'file_$i';
          final mimeType = _mimeType(fileName);
          filesDataUris.add('data:$mimeType;base64,${base64Encode(bytes)}');
          fileNamesArray.add(fileName);
        }

        final body = <String, dynamic>{
          if (params.dealId != null) 'deal_id': params.dealId,
          if (params.activityId != null) 'activity_id': params.activityId,
          'attachment_type_id': params.attachmentTypeId,
          if (params.attachmentNote != null) 'attachment_note': params.attachmentNote,
          'files': filesDataUris,
          'file_names': fileNamesArray,
        };

        final response = await dio.post('/contacts/${params.contactId}/attachments', data: body);
        if (response.data['status'] != true) {
          throw Exception(response.data['message'] ?? 'Failed to upload attachments');
        }
        return;
      }

      
      final fileBase64 = await _toBase64(params);
      final body = <String, dynamic>{
        if (params.dealId != null) 'deal_id': params.dealId,
        if (params.activityId != null) 'activity_id': params.activityId,
        'attachment_type_id': params.attachmentTypeId,
        if (params.attachmentNote != null) 'attachment_note': params.attachmentNote,
        if (fileBase64.isNotEmpty) ...{
          'file_base64': fileBase64,
          'mime_type': _mimeType(params.fileName),
          'file_name': params.fileName ?? 'file',
        },
      };

      final response = await dio.post(
        '/contacts/${params.contactId}/attachments',
        data: body,
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
      

      final fileBase64 = await _toBase64(params);
      final body = <String, dynamic>{
        if (params.dealId != null) 'deal_id': params.dealId,
        if (params.activityId != null) 'activity_id': params.activityId,
        'attachment_type_id': params.attachmentTypeId,
        if (params.attachmentNote != null) 'attachment_note': params.attachmentNote,
        if (fileBase64.isNotEmpty) ...{
          'file_base64': fileBase64,
          'mime_type': _mimeType(params.fileName),
          'file_name': params.fileName ?? 'file',
        },
      };

      

      final response = await dio.patch(
        '/contacts/$contactId/attachments/$attachmentId',
        data: body,
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

  @override
  Future<List<UnitCluster>> getUnitHierarchy({required int townshipId, String? search}) async {
    try {
      final response = await dio.get('/property/units/hierarchy', queryParameters: {
        'township_id': townshipId,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data']['data'] ?? [];
        return data.map((j) => UnitCluster.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat hierarki unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat hierarki unit'));
    }
  }

  @override
  Future<List<UnitLot>> getUnitLots({required int productId, int? townshipId, int? companyId, String? search}) async {
    try {
      final response = await dio.get('/property/units/hierarchy', queryParameters: {
        'product_id': productId,
        
        if ((townshipId ?? 0) != 0) 'township_id': townshipId,
        if ((companyId ?? 0) != 0) 'company_id': companyId,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data']['lots'] ?? [];
        return data.map((j) => UnitLot.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat kavling');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat kavling'));
    }
  }

  @override
  Future<List<PameranAktifModel>> getPameranAktif({String? lokasiPameran}) async {
    try {
      final response = await dio.get(
        '/pameran/aktif',
        queryParameters: {
          if (lokasiPameran != null && lokasiPameran.isNotEmpty) 'lokasi_pameran': lokasiPameran,
        },
      );

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PameranAktifModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat data pameran aktif'));
    }
  }

  @override
  Future<List<String>> getProductTypes() async {
    try {
      final response = await dio.get('/sales/product-types');
      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat product types'));
    }
  }

}