import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_response.dart';
import '../../repositories/contact_repository.dart';

class GetContactsUseCase {
  final ContactRepository repository;

  GetContactsUseCase(this.repository);

  Future<Either<String, ContactResponse>> call({int page = 1, int perPage = 10, String? search, String? startDate, String? endDate, List<int>? ownerIds, List<int>? statusProspectIds, List<int>? salesChannelIds, List<int>? salesChannelDetailIds, List<int>? salesTeamIds, List<int>? salesExecutiveIds, List<int>? salesSupervisorIds, List<int>? salesManagerIds, List<int>? salesGeneralManagerIds, String? apptStartDate, String? apptEndDate, String? visitStartDate, String? visitEndDate, String? reserveStartDate, String? reserveEndDate, String? spStartDate, String? spEndDate, String? lostStartDate, String? lostEndDate, String? lastProject, String? sort}) {
    return repository.getContacts(
      page: page,
      perPage: perPage,
      search: search,
      startDate: startDate,
      endDate: endDate,
      ownerIds: ownerIds,
      statusProspectIds: statusProspectIds,
      salesChannelIds: salesChannelIds,
      salesChannelDetailIds: salesChannelDetailIds,
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
      lostStartDate: lostStartDate,
      lostEndDate: lostEndDate,
      lastProject: lastProject,
      sort: sort,
    );
  }
}
