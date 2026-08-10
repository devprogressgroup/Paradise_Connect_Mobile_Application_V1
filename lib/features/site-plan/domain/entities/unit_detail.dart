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
