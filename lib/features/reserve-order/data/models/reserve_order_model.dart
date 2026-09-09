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
        ReserveOrderStatus.diproses => 'Diproses',
        ReserveOrderStatus.ditolak => 'Ditolak',
        ReserveOrderStatus.rba => 'RBA',
        ReserveOrderStatus.rbb => 'RBB',
        ReserveOrderStatus.sp => 'SP',
        ReserveOrderStatus.prosesBank => 'Proses Bank',
        ReserveOrderStatus.akad => 'Akad ✓',
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

enum ReserveOrderNoteRole { sales, kasir, salesAdmin, sistem }

class ReserveOrderNote {
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

  Color get avatarColor => switch (roleKind) {
        ReserveOrderNoteRole.sales => const Color(primaryColor),
        ReserveOrderNoteRole.kasir => const Color(purpleColor),
        ReserveOrderNoteRole.salesAdmin => const Color(infoColor),
        ReserveOrderNoteRole.sistem => const Color(grey4Color),
      };

  String get initials => initialsOf(author);
}

/// Baris read-only di tab "Data Pembeli".
class ReserveOrderField {
  final String label;
  final String value;

  const ReserveOrderField(this.label, this.value);
}

/// Detail satu customer reserve, dari `GET /api/reserve/customer?reserve_order_id=…`. Melengkapi
/// field yang tidak ada di `GET /api/reserve` (list) — No. KTP, alamat, status pernikahan, & cara
/// bayar — dipakai [ReserveOrder.applyCustomerDetail] buat mengisi tab "Data Pembeli" begitu
/// halaman detailnya dibuka.
class ReserveCustomerDetail {
  final String custName;
  final String? custKtp;
  final String? custAddress1;
  final String? custMaritalStatus;

  /// Ada di objek `reserve_order`, bukan `customer` — cuma id, namanya dipetakan lewat master
  /// `GET /api/reserve/cara-bayar` (`ReserveOrderListCubit.ensureCaraBayarOptions`).
  final int? caraBayarId;

  const ReserveCustomerDetail({
    required this.custName,
    this.custKtp,
    this.custAddress1,
    this.custMaritalStatus,
    this.caraBayarId,
  });

  factory ReserveCustomerDetail.fromJson(Map<String, dynamic> json) {
    final reserveOrder = json['reserve_order'] is Map ? Map<String, dynamic>.from(json['reserve_order'] as Map) : const {};
    final customer = json['customer'] is Map ? Map<String, dynamic>.from(json['customer'] as Map) : const {};

    return ReserveCustomerDetail(
      custName: _text(customer['cust_name']) ?? _text(reserveOrder['cust_name']) ?? '-',
      custKtp: _text(customer['cust_ktp']),
      custAddress1: _text(customer['cust_address1']),
      custMaritalStatus: _text(customer['cust_marital_status']),
      caraBayarId: _int(reserveOrder['cara_bayar_id']),
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
      _ when isRejected => (ReserveOrderStatus.ditolak, 'Ditolak', 'Ditolak - Perlu Revisi'),
      _ when spDate != null => (ReserveOrderStatus.sp, 'SP', 'SP Terbit'),
      // `rb_date` tidak membedakan RBA & RBB, jadi badge-nya ditulis netral.
      _ when rbDate != null => (ReserveOrderStatus.rba, 'R/BR', 'Reserve Booking Aktif'),
      _ => (ReserveOrderStatus.diproses, 'Diproses', 'Masih Diproses'),
    };

    final customerName = _text(json['cust_name']) ?? _text(json['contact_name']) ?? '-';
    final phone = _text(json['phone_number']) ?? '';
    final note = _text(json['reserve_note']);
    final salesName = _text(json['owner_name']) ?? '-';

    return ReserveOrder(
      id: '${json['reserve_order_id'] ?? ''}',
      customerName: customerName,
      phone: phone,
      unitLabel: _text(json['property_name']) ?? _text(json['deal_blok_no']) ?? 'Unit belum ditentukan',
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
      rejectReason: isRejected ? (rejectReason ?? 'Ditolak tanpa keterangan. Hubungi kasir untuk detailnya.') : null,
      stageLabel: label,
      paidSoFar: amount ?? 0,
      // Top up cuma masuk akal selagi transaksinya masih di tahap reserve / reserve booking.
      canTopUp: !isRejected && spDate == null,
      journey: buildReserveJourney(
        reached: spDate != null ? 5 : (rbDate != null ? 4 : 3),
        subs: {
          3: [
            if (createdAt != null) 'Diajukan ${_longDate(createdAt)}',
            if (amountLabel != null) amountLabel,
            if (isRejected) 'Ditolak, Perlu Revisi' else 'sedang diverifikasi',
          ].join(' · '),
          if (rbDate != null) 4: _longDate(rbDate),
          if (spDate != null) 5: _longDate(spDate),
        },
        errorSubs: isRejected ? const {3} : const {},
        notes: {
          if (isRejected && rejectReason != null)
            3: [
              ReserveOrderTimelineNote(
                who: 'Kasir —',
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
        ReserveOrderField('Nama Lengkap (sesuai KTP)', customerName),
        const ReserveOrderField('No. KTP', '-'),
        const ReserveOrderField('Alamat sesuai KTP', '-'),
        const ReserveOrderField('Status Pernikahan', '-'),
        const ReserveOrderField('Cara Pembayaran', '-'),
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
        ReserveOrderField('Nama Lengkap (sesuai KTP)', detail.custName),
        ReserveOrderField('No. KTP', detail.custKtp ?? '-'),
        ReserveOrderField('Alamat sesuai KTP', detail.custAddress1 ?? '-'),
        ReserveOrderField('Status Pernikahan', detail.custMaritalStatus ?? '-'),
        ReserveOrderField('Cara Pembayaran', caraBayarName ?? '-'),
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
  'L8 Proses Bank',
  'L9 SPK',
  'L10 AKAD',
];

/// Tahap yang tidak bisa digerakkan sales sendiri. L5/L6 menunggu verifikasi kasir & sales admin,
/// L7-L9 murni progress dari tim lain.
const Map<int, String> _reserveLockLabels = {
  4: 'Masih Diproses',
  5: 'Masih Diproses',
  6: 'Progress saja',
  7: 'Progress saja',
  8: 'Progress saja',
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

/// Nilai ringkas untuk kartu list: "Rp 450jt" / "Rp 1,2M" seperti mockup, tapi angka kecil tetap
/// ditulis utuh supaya tidak jadi "Rp 0jt".
String _compactRupiah(num value) {
  if (value >= 1000000000) {
    final miliar = value / 1000000000;
    return 'Rp ${miliar.toStringAsFixed(miliar % 1 == 0 ? 0 : 1).replaceAll('.', ',')}M';
  }
  if (value >= 1000000) {
    final juta = value / 1000000;
    return 'Rp ${juta.toStringAsFixed(juta % 1 == 0 ? 0 : 1).replaceAll('.', ',')}jt';
  }
  return 'Rp ${NumberHelper.thousands(value)}';
}
