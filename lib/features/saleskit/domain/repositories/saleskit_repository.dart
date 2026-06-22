import 'package:progress_group/features/saleskit/data/datasources/saleskit_remote_datasource.dart';
import 'package:progress_group/features/saleskit/data/models/cluster_model.dart';
import 'package:progress_group/features/saleskit/data/models/commercial_model.dart';
import 'package:progress_group/features/saleskit/data/models/township_model.dart';
import '../entities/cluster_entity.dart';
import '../entities/commercial_entity.dart';
import '../entities/township_entity.dart';

abstract class SalesKitRepository {
  Future<List<TownshipEntity>> getTownships();
  Future<List<TownshipEntity>> getTownshipsSalesKit();
  Future<List<ClusterEntity>> getClusters(int townshipId);
  Future<List<CommercialEntity>> getCommercials(int townshipId);
}

class SalesKitRepositoryImpl implements SalesKitRepository {
  final SalesKitRemoteDataSource remoteDataSource;
  SalesKitRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TownshipEntity>> getTownships() async {
    final result = await remoteDataSource.getTownships();
    return result.map((e) => TownshipModel.fromJson(e)).toList();
  }

  @override
  Future<List<TownshipEntity>> getTownshipsSalesKit() async {
    final result = await remoteDataSource.getTownshipsSalesKit();
    return result.map((e) => TownshipModel.fromJson(e)).toList();
  }

  @override
  Future<List<ClusterEntity>> getClusters(int townshipId) async {
    final result = await remoteDataSource.getClusters(townshipId);
    return result.map((e) => ClusterModel.fromJson(e)).toList();
  }

  @override
  Future<List<CommercialEntity>> getCommercials(int townshipId) async {
    final result = await remoteDataSource.getCommercials(townshipId);
    return result.map((e) => CommercialModel.fromJson(e)).toList();
  }
}
