import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _toText(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

class VirtualAccountModel extends VirtualAccountEntity {
  const VirtualAccountModel({
    super.bankId,
    required super.bankName,
    super.virtualAccountTitle,
    super.kodeBiller,
    super.virtualAccountNumber,
    required super.virtualAccountFull,
  });

  factory VirtualAccountModel.fromJson(Map<String, dynamic> json) {
    final kodeBiller = _toText(json['kode_biller']);
    final number = _toText(json['virtual_account_number']);
    return VirtualAccountModel(
      bankId: _toInt(json['bank_id']),
      bankName: _toText(json['bank_name']) ?? '',
      virtualAccountTitle: _toText(json['virtual_account_title']),
      kodeBiller: kodeBiller,
      virtualAccountNumber: number,
      // Nomor tetap String — jangan di-parse ke angka (nol di depan & 16 digit).
      virtualAccountFull:
          _toText(json['virtual_account_full']) ??
          '${kodeBiller ?? ''}${number ?? ''}',
    );
  }
}

class PropertyVirtualAccountModel extends PropertyVirtualAccountEntity {
  const PropertyVirtualAccountModel({
    super.townshipId,
    super.townshipName,
    super.companyId,
    super.companyName,
    super.propertyId,
    super.propertyName,
    super.virtualAccounts,
  });

  factory PropertyVirtualAccountModel.fromJson(Map<String, dynamic> json) {
    final rawAccounts = json['virtual_accounts'];
    return PropertyVirtualAccountModel(
      townshipId: _toInt(json['township_id']),
      townshipName: _toText(json['township_name']),
      companyId: _toInt(json['company_id']),
      companyName: _toText(json['company_name']),
      propertyId: _toInt(json['property_id']),
      propertyName: _toText(json['property_name']),
      virtualAccounts: rawAccounts is List
          ? rawAccounts
                .whereType<Map>()
                .map(
                  (e) => VirtualAccountModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .where((va) => va.virtualAccountFull.isNotEmpty)
                .toList()
          : const [],
    );
  }
}
