import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_prospect_status.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import 'package:progress_group/features/contact/domain/entities/activity/whatsapp_activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_type.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/domain/entities/lost_reason/lost_reason_entity.dart';
import 'package:progress_group/features/contact/domain/entities/pameran/pameran_aktif_entity.dart';
import 'package:progress_group/features/contact/domain/entities/property/property_unit_entity.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import '../entities/activity/activity_entity.dart';
import '../entities/contact/contact_entity.dart';
import '../entities/contact/contact_response.dart';
import '../entities/activity/create_activity_params.dart';
import '../entities/prospect/prospect_status.dart';
import '../entities/contact/create_contact_params.dart';
import '../entities/contact/contact_property.dart';
import 'contact_repository.dart';
import '../../data/datasources/contact_remote_datasource.dart';
import '../entities/attachment/upload_attachment_params.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;

  ContactRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, ContactResponse>> getContacts({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds, List<int>? salesChannelIds, List<int>? salesTeamIds, List<int>? salesExecutiveIds, List<int>? salesSupervisorIds, List<int>? salesManagerIds, List<int>? salesGeneralManagerIds, String? apptStartDate, String? apptEndDate, String? visitStartDate, String? visitEndDate, String? reserveStartDate, String? reserveEndDate, String? spStartDate, String? spEndDate, String? sort}) async {
    try {
      final result = await remoteDataSource.getContacts(
        page: page,
        perPage: perPage,
        search: search,
        startDate: startDate,
        endDate: endDate,
        ownerIds: ownerIds,
        statusProspectIds: statusProspectIds,
        salesChannelIds: salesChannelIds,
        salesTeamIds: salesTeamIds,
        salesExecutiveIds: salesExecutiveIds,
        salesSupervisorIds: salesSupervisorIds,
        salesManagerIds: salesManagerIds,
        salesGeneralManagerIds: salesGeneralManagerIds,
        apptStartDate: apptStartDate,
        apptEndDate: apptEndDate,
        visitStartDate: visitStartDate,
        visitEndDate: visitEndDate,
        reserveStartDate: reserveStartDate,
        reserveEndDate: reserveEndDate,
        spStartDate: spStartDate,
        spEndDate: spEndDate,
        sort: sort,
      );
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ContactEntity>>> getAllContactsForDuplicateCheck() async {
    try {
      final result = await remoteDataSource.getAllContactsForDuplicateCheck();
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ContactEntity>> getContactDetail(int id) async {
    try {
      final result = await remoteDataSource.getContactDetail(id);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ContactEntity?>> checkDuplicateContact({required int ownerId, required String phone}) async {
    try {
      final result = await remoteDataSource.checkDuplicateContact(ownerId: ownerId, phone: phone);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<InfoSource>>> getInfoSources({int? type, int? userId, String? salesChannel}) async {
    try {
      final result = await remoteDataSource.getInfoSources(type: type, userId: userId, salesChannel: salesChannel);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ProspectStatusEntity>>> getProspectStatuses({String? type}) async {
    try {
      final result = await remoteDataSource.getProspectStatuses(type: type);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<LostReasonEntity>>> getLostReasons() async {
    try {
      final result = await remoteDataSource.getLostReasons();
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
  
  @override
  Future<Either<String, List<ContactPropertyGroup>>> getContactProperties() async {
    try {
      final result = await remoteDataSource.getContactProperties();
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ContactEntity>> createContact(CreateContactParams params) async {
    try {
      final result = await remoteDataSource.createContact(params);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ContactEntity>> updateContact(int id, CreateContactParams params) async {
    try {
      final result = await remoteDataSource.updateContact(id, params);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteContact(int id) async {
    try {
      await remoteDataSource.deleteContact(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ActivityEntity>>> getActivities({int? contactId, int? dealId, String? activityType, String? followUpStartDate, String? followUpEndDate, int page = 1,}) async {
    try {
      final result = await remoteDataSource.getActivities(
        contactId: contactId,
        dealId: dealId,
        activityType: activityType,
        followUpStartDate: followUpStartDate,
        followUpEndDate: followUpEndDate,
        page: page,
      );
      return Right(result.activities);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> createActivityVisit(CreateVisitParams params) async {
    try {
      await remoteDataSource.createActivityVisit(params);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> createActivity(  CreateActivityParams params) async {
    try {
      await remoteDataSource.createActivity(params);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> postStatusFollow(List<int> activityIds) async {
    try {
      await remoteDataSource.postStatusFollow(activityIds);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ActivityProspectStatusEntity>>> getActivityProspectStatus(int contactId) async {
    try {
      final result = await remoteDataSource.getActivityProspectStatus(contactId);

      return Right(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<WhatsappUnreadSummaryEntity>>> getWhatsappUnreadSummary(int contactId) async {
    try {
      final result = await remoteDataSource.getWhatsappUnreadSummary(contactId);

      return Right(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<AttachmentType>>> getAttachmentTypes() async {
    try {
      final result = await remoteDataSource.getAttachmentTypes();
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> uploadAttachment(UploadAttachmentParams params) async {
    try {
      await remoteDataSource.uploadAttachment(params);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ContactAttachment>>> getAttachments({required int contactId,int? dealId,}) async {
    try {
      final result = await remoteDataSource.getAttachments(contactId: contactId,dealId: dealId);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteAttachment({required int contactId,required int attachmentId,}) async {
    try {
      await remoteDataSource.deleteAttachment(
        contactId: contactId,
        attachmentId: attachmentId,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either<String, void>> updateAttachment({  required int contactId,  required int attachmentId,  required UploadAttachmentParams params,}) async {
    try {
      await remoteDataSource.updateAttachment(
        contactId: contactId,
        attachmentId: attachmentId,
        params: params,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<PropertyUnitCluster>>> getPropertyUnits({required int townshipId}) async {
    try {
      final result = await remoteDataSource.getPropertyUnits(townshipId: townshipId);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<PropertyUnitCluster>>> getPropertyCommercialUnits({required int townshipId}) async {
    try {
      final result = await remoteDataSource.getPropertyCommercialUnits(townshipId: townshipId);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<UnitCluster>>> getUnitHierarchy({required int townshipId, String? search}) async {
    try {
      return Right(await remoteDataSource.getUnitHierarchy(townshipId: townshipId, search: search));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<UnitLot>>> getUnitLots({required int productId, int? townshipId, int? companyId, String? search}) async {
    try {
      return Right(await remoteDataSource.getUnitLots(productId: productId, townshipId: townshipId, companyId: companyId, search: search));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<PameranAktifEntity>>> getPameranAktif({String? lokasiPameran, int? userId}) async {
    try {
      final result = await remoteDataSource.getPameranAktif(lokasiPameran: lokasiPameran, userId: userId);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<String>>> getProductTypes() async {
    try {
      final result = await remoteDataSource.getProductTypes();
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

}
