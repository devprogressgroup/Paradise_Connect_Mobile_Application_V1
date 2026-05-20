abstract class SalesKitDetailEvent {}

class LoadSalesKitDetailEvent extends SalesKitDetailEvent {
  final int townshipId;
  LoadSalesKitDetailEvent(this.townshipId);
}
