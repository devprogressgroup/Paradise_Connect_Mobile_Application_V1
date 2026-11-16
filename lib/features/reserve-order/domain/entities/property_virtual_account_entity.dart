import 'package:equatable/equatable.dart';

/// Satu Virtual Account unit — item `data.virtual_accounts[]` dari `GET /property/virtual-account`.
///
/// Nomor VA disimpan sebagai String, JANGAN di-parse ke angka: bisa diawali nol dan
/// [virtualAccountFull] panjangnya 16 digit.
class VirtualAccountEntity extends Equatable {
  final int? bankId;
  final String bankName;
  final String? virtualAccountTitle;
  final String? kodeBiller;
  final String? virtualAccountNumber;

  /// Nomor lengkap yang ditampilkan/dibayarkan (kode biller + nomor VA).
  final String virtualAccountFull;

  const VirtualAccountEntity({
    this.bankId,
    required this.bankName,
    this.virtualAccountTitle,
    this.kodeBiller,
    this.virtualAccountNumber,
    required this.virtualAccountFull,
  });

  @override
  List<Object?> get props => [
    bankId,
    bankName,
    virtualAccountTitle,
    kodeBiller,
    virtualAccountNumber,
    virtualAccountFull,
  ];
}

/// `data` dari `GET /property/virtual-account?township_id=&company_id=&property_id=`.
class PropertyVirtualAccountEntity extends Equatable {
  final int? townshipId;
  final String? townshipName;
  final int? companyId;
  final String? companyName;
  final int? propertyId;
  final String? propertyName;
  final List<VirtualAccountEntity> virtualAccounts;

  const PropertyVirtualAccountEntity({
    this.townshipId,
    this.townshipName,
    this.companyId,
    this.companyName,
    this.propertyId,
    this.propertyName,
    this.virtualAccounts = const [],
  });

  @override
  List<Object?> get props => [
    townshipId,
    townshipName,
    companyId,
    companyName,
    propertyId,
    propertyName,
    virtualAccounts,
  ];
}

/// Gagal memuat `GET /property/virtual-account`. [errorCode] = `error_code` body gagal
/// (`VA_NOT_FOUND`, `UNIT_NOT_FOUND`, `VALIDATION`, `AMBIGUOUS_UNIT`); null kalau gagal
/// jaringan/timeout atau respons tidak dikenal.
class VirtualAccountFailure extends Equatable {
  final String message;
  final String? errorCode;

  const VirtualAccountFailure(this.message, {this.errorCode});

  /// Unit ada tapi belum punya Virtual Account (404 `VA_NOT_FOUND`).
  bool get isNotFound => errorCode == 'VA_NOT_FOUND';

  @override
  List<Object?> get props => [message, errorCode];
}
