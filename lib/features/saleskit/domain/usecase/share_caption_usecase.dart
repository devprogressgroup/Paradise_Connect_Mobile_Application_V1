import '../repositories/saleskit_repository.dart';

class ShareCaptionUseCase {
  final SalesKitRepository repository;
  ShareCaptionUseCase(this.repository);

  Future<void> call(int captionId) => repository.shareCaption(captionId);
}
