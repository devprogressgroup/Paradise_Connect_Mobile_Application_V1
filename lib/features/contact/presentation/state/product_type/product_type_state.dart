import 'package:equatable/equatable.dart';

enum ProductTypeStatus { initial, loading, loaded, error }

class ProductTypeState extends Equatable {
  final ProductTypeStatus status;
  final List<String> types;
  final String? errorMessage;

  const ProductTypeState({
    this.status = ProductTypeStatus.initial,
    this.types = const [],
    this.errorMessage,
  });

  ProductTypeState copyWith({
    ProductTypeStatus? status,
    List<String>? types,
    String? errorMessage,
  }) {
    return ProductTypeState(
      status: status ?? this.status,
      types: types ?? this.types,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, types, errorMessage];
}
