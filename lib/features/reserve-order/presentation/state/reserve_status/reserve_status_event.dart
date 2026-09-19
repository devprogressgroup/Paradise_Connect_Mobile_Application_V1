import 'package:equatable/equatable.dart';

abstract class ReserveStatusEvent extends Equatable {
  const ReserveStatusEvent();

  @override
  List<Object?> get props => [];
}

class FetchReserveStatusesEvent extends ReserveStatusEvent {
  const FetchReserveStatusesEvent();
}
