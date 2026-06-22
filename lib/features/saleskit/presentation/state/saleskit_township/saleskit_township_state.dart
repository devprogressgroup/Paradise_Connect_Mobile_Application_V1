import 'package:progress_group/features/saleskit/domain/entities/township_entity.dart';

abstract class SalesKitTownshipState {}

class SalesKitTownshipInitial extends SalesKitTownshipState {}

class SalesKitTownshipLoading extends SalesKitTownshipState {}

class SalesKitTownshipLoaded extends SalesKitTownshipState {
  final List<TownshipEntity> townships;
  SalesKitTownshipLoaded(this.townships);
}

class SalesKitTownshipError extends SalesKitTownshipState {
  final String message;
  SalesKitTownshipError(this.message);
}
