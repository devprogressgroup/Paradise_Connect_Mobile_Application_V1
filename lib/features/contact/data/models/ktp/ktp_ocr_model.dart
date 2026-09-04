// Hasil OCR KTP dari backend (POST /api/reserve/ktp-ocr). Semua field nullable karena OCR bisa
// gagal baca sebagian baris — yang kosong dibiarkan kosong supaya user tinggal melengkapi manual
// di form Data Pembeli.
class KtpOcrModel {
  final String? nama;
  final String? nik;
  final String? tempatLahir;

  // Dibiarkan String (bukan DateTime) karena format dari OCR belum pasti: server mengirim
  // yyyy-MM-dd, tapi kalau nanti dipakai sumber OCR lain bisa saja format cetak KTP
  // (dd-MM-yyyy). Parsing-nya di halaman form.
  final String? tanggalLahir;

  final String? jenisKelamin;
  final String? statusPerkawinan;
  final String? agama;
  final String? pekerjaan;
  final String? alamat;
  final String? kecamatan;
  final String? kabupaten;

  const KtpOcrModel({
    this.nama,
    this.nik,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.statusPerkawinan,
    this.agama,
    this.pekerjaan,
    this.alamat,
    this.kecamatan,
    this.kabupaten,
  });

  // Kunci utamanya `cust_*` — sama dengan kolom `m_customer_reserve` / body POST /api/reserve,
  // jadi hasil OCR bisa dikirim balik ke server tanpa lapisan mapping baru. Alias bahasa
  // Indonesia/Inggris dibiarkan sebagai jaring-jaring kalau sumber OCR-nya nanti berubah.
  factory KtpOcrModel.fromJson(Map<String, dynamic> json) {
    return KtpOcrModel(
      nama: _str(json['cust_name'] ?? json['nama'] ?? json['name']),
      nik: _str(json['cust_ktp'] ?? json['nik'] ?? json['no_ktp']),
      tempatLahir: _str(json['cust_birth_place'] ?? json['tempat_lahir'] ?? json['birth_place']),
      tanggalLahir: _str(json['cust_birth_date'] ?? json['tanggal_lahir'] ?? json['tgl_lahir'] ?? json['birth_date']),
      jenisKelamin: _gender(json['cust_gender_is_male']) ?? _str(json['jenis_kelamin'] ?? json['gender']),
      statusPerkawinan: _str(json['cust_marital_status'] ?? json['status_perkawinan'] ?? json['marital_status']),
      agama: _str(json['cust_religion'] ?? json['agama'] ?? json['religion']),
      pekerjaan: _str(json['cust_occupation'] ?? json['pekerjaan'] ?? json['occupation']),
      alamat: _str(json['cust_address1'] ?? json['alamat'] ?? json['address']),
      kecamatan: _str(json['kecamatan'] ?? json['district']),
      kabupaten: _str(json['nama_kota'] ?? json['kabupaten_kota'] ?? json['kabupaten'] ?? json['kota'] ?? json['city']),
    );
  }

  // Dipakai buat bedain "OCR sukses tapi tidak kebaca apa pun" dari "OCR sukses & ada isinya".
  bool get isEmpty =>
      [nama, nik, tempatLahir, tanggalLahir, jenisKelamin, statusPerkawinan, agama, pekerjaan, alamat, kecamatan, kabupaten]
          .every((e) => e == null || e.isEmpty);

  static String? _str(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s == '-' ? null : s;
  }

  // Server mengirim jenis kelamin sebagai boolean `cust_gender_is_male` (kolom DB-nya boolean),
  // sedangkan form menampilkannya sebagai pilihan teks.
  static String? _gender(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Laki-laki' : 'Perempuan';
    if (value is num) return value == 1 ? 'Laki-laki' : 'Perempuan';
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return 'Laki-laki';
    if (s == 'false' || s == '0') return 'Perempuan';
    return null;
  }
}
