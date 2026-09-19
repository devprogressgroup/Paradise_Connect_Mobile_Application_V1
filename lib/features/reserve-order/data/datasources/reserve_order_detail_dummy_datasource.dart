import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

import '../models/reserve_order_customer_data.dart';
import '../models/reserve_order_detail.dart';

/// Sumber data halaman Detail Reserve Order — masih dummy (belum ada API reserve-order di branch
/// ini). Isinya disamakan dengan seed `ro-luthfi` (contoh berhasil) & `Reyhan Pradipta` (contoh
/// Ditolak, dipakai kartu berstatus Ditolak di List) di prototype `reserve-order-prototype (1).html`.
class ReserveOrderDetailDummyDataSource {
  const ReserveOrderDetailDummyDataSource();

  ReserveOrderDetail getOrder({bool rejected = false}) {
    return ReserveOrderDetail(
      customerName: rejected ? 'Reyhan Pradipta' : 'Luthfi Fajri',
      avatarInitials: rejected ? 'RP' : 'LF',
      phone: rejected ? '0857-xxxx-xxxx' : '0812-xxxx-xxxx',
      unitName: rejected ? 'Blok E1 No. 22' : 'Blok E1 No. 19',
      unitSub: 'PAR2 · Ecoscape',
      price: rejected ? 400000000 : 450000000,
      canTopup: !rejected,
      rejected: rejected,
      rejectStage: rejected ? 'L4 Reserve' : null,
      rejectReason: rejected ? 'Foto KTP yang diupload buram dan NIK tidak terbaca jelas. Mohon upload ulang foto KTP yang lebih jernih.' : null,
      rejectFixIsCustomerData: rejected,
      timeline: [
        const ReserveOrderTimelineStep(label: 'L1 Leads', sub: '18 Jul 2026', status: ReserveOrderStepStatus.done),
        const ReserveOrderTimelineStep(label: 'L2 APPT', sub: '20 Jul 2026', status: ReserveOrderStepStatus.done),
        const ReserveOrderTimelineStep(label: 'L3 Visitor', sub: '28 Jul 2026', status: ReserveOrderStepStatus.done),
        ReserveOrderTimelineStep(
          label: 'L4 Reserve',
          sub: rejected ? 'Diajukan 05 Sep 2026 · Rp 2.000.000 — ditolak, perlu revisi' : 'Diajukan 05 Sep 2026 · Rp 2.000.000 — sedang diverifikasi',
          subColor: rejected ? const Color(redColor) : null,
          status: rejected ? ReserveOrderStepStatus.todo : ReserveOrderStepStatus.active,
          notes: rejected ? const [] : const [ReserveOrderTimelineNote('Sistem', 'Top Up Booking Reserve Rp 3.000.000 diajukan (05 Sep, 11:30)')],
        ),
        const ReserveOrderTimelineStep(label: 'L5 Reserve Booking (R/BR)', status: ReserveOrderStepStatus.todo),
        const ReserveOrderTimelineStep(label: 'L6 SP', status: ReserveOrderStepStatus.todo),
        const ReserveOrderTimelineStep(label: 'L7 Collect Data', status: ReserveOrderStepStatus.todo),
        const ReserveOrderTimelineStep(label: 'L8 Proses Bank', status: ReserveOrderStepStatus.todo),
        const ReserveOrderTimelineStep(label: 'L9 SPK', status: ReserveOrderStepStatus.todo),
        const ReserveOrderTimelineStep(label: 'L10 AKAD/PPJB', status: ReserveOrderStepStatus.todo),
      ],
      customer: rejected
          ? ReserveOrderCustomerData(raw: {
              'cust_name': 'Reyhan Pradipta',
              'cust_ktp': '3175xxxxxxxxxxxx',
              'cust_npwp': '-',
              'cust_birth_place': 'Bekasi',
              'cust_birth_date': '1988-05-14',
              'cust_gender_is_male': true,
              'cust_telp_mobile1': '0857-xxxx-xxxx',
              'cust_marital_status': 'Belum Kawin',
              'work_category': 'Profesional',
              'cust_occupation': 'Konsultan pajak',
              'cara_bayar_name': 'KPR',
              'sales_channel': 'Referral',
              'sales_channel_detail': 'Referral Karyawan',
              'cust_address1': 'Jl. Kenanga No. 5, Bekasi',
            })
          : ReserveOrderCustomerData(raw: {
              'cust_name': 'Luthfi Fajri',
              'cust_ktp': '3201xxxxxxxxxxxx',
              'cust_npwp': '-',
              'cust_birth_place': 'Jakarta',
              'cust_birth_date': '1990-01-01',
              'cust_gender_is_male': true,
              'cust_telp_mobile1': '0812-xxxx-xxxx',
              'cust_marital_status': 'Kawin',
              'work_category': 'Wiraswasta',
              'cust_occupation': 'Pemilik toko bangunan',
              'cara_bayar_name': 'KPR',
              'sales_channel': 'Referral',
              'sales_channel_detail': 'Referral Karyawan',
              'spouse_name': 'Ayu Lestari',
              'cust_address1': 'Jl. Merdeka No. 12, Bekasi',
            }),
      requiredDocs: const [
        'Formulir Aplikasi',
        'KTP Pemohon & Pasangan',
        'Surat Nikah/Cerai',
        'Kartu Keluarga',
        'Rekening Koran 3 Bulan Terakhir',
        'NPWP Pribadi',
        'Neraca Laba Rugi / Info Keuangan Terakhir',
        'Akte Pendirian Perusahaan & Ijin Usaha',
      ],
      docsUploaded: {
        'Formulir Aplikasi': true,
        'KTP Pemohon & Pasangan': true,
        'Surat Nikah/Cerai': true,
        'Kartu Keluarga': false,
        'Rekening Koran 3 Bulan Terakhir': false,
        'NPWP Pribadi': false,
        'Neraca Laba Rugi / Info Keuangan Terakhir': false,
        'Akte Pendirian Perusahaan & Ijin Usaha': false,
      },
      notes: [
        ReserveOrderChatMessage(
          who: 'Dian A.',
          role: 'Sales',
          time: '05 Sep, 09:12',
          text: 'Customer minta konfirmasi cicilan bisa mulai bulan depan, sudah saya sampaikan ke Kasir ya.',
          color: const Color(primaryColor),
        ),
        ReserveOrderChatMessage(
          who: 'Rina',
          role: 'Kasir',
          time: '05 Sep, 10:40',
          text: 'Noted, TTS akan saya buat setelah bukti transfer diverifikasi.',
          color: const Color(purpleColor),
        ),
      ],
    );
  }
}
