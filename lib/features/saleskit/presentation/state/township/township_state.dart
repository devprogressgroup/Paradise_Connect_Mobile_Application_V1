import 'package:progress_group/features/saleskit/domain/entities/township_entity.dart';

abstract class TownshipState {}

class TownshipInitial extends TownshipState {}

class TownshipLoading extends TownshipState {}

class TownshipLoaded extends TownshipState {
  final List<TownshipEntity> townships;
  TownshipLoaded(this.townships);
}

class TownshipError extends TownshipState {
  final String message;
  TownshipError(this.message);
}
