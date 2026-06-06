import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/usecases/product_type/get_product_types_usecase.dart';
import 'product_type_event.dart';
import 'product_type_state.dart';

class ProductTypeBloc extends Bloc<ProductTypeEvent, ProductTypeState> {
  final GetProductTypesUseCase getProductTypesUseCase;

  ProductTypeBloc({required this.getProductTypesUseCase}) : super(const ProductTypeState()) {
    on<FetchProductTypesEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchProductTypesEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    if (state.status == ProductTypeStatus.loaded) return;

    emit(state.copyWith(status: ProductTypeStatus.loading));

    final result = await getProductTypesUseCase();

    result.fold(
      (failure) => emit(state.copyWith(status: ProductTypeStatus.error, errorMessage: failure)),
      (data) => emit(state.copyWith(status: ProductTypeStatus.loaded, types: data)),
    );
  }
}
