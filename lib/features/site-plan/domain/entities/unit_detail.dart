import 'dart:convert';

import '../../../../core/network/proxy_cipher.dart';

class UnitDetail {
  final String? projectName;
  final String? clusterName;
  final String? productName;
  final String? blokUnit;
  final String? status;
  final bool isSold;
  final UnitSpec spec;
  final List<PriceScheme> priceSchemes;

  UnitDetail({
    this.projectName,
    this.clusterName,
    this.productName,
    this.blokUnit,
    this.status,
    this.isSold = false,
    required this.spec,
    this.priceSchemes = const [],
  });

  /// Backend pakai "-" sebagai placeholder "tidak ada data" untuk field string
  /// (cluster/product/is_sold/dst) — dianggap sama dengan tidak ada nilai.
  static String? _cleanStr(dynamic v) => (v is String && v.isNotEmpty && v != '-') ? v : null;

  factory UnitDetail.fromJson(Map<String, dynamic> json) {
    return UnitDetail(
      projectName: _cleanStr(json['projects']),
      clusterName: _cleanStr(json['cluster']),
      productName: _cleanStr(json['product']),
      blokUnit: _cleanStr(json['blok_unit']),
      status: _cleanStr(json['status']),
      isSold: json['is_sold'] is bool ? json['is_sold'] as bool : false,
      // Kalau unit belum punya spec, backend balikin array kosong `[]` alih-alih object.
      spec: UnitSpec.fromJson(
        json['spec'] is Map<String, dynamic> ? json['spec'] as Map<String, dynamic> : const {},
      ),
      priceSchemes: ((json['price_schemes'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => PriceScheme.fromJson(e))
          .toList(),
    );
  }

  /// Decrypt url dari endpoint `/siteplan-key`, formatnya:
  /// `https://.../siteplan-key?=<ivBase64>:<ciphertextBase64>`
  static UnitDetail? fromEncryptedKeyUrl(String url) {
    final json = decryptKeyUrlToJson(url);
    return json == null ? null : UnitDetail.fromJson(json);
  }

  /// Sama seperti [fromEncryptedKeyUrl], tapi mengembalikan Map mentah
  /// (dipakai kalau cuma butuh datanya, tanpa langsung jadi [UnitDetail]).
  static Map<String, dynamic>? decryptKeyUrlToJson(String url) {
    final markerIndex = url.indexOf('?=');
    if (markerIndex == -1) return null;
    return decryptPayload(url.substring(markerIndex + 2));
  }

  /// Decrypt payload mentah `ivBase64:ciphertextBase64` (tanpa url pembungkus),
  /// dipakai untuk baca payload dari query string App Link `/link/{hash}?=...`
  /// (lihat [AppRouter] — hash cuma dipakai buat resolve target halaman,
  /// payload unit ikut nebeng di query aslinya, tidak lewat endpoint resolve).
  static Map<String, dynamic>? decryptPayload(String rawIvCiphertext) {
    final plain = ProxyCipher.decryptString(rawIvCiphertext);
    if (plain == null) return null;

    try {
      return jsonDecode(plain) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class UnitSpec {
  final num? luasTanah;
  final num? luasBangunan;
  final num? kelebihanTanah;
  final num? jumlahLantai;
  final num? kamarTidur;
  final num? kamarMandi;
  final num? jumlahCarport;

  UnitSpec({
    this.luasTanah,
    this.luasBangunan,
    this.kelebihanTanah,
    this.jumlahLantai,
    this.kamarTidur,
    this.kamarMandi,
    this.jumlahCarport,
  });

  factory UnitSpec.fromJson(Map<String, dynamic> json) {
    return UnitSpec(
      luasTanah: json['luas_tanah'] as num?,
      luasBangunan: json['luas_bangunan'] as num?,
      kelebihanTanah: json['kelebihan_tanah'] as num?,
      jumlahLantai: json['jumlah_lantai'] as num?,
      kamarTidur: json['kamar_tidur'] as num?,
      kamarMandi: json['kamar_mandi'] as num?,
      jumlahCarport: json['jumlah_carport'] as num?,
    );
  }
}

class PriceScheme {
  final String name;
  final String? bank;
  final String? promoName;
  final num? promoPercentage;
  final String? hargaSebelumPromo;
  final String? harga;
  final int? tenor;
  final List<Installment> installments;
  // Varian per-bank dari skema yang sama (mis. "KPR" punya beberapa promo bank: BCA, Mandiri,
  // dst) — tiap entrinya bentuknya SAMA seperti PriceScheme lain (name/bank/promo_name/
  // promo_percentage/harga/installments), makanya di-parse rekursif lewat fromJson yang sama.
  final List<PriceScheme> promo;

  PriceScheme({
    required this.name,
    this.bank,
    this.promoName,
    this.promoPercentage,
    this.hargaSebelumPromo,
    this.harga,
    this.tenor,
    this.installments = const [],
    this.promo = const [],
  });

  factory PriceScheme.fromJson(Map<String, dynamic> json) {
    return PriceScheme(
      name: json['name'] as String? ?? '-',
      bank: json['bank'] as String?,
      promoName: json['promo_name'] as String?,
      promoPercentage: json['promo_percentage'] as num?,
      hargaSebelumPromo: json['harga_sebelum_promo'] as String?,
      harga: json['harga'] as String?,
      tenor: json['tenor'] as int?,
      installments: ((json['installments'] as List?) ?? const [])
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList(),
      promo: ((json['promo'] as List?) ?? const [])
          .map((e) => PriceScheme.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Installment {
  final String name;
  final String total;

  Installment({required this.name, required this.total});

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      name: json['name'] as String? ?? '-',
      total: json['total'] as String? ?? '-',
    );
  }
}
