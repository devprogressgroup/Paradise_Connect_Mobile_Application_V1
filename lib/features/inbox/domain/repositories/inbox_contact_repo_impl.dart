import 'package:progress_group/features/inbox/data/datasources/inbox_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/models/inbox_contact_model.dart';
import 'package:progress_group/features/inbox/data/models/whatsapp_device_model.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/inbox/domain/entities/whatsapp_device_entity.dart';
import 'package:progress_group/features/inbox/domain/repositories/inbox_contact_repository.dart';

import '../../../../core/network/base_response.dart';

class InboxContactRepositoryImpl implements InboxContactRepository {
  final InboxContactRemoteDataSource remoteDataSource;

  InboxContactRepositoryImpl(this.remoteDataSource);

  @override
  Future<(List<InboxContact> contacts, List<InboxContact> groups)> getContacts({String? search,int? cPage,int? gPage}) async {
    final result = await remoteDataSource.getInboxContacts(search: search,cPage: cPage,gPage: gPage);

    final response = BaseResponse<Map<String, dynamic>>.fromJson(result,(data) => data,);

    if (!response.status) {
      throw Exception(response.message);
    }

    final data = response.data!;

    final contactsList = (data["contact_list"] as List? ?? []).map((e) => InboxContactModel.fromJson(e)).toList();
    final groupsList = (data["group_list"] as List? ?? []).map((e) => InboxContactModel.fromJson(e)).toList();

    return (contactsList, groupsList);
  }

  @override
  Future<List<WhatsappDevice>> getWhatsappDevices() async {
    final result = await remoteDataSource.getWhatsappDevices();

    final response = BaseResponse<Map<String, dynamic>>.fromJson(result, (data) => data);

    if (!response.status) {
      throw Exception(response.message);
    }

    final data = response.data!;
    final List<dynamic> devicesData = data["data"] is Map ? (data["data"]["data"] as List? ?? []) : (data["data"] as List? ?? []);
    
    return devicesData.map((e) {
      final model = WhatsappDeviceModel.fromJson(e);
      return WhatsappDevice(
        id: model.whatsappNumberId,
        whatsappNumber: model.whatsappNumber,
        status: model.status,
        isActive: model.isActive,
        fullName: model.user?.fullName,
        sessionCode: model.sessionCode,
      );
    }).toList();
  }

  @override
  Future<void> getQrSession({required String session}) async {
    final result = await remoteDataSource.getQrSession(session: session);
    
    final response = BaseResponse<Map<String, dynamic>>.fromJson(result, (data) => data);

    if (!response.status) {
      throw Exception(response.message);
    }
  }
}