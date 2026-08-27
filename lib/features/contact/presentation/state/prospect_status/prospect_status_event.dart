import 'package:equatable/equatable.dart';

abstract class ProspectStatusEvent extends Equatable {
  const ProspectStatusEvent();

  @override
  List<Object> get props => [];
}

class FetchProspectStatusesEvent extends ProspectStatusEvent {
  final String? type;
  final int? contactId;

  const FetchProspectStatusesEvent({this.type, this.contactId});

  @override
  List<Object> get props => [type ?? '', contactId ?? 0];
}
