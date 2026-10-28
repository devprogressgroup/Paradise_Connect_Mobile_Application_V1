import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';

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

/// [option] = dropdown yang opsinya dari API (GET /reserve-order/customer-options, lihat
/// [CustomerOptionsEntity]) — tidak ada daftar opsi tetap di app.
enum ReserveCustomerFieldKind { text, date, boolChoice, option }

class ReserveCustomerFieldSpec {
  final String key;
  final String label;
  final ReserveCustomerFieldKind kind;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  /// Nominal (Rupiah) — tampil "Rp 3.000.000" kalau nilainya di luar daftar opsi.
  final bool numeric;

  final String? trueLabel;
  final String? falseLabel;

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
  });
}

class ReserveCustomerFieldSection {
  /// Judul grup — ":pasangan" diganti Istri / Suami / Calon Pasangan ([titleFor]).
  final String title;
  final List<ReserveCustomerFieldSpec> fields;

  const ReserveCustomerFieldSection({
    required this.title,
    required this.fields,
  });

  String titleFor(Map<String, dynamic> raw) =>
      title.replaceAll(':pasangan', partnerTitle(raw));
}

/// Nilai tampil 1 field — dropdown tampil label opsinya dari [options] (mis. nama Wilayah Area,
/// rentang Penghasilan), nominal di luar opsi tampil format Rupiah. Sama dgn backend
/// CustomerReserveFields::displayValue().
String? displayValueFor(
  ReserveCustomerFieldSpec field,
  Map<String, dynamic> raw, {
  CustomerOptionsEntity options = const CustomerOptionsEntity(),
}) {
  final value = raw[field.key];
  switch (field.kind) {
    case ReserveCustomerFieldKind.date:
      if (value == null) return null;
      final date = DateTime.tryParse('$value');
      return date == null
          ? '$value'
          : DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    case ReserveCustomerFieldKind.boolChoice:
      if (value == true) return field.trueLabel;
      if (value == false) return field.falseLabel;
      return null;
    case ReserveCustomerFieldKind.text:
    case ReserveCustomerFieldKind.option:
      if (value == null) return null;
      final text = '$value'.trim();
      if (text.isEmpty) return null;
      final match = options.match(field.key, text);
      if (match != null) return match.label;
      final number = field.numeric ? num.tryParse(text) : null;
      return number == null ? text : 'Rp ${NumberHelper.thousands(number)}';
  }
}

/// Nilai Status Pernikahan "Sudah Menikah" — SAMA dgn Paradise Dynamics & backend
/// CustomerReserveFields::MARRIED_STATUS; status ini yang mewajibkan Nama Pasangan. Opsinya (label +
/// nilai SINGLE / KAWIN / TUNANGAN / Lainnya) dari GET /reserve-order/customer-options.
const String roMarriedStatus = 'KAWIN';

/// Pilihan Status Pernikahan yang memunculkan isian bebas (yang disimpan isiannya).
const String roMaritalOther = 'Lainnya';

/// Samakan nilai lama / hasil OCR KTP ("BELUM KAWIN", "KAWIN", "Sudah Menikah", …) ke nilai dropdown
/// Status Pernikahan (sama dgn backend CustomerReserveFields::normalizeMaritalStatus()); selain itu
/// (mis. "CERAI HIDUP") = [roMaritalOther]. null = kosong.
String? normalizeMaritalStatus(String raw) {
  final s = raw.trim().toUpperCase();
  if (s.isEmpty) return null;
  if (s == 'SINGLE' || s.contains('BELUM')) return 'SINGLE';
  if (s.contains('TUNANG')) return 'TUNANGAN';
  if (s.contains('MENIKAH') || s.contains('KAWIN')) return roMarriedStatus;
  return roMaritalOther;
}

/// Alamat "Sekarang" yang mengikuti alamat KTP selama "Sama dengan Alamat KTP?" = Ya — key sekarang
/// → key KTP. SAMA dgn backend MCustomerReserve::CURRENT_ADDRESS_FROM_KTP (yang juga menyalinnya
/// tiap disimpan).
const Map<String, String> roCurrentAddressFromKtp = {
  'current_address': 'cust_address1',
  'current_area': 'cust_area',
  'current_city': 'nama_kota',
  'current_postal_code': 'postal_code',
};

/// Sebutan pasangan di judul grup — SAMA dgn web (CustomerReserveFields::partnerTitle()) &
/// Paradise Dynamics: menikah + laki-laki = Istri, menikah + perempuan = Suami, selain itu =
/// Calon Pasangan.
String partnerTitle(Map<String, dynamic> raw) {
  final status = '${raw['cust_marital_status'] ?? ''}'.trim().toUpperCase();
  final married = const {'SUDAH MENIKAH', 'MENIKAH', 'KAWIN'}.contains(status);
  final male = raw['cust_gender_is_male'];
  if (!married || male == null) return 'Calon Pasangan';
  return (male == true || male == 1 || male == '1') ? 'Istri' : 'Suami';
}

/// Grup & label "Data Customer" — SAMA dgn web (backend CustomerReserveFields::SECTIONS) yang
/// mengikuti form Master Customer Paradise Dynamics.
const List<ReserveCustomerFieldSection> reserveCustomerFieldSections = [
  ReserveCustomerFieldSection(
    title: 'Data Pembeli',
    fields: [
      ReserveCustomerFieldSpec(
        key: 'cust_name',
        label: 'Nama Pemesan (sesuai KTP)',
        hint: 'Nama sesuai KTP',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_ktp',
        label: 'Nomor KTP Pemesan',
        hint: 'NIK 16 digit',
        keyboardType: TextInputType.number,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_npwp',
        label: 'Nomor NPWP Pemesan',
        hint: '00.000.000.0-000.000',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_birth_place',
        label: 'Tempat Lahir',
        hint: 'Jakarta',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_birth_date',
        label: 'Tgl Lahir',
        kind: ReserveCustomerFieldKind.date,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_address1',
        label: 'Alamat (KTP)',
        hint: 'mis. Nama Jalan No. 1…',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_gender_is_male',
        label: 'Jenis Kelamin',
        kind: ReserveCustomerFieldKind.boolChoice,
        trueLabel: 'Laki-laki',
        falseLabel: 'Perempuan',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_marital_status',
        label: 'Marital Status',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'work_category',
        label: 'Kategori Pekerjaan',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_occupation',
        label: 'Pekerjaan',
        hint: 'Wiraswasta',
      ),
      ReserveCustomerFieldSpec(
        key: 'cara_bayar_name',
        label: 'Cara Pembayaran',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_religion',
        label: 'Agama',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_education',
        label: 'Pendidikan',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_home',
        label: 'Tlp. Rumah 1',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_home2',
        label: 'Tlp. Rumah 2',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_mobile1',
        label: 'HP 1',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_mobile2',
        label: 'HP 2',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_mobile3',
        label: 'HP 3',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_email1',
        label: 'Email 1',
        keyboardType: TextInputType.emailAddress,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_email2',
        label: 'Email 2',
        keyboardType: TextInputType.emailAddress,
      ),
      // Bukan kolom customer — backend menyimpannya ke t_customer_reserve_answer.04_ (sama spt
      // Paradise Dynamics). Opsinya (Untuk dihuni / Investasi) dari GET /reserve-order/customer-options.
      ReserveCustomerFieldSpec(
        key: 'purchase_purpose',
        label: 'Tujuan Pembelian',
        kind: ReserveCustomerFieldKind.option,
      ),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Data :pasangan',
    fields: [
      ReserveCustomerFieldSpec(key: 'spouse_name', label: 'Nama Lengkap'),
      ReserveCustomerFieldSpec(key: 'spouse_birth_place', label: 'Tempat Lahir'),
      ReserveCustomerFieldSpec(
        key: 'spouse_birth_date',
        label: 'Tgl. Lahir',
        kind: ReserveCustomerFieldKind.date,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_email',
        label: 'Email',
        keyboardType: TextInputType.emailAddress,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_telp_mobile',
        label: 'No. HP',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(key: 'child1_name', label: 'Nama Anak 1'),
      ReserveCustomerFieldSpec(key: 'child2_name', label: 'Nama Anak 2'),
      ReserveCustomerFieldSpec(key: 'child3_name', label: 'Nama Anak 3'),
      ReserveCustomerFieldSpec(key: 'child4_name', label: 'Nama Anak 4'),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Kontak yang Dapat Dihubungi bila Keadaan Mendesak (Tidak Serumah)',
    fields: [
      ReserveCustomerFieldSpec(key: 'em_contact_name', label: 'Nama Lengkap'),
      ReserveCustomerFieldSpec(key: 'em_hubungan', label: 'Hubungan'),
      ReserveCustomerFieldSpec(
        key: 'em_hp1',
        label: 'HP 1',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'em_hp2',
        label: 'HP 2',
        keyboardType: TextInputType.phone,
      ),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Data Alamat Pembeli',
    fields: [
      ReserveCustomerFieldSpec(
        key: 'cust_area',
        label: 'Wilayah Area (KTP)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'nama_kota', label: 'Kota (KTP)'),
      ReserveCustomerFieldSpec(
        key: 'postal_code',
        label: 'Kode Pos (KTP)',
        keyboardType: TextInputType.number,
      ),
      ReserveCustomerFieldSpec(
        key: 'current_address_similar_ktp',
        label: 'Sama dengan Alamat KTP?',
        kind: ReserveCustomerFieldKind.boolChoice,
        trueLabel: 'Ya',
        falseLabel: 'Tidak',
      ),
      ReserveCustomerFieldSpec(
        key: 'current_address',
        label: 'Alamat (Sekarang)',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'current_area',
        label: 'Wilayah Area (Sekarang)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'current_city', label: 'Kota (Sekarang)'),
      ReserveCustomerFieldSpec(
        key: 'current_postal_code',
        label: 'Kode Pos (Sekarang)',
        keyboardType: TextInputType.number,
      ),
      ReserveCustomerFieldSpec(
        key: 'mailing_address',
        label: 'Alamat (Surat)',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'mailing_area',
        label: 'Wilayah Area (Surat)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'mailing_city', label: 'Kota (Surat)'),
      ReserveCustomerFieldSpec(
        key: 'mailing_postal_code',
        label: 'Kode Pos (Surat)',
        keyboardType: TextInputType.number,
      ),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Data Alamat :pasangan',
    fields: [
      ReserveCustomerFieldSpec(
        key: 'mate_ktp_address',
        label: 'Alamat (KTP)',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_ktp_area',
        label: 'Wilayah Area (KTP)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'mate_ktp_city', label: 'Kota (KTP)'),
      ReserveCustomerFieldSpec(
        key: 'mate_ktp_postal_code',
        label: 'Kode Pos (KTP)',
        keyboardType: TextInputType.number,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_current_address',
        label: 'Alamat (Sekarang)',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_current_area',
        label: 'Wilayah Area (Sekarang)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_current_city',
        label: 'Kota (Sekarang)',
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_current_postal_code',
        label: 'Kode Pos (Sekarang)',
        keyboardType: TextInputType.number,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_mailing_address',
        label: 'Alamat (Surat)',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_mailing_area',
        label: 'Wilayah Area (Surat)',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_mailing_city',
        label: 'Kota (Surat)',
      ),
      ReserveCustomerFieldSpec(
        key: 'mate_mailing_postal_code',
        label: 'Kode Pos (Surat)',
        keyboardType: TextInputType.number,
      ),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Data Pekerjaan Pembeli',
    fields: [
      ReserveCustomerFieldSpec(
        key: 'cust_company_name',
        label: 'Nama Perusahaan',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_office_building',
        label: 'Nama Gedung Kantor',
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_work_address',
        label: 'Alamat',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'work_area',
        label: 'Wilayah Area',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'cust_work_city', label: 'Kota'),
      ReserveCustomerFieldSpec(
        key: 'cust_telp_work',
        label: 'Telpon Kantor',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_work_fax',
        label: 'Fax',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_job_title',
        label: 'Jabatan',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'cust_income',
        label: 'Penghasilan',
        kind: ReserveCustomerFieldKind.option,
        numeric: true,
      ),
    ],
  ),
  ReserveCustomerFieldSection(
    title: 'Data Pekerjaan :pasangan',
    fields: [
      ReserveCustomerFieldSpec(key: 'spouse_occupation', label: 'Pekerjaan'),
      ReserveCustomerFieldSpec(
        key: 'spouse_company_name',
        label: 'Nama Perusahaan',
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_office_building',
        label: 'Nama Gedung Kantor',
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_work_address',
        label: 'Alamat',
        maxLines: 2,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_area',
        label: 'Wilayah Area',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(key: 'spouse_work_city', label: 'Kota'),
      ReserveCustomerFieldSpec(
        key: 'spouse_telp_work',
        label: 'Telpon Kantor',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_work_fax',
        label: 'Fax',
        keyboardType: TextInputType.phone,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_job_title',
        label: 'Jabatan',
        kind: ReserveCustomerFieldKind.option,
      ),
      ReserveCustomerFieldSpec(
        key: 'spouse_income',
        label: 'Penghasilan',
        kind: ReserveCustomerFieldKind.option,
        numeric: true,
      ),
    ],
  ),
  // Tidak ada grup "Lainnya" (SAMA dgn web & Paradise Dynamics). Identitas pasangan mate_* tidak punya
  // baris sendiri: API mengirim spouse_* berisi nilai yang berlaku (mate_* kalau sudah menikah) & backend
  // menyimpan isian spouse_* ke mate_* kalau sudah menikah (MCustomerReserve::routePartnerColumns()).
];

/// Grup "Sales Channel" — "Sumber Informasi 1 / 2" Paradise Dynamics, di Connect = Sales Channel
/// reserve order (`sales_channel` / `sales_channel_detail` di data customer detail). Hanya tampil
/// (tab Customer, setelah Kuesioner — urutan sama dgn Dynamics), tidak diedit di halaman Edit.
const ReserveCustomerFieldSection reserveSalesChannelSection =
    ReserveCustomerFieldSection(
      title: 'Sales Channel',
      fields: [
        ReserveCustomerFieldSpec(key: 'sales_channel', label: 'Sales Channel'),
        ReserveCustomerFieldSpec(
          key: 'sales_channel_detail',
          label: 'Sales Channel Detail',
        ),
      ],
    );
