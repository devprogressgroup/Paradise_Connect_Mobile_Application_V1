

class PipelineDeal {
  final int dealId;
  final int contactId;
  final String contactName;
  final String? salutation;
  final String? phone;
  final String? whatsapp;
  
  final String? clusterName;
  final String? productName;
  final String? propertyName;
  final bool isWaitingList;
  final bool isHoek;
  
  final int? statusProspectId;
  final String? statusName;
  final String? statusValue;
  
  final String? ownerName;
  final String? seName;
  final String? salesTeamName;
  final double dealValue;
  
  final String? apptDate;
  final String? visitDate;
  final String? reserveDate;
  final String? spDate;
  final String? akadDate;
  final String? lostDate;
  final String? lostReasonName;
  final String? createdAt;

  PipelineDeal({
    required this.dealId,
    required this.contactId,
    required this.contactName,
    this.salutation,
    this.phone,
    this.whatsapp,
    this.clusterName,
    this.productName,
    this.propertyName,
    this.isWaitingList = false,
    this.isHoek = false,
    this.statusProspectId,
    this.statusName,
    this.statusValue,
    this.ownerName,
    this.seName,
    this.salesTeamName,
    this.dealValue = 0,
    this.apptDate,
    this.visitDate,
    this.reserveDate,
    this.spDate,
    this.akadDate,
    this.lostDate,
    this.lostReasonName,
    this.createdAt,
  });

  static int _toInt(dynamic v) => v is int ? v : (int.tryParse('${v ?? ''}') ?? 0);

  factory PipelineDeal.fromJson(Map<String, dynamic> j) {
    final c = Map<String, dynamic>.from((j['contact'] ?? {}) as Map);
    final u = Map<String, dynamic>.from((j['unit'] ?? {}) as Map);
    final s = Map<String, dynamic>.from((j['status'] ?? {}) as Map);
    final sl = Map<String, dynamic>.from((j['sales'] ?? {}) as Map);
    final dt = Map<String, dynamic>.from((j['dates'] ?? {}) as Map);
    final lo = Map<String, dynamic>.from((j['lost'] ?? {}) as Map);
    return PipelineDeal(
      dealId: _toInt(j['deal_id']),
      contactId: _toInt(j['contact_id']),
      contactName: (c['full_name'] ?? '').toString(),
      salutation: c['salutation']?.toString(),
      phone: c['primary_phone']?.toString(),
      whatsapp: c['whatsapp_number']?.toString(),
      clusterName: u['cluster_name']?.toString(),
      productName: u['product_name']?.toString(),
      propertyName: u['property_name']?.toString(),
      isWaitingList: _toInt(u['is_waiting_list']) == 1,
      isHoek: _toInt(u['is_tipe_hoek']) == 1,
      statusProspectId: s['status_prospect_id'] == null ? null : _toInt(s['status_prospect_id']),
      statusName: s['status_name']?.toString(),
      statusValue: s['status_value']?.toString(),
      ownerName: sl['owner_name']?.toString(),
      seName: sl['se_name']?.toString(),
      salesTeamName: sl['sales_team_name']?.toString(),
      dealValue: double.tryParse('${j['deal_value'] ?? 0}') ?? 0,
      apptDate: dt['appt_date']?.toString(),
      visitDate: dt['visit_date']?.toString(),
      reserveDate: dt['reserve_date']?.toString(),
      spDate: dt['sp_date']?.toString(),
      akadDate: dt['akad_date']?.toString(),
      lostDate: dt['lost_date']?.toString(),
      lostReasonName: lo['lost_reason_name']?.toString(),
      createdAt: j['created_at']?.toString(),
    );
  }
}


class PipelineDealsPage {
  final List<PipelineDeal> items;
  final int currentPage;
  final int lastPage;
  final int total;
  PipelineDealsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
