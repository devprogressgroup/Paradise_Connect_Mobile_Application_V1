import 'dart:convert';

import '../../../../core/network/proxy_cipher.dart';

/// Contoh response API `/siteplan-key` (payload unit terenkripsi), dipakai
/// tombol preview site plan sebelum endpoint aslinya tersedia di app.
const String sampleEncryptedSiteplanKeyUrl =
    'https://devconnect.paradise.id/siteplan-key?=fLSZ/IglGMfqJwr8KBUOqw==:brOqClrp3c3kqU3g8ZOaj65bcGBq0MiaP7TkLzZlynxLjBPgqd8HHQ1Kjvpk2vffxN7vadn8j06EBnzOJu8kxsXcq1o2IqZ7tNZb++aSGEjuhcsLtcESUKCZMyccpHZLC/Vvp/RiqEtQiTqHyt2bH+Yyuq3hK4U0bYUDkYFOo2cZ1YXbhCd9TybQQSQ6puJBgMyPRmKtzm5sztfZT/J4spQy9e01Vhguip3J3bGnVqKD7pIB1jH3KeetIb82WQWjXA/QvrrYyu0VenJLfh26HoeWSfJsfwTDmsZOesQZRA4/bviDNhIYzb6aSf4qWpYg13FnwDjmK3Dad1sNX5oYSnnsoRlxasP0fDM8Ww76fdYXSXhQY50AYskS1neJgDNgIhsVF2ORnomazfoSoY9D2hpPQx3uPX5R0Bz0ySEJDW6bLcdfqPEP4RoxKMfNsO4SfkU30cdK3Dfx5ee//T0ty5s9v1QY0xjmQvVUQqNLHXgYLGe+6kpx1gVu3vfUmqbgJOJT8qMuEAzls3Xxi0GDyW/2xdFksfGBo/zuLFxe6wAAFXaS6pUY8dhlcJ78GV8fMn5NT1eaz+3JsW5t/Spsqw4qsEPeCQIC8ODO0KcGHTRNSpcNe2agBaZ19aujj1S+9IE5PsCCFfO3h75KCyHMxTfSVpWBAosOhmrSA0vMuQYsKKhsINk6KscaRE0jD77LI9JFMawomWMbio6Q/5InwFknzryWMaLuZKnRPf55CydjXK9Tj3O0EMr3PVRgNmM2XQj1zIirFjnunP7QW7JETujxVA+nFVuuc0R5kO/TAT25JyM8po0tucabUtd5HlegFO7yWKN5VXwdmD3OEKKJnGIQrBRvTgBO1l+BKicBZUULBxRX1WkOkcRF328nfuH16rqy/4L6Q+5BSktElo06A6iBp6xXxaIjfAVevIb5njwKdGakK5jA+QE1cvxtJ0H63rx004WhKOb6nQl7zr6V8fzANDZd5lvIn433NouDLw0DZaMU/c9dPEU1vJhD4+UrNI5F5AG4BBLSnQls5sVNOW5jrmH99OhZxAjFlKZ5xJnlzhMuRXGlrW2Z3bi1vK8s8+1BuuYK7suxqGCwZKx+u5nUH2Uc6/NzC2Go3Y+GKNgPrrnri4IFh9cCxzCYVjlgHiiPLLTn3coqCDWcZdQNHVGHjnTQJd3cWaWmsnEYKODb1e2fTK0YGQ+WXlc64rwuxxh9wE5X1Q08npX5hIQnBcWDmh2w9pxEQWOFgO26mtUHCTQI3Gp1TGQ8tk9GUPain5LLt9YJ1crTBFzKDSf2LlQ5umcM2cAC7a56tpdteBhl63nGWGKgEnzk3qLn1Y1d9RS2D6b7aPQ+bj+ckv2VtsnYnd+A7rAnqSYUi8hH8myJ1xyBC0l9qM/AeamQGiIYLxbkue3MkHKGDXQfFLsq+MdrH7d03dk00jBlQBJm9cQKY3M+Wfn2soGq326zqMZv95pzAjOKWqbWBb/xkATL7F1o9RK/pUicVMayUMutWLo=';

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

  factory UnitDetail.fromJson(Map<String, dynamic> json) {
    return UnitDetail(
      projectName: json['projects'] as String?,
      clusterName: json['cluster'] as String?,
      productName: json['product'] as String?,
      blokUnit: json['blok_unit'] as String?,
      status: json['status'] as String?,
      isSold: json['is_sold'] as bool? ?? false,
      spec: UnitSpec.fromJson(
        (json['spec'] as Map<String, dynamic>?) ?? const {},
      ),
      priceSchemes: ((json['price_schemes'] as List?) ?? const [])
          .map((e) => PriceScheme.fromJson(e as Map<String, dynamic>))
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

  UnitSpec({
    this.luasTanah,
    this.luasBangunan,
    this.kelebihanTanah,
    this.jumlahLantai,
    this.kamarTidur,
    this.kamarMandi,
  });

  factory UnitSpec.fromJson(Map<String, dynamic> json) {
    return UnitSpec(
      luasTanah: json['luas_tanah'] as num?,
      luasBangunan: json['luas_bangunan'] as num?,
      kelebihanTanah: json['kelebihan_tanah'] as num?,
      jumlahLantai: json['jumlah_lantai'] as num?,
      kamarTidur: json['kamar_tidur'] as num?,
      kamarMandi: json['kamar_mandi'] as num?,
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
  final List<Installment> installments;

  PriceScheme({
    required this.name,
    this.bank,
    this.promoName,
    this.promoPercentage,
    this.hargaSebelumPromo,
    this.harga,
    this.installments = const [],
  });

  factory PriceScheme.fromJson(Map<String, dynamic> json) {
    return PriceScheme(
      name: json['name'] as String? ?? '-',
      bank: json['bank'] as String?,
      promoName: json['promo_name'] as String?,
      promoPercentage: json['promo_percentage'] as num?,
      hargaSebelumPromo: json['harga_sebelum_promo'] as String?,
      harga: json['harga'] as String?,
      installments: ((json['installments'] as List?) ?? const [])
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
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
