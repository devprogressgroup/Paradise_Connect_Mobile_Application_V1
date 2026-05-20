import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_clusters_usecase.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_commercials_usecase.dart';
import 'saleskit_detail_event.dart';
import 'saleskit_detail_state.dart';

class SalesKitDetailBloc extends Bloc<SalesKitDetailEvent, SalesKitDetailState> {
  final GetClustersUseCase getClustersUseCase;
  final GetCommercialsUseCase getCommercialsUseCase;

  SalesKitDetailBloc({
    required this.getClustersUseCase,
    required this.getCommercialsUseCase,
  }) : super(SalesKitDetailInitial()) {
    on<LoadSalesKitDetailEvent>((event, emit) async {
      emit(SalesKitDetailLoading());
      try {
        final clusterFuture = getClustersUseCase(event.townshipId);
        final commercialFuture = getCommercialsUseCase(event.townshipId);
        final clusters = await clusterFuture;
        final commercials = await commercialFuture;
        emit(SalesKitDetailLoaded(clusters: clusters, commercials: commercials));
      } catch (e) {
        emit(SalesKitDetailError(e.toString()));
      }
    });
  }
}
