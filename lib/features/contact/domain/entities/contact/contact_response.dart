import 'package:equatable/equatable.dart';
import 'contact_entity.dart';

class ContactResponse extends Equatable {
  final int currentPage;
  final String? currentPageUrl;
  final List<ContactEntity> data;
  final String? firstPageUrl;
  final int? from;
  final String? nextPageUrl;
  final String? path;
  final String? perPage;
  final String? prevPageUrl;
  final int? to;

  const ContactResponse({
    required this.currentPage,
    this.currentPageUrl,
    required this.data,
    this.firstPageUrl,
    this.from,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
  });

  @override
  List<Object?> get props => [
        currentPage,
        currentPageUrl,
        data,
        firstPageUrl,
        from,
        nextPageUrl,
        path,
        perPage,
        prevPageUrl,
        to,
      ];
}
