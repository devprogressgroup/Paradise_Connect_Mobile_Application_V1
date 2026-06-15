import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/update_attachment_usecase.dart';
import '../../../domain/usecases/attachment/upload_attachment_usecase.dart';
import 'upload_attachment_event.dart';
import 'upload_attachment_state.dart';



class UploadAttachmentBloc extends Bloc<UploadAttachmentEvent, UploadAttachmentState> {
  final UploadAttachmentUseCase uploadUseCase;
  final UpdateAttachmentUseCase updateUseCase;

  UploadAttachmentBloc(this.uploadUseCase, this.updateUseCase)
      : super(UploadAttachmentInitial()) {
    on<SubmitAttachmentEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitAttachmentEvent event,
    Emitter<UploadAttachmentState> emit,
  ) async {
    debugPrint('[UploadAttachmentBloc] _onSubmit isUpdate=${event.attachmentId != null} attachmentId=${event.attachmentId} contactId=${event.params.contactId}');
    emit(UploadAttachmentLoading());

    final result = event.attachmentId == null ? await uploadUseCase(event.params): await updateUseCase(contactId: event.params.contactId,attachmentId: event.attachmentId!,params: event.params);

    result.fold(
      (error) {
        debugPrint('[UploadAttachmentBloc] error: $error');
        emit(UploadAttachmentError(error));
      },
      (_) {
        debugPrint('[UploadAttachmentBloc] success');
        emit(UploadAttachmentSuccess());
      },
    );
  }
}