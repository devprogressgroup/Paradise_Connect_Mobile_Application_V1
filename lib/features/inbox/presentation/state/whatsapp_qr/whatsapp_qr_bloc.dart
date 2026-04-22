import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_qr_session_usecase.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Events
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

// States
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

// Bloc
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
      // 1. Trigger session via API (usecase kamu sudah siap pakai token!)
      await getQrSession(session: event.session);
      
      // 2. Tampilkan Stream Kosong sambil menunggu Socket
      emit(WhatsappQrStreaming());

      // 3. Connect ke Socket.IO
      print("Socket.IO Connecting to: ${ApiConstants.waServerURL}");
      _connectSocket(event.session);
    } catch (e) {
      emit(WhatsappQrError(e.toString()));
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
    
    // PENTING: waServerURL di ApiConstants WAJIB berupa http://192.168.8.21:3000
    // JANGAN GUNAKAN localhost atau 127.0.0.1 
    _socket = IO.io(ApiConstants.waServerURL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {
      print('Socket terhubung untuk session: $session');
    });

    _socket?.on('qr', (data) {
      print('Menerima Socket QR event');
      if (data is Map && data['sessionId'] == session) {
        String qrFull = data['qr'].toString();
        // Buang 'data:image/png;base64,' agar sisa string Base64 murni
        String cleanBase64 = qrFull.split(',').last;
        add(UpdateQrCodeEvent(cleanBase64));
      }
    });

    _socket?.on('status', (data) {
      print('Menerima Socket Status Event: $data');
      if (data is Map && data['status'] == 'CONNECTED') {
        add(UpdateConnectionStatusEvent('CONNECTED'));
        // Optional: otomatis putuskan socket jika udah sukses sambung
        // _socket?.disconnect(); 
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
