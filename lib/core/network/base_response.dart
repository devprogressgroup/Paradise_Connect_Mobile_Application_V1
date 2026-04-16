class BaseResponse<T> {
  final bool status;
  final String message;
  final T? data;
  final dynamic errors;

  BaseResponse({
    required this.status,
    required this.message,
    this.data,
    this.errors,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return BaseResponse<T>(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'],
    );
  }
}