import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_qr_session_usecase.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


abstract class WhatsappQrEvent {}

class StartQrSessionEvent extends WhatsappQrEvent {
  final String session;
  StartQrSessionEvent(this.session);
}

class UpdateQrCodeEvent extends WhatsappQrEvent {
  final String qrBase64;
  UpdateQrCodeEvent(this.qrBase64);
}

class UpdateConnectionStatusEvent extends WhatsappQrEvent {
  final String status;
  UpdateConnectionStatusEvent(this.status);
}


abstract class WhatsappQrState {}

class WhatsappQrInitial extends WhatsappQrState {}

class WhatsappQrLoading extends WhatsappQrState {}

class WhatsappQrStreaming extends WhatsappQrState {
  final String? qrBase64;
  final String? status;
  WhatsappQrStreaming({this.qrBase64, this.status});
}

class WhatsappQrError extends WhatsappQrState {
  final String message;
  WhatsappQrError(this.message);
}


class WhatsappQrBloc extends Bloc<WhatsappQrEvent, WhatsappQrState> {
  final GetQrSessionUsecase getQrSession;
  IO.Socket? _socket;

  WhatsappQrBloc(this.getQrSession) : super(WhatsappQrInitial()) {
    on<StartQrSessionEvent>(_onStartSession);
    on<UpdateQrCodeEvent>(_onUpdateQr);
    on<UpdateConnectionStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onStartSession(StartQrSessionEvent event, Emitter<WhatsappQrState> emit) async {
    emit(WhatsappQrLoading());
    try {
      
      await getQrSession(session: event.session);
      
      
      emit(WhatsappQrStreaming());

      
      _connectSocket(event.session);
    } catch (e) {
      emit(WhatsappQrError(cleanErrorMessage(e)));
    }
  }

  void _onUpdateQr(UpdateQrCodeEvent event, Emitter<WhatsappQrState> emit) {
    if (state is WhatsappQrStreaming) {
      emit(WhatsappQrStreaming(
        qrBase64: event.qrBase64,
        status: (state as WhatsappQrStreaming).status,
      ));
    } else {
      emit(WhatsappQrStreaming(qrBase64: event.qrBase64));
    }
  }

  void _onUpdateStatus(UpdateConnectionStatusEvent event, Emitter<WhatsappQrState> emit) {
    if (state is WhatsappQrStreaming) {
      emit(WhatsappQrStreaming(
        qrBase64: (state as WhatsappQrStreaming).qrBase64,
        status: event.status,
      ));
    } else {
       emit(WhatsappQrStreaming(status: event.status));
    }
  }

  void _connectSocket(String session) {
    _socket?.disconnect();
    
    
    
    _socket = IO.io(ApiConstants.waServerURL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {});

    _socket?.on('qr', (data) {
      if (data is Map && data['sessionId'] == session) {
        String qrFull = data['qr'].toString();
        
        String cleanBase64 = qrFull.split(',').last;
        add(UpdateQrCodeEvent(cleanBase64));
      }
    });

    _socket?.on('status', (data) {
      if (data is Map && data['status'] == 'CONNECTED') {
        add(UpdateConnectionStatusEvent('CONNECTED'));
        
        
      }
    });
  }

  @override
  Future<void> close() {
    _socket?.disconnect();
    _socket?.dispose();
    return super.close();
  }
}
