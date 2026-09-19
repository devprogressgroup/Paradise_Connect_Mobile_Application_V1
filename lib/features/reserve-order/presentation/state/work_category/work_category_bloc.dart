import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_work_category_usecase.dart';
import 'work_category_event.dart';
import 'work_category_state.dart';

class WorkCategoryBloc extends Bloc<WorkCategoryEvent, WorkCategoryState> {
  final GetWorkCategoryUseCase getWorkCategoryUseCase;

  WorkCategoryBloc({required this.getWorkCategoryUseCase})
    : super(const WorkCategoryState()) {
    on<FetchWorkCategoryEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchWorkCategoryEvent event,
    Emitter<WorkCategoryState> emit,
  ) async {
    emit(state.copyWith(status: WorkCategoryStatus.loading));

    final result = await getWorkCategoryUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(status: WorkCategoryStatus.error, errorMessage: failure),
      ),
      (data) =>
          emit(state.copyWith(status: WorkCategoryStatus.loaded, items: data)),
    );
  }
}
