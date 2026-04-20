import 'package:progress_group/features/inbox/data/datasources/inbox_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/models/inbox_contact_model.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/inbox/domain/repositories/inbox_contact_repository.dart';

import '../../../../core/network/base_response.dart';

class InboxContactRepositoryImpl implements InboxContactRepository {
  final InboxContactRemoteDataSource remoteDataSource;

  InboxContactRepositoryImpl(this.remoteDataSource);

  @override
  Future<(List<InboxContact> contacts, List<InboxContact> groups)> getContacts({
    String? search,
    int? cPage,
    int? gPage,
  }) async {
    final result = await remoteDataSource.getInboxContacts(
      search: search,
      cPage: cPage,
      gPage: gPage,
    );

    final response = BaseResponse<Map<String, dynamic>>.fromJson(
      result,
      (data) => data,
    );

    if (!response.status) {
      throw Exception(response.message);
    }

    final data = response.data!;

    final contactsList = (data["contact_list"] as List? ?? [])
        .map((e) => InboxContactModel.fromJson(e))
        .toList();
    final groupsList = (data["group_list"] as List? ?? [])
        .map((e) => InboxContactModel.fromJson(e))
        .toList();

    return (contactsList, groupsList);
  }
}