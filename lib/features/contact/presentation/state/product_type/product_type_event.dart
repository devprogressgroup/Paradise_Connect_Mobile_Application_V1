import 'package:equatable/equatable.dart';

abstract class ProductTypeEvent extends Equatable {
  const ProductTypeEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductTypesEvent extends ProductTypeEvent {
  const FetchProductTypesEvent();
}
