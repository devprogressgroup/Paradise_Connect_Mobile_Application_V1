import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import '../../domain/usecases/get_landing_page_url_usecase.dart';
import 'landing_page_state.dart';

class LandingPageCubit extends Cubit<LandingPageState> {
  final GetLandingPageUrlUseCase getLandingPageUrlUseCase;

  LandingPageCubit(this.getLandingPageUrlUseCase) : super(LandingPageInitial());

  Future<void> fetchUrl({String? username, String? roleName}) async {
    emit(LandingPageLoading());
    try {
      final url = await getLandingPageUrlUseCase();
      final result = _injectUserParams(_ensureProtocol(url), username, roleName);
      debugPrint('[LandingPage] URL: $result');
      emit(LandingPageLoaded(result));
    } catch (e) {
      emit(LandingPageError(cleanErrorMessage(e)));
    }
  }

  String _ensureProtocol(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  String _injectUserParams(String url, String? username, String? roleName) {
    if (username == null && roleName == null) return url;
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);
      if (username != null && username.isNotEmpty) params['user'] = username;
      if (roleName != null && roleName.isNotEmpty) params['role'] = roleName;
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }
}
