import 'package:equatable/equatable.dart';

abstract class CustomerOptionsEvent extends Equatable {
  const CustomerOptionsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCustomerOptionsEvent extends CustomerOptionsEvent {
  const FetchCustomerOptionsEvent();
}
