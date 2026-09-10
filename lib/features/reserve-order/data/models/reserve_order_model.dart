import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';

/// Model tampilan untuk menu "Reserve Order" (list transaksi) — Bagian 3 mockup.
///
/// Diisi dari `GET /api/reserve` lewat [ReserveOrder.fromJson]. Response-nya baru memuat data
/// ringkas (nama, unit, nominal, tanggal, alasan tolak), jadi tab Attachment & Catatan sebagian
/// besar masih kosong sampai endpoint detail reserve order tersedia.

/// Tahap transaksi yang tampil sebagai badge di kartu list & detail.
enum ReserveOrderStatus { diproses, ditolak, rba, rbb, sp, prosesBank, akad }

extension ReserveOrderStatusX on ReserveOrderStatus {
  String get label => switch (this) {
        ReserveOrderStatus.diproses => 'Processing',
        ReserveOrderStatus.ditolak => 'Rejected',
        ReserveOrderStatus.rba => 'RBA',
        ReserveOrderStatus.rbb => 'RBB',
        ReserveOrderStatus.sp => 'SP',
        ReserveOrderStatus.prosesBank => 'Bank Process',
        ReserveOrderStatus.akad => 'AKAD ✓',
      };

  /// Warna badge. RBA/RBB/SP memakai warna status unit yang sudah dipakai site plan supaya
  /// konsisten; sisanya warna semantik (kuning = menunggu, merah = ditolak, hijau = selesai).
  Color get color => switch (this) {
        ReserveOrderStatus.diproses => const Color(warningColor),
        ReserveOrderStatus.ditolak => const Color(redColor),
        ReserveOrderStatus.rba => const Color(rbaColor),
        ReserveOrderStatus.rbb => const Color(rbbColor),
        ReserveOrderStatus.sp => const Color(spColor),
        ReserveOrderStatus.prosesBank => const Color(infoColor),
        ReserveOrderStatus.akad => const Color(successColor),
      };
}

/// Satu chip filter di atas list, dari `GET /api/reserve-filter` (master status reserve).
/// [statusReserveId] dikirim ke server lewat `ReserveOrderListCubit.load(statusIds: …)` —
/// filternya jalan di server, bukan disaring di app.
class ReserveFilterOption {
  final int statusReserveId;
  final String name;
  final bool isActive;

  const ReserveFilterOption({required this.statusReserveId, required this.name, this.isActive = true});

  factory ReserveFilterOption.fromJson(Map<String, dynamic> json) {
    return ReserveFilterOption(
      statusReserveId: _int(json['status_reserve_id']) ?? 0,
      name: _text(json['status_reserve_name']) ?? '-',
      isActive: '${json['is_active']}' == '1' || json['is_active'] == true,
    );
  }
}

/// Satu opsi "Cara Pembayaran" di form Reserve, dari `GET /api/reserve/cara-bayar`.
/// [caraBayarId] yang dipakai/disimpan; [name] cuma buat ditampilkan di picker.
class CaraBayarOption {
  final int caraBayarId;
  final String name;

  const CaraBayarOption({required this.caraBayarId, required this.name});

  factory CaraBayarOption.fromJson(Map<String, dynamic> json) {
    return CaraBayarOption(
      caraBayarId: _int(json['cara_bayar_id']) ?? 0,
      name: _text(json['name']) ?? '-',
    );
  }
}

/// Satu opsi "Area" (lokasi/wilayah) di dropdown Area Code halaman Edit Customer, dari
/// `GET /api/reserve/area` (`data.data`, bukan `data` langsung — sama seperti struktur
/// `GET /api/reserve`). [locationId] yang dikirim balik ke `PATCH /api/reserve/{id}`
/// (`cust_area`/`current_area`/dst); [city]/[locationName] digabung jadi [label] buat picker.
class AreaOption {
  final int locationId;
  final String city;
  final String locationName;

  const AreaOption({required this.locationId, required this.city, required this.locationName});

  factory AreaOption.fromJson(Map<String, dynamic> json) {
    return AreaOption(
      locationId: _int(json['location_id']) ?? 0,
      city: _text(json['city']) ?? '-',
      locationName: _text(json['location_name']) ?? '-',
    );
  }

  String get label => '$locationName — $city';
}

/// Opsi "Status Pernikahan" — dipakai form Reserve & halaman Edit Customer. Sengaja tetap Bahasa
/// Indonesia: harus sama persis dengan nilai `status_perkawinan` hasil OCR KTP, dan dengan apa yang
/// disimpan di backend (`cust_marital_status`).
const List<String> roMaritalStatusItems = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

enum ReserveOrderStepState { done, active, todo }

/// Balon catatan yang menempel di salah satu tahap timeline.
class ReserveOrderTimelineNote {
  /// Penulisnya, mis. "Rina · Kasir —" atau "Sistem ·".
  final String who;
  final String text;

  /// Waktu dalam kurung, mis. "(05 Sep, 15:22)".
  final String time;

  /// Kalau diisi, muncul link biru di bawah teks catatan.
  final String? linkLabel;

  const ReserveOrderTimelineNote({required this.who, required this.text, required this.time, this.linkLabel});
}

class ReserveOrderStep {
  final String label;
  final ReserveOrderStepState state;

  /// [sub] & [subIsError] ikut berubah saat transaksi yang ditolak diajukan ulang, jadi keduanya
  /// tidak final. Sub ditulis merah selama [subIsError] true.
  String? sub;
  bool subIsError;

  /// Teks chip gembok ("Masih Diproses" / "Progress saja"); null berarti tahapnya tidak dikunci.
  final String? lockLabel;

  /// L10 AKAD — ditandai chip "Tujuan Akhir", bukan gembok.
  final bool isGoal;

  /// Bisa ditambah: pengajuan top up / ajukan ulang menempelkan catatan baru ke tahap berjalan.
  final List<ReserveOrderTimelineNote> notes;

  ReserveOrderStep({
    required this.label,
    this.sub,
    required this.state,
    this.subIsError = false,
    this.lockLabel,
    this.isGoal = false,
    List<ReserveOrderTimelineNote>? notes,
  }) : notes = List.of(notes ?? const []);
}

enum ReserveOrderDocState {
  /// Slot kosong yang menunggu diunggah.
  awaitingUpload,

  /// Sudah diunggah & lolos verifikasi.
  uploaded,

  /// Sudah diunggah, masih ditunggu kasir.
  pending,

  /// Ditolak, harus diunggah ulang lewat "Edit & Ajukan Ulang".
  rejected,

  /// Diterbitkan pihak lain (mis. SP dari Sales Admin) — sales cuma bisa lihat/unduh.
  issued,
}

class ReserveOrderDoc {
  final IconData icon;
  final String name;

  /// Keterangan kecil di sebelah nama, mis. "· Wajib".
  final String? badge;

  /// Baris status di bawah nama, mis. "Terupload · 240 KB".
  final String status;
  final ReserveOrderDocState state;

  /// Memisahkan bagian "Bukti Bayar" dari "Dokumen Identitas" di halaman Edit & Ajukan Ulang.
  final bool isPaymentProof;

  const ReserveOrderDoc({
    required this.icon,
    required this.name,
    this.badge,
    required this.status,
    this.state = ReserveOrderDocState.uploaded,
    this.isPaymentProof = false,
  });

  ReserveOrderDoc copyWith({String? name, String? badge, String? status, ReserveOrderDocState? state}) {
    return ReserveOrderDoc(
      icon: icon,
      name: name ?? this.name,
      badge: badge ?? this.badge,
      status: status ?? this.status,
      state: state ?? this.state,
      isPaymentProof: isPaymentProof,
    );
  }
}

enum ReserveOrderNoteRole { sales, kasir, salesAdmin, sistem, user }

class ReserveOrderNote {
  /// `'me'` kalau dikirim lewat app ini sendiri (lihat [ReserveOrderDetailPage._sendNote] — belum
  /// ada endpoint kirim pesan, jadi masih lokal), atau `sender_name` asli dari
  /// `GET /api/reserve/notes` buat pesan orang lain. Dipakai langsung buat nentuin bubble kiri/kanan
  /// ([isMine]) — bukan dibandingkan ke user yang sedang login.
  final String author;

  /// Jabatan yang tampil abu-abu di sebelah nama, mis. "Sales" / "otomatis".
  final String role;
  final ReserveOrderNoteRole roleKind;
  final String time;
  final String text;

  const ReserveOrderNote({
    required this.author,
    required this.role,
    required this.roleKind,
    required this.time,
    required this.text,
  });

  bool get isMine => author == 'me';

  /// Label yang ditampilkan di atas bubble — "Me" (bukan literal "me") kalau [isMine].
  String get displayAuthor => isMine ? 'Me' : author;

  Color get avatarColor => switch (roleKind) {
        ReserveOrderNoteRole.sales => const Color(primaryColor),
        ReserveOrderNoteRole.kasir => const Color(purpleColor),
        ReserveOrderNoteRole.salesAdmin => const Color(infoColor),
        ReserveOrderNoteRole.sistem => const Color(grey4Color),
        ReserveOrderNoteRole.user => const Color(infoColor),
      };

  String get initials => initialsOf(author);
}

/// Satu pesan dari `GET /api/reserve/notes?reserve_order_id=…` — tab "Notes" bergaya chat di
/// halaman Detail. Dipetakan ke [ReserveOrderNote] (`ReserveOrderDetailPage._loadNotes`) supaya
/// pipeline tampilan/tambah-catatan-lokal yang sudah ada (dipakai juga oleh `revise.dart`/
/// `top_up.dart`) tetap satu jalur, bukan dua sumber data terpisah.
class ReserveOrderActivityMessage {
  final int id;
  final String message;
  final String senderName;
  final String? senderRole;
  final DateTime? createDatetime;

  const ReserveOrderActivityMessage({
    required this.id,
    required this.message,
    required this.senderName,
    this.senderRole,
    this.createDatetime,
  });

  factory ReserveOrderActivityMessage.fromJson(Map<String, dynamic> json) {
    return ReserveOrderActivityMessage(
      id: _int(json['reserve_order_activity_message_id']) ?? 0,
      message: _text(json['message']) ?? '',
      senderName: _text(json['sender_name']) ?? '-',
      senderRole: _text(json['sender_role']),
      createDatetime: _parseDate(json['create_datetime']),
    );
  }
}

/// Baris read-only di tab "Data Pembeli".
class ReserveOrderField {
  final String label;
  final String value;

  const ReserveOrderField(this.label, this.value);
}

/// Detail satu customer reserve, dari `GET /api/reserve/customer?reserve_order_id=…`. Melengkapi
/// field yang tidak ada di `GET /api/reserve` (list) — dipakai [ReserveOrder.applyCustomerDetail]
/// buat mengisi tab "Data Pembeli" begitu halaman detailnya dibuka, dan disimpan utuh di
/// [ReserveOrder.customerDetail] buat halaman "Edit Customer" ([ReserveOrderEditCustomerPage]).
///
/// Field-nya sangat banyak (~90 — alamat KTP/domisili/surat-menyurat, kontak, data pekerjaan,
/// pasangan, anak, penjamin, kontak sekunder & darurat, dst) dan sebagian besar cuma
/// ditampilkan/diedit apa adanya tanpa logika lain di app ini, jadi disimpan sebagai [raw] (map
/// mentah per key backend, mis. `cust_name`, `spouse_income`, `mate_ktp_city`) daripada dideklarasi
/// satu-satu — bikin field bernama untuk semuanya cuma nambah boilerplate tanpa manfaat. Beberapa
/// yang memang dipakai di luar halaman edit (tab ringkas, [ReserveOrder.applyCustomerDetail]) tetap
/// punya getter pendek di bawah.
class ReserveCustomerDetail {
  final Map<String, dynamic> raw;

  const ReserveCustomerDetail({this.raw = const {}});

  String get custName => _text(raw['cust_name']) ?? '-';
  String? get custKtp => _text(raw['cust_ktp']);
  String? get custAddress1 => _text(raw['cust_address1']);
  String? get custMaritalStatus => _text(raw['cust_marital_status']);

  /// Ada di objek `reserve_order`, bukan `customer` — cuma id, namanya dipetakan lewat master
  /// `GET /api/reserve/cara-bayar` (`ReserveOrderListCubit.ensureCaraBayarOptions`).
  int? get caraBayarId => _int(raw['cara_bayar_id']);

  factory ReserveCustomerDetail.fromJson(Map<String, dynamic> json) {
    final reserveOrder = json['reserve_order'] is Map ? Map<String, dynamic>.from(json['reserve_order'] as Map) : const {};
    final customer = json['customer'] is Map ? Map<String, dynamic>.from(json['customer'] as Map) : const {};

    return ReserveCustomerDetail(raw: {
      ...customer,
      // `cust_name` & `cara_bayar_id` ada di objek `reserve_order`, bukan `customer` — dipakai
      // sebagai fallback kalau belum keisi di sana (transaksi baru, belum lengkap datanya).
      if (_text(customer['cust_name']) == null && reserveOrder['cust_name'] != null) 'cust_name': reserveOrder['cust_name'],
      if (_int(customer['cara_bayar_id']) == null && reserveOrder['cara_bayar_id'] != null) 'cara_bayar_id': reserveOrder['cara_bayar_id'],
    });
  }
}

/// Cara nilai satu [ReserveCustomerFieldSpec] mesti diformat/ditampilkan — dipakai tab "Customer"
/// (read-only) di `ReserveOrderDetailPage`. `text` = tampilkan `raw[key]` apa adanya.
enum ReserveCustomerFieldKind { text, date, genderBool, yesNoBool, area, maritalStatus, religion, paymentPlan }

/// Satu field profil pembeli: key backend + label tampilan + cara formatnya. Dipakai bareng oleh
/// `ReserveOrderEditCustomerPage` (bikin input-nya) & `ReserveOrderDetailPage` (tab "Customer",
/// baca-saja) lewat [reserveCustomerFieldSections] supaya key/label/pengelompokan field profil
/// pembeli cuma didefinisikan sekali. **Kalau nambah/hapus/pindah field di
/// `ReserveOrderEditCustomerPage`, sinkronkan juga di sini** — halaman itu masih pakai widget
/// input sendiri-sendiri (teks/date-picker/dsb) jadi belum benar-benar dibaca dari list ini.
class ReserveCustomerFieldSpec {
  final String key;
  final String label;
  final ReserveCustomerFieldKind kind;

  const ReserveCustomerFieldSpec(this.key, this.label, {this.kind = ReserveCustomerFieldKind.text});
}

class ReserveCustomerFieldSection {
  final String title;
  final List<ReserveCustomerFieldSpec> fields;

  const ReserveCustomerFieldSection(this.title, this.fields);
}

const List<ReserveCustomerFieldSection> reserveCustomerFieldSections = [
  ReserveCustomerFieldSection('Buyer Data', [
    ReserveCustomerFieldSpec('cust_name', 'Full Name (as per KTP)'),
    ReserveCustomerFieldSpec('cust_ktp', 'KTP No.'),
    ReserveCustomerFieldSpec('cust_npwp', 'NPWP No.'),
    ReserveCustomerFieldSpec('cust_birth_place', 'Place of Birth'),
    ReserveCustomerFieldSpec('cust_birth_date', 'Date of Birth', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec('cust_gender_is_male', 'Gender', kind: ReserveCustomerFieldKind.genderBool),
    ReserveCustomerFieldSpec('cust_marital_status', 'Marital Status', kind: ReserveCustomerFieldKind.maritalStatus),
    ReserveCustomerFieldSpec('work_category', 'Work Category'),
    ReserveCustomerFieldSpec('cust_occupation', 'Occupation'),
    ReserveCustomerFieldSpec('cara_bayar_id', 'Payment Plan', kind: ReserveCustomerFieldKind.paymentPlan),
    ReserveCustomerFieldSpec('cust_religion', 'Religion', kind: ReserveCustomerFieldKind.religion),
    ReserveCustomerFieldSpec('cust_education', 'Education'),
    ReserveCustomerFieldSpec('cust_telp_home', 'Home Phone'),
    ReserveCustomerFieldSpec('cust_telp_home2', 'Home Phone 2'),
    ReserveCustomerFieldSpec('cust_telp_mobile1', 'Mobile Phone 1'),
    ReserveCustomerFieldSpec('cust_telp_mobile2', 'Mobile Phone 2'),
    ReserveCustomerFieldSpec('cust_telp_mobile3', 'Mobile Phone 3'),
    ReserveCustomerFieldSpec('cust_email1', 'Email 1'),
    ReserveCustomerFieldSpec('cust_email2', 'Email 2'),
  ]),
  ReserveCustomerFieldSection('Prospective Spouse', [
    ReserveCustomerFieldSpec('spouse_name', 'Spouse Name'),
    ReserveCustomerFieldSpec('spouse_birth_place', 'Spouse Place of Birth'),
    ReserveCustomerFieldSpec('spouse_birth_date', 'Spouse Date of Birth', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec('spouse_email', 'Spouse Email'),
    ReserveCustomerFieldSpec('spouse_telp_mobile', 'Spouse Mobile Phone'),
  ]),
  ReserveCustomerFieldSection('Children Data', [
    ReserveCustomerFieldSpec('child1_name', 'Child 1 Name'),
    ReserveCustomerFieldSpec('child2_name', 'Child 2 Name'),
    ReserveCustomerFieldSpec('child3_name', 'Child 3 Name'),
    ReserveCustomerFieldSpec('child4_name', 'Child 4 Name'),
  ]),
  ReserveCustomerFieldSection('Emergency Contact (Not Living Together)', [
    ReserveCustomerFieldSpec('em_contact_name', 'Contact Name'),
    ReserveCustomerFieldSpec('em_hubungan', 'Relationship'),
    ReserveCustomerFieldSpec('em_hp1', 'Phone 1'),
    ReserveCustomerFieldSpec('em_hp2', 'Phone 2'),
  ]),
  ReserveCustomerFieldSection('Buyer Address Data', [
    ReserveCustomerFieldSpec('cust_address1', 'Address (as per KTP)'),
    ReserveCustomerFieldSpec('cust_area', 'Area Code (as per KTP)', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('nama_kota', 'City (as per KTP)'),
    ReserveCustomerFieldSpec('postal_code', 'Postal Code (as per KTP)'),
    ReserveCustomerFieldSpec('current_address_similar_ktp', 'Same as KTP Address?', kind: ReserveCustomerFieldKind.yesNoBool),
    ReserveCustomerFieldSpec('current_address', 'Current Address'),
    ReserveCustomerFieldSpec('current_area', 'Current Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('current_city', 'Current City'),
    ReserveCustomerFieldSpec('current_postal_code', 'Current Postal Code'),
    ReserveCustomerFieldSpec('mailing_address', 'Mailing Address'),
    ReserveCustomerFieldSpec('mailing_area', 'Mailing Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('mailing_city', 'Mailing City'),
    ReserveCustomerFieldSpec('mailing_postal_code', 'Mailing Postal Code'),
  ]),
  ReserveCustomerFieldSection('Prospective Spouse Address (Co-Buyer)', [
    ReserveCustomerFieldSpec('mate_name', 'Name'),
    ReserveCustomerFieldSpec('mate_telp_mobile', 'Mobile Phone'),
    ReserveCustomerFieldSpec('mate_birth_place', 'Place of Birth'),
    ReserveCustomerFieldSpec('mate_birth_date', 'Date of Birth', kind: ReserveCustomerFieldKind.date),
    ReserveCustomerFieldSpec('mate_email', 'Email'),
    ReserveCustomerFieldSpec('mate_ktp_address', 'KTP Address'),
    ReserveCustomerFieldSpec('mate_ktp_area', 'KTP Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('mate_ktp_city', 'KTP City'),
    ReserveCustomerFieldSpec('mate_ktp_postal_code', 'KTP Postal Code'),
    ReserveCustomerFieldSpec('mate_current_address', 'Current Address'),
    ReserveCustomerFieldSpec('mate_current_area', 'Current Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('mate_current_city', 'Current City'),
    ReserveCustomerFieldSpec('mate_current_postal_code', 'Current Postal Code'),
    ReserveCustomerFieldSpec('mate_mailing_address', 'Mailing Address'),
    ReserveCustomerFieldSpec('mate_mailing_area', 'Mailing Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('mate_mailing_city', 'Mailing City'),
    ReserveCustomerFieldSpec('mate_mailing_postal_code', 'Mailing Postal Code'),
  ]),
  ReserveCustomerFieldSection('Buyer Work Data', [
    ReserveCustomerFieldSpec('cust_company_name', 'Company Name'),
    ReserveCustomerFieldSpec('cust_office_building', 'Office Building'),
    ReserveCustomerFieldSpec('cust_work_address', 'Work Address'),
    ReserveCustomerFieldSpec('work_area', 'Work Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('cust_work_city', 'Work City'),
    ReserveCustomerFieldSpec('cust_telp_work', 'Work Phone'),
    ReserveCustomerFieldSpec('cust_telp_work2', 'Work Phone 2'),
    ReserveCustomerFieldSpec('cust_work_fax', 'Work Fax'),
    ReserveCustomerFieldSpec('cust_job_title', 'Job Title'),
    ReserveCustomerFieldSpec('cust_income', 'Monthly Income'),
  ]),
  ReserveCustomerFieldSection('Prospective Spouse Work Data', [
    ReserveCustomerFieldSpec('spouse_occupation', 'Occupation'),
    ReserveCustomerFieldSpec('spouse_company_name', 'Company Name'),
    ReserveCustomerFieldSpec('spouse_office_building', 'Office Building'),
    ReserveCustomerFieldSpec('spouse_work_address', 'Work Address'),
    ReserveCustomerFieldSpec('spouse_area', 'Work Area Code', kind: ReserveCustomerFieldKind.area),
    ReserveCustomerFieldSpec('spouse_work_city', 'Work City'),
    ReserveCustomerFieldSpec('spouse_telp_work', 'Work Phone'),
    ReserveCustomerFieldSpec('spouse_work_fax', 'Work Fax'),
    ReserveCustomerFieldSpec('spouse_job_title', 'Job Title'),
    ReserveCustomerFieldSpec('spouse_income', 'Monthly Income'),
  ]),
];

/// Satu grup slot bernomor (mis. "Mobile Phone 1/2/3") buat tab "Customer" (read-only) —
/// [ReserveOrderDetailPage] cuma menampilkan satu baris berlabel [baseLabel] (tanpa angka) kalau
/// cuma satu slot yang keisi datanya; kalau lebih dari satu, semua slot yang keisi ditampilkan
/// pakai label aslinya dari [reserveCustomerFieldSections] (yang kosong dilewati).
class ReserveCustomerSlotGroup {
  final String baseLabel;
  final List<String> keys;

  const ReserveCustomerSlotGroup(this.baseLabel, this.keys);
}

const List<ReserveCustomerSlotGroup> reserveCustomerSlotGroups = [
  ReserveCustomerSlotGroup('Home Phone', ['cust_telp_home', 'cust_telp_home2']),
  ReserveCustomerSlotGroup('Mobile Phone', ['cust_telp_mobile1', 'cust_telp_mobile2', 'cust_telp_mobile3']),
  ReserveCustomerSlotGroup('Email', ['cust_email1', 'cust_email2']),
  ReserveCustomerSlotGroup('Phone', ['em_hp1', 'em_hp2']),
  ReserveCustomerSlotGroup('Work Phone', ['cust_telp_work', 'cust_telp_work2']),
];

/// Satu dokumen dari `GET /api/reserve/attachment?reserve_order_id=…&reserve_order_tts_id=…` —
/// file (KTP/NPWP/bukti transfer) yang tersimpan lewat `POST /api/reserve/doc-payment`. Baris ini
/// sebenarnya row `contact_attachments` yang sama dengan attachment kontak biasa, tapi diekspos
/// lewat endpoint bergaris reserve order + di-lengkapi info verifikasi & nama pengunggah — beda
/// struktur dari `ContactAttachment` (fitur contact), jadi sengaja model terpisah, bukan reuse.
class ReserveOrderAttachment {
  final int contactAttachmentId;
  final String attachmentUrl;
  final String attachmentTypeName;
  final String attachmentNote;
  final DateTime? createDatetime;
  final String? createUserName;
  final String? verificationStatus;

  const ReserveOrderAttachment({
    required this.contactAttachmentId,
    required this.attachmentUrl,
    required this.attachmentTypeName,
    required this.attachmentNote,
    this.createDatetime,
    this.createUserName,
    this.verificationStatus,
  });

  factory ReserveOrderAttachment.fromJson(Map<String, dynamic> json) {
    return ReserveOrderAttachment(
      contactAttachmentId: _int(json['contact_attachment_id']) ?? 0,
      // `attachment_url` biasanya sama dengan `attachment_path` (link Google Drive) — dijaga kalau
      // salah satu tidak diisi.
      attachmentUrl: _text(json['attachment_url']) ?? _text(json['attachment_path']) ?? '',
      attachmentTypeName: _text(json['attachment_type_name']) ?? 'Document',
      attachmentNote: _text(json['attachment_note']) ?? '',
      createDatetime: DateTime.tryParse('${json['create_datetime']}'),
      createUserName: _text(json['create_user_name']),
      verificationStatus: _text(json['verification_status']),
    );
  }
}

class ReserveOrder {
  final String id;
  final String customerName;
  final String phone;

  /// Nama unit di kartu, mis. "Blok E1 No. 19".
  final String unitLabel;

  /// Township · cluster, mis. "PAR2 · Ecoscape".
  final String unitSub;

  /// Harga unit lengkap, mis. "Rp 450.000.000". Null untuk unit yang harganya belum ditentukan.
  final String? priceLabel;

  final String salesName;

  /// Nilai ringkas di kartu list, mis. "Rp 450jt". Null berarti barisnya dilewati.
  final String? amountShort;

  /// Tanggal ringkas di kartu list, mis. "Reserve: 05 Sep".
  final String dateLabel;

  /// [status], [statusText] & [rejectReason] sengaja tidak final: "Submit Ulang" mengembalikan
  /// transaksi yang ditolak ke tahap Diproses. Nanti perubahan ini datang dari response server.
  ReserveOrderStatus status;
  String? statusText;
  String? rejectReason;

  /// Teks badge kalau nama tahapnya lebih spesifik daripada [status]. Dipakai karena response
  /// `/api/reserve` cuma punya `rb_date` — tidak bisa dibedakan RBA atau RBB, jadi ditulis "R/BR".
  /// Nanti diisi nama status dari master `status_reserve_id` begitu endpoint filternya ada.
  final String? statusLabelOverride;

  /// Id mentah dari server, disimpan untuk dipetakan ke master status & dipakai endpoint detail.
  final int? statusReserveId;

  /// Dipakai tautan "Profil & Riwayat Lengkap ›" untuk membuka halaman Contact Detail.
  final int? contactId;
  final int? dealId;

  /// Status yang tampil di ringkasan halaman Top Up, mis. "Reserve".
  final String stageLabel;

  /// Total yang sudah dibayar sejauh ini (rupiah penuh).
  final num paidSoFar;

  /// Top Up hanya masuk akal selama transaksi masih di tahap reserve/booking reserve.
  final bool canTopUp;

  final List<ReserveOrderStep> journey;
  final List<ReserveOrderField> buyer;

  /// Profil pembeli lengkap (~90 field), diisi [applyCustomerDetail] begitu `GET
  /// /api/reserve/customer` kembali. [buyer] di atas cuma ringkasan 5 field buat tab "Data
  /// Pembeli" — ini dipakai halaman "Edit Customer" biar semua field bisa diedit, bukan cuma yang
  /// ringkas. Sengaja tidak final: sama seperti [status]/[rejectReason], bisa berubah tanpa membuat
  /// objek transaksi baru.
  ReserveCustomerDetail? customerDetail;

  /// [docs] & [notes] sengaja disalin jadi list yang bisa ditambah: tab Attachment bisa menambah
  /// dokumen dan tab Catatan bisa menambah catatan tanpa membuat objek transaksi baru.
  final List<ReserveOrderDoc> docs;
  final List<ReserveOrderNote> notes;

  ReserveOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.unitLabel,
    required this.unitSub,
    this.priceLabel,
    required this.salesName,
    this.amountShort,
    required this.dateLabel,
    required this.status,
    this.statusText,
    this.rejectReason,
    this.statusLabelOverride,
    this.statusReserveId,
    this.contactId,
    this.dealId,
    required this.stageLabel,
    this.paidSoFar = 0,
    this.canTopUp = false,
    required this.journey,
    List<ReserveOrderField>? buyer,
    List<ReserveOrderDoc>? docs,
    List<ReserveOrderNote>? notes,
  })  : buyer = List.of(buyer ?? const []),
        docs = List.of(docs ?? const []),
        notes = List.of(notes ?? const []);

  /// Memetakan satu baris `GET /api/reserve`.
  ///
  /// Tahapnya diturunkan dari tanggal yang ada (`sp_date` -> `rb_date` -> `created_datetime`) plus
  /// jejak penolakan kasir/sales admin. `status_reserve_id` ikut disimpan tapi belum dipakai untuk
  /// menamai badge, karena master statusnya belum ada endpoint-nya.
  factory ReserveOrder.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_datetime']);
    final rbDate = _parseDate(json['rb_date']);
    final spDate = _parseDate(json['sp_date']);
    final rejectedAt = _parseDate(json['kasir_rejected_datetime']) ?? _parseDate(json['sa_rejected_datetime']);

    final rejectReason = _text(json['kasir_rejected_reason']) ?? _text(json['sa_rejected_reason']);
    final isRejected = rejectedAt != null || rejectReason != null;

    final amount = _number(json['amount_rp']);
    final amountLabel = amount == null || amount <= 0 ? null : 'Rp ${NumberHelper.thousands(amount)}';

    final (status, label, statusText) = switch (true) {
      _ when isRejected => (ReserveOrderStatus.ditolak, 'Rejected', 'Rejected - Needs Revision'),
      _ when spDate != null => (ReserveOrderStatus.sp, 'SP', 'SP Issued'),
      // `rb_date` tidak membedakan RBA & RBB, jadi badge-nya ditulis netral.
      _ when rbDate != null => (ReserveOrderStatus.rba, 'R/BR', 'Reserve Booking Active'),
      _ => (ReserveOrderStatus.diproses, 'Processing', 'Still Processing'),
    };

    final customerName = _text(json['cust_name']) ?? _text(json['contact_name']) ?? '-';
    final phone = _text(json['phone_number']) ?? '';
    final note = _text(json['reserve_note']);
    final salesName = _text(json['owner_name']) ?? '-';

    return ReserveOrder(
      id: '${json['reserve_order_id'] ?? ''}',
      customerName: customerName,
      phone: phone,
      unitLabel: _text(json['property_name']) ?? _text(json['deal_blok_no']) ?? 'Unit not yet determined',
      unitSub: _text(json['deal_project_name']) ?? '',
      salesName: salesName,
      amountShort: amount == null || amount <= 0 ? null : _compactRupiah(amount),
      dateLabel: switch (true) {
        _ when spDate != null => 'SP: ${_shortDate(spDate)}',
        _ when rbDate != null => 'R/BR: ${_shortDate(rbDate)}',
        _ => 'Reserve: ${_shortDate(createdAt)}',
      },
      status: status,
      statusText: statusText,
      statusLabelOverride: label,
      statusReserveId: _int(json['status_reserve_id']),
      contactId: _int(json['contact_id']),
      dealId: _int(json['deal_id']),
      rejectReason: isRejected ? (rejectReason ?? 'Rejected without a reason. Contact the cashier for details.') : null,
      stageLabel: label,
      paidSoFar: amount ?? 0,
      // Top up cuma masuk akal selagi transaksinya masih di tahap reserve / reserve booking.
      canTopUp: !isRejected && spDate == null,
      journey: buildReserveJourney(
        reached: spDate != null ? 5 : (rbDate != null ? 4 : 3),
        subs: {
          3: [
            if (createdAt != null) 'Submitted ${_longDate(createdAt)}',
            if (amountLabel != null) amountLabel,
            if (isRejected) 'Rejected, Needs Revision' else 'under verification',
          ].join(' · '),
          if (rbDate != null) 4: _longDate(rbDate),
          if (spDate != null) 5: _longDate(spDate),
        },
        errorSubs: isRejected ? const {3} : const {},
        notes: {
          if (isRejected && rejectReason != null)
            3: [
              ReserveOrderTimelineNote(
                who: 'Cashier —',
                text: rejectReason,
                time: rejectedAt == null ? '' : '(${_noteTime(rejectedAt)})',
              ),
            ],
        },
      ),
      // Baris tab "Data Pembeli" tetap tampil semua walau datanya belum ada — No. KTP, alamat,
      // status pernikahan, & cara pembayaran belum dikirim `/api/reserve`, jadi ditulis "-" dulu
      // (bukan disembunyikan) supaya layoutnya konsisten dengan mockup.
      buyer: [
        ReserveOrderField('Full Name (as per KTP)', customerName),
        const ReserveOrderField('KTP No.', '-'),
        const ReserveOrderField('Address (as per KTP)', '-'),
        const ReserveOrderField('Marital Status', '-'),
        const ReserveOrderField('Payment Plan', '-'),
      ],
      notes: [
        if (note != null)
          ReserveOrderNote(
            author: salesName,
            role: 'Sales',
            roleKind: ReserveOrderNoteRole.sales,
            time: createdAt == null ? '' : _noteTime(createdAt),
            text: note,
          ),
      ],
    );
  }

  /// Melengkapi tab "Data Pembeli" dengan hasil `GET /api/reserve/customer` — dipanggil dari
  /// `ReserveOrderDetailPage.initState` begitu detailnya berhasil dimuat. [caraBayarOptions] dipakai
  /// memetakan `cara_bayar_id` (angka) ke namanya; kalau id-nya tidak ketemu di master (atau memang
  /// null), barisnya tetap ditulis "-" sama seperti field yang belum diisi.
  void applyCustomerDetail(ReserveCustomerDetail detail, List<CaraBayarOption> caraBayarOptions) {
    customerDetail = detail;

    String? caraBayarName;
    for (final option in caraBayarOptions) {
      if (option.caraBayarId == detail.caraBayarId) {
        caraBayarName = option.name;
        break;
      }
    }

    buyer
      ..clear()
      ..addAll([
        ReserveOrderField('Full Name (as per KTP)', detail.custName),
        ReserveOrderField('KTP No.', detail.custKtp ?? '-'),
        ReserveOrderField('Address (as per KTP)', detail.custAddress1 ?? '-'),
        ReserveOrderField('Marital Status', detail.custMaritalStatus ?? '-'),
        ReserveOrderField('Payment Plan', caraBayarName ?? '-'),
      ]);
  }

  String get initials => initialsOf(customerName);

  bool get isRejected => rejectReason != null;

  /// Teks badge di kartu list & kotak status detail.
  String get badgeLabel => statusLabelOverride ?? status.label;

  /// Baris di bawah nama pembeli pada header detail: unit · lokasi · harga.
  String get detailUnitLine => [unitLabel, unitSub.replaceAll(' · ', ' '), if (priceLabel != null) priceLabel!].where((e) => e.isNotEmpty).join(' · ');
}

/// Inisial dua huruf untuk avatar ("Luthfi Fajri" → "LF").
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '-';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Nama tahap L1-L10 di timeline detail.
const List<String> reserveStageLabels = [
  'L1 Leads',
  'L2 APPT',
  'L3 Visitor',
  'L4 Reserve',
  'L5 Reserve Booking (R/BR)',
  'L6 SP',
  'L7 Collect Data',
  'L8 Bank Process',
  'L9 SPK',
  'L10 AKAD',
];

/// Tahap yang tidak bisa digerakkan sales sendiri. L5/L6 menunggu verifikasi kasir & sales admin,
/// L7-L9 murni progress dari tim lain.
const Map<int, String> _reserveLockLabels = {
  4: 'Still Processing',
  5: 'Still Processing',
  6: 'Progress Only',
  7: 'Progress Only',
  8: 'Progress Only',
};

/// Menyusun 10 tahap sekaligus: apa pun di bawah [reached] dianggap selesai, [reached] jadi tahap
/// berjalan, sisanya belum tercapai. Chip gembok baru muncul mulai tahap berjalan ke atas - tahap
/// yang sudah lewat tidak perlu diingatkan lagi bahwa ia read-only.
List<ReserveOrderStep> buildReserveJourney({
  required int reached,
  Map<int, String> subs = const {},
  Map<int, List<ReserveOrderTimelineNote>> notes = const {},
  Set<int> errorSubs = const {},
}) {
  return [
    for (var i = 0; i < reserveStageLabels.length; i++)
      ReserveOrderStep(
        label: reserveStageLabels[i],
        sub: subs[i],
        state: i < reached
            ? ReserveOrderStepState.done
            : (i == reached ? ReserveOrderStepState.active : ReserveOrderStepState.todo),
        subIsError: errorSubs.contains(i),
        lockLabel: i >= reached ? _reserveLockLabels[i] : null,
        isGoal: i == reserveStageLabels.length - 1,
        notes: notes[i],
      ),
  ];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// String kosong dari server diperlakukan sama dengan null supaya tidak ada baris kosong di UI.
String? _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

num? _number(dynamic value) => value is num ? value : num.tryParse('${value ?? ''}');

int? _int(dynamic value) => value is int ? value : int.tryParse('${value ?? ''}');

String _shortDate(DateTime? date) => date == null ? '-' : DateFormat('dd MMM').format(date);

String _longDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String _noteTime(DateTime date) => DateFormat('dd MMM, HH:mm').format(date);

/// Nilai ringkas untuk kartu list: "Rp 450M" / "Rp 1.2B" (M = million, B = billion — konvensi
/// Inggris, beda dari singkatan "jt"/"M" ala Indonesia di mockup aslinya supaya tidak ketuker
/// dengan makna "M" = juta di Indonesia), tapi angka kecil tetap ditulis utuh supaya tidak jadi
/// "Rp 0M".
String _compactRupiah(num value) {
  if (value >= 1000000000) {
    final billions = value / 1000000000;
    return 'Rp ${billions.toStringAsFixed(billions % 1 == 0 ? 0 : 1)}B';
  }
  if (value >= 1000000) {
    final millions = value / 1000000;
    return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}M';
  }
  return 'Rp ${NumberHelper.thousands(value)}';
}
