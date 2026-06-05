import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_landing_page_url_usecase.dart';
import 'landing_page_state.dart';

class LandingPageCubit extends Cubit<LandingPageState> {
  final GetLandingPageUrlUseCase getLandingPageUrlUseCase;

  LandingPageCubit(this.getLandingPageUrlUseCase) : super(LandingPageInitial());

  Future<void> fetchUrl() async {
    emit(LandingPageLoading());
    try {
      final url = await getLandingPageUrlUseCase();
      emit(LandingPageLoaded(_ensureProtocol(url)));
    } catch (e) {
      emit(LandingPageError(e.toString()));
    }
  }

  String _ensureProtocol(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }
}
