import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ReserveOrderCustomerData {
  final Map<String, dynamic> raw;

  const ReserveOrderCustomerData({this.raw = const {}});

  String? _text(String key) {
    final v = raw[key];
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  String? get nama => _text('cust_name');
  String? get hp => _text('cust_telp_mobile1');
  String? get salesChannel => _text('sales_channel');
  String? get salesChannelDetail => _text('sales_channel_detail');
}
enum ReserveCustomerFieldKind { text, date, boolChoice, option }

class ReserveCustomerFieldSpec {
  final String key;
  final String label;
  final ReserveCustomerFieldKind kind;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool numeric;

  final String? trueLabel;
  final String? falseLabel;

  final List<String>? options;

  const ReserveCustomerFieldSpec({
    required this.key,
    required this.label,
    this.kind = ReserveCustomerFieldKind.text,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.numeric = false,
    this.trueLabel,
    this.falseLabel,
    this.options,
  });
}

class ReserveCustomerFieldSection {
  final String title;
  final List<ReserveCustomerFieldSpec> fields;

  const ReserveCustomerFieldSection({required this.title, required this.fields});
}


String? displayValueFor(ReserveCustomerFieldSpec field, Map<String, dynamic> raw) {
  final value = raw[field.key];
  switch (field.kind) {
    case ReserveCustomerFieldKind.date:
      if (value == null) return null;
      final date = DateTime.tryParse('$value');
      return date == null ? '$value' : DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    case ReserveCustomerFieldKind.boolChoice:
      if (value == true) return field.trueLabel;
      if (value == false) return field.falseLabel;
      return null;
    case ReserveCustomerFieldKind.text:
    case ReserveCustomerFieldKind.option:
      if (value == null) return null;
      final text = '$value'.trim();
      return text.isEmpty ? null : text;
  }
}
const List<String> roMaritalStatusItems = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];
const List<String> roReligionItems = ['ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA', 'KONGHUCU'];
const List<String> reserveWorkCategoryItems = ['Wiraswasta', 'Pegawai', 'Profesional'];
const List<String> reserveCaraBayarItems = ['KPR', 'Cash Keras', 'Cash Bertahap', 'Lainnya'];
const List<ReserveCustomerFieldSection> reserveCustomerFieldSections = [
  ReserveCustomerFieldSection(title: 'Data Pembeli', fields: [
    ReserveCustomerFieldSpec(key: 'cust_name', label: 'Nama Lengkap (sesuai KTP)', hint: 'Nama sesuai KTP'),
    ReserveCustomerFieldSpec(key: 'cust_ktp', label: 'No. KTP', hint: 'NIK 16 digit', keyboardType: TextInputType.number),
    ReserveCustomerFieldSpec(key: 'cust_npwp', label: 'No. NPWP', hint: '00.000.000.0-000.000'),
    ReserveCustomerFieldSpec(key: 'cust_birth_place', label: 'Tempat Lahir', hint: 'Jakarta'),
    ReserveCustomerFieldSpec(key: 'cust_birth_date', label: 'Tanggal Lahir', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec(key: 'cust_gender_is_male',label: 'Jenis Kelamin',kind: ReserveCustomerFieldKind.boolChoice,trueLabel: 'Laki-laki',falseLabel: 'Perempuan',),
    ReserveCustomerFieldSpec(key: 'cust_marital_status',label: 'Status Pernikahan',kind: ReserveCustomerFieldKind.option,options: roMaritalStatusItems),
    ReserveCustomerFieldSpec(key: 'work_category',label: 'Kategori Pekerjaan',kind: ReserveCustomerFieldKind.option,options: reserveWorkCategoryItems),
    ReserveCustomerFieldSpec(key: 'cust_occupation', label: 'Pekerjaan', hint: 'Wiraswasta'),
    ReserveCustomerFieldSpec(key: 'cara_bayar_name',label: 'Cara Pembarayan',kind: ReserveCustomerFieldKind.option,options: reserveCaraBayarItems),
    ReserveCustomerFieldSpec(key: 'cust_religion', label: 'Agama', kind: ReserveCustomerFieldKind.option, options: roReligionItems),
    ReserveCustomerFieldSpec(key: 'cust_education', label: 'Pendidikan', hint: 'S1'),
    ReserveCustomerFieldSpec(key: 'cust_telp_home', label: 'Telepon Rumah', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_telp_home2', label: 'Telepon Rumah 2', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_telp_mobile1', label: 'No. HP 1', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_telp_mobile2', label: 'No. HP 2', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_telp_mobile3', label: 'No. HP 3', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_email1', label: 'Email 1', keyboardType: TextInputType.emailAddress),
    ReserveCustomerFieldSpec(key: 'cust_email2', label: 'Email 2', keyboardType: TextInputType.emailAddress),
  ]),
  ReserveCustomerFieldSection(title: 'Calon Pasangan', fields: [
    ReserveCustomerFieldSpec(key: 'spouse_name', label: 'Nama Pasangan'),
    ReserveCustomerFieldSpec(key: 'spouse_birth_place', label: 'Tempat Lahir Pasangan'),
    ReserveCustomerFieldSpec(key: 'spouse_birth_date', label: 'Tanggal Lahir Pasangan', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec(key: 'spouse_email', label: 'Email Pasangan', keyboardType: TextInputType.emailAddress),
    ReserveCustomerFieldSpec(key: 'spouse_telp_mobile', label: 'No. HP Pasangan', keyboardType: TextInputType.phone),
  ]),
  ReserveCustomerFieldSection(title: 'Data Anak', fields: [
    ReserveCustomerFieldSpec(key: 'child1_name', label: 'Nama Anak 1'),
    ReserveCustomerFieldSpec(key: 'child2_name', label: 'Nama Anak 2'),
    ReserveCustomerFieldSpec(key: 'child3_name', label: 'Nama Anak 3'),
    ReserveCustomerFieldSpec(key: 'child4_name', label: 'Nama Anak 4'),
  ]),
  ReserveCustomerFieldSection(title: 'Kontak Darurat (Tidak Tinggal Bersama)', fields: [
    ReserveCustomerFieldSpec(key: 'em_contact_name', label: 'Nama Kontak'),
    ReserveCustomerFieldSpec(key: 'em_hubungan', label: 'Hubungan'),
    ReserveCustomerFieldSpec(key: 'em_hp1', label: 'Telepon 1', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'em_hp2', label: 'Telepon 2', keyboardType: TextInputType.phone),
  ]),
  ReserveCustomerFieldSection(title: 'Data Alamat Pembeli', fields: [
    ReserveCustomerFieldSpec(key: 'cust_address1', label: 'Alamat (sesuai KTP)', hint: 'mis. Nama Jalan No. 1…', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'cust_area', label: 'Kode Area (sesuai KTP)', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'nama_kota', label: 'Kota (sesuai KTP)'),
    ReserveCustomerFieldSpec(key: 'postal_code', label: 'Kode Pos (sesuai KTP)', keyboardType: TextInputType.number),
    ReserveCustomerFieldSpec(key: 'current_address_similar_ktp',label: 'Sama dengan Alamat KTP?',kind: ReserveCustomerFieldKind.boolChoice,trueLabel: 'Ya',falseLabel: 'Tidak',),
    ReserveCustomerFieldSpec(key: 'current_address', label: 'Alamat Saat Ini', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'current_area', label: 'Kode Area Saat Ini', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'current_city', label: 'Kota Saat Ini'),
    ReserveCustomerFieldSpec(key: 'current_postal_code', label: 'Kode Pos Saat Ini', keyboardType: TextInputType.number),
    ReserveCustomerFieldSpec(key: 'mailing_address', label: 'Alamat Surat-Menyurat', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'mailing_area', label: 'Kode Area Surat-Menyurat', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'mailing_city', label: 'Kota Surat-Menyurat'),
    ReserveCustomerFieldSpec(key: 'mailing_postal_code', label: 'Kode Pos Surat-Menyurat', keyboardType: TextInputType.number),
  ]),
  ReserveCustomerFieldSection(title: 'Alamat Calon Pasangan (Pembeli Bersama)', fields: [
    ReserveCustomerFieldSpec(key: 'mate_name', label: 'Nama'),
    ReserveCustomerFieldSpec(key: 'mate_telp_mobile', label: 'No. HP', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'mate_birth_place', label: 'Tempat Lahir'),
    ReserveCustomerFieldSpec(key: 'mate_birth_date', label: 'Tanggal Lahir', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec(key: 'mate_email', label: 'Email', keyboardType: TextInputType.emailAddress),
    ReserveCustomerFieldSpec(key: 'mate_ktp_address', label: 'Alamat KTP', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'mate_ktp_area', label: 'Kode Area KTP', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'mate_ktp_city', label: 'Kota KTP'),
    ReserveCustomerFieldSpec(key: 'mate_ktp_postal_code', label: 'Kode Pos KTP', keyboardType: TextInputType.number),
    ReserveCustomerFieldSpec(key: 'mate_current_address', label: 'Alamat Saat Ini', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'mate_current_area', label: 'Kode Area Saat Ini', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'mate_current_city', label: 'Kota Saat Ini'),
    ReserveCustomerFieldSpec(key: 'mate_current_postal_code', label: 'Kode Pos Saat Ini', keyboardType: TextInputType.number),
    ReserveCustomerFieldSpec(key: 'mate_mailing_address', label: 'Alamat Surat-Menyurat', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'mate_mailing_area', label: 'Kode Area Surat-Menyurat', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'mate_mailing_city', label: 'Kota Surat-Menyurat'),
    ReserveCustomerFieldSpec(key: 'mate_mailing_postal_code', label: 'Kode Pos Surat-Menyurat', keyboardType: TextInputType.number),
  ]),
  ReserveCustomerFieldSection(title: 'Data Pekerjaan Pembeli', fields: [
    ReserveCustomerFieldSpec(key: 'cust_company_name', label: 'Nama Perusahaan'),
    ReserveCustomerFieldSpec(key: 'cust_office_building', label: 'Gedung Kantor'),
    ReserveCustomerFieldSpec(key: 'cust_work_address', label: 'Alamat Kantor', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'work_area', label: 'Kode Area Kantor', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'cust_work_city', label: 'Kota Kantor'),
    ReserveCustomerFieldSpec(key: 'cust_telp_work', label: 'Telepon Kantor', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_telp_work2', label: 'Telepon Kantor 2', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_work_fax', label: 'Fax Kantor', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'cust_job_title', label: 'Jabatan'),
    ReserveCustomerFieldSpec(key: 'cust_income', label: 'Penghasilan Bulanan', hint: 'Rp 0', keyboardType: TextInputType.number, numeric: true),
  ]),
  ReserveCustomerFieldSection(title: 'Data Pekerjaan Calon Pasangan', fields: [
    ReserveCustomerFieldSpec(key: 'spouse_occupation', label: 'Pekerjaan'),
    ReserveCustomerFieldSpec(key: 'spouse_company_name', label: 'Nama Perusahaan'),
    ReserveCustomerFieldSpec(key: 'spouse_office_building', label: 'Gedung Kantor'),
    ReserveCustomerFieldSpec(key: 'spouse_work_address', label: 'Alamat Kantor', maxLines: 2),
    ReserveCustomerFieldSpec(key: 'spouse_area', label: 'Kode Area Kantor', kind: ReserveCustomerFieldKind.option, options: []),
    ReserveCustomerFieldSpec(key: 'spouse_work_city', label: 'Kota Kantor'),
    ReserveCustomerFieldSpec(key: 'spouse_telp_work', label: 'Telepon Kantor', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'spouse_work_fax', label: 'Fax Kantor', keyboardType: TextInputType.phone),
    ReserveCustomerFieldSpec(key: 'spouse_job_title', label: 'Jabatan'),
    ReserveCustomerFieldSpec(key: 'spouse_income', label: 'Penghasilan Bulanan', hint: 'Rp 0', keyboardType: TextInputType.number, numeric: true),
  ]),
];
