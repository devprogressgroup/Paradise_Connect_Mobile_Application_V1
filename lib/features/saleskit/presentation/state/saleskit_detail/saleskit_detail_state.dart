import 'package:progress_group/features/saleskit/domain/entities/cluster_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/commercial_entity.dart';

abstract class SalesKitDetailState {}

class SalesKitDetailInitial extends SalesKitDetailState {}

class SalesKitDetailLoading extends SalesKitDetailState {}

class SalesKitDetailLoaded extends SalesKitDetailState {
  final List<ClusterEntity> clusters;
  final List<CommercialEntity> commercials;

  SalesKitDetailLoaded({required this.clusters, required this.commercials});
}

class SalesKitDetailError extends SalesKitDetailState {
  final String message;
  SalesKitDetailError(this.message);
}
