import 'package:equatable/equatable.dart';

abstract class LostReasonEvent extends Equatable {
  const LostReasonEvent();

  @override
  List<Object?> get props => [];
}

class FetchLostReasonsEvent extends LostReasonEvent {
  final String? type; 

  const FetchLostReasonsEvent({this.type});

  @override
  List<Object?> get props => [type ?? ''];
}