import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/inbox/domain/entities/whatsapp_device_entity.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_whatsapp_devices_usecase.dart';


abstract class WhatsappDeviceEvent {}
class GetWhatsappDevicesEvent extends WhatsappDeviceEvent {}


abstract class WhatsappDeviceState {}
class WhatsappDeviceInitial extends WhatsappDeviceState {}
class WhatsappDeviceLoading extends WhatsappDeviceState {}
class WhatsappDeviceLoaded extends WhatsappDeviceState {
  final List<WhatsappDevice> devices;
  WhatsappDeviceLoaded(this.devices);
}
class WhatsappDeviceError extends WhatsappDeviceState {
  final String message;
  WhatsappDeviceError(this.message);
}


class WhatsappDeviceBloc extends Bloc<WhatsappDeviceEvent, WhatsappDeviceState> {
  final GetWhatsappDevicesUsecase getDevices;

  WhatsappDeviceBloc(this.getDevices) : super(WhatsappDeviceInitial()) {
    on<GetWhatsappDevicesEvent>((event, emit) async {
      emit(WhatsappDeviceLoading());
      try {
        final devices = await getDevices();
        emit(WhatsappDeviceLoaded(devices));
      } catch (e) {
        emit(WhatsappDeviceError(cleanErrorMessage(e)));
      }
    });
  }
}
