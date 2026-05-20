import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/site_plan_repository.dart';
import 'siteplan_event.dart';
import 'siteplan_state.dart';

class SiteplanBloc extends Bloc<SiteplanEvent, SiteplanState> {
  final SitePlanRepository repository;

  SiteplanBloc(this.repository) : super(SiteplanInitial()) {
    on<LoadSiteplanEvent>((event, emit) async {
      emit(SiteplanLoading());
      try {
        final sites = await repository.getAvailableSites();
        emit(SiteplanLoaded(sites));
      } catch (e) {
        emit(SiteplanError(e.toString()));
      }
    });
  }
}
