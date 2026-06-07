import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import '../../../domain/usecases/attachment/get_attachments.dart';
import 'attachment_state.dart';
import '../../../domain/usecases/attachment/delete_attachment_usecase.dart';

class AttachmentCubit extends Cubit<AttachmentState> {
  final GetAttachments getAttachments;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;

  AttachmentCubit(this.getAttachments, this.deleteAttachmentUseCase) : super(AttachmentInitial());

  void reset() => emit(AttachmentInitial());

  Future<void> fetch(int contactId, int? dealId) async {
    emit(AttachmentLoading());

    try {
      final data = await getAttachments(
        contactId: contactId,
        dealId: dealId,
      );
      data.fold(
        (failure) => emit(AttachmentError(failure)),
        (attachments) => emit(AttachmentLoaded(attachments)),
      );
    } catch (e) {
      emit(AttachmentError(cleanErrorMessage(e)));
    }
  }

  Future<void> delete({required int contactId, required int attachmentId, int? dealId}) async {
    try {
      await deleteAttachmentUseCase.call(contactId: contactId, attachmentId: attachmentId,);
      await fetch(contactId, dealId);
    } catch (e) {
      emit(AttachmentError(cleanErrorMessage(e)));
    }
  }
}