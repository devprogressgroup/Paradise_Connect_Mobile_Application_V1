import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/notif/data/datasources/global_notification_remote_datasource.dart';
import 'global_notification_state.dart';

class GlobalNotificationCubit extends Cubit<GlobalNotificationState> {
  final GlobalNotificationRemoteDataSource dataSource;

  GlobalNotificationCubit(this.dataSource) : super(const GlobalNotificationState());

  Future<void> load() async {
    emit(state.copyWith(status: GlobalNotificationStatus.loading, error: null));
    try {
      final items = await dataSource.getNotifications(page: 1, perPage: 50);
      emit(state.copyWith(status: GlobalNotificationStatus.loaded, items: items));
    } catch (e) {
      emit(state.copyWith(status: GlobalNotificationStatus.error, error: cleanErrorMessage(e)));
    }
  }
}
