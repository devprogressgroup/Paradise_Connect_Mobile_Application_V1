import '../../../domain/entities/contact/contact_response.dart';
import 'contact_model.dart';

class ContactResponseModel extends ContactResponse {
  const ContactResponseModel({
    required super.currentPage,
    super.currentPageUrl,
    required super.data,
    super.firstPageUrl,
    super.from,
    super.nextPageUrl,
    super.path,
    super.perPage,
    super.prevPageUrl,
    super.to,
    super.total,
  });

  factory ContactResponseModel.fromJson(Map<String, dynamic> json) {
    return ContactResponseModel(
      currentPage: json['current_page'] ?? 1,
      currentPageUrl: json['current_page_url'],
      data: json['data'] != null
          ? List<ContactModel>.from(
              (json['data'] as List).map((x) => ContactModel.fromJson(x)))
          : [],
      firstPageUrl: json['first_page_url'],
      from: json['from'] != null ? int.tryParse(json['from'].toString()) : null,
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page']?.toString(),
      prevPageUrl: json['prev_page_url'],
      to: json['to'] != null ? int.tryParse(json['to'].toString()) : null,
      total: json['total'] != null ? int.tryParse(json['total'].toString()) : null,
    );
  }
}
