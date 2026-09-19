import 'package:equatable/equatable.dart';

abstract class SelectUnitEvent extends Equatable {
  const SelectUnitEvent();

  @override
  List<Object?> get props => [];
}

class FetchSelectUnitEvent extends SelectUnitEvent {
  final int contactId;
  final int townshipId;

  const FetchSelectUnitEvent({
    required this.contactId,
    required this.townshipId,
  });

  @override
  List<Object?> get props => [contactId, townshipId];
}

class ResetSelectUnitEvent extends SelectUnitEvent {
  const ResetSelectUnitEvent();
}
