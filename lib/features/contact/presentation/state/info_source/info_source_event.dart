import 'package:equatable/equatable.dart';

abstract class InfoSourceEvent extends Equatable {
  const InfoSourceEvent();

  @override
  List<Object> get props => [];
}

class FetchInfoSourcesEvent extends InfoSourceEvent {
  final int? type;
  final int? userId;
  final String? salesChannel;
  final bool all;
  const FetchInfoSourcesEvent({this.type, this.userId, this.salesChannel, this.all = false});

  @override
  List<Object> get props => [type ?? 0, userId ?? 0, salesChannel ?? '', all];
}

class FetchSalesChannelDetailsEvent extends InfoSourceEvent {
  const FetchSalesChannelDetailsEvent();
}

class ResetInfoSourcesEvent extends InfoSourceEvent {
  final List<int> types;
  const ResetInfoSourcesEvent(this.types);

  @override
  List<Object> get props => [types];
}