import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/services/salesbook_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/presentation/pages/unit-picker/index.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_event.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_state.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_block.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_event.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_state.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_event.dart';

import '../../../../../core/constants/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/widget/custom_dropdown_group.dart';
import '../../../../auth/domain/entities/user_profile.dart';
import '../../../../auth/presentation/state/profile/profile_bloc.dart';
import '../../../../auth/presentation/state/profile/profile_state.dart';
import '../../../data/arguments/contact_detail_args.dart';
import '../../../data/arguments/contact_dropdown_args.dart';
import '../../state/contact/contact_bloc.dart';
import '../../state/contact/contact_event.dart';
import '../../state/contact/contact_state.dart';
import '../../state/prospect_status/prospect_status_bloc.dart';
import '../../state/prospect_status/prospect_status_state.dart';
import '../../state/contact_properties/contact_properties_bloc.dart';
import '../../state/contact_properties/contact_properties_event.dart';
import '../../state/contact_properties/contact_properties_state.dart';
import '../../../domain/entities/contact/contact_property.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_state.dart';
import 'package:progress_group/features/contact/presentation/state/property_unit/property_unit_cubit.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import '../../../../../core/utils/widget/custom_file_picker.dart';
import '../../state/activity/activity_bloc.dart';
import '../../state/activity/activity_event.dart';
import '../../../domain/entities/pameran/pameran_aktif_entity.dart';
import '../../state/pameran_aktif/pameran_aktif_cubit.dart';

enum _DuplicateAction { cancel, proceed, openExisting }

class ContactFormPage extends StatefulWidget {
  final ContactDetailArgs args;
  const ContactFormPage({super.key, required this.args});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  TextEditingController fullNameTC = TextEditingController();
  TextEditingController emailTC = TextEditingController();
  TextEditingController waTC = TextEditingController();
  TextEditingController fBlockNoTC = TextEditingController();
  TextEditingController salesExecutiveTC = TextEditingController();
  TextEditingController salesManagerTC = TextEditingController();
  TextEditingController generalNotesTC = TextEditingController();

  TextEditingController lBlockNoTC = TextEditingController();
  TextEditingController noKTPTC = TextEditingController();
  TextEditingController ktpAddressTC = TextEditingController();
  TextEditingController volumePlanTC = TextEditingController();
  TextEditingController vCountTC = TextEditingController();
  TextEditingController firstVisitorDateTC = TextEditingController();
  TextEditingController lastVisitorDateTC = TextEditingController();
  TextEditingController firstApptDateTC = TextEditingController();
  TextEditingController lastApptDateTC = TextEditingController();
  TextEditingController dealValueTC = TextEditingController();
  TextEditingController reserveDateTC = TextEditingController();
  TextEditingController firstReserveDateTC = TextEditingController();
  TextEditingController lossReasonNoteTC = TextEditingController();
  TextEditingController fspTC = TextEditingController();
  TextEditingController lspTC = TextEditingController();
  TextEditingController fakadTC = TextEditingController();
  TextEditingController lakadTC = TextEditingController();
  TextEditingController createAdTC = TextEditingController();
  TextEditingController lastLostDateTC = TextEditingController();
  TextEditingController lostDateTC = TextEditingController();
  TextEditingController periodePameranDateTC = TextEditingController();
  TextEditingController nameSPTC = TextEditingController();

  String? selectedSalutation;
  int? selectedOwnerId;
  String? selectedOwnerName;
  int? selectedStatusId;
  String? selectedStatusProspectName;
  String? selectedProject;
  int? selectedChannelId;
  int? selectedTeamId;
  int? selectedSupervisorId;
  int? selectedSalesExecutiveId;
  String? selectedSalesExecutiveName;
  int? selectedSalesManagerId;
  int? selectedGeneralManagerId;

  String? selectedSalesManagerName;
  String? selectFirstProject;
  String? selectLastProject;
  int? selectFirstTownshipId;
  int? selectLastTownshipId;
  String? selectFirstProjectProduct;
  String? selectLastProjectProduct;
  String? selectFirstProjectCategory;
  String? selectLastProjectCategory;
  String? selectProductType;
  int? selectLastClusterId;
  int? selectLastCommercialId;
  int? selectLastProductId;
  int? _existingFirstProjectId;
  int? _existingFirstClusterId;
  int? _existingFirstCommercialId;
  int? _existingFirstProductId;
  String? selectedSourceName;
  int? selectedSourceId;
  String? selectedSource1Name;
  int? selectedSource1Id;
  String? selectedSource2Name;
  int? selectedSource2Id;
  int? selectedLostReasonId;
  String? selectedLostReasonName;

  List<Map<String, dynamic>> salesInfoFields = [];
  final Map<int, TextEditingController> _propertyControllers = {};
  final Map<int, FocusNode> _propertyFocusNodes = {};
  final Map<int, PickedFileResult?> _propertyFiles = {};
  bool _propertyFocusHandled = false;
  bool _isDialogShowing = false;

  FocusNode fullNameFN = FocusNode();
  FocusNode emailFN = FocusNode();
  FocusNode waFN = FocusNode();
  FocusNode fBlockNoFN = FocusNode();
  FocusNode salesExecutiveFN = FocusNode();
  FocusNode salesManagerFN = FocusNode();
  FocusNode generalNotesFN = FocusNode();

  FocusNode lBlockNoFN = FocusNode();
  FocusNode noKTPFN = FocusNode();
  FocusNode ktpAddressFN = FocusNode();
  FocusNode volumePlanFN = FocusNode();
  FocusNode vCountFN = FocusNode();
  FocusNode firstVisitorDateFN = FocusNode();
  FocusNode lastVisitorDateFN = FocusNode();
  FocusNode firstApptDateFN = FocusNode();
  FocusNode lastApptDateFN = FocusNode();
  FocusNode dealValueFN = FocusNode();
  FocusNode reserveDateFN = FocusNode();
  FocusNode firstReserveDateFN = FocusNode();
  FocusNode lossReasonNoteFN = FocusNode();
  FocusNode fspFN = FocusNode();
  FocusNode lspFN = FocusNode();
  FocusNode fakadFN = FocusNode();
  FocusNode lakadFN = FocusNode();
  FocusNode createAdFN = FocusNode();
  FocusNode lastLostDateFN = FocusNode();
  FocusNode periodePameranDateFN = FocusNode();
  FocusNode nameSPFN = FocusNode();

  String? _periodePameranDateBackend;
  static const Set<String> _requiredLabels = {'Salutation', 'Full Name', 'Hp/Whatsapp', 'Owner', 'Project', 'Sales Channel', 'Sales Channel Detail', 'Note'};

  bool _showValidation = false;
  bool _isSaving = false;
  String? _highlightedField;

  
  List<SelectedUnit> _selectedUnits = [];
  
  List<SelectedUnit> _allUnits = [];
  bool _unitsTouched = false;
  
  
  bool _unitsLoaded = false;
  
  
  bool get _canManageUnits => widget.args.page == 0 || (widget.args.page == 1 && _unitsLoaded);

  
  
  List<SelectedUnit> _activeUnitsForTownship(int? townshipId) =>
      _allUnits.where((u) => !u.isLost && (townshipId == null || u.townshipId == townshipId)).toList();

  final List<OwnerDropdownItem> itemsProjectCategory = [
    OwnerDropdownItem(name: "Residential"),
    OwnerDropdownItem(name: "Commercial"),
  ];

  final List<OwnerDropdownItem> itemsJmlDatang = [
    OwnerDropdownItem(name: "1"),
    OwnerDropdownItem(name: "2"),
    OwnerDropdownItem(name: "3"),
    OwnerDropdownItem(name: "4"),
    OwnerDropdownItem(name: ">5"),
  ];

  final List<OwnerDropdownItem> itemsVolume = [
    OwnerDropdownItem(name: "1"),
    OwnerDropdownItem(name: "2"),
    OwnerDropdownItem(name: "3"),
    OwnerDropdownItem(name: "4"),
    OwnerDropdownItem(name: ">5"),
  ];

  final List<OwnerDropdownItem> itemsLastProjectCategory = [
    OwnerDropdownItem(name: "Residential"),
    OwnerDropdownItem(name: "Commercial"),
  ];

  final ScrollController _scrollController = ScrollController();
  bool _hideWhatsappField = false;
  bool _formInitialized = false;
  double _lastOffset = 0;
  final Map<String, GlobalKey> _fieldKeys = {};

  CreateContactParams createContactParams = CreateContactParams();

  
  
  
  Widget _buildUnitField() {
    final isAbout = widget.args.page == 2;

    
    final VoidCallback? rowTap = isAbout
        ? () => _goToEdit(focusField: 'Produk/Unit')
        : (_canManageUnits ? _openUnitPicker : _editUnitNotice);
    
    final bool showChevron = !isAbout && _canManageUnits;

    if (_selectedUnits.isEmpty) {
      return _unitFieldRow(value: '', onTap: rowTap, showChevron: showChevron);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final u in _selectedUnits)
          _unitFieldRow(
            value: _unitDisplay(u),
            onTap: rowTap,
            showChevron: showChevron,
            isHoek: u.isTipeHoek,
          ),
      ],
    );
  }

  
  
  String _unitDisplay(SelectedUnit u) {
    final tail = [u.productName, u.clusterName]
        .where((e) => (e ?? '').toString().trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(' ');
    if (u.propertyId != null && (u.propertyName ?? '').trim().isNotEmpty) {
      return [u.propertyName!.trim(), tail].where((e) => e.isNotEmpty).join(' ');
    }
    final status = u.isWaitingList ? 'Waiting list' : 'Belum tentukan kavling';
    return tail.isNotEmpty ? '$tail · $status' : status;
  }

  
  
  Widget _unitFieldRow({
    required String value,
    required VoidCallback? onTap,
    required bool showChevron,
    bool isHoek = false,
  }) {
    final bool isEmpty = value.trim().isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          border: Border(bottom: BorderSide(width: 1, color: Color(grey9Color))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEmpty) ...[
                    Text('Produk/Unit',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(grey2Color))),
                    const SizedBox(height: 2),
                  ],
                  isEmpty
                      ? Text('Produk/Unit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(grey2Color)))
                      : Row(
                          children: [
                            Flexible(
                              child: Text(value,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blackColor))),
                            ),
                            if (isHoek)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Hook',
                                    style: TextStyle(fontSize: 9, color: Color(0xFFB26A00), fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.arrow_drop_down, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _openUnitPicker() async {
    AnalyticsService.logEvent('contact_form_select_unit');
    final townshipId = selectLastTownshipId ?? selectFirstTownshipId;
    final townshipName = selectLastProject ?? selectFirstProject;
    if (townshipId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Project terlebih dahulu')),
      );
      return;
    }
    final result = await Navigator.of(context).push<List<SelectedUnit>>(
      MaterialPageRoute(
        builder: (_) => UnitPickerScreen(
          townshipId: townshipId,
          townshipName: townshipName ?? 'Project',
          initial: _selectedUnits,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedUnits = result;
        _unitsTouched = true;
      });
    }
  }

  void _editUnitNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kelola unit untuk kontak yang sudah ada akan segera tersedia.')),
    );
  }

  CreateContactParams _buildCurrentParams() {
    final isUpdate = widget.args.page == 1;
    final List<Map<String, dynamic>> propertiesJson = [];
    _propertyControllers.forEach((id, ctrl) {
      if (ctrl.text.isNotEmpty && _propertyFiles[id] == null) {
        propertiesJson.add({'property_id': id, 'property_value': ctrl.text});
      }
    });
    Map<int, Uint8List>? fileBytes;
    Map<int, String>? fileNames;
    _propertyFiles.forEach((id, file) {
      if (file != null && file.bytes != null) {
        (fileBytes ??= {})[id] = file.bytes!;
        (fileNames ??= {})[id] = file.name;
      }
    });
    final _normalizedPhone = waTC.text.isNotEmpty ? _normalizePhone(waTC.text) : null;
    return CreateContactParams(
      salutation: selectedSalutation,
      fullName: fullNameTC.text.isNotEmpty ? fullNameTC.text : null,
      primaryPhone: _normalizedPhone,
      whatsappNumber: _normalizedPhone,
      primaryEmail: emailTC.text.isNotEmpty ? emailTC.text : null,
      ownerId: selectedOwnerId,
      salesExecutiveId: selectedSalesExecutiveId,
      salesManagerId: selectedSalesManagerId,
      salesSupervisorId: selectedSupervisorId,
      salesGeneralManagerId: selectedGeneralManagerId,
      salesTeamId: selectedTeamId,
      statusProspectId: selectedStatusId,
      lastProject: isUpdate ? selectLastProject : selectFirstProject,
      firstProject: isUpdate ? null : selectFirstProject,
      lastProjectCategory: isUpdate ? selectLastProjectCategory : null,
      firstProjectCategory: isUpdate ? null : selectFirstProjectCategory,
      productType: selectProductType,
      lastProduct: isUpdate ? selectLastProjectProduct : null,
      firstProduct: isUpdate ? null : selectFirstProjectProduct,
      lastBlokNo: isUpdate ? (lBlockNoTC.text.isNotEmpty ? lBlockNoTC.text : null) : null,
      firstBlokNo: isUpdate ? null : (fBlockNoTC.text.isNotEmpty ? fBlockNoTC.text : null),
      lastProjectId: isUpdate ? selectLastTownshipId : null,
      firstProjectId: isUpdate ? null : (_existingFirstProjectId == null ? selectFirstTownshipId : null),
      lastClusterId: isUpdate ? selectLastClusterId : null,
      firstClusterId: isUpdate ? (_existingFirstClusterId == null ? selectLastClusterId : null) : null,
      lastCommercialId: isUpdate ? selectLastCommercialId : null,
      firstCommercialId: isUpdate ? (_existingFirstCommercialId == null ? selectLastCommercialId : null) : null,
      lastProductId: isUpdate ? selectLastProductId : null,
      firstProductId: isUpdate ? (_existingFirstProductId == null ? selectLastProductId : null) : null,
      salesChannelId: selectedSource1Id,
      sumberInformasi2: selectedSource2Id?.toString(),
      generalNotes: generalNotesTC.text.isNotEmpty ? generalNotesTC.text : null,
      lostReasonId: selectedLostReasonId,
      lostReasonNote: lossReasonNoteTC.text.isNotEmpty ? lossReasonNoteTC.text : null,
      lastApptDate: _toBackendDate(isUpdate ? lastApptDateTC.text : firstApptDateTC.text),
      firstApptDate: _toBackendDate(firstApptDateTC.text),
      lastVisitDate: _toBackendDate(isUpdate ? lastVisitorDateTC.text : firstVisitorDateTC.text),
      firstVisitDate: _toBackendDate(firstVisitorDateTC.text),
      reserveDate: _toBackendDate(reserveDateTC.text),
      lastReserveDate: _toBackendDate(reserveDateTC.text),
      firstReserveDate: _toBackendDate(firstReserveDateTC.text.isNotEmpty ? firstReserveDateTC.text : reserveDateTC.text),
      lastSPDate: _toBackendDate(lspTC.text),
      firstSPDate: _toBackendDate(fspTC.text),
      lastAkadDate: _toBackendDate(lakadTC.text),
      firstAkadDate: _toBackendDate(fakadTC.text),
      lostDate: _toBackendDate(lastLostDateTC.text),
      lastLostDate: _toBackendDate(lastLostDateTC.text),
      dealValue: dealValueTC.text.isNotEmpty ? dealValueTC.text : null,
      visitCount: vCountTC.text.isNotEmpty ? int.tryParse(vCountTC.text) : null,
      volumePlan: volumePlanTC.text.isNotEmpty ? volumePlanTC.text : null,
      nameSP: nameSPTC.text.isNotEmpty ? nameSPTC.text : null,
      noKtp: noKTPTC.text.isNotEmpty ? noKTPTC.text : null,
      ktpAddress: ktpAddressTC.text.isNotEmpty ? ktpAddressTC.text : null,
      propertiesJson: propertiesJson.isNotEmpty ? propertiesJson : null,
      propertyFileBytes: fileBytes,
      propertyFileNames: fileNames,
      periodePameranDate: _isPameranSource1(selectedSource1Id) ? _periodePameranDateBackend : null,
      periodePameranId: _isPameranSource1(selectedSource1Id) ? _resolvePeriodePameranId() : null,

      units: ((widget.args.page == 0 && _selectedUnits.isNotEmpty) || (widget.args.page != 0 && _unitsTouched))
          ? _selectedUnits.map((u) => u.toApiJson()).toList()
          : null,
    );
  }

  void _syncParams() {
    _syncPameranBackendDate();
    createContactParams = _buildCurrentParams();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    createContactParams = _buildCurrentParams();
  }

  void _addControllerListeners() {
    for (final tc in [
      fullNameTC, emailTC, waTC, fBlockNoTC, salesExecutiveTC, salesManagerTC,
      generalNotesTC, lBlockNoTC, noKTPTC, ktpAddressTC, volumePlanTC, vCountTC,
      firstVisitorDateTC, lastVisitorDateTC, firstApptDateTC, lastApptDateTC,
      dealValueTC, reserveDateTC, firstReserveDateTC, lossReasonNoteTC,
      fspTC, lspTC, fakadTC, lakadTC, createAdTC, lastLostDateTC, lostDateTC,
      periodePameranDateTC, nameSPTC,
    ]) {
      tc.addListener(_syncParams);
    }
  }

  void _syncPameranBackendDate() {
    final text = periodePameranDateTC.text;
    if (text.isEmpty) {
      _periodePameranDateBackend = null;
      return;
    }
    final parsed = _parseDateOrToday(text);
    final now = AppTime.now();
    final combined = DateTime(parsed.year, parsed.month, parsed.day, now.hour, now.minute, now.second);
    _periodePameranDateBackend = '${DateHelper.formatNumericCompact(combined)} ${DateFormat('HH:mm:ss').format(combined)}';
  }

  InfoSource? _findInfoSource(int type, int? id) {
    if (id == null) return null;
    final sources = context.read<InfoSourceBloc>().state.sourcesMap[type];
    if (sources == null) return null;
    return sources.cast<InfoSource?>().firstWhere((e) => e?.id == id, orElse: () => null);
  }

  bool _isPameranSource1(int? sourceId) => _findInfoSource(1, sourceId)?.isPameran ?? false;

  List<InfoSource> _dedupeByName(List<InfoSource> sources) {
    final seen = <String>{};
    return sources.where((s) => seen.add(s.name)).toList();
  }

  

  void _applyPameranDate(List<PameranAktifEntity> list, DateTime fallbackNow) {
    if (list.isEmpty) {
      periodePameranDateTC.text = '';
      _periodePameranDateBackend = null;
      return;
    }
    periodePameranDateTC.text = DateHelper.formatDate(_clampToPameranRange(fallbackNow, list));
    _syncPameranBackendDate();
  }

  DateTime _clampToPameranRange(DateTime date, List<PameranAktifEntity> list) {
    if (list.isEmpty) return date;
    final firstDate = list.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = list.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
    if (date.isBefore(firstDate)) return firstDate;
    if (date.isAfter(lastDate)) return lastDate;
    return date;
  }

  int? _resolvePeriodePameranId() {
    final text = periodePameranDateTC.text;
    if (text.isEmpty) return null;
    final picked = _parseDateOrToday(text);
    final pickedDate = DateTime(picked.year, picked.month, picked.day);
    final ps = context.read<PameranAktifCubit>().state;
    if (ps is! PameranAktifLoaded) return null;
    for (final e in ps.data) {
      final start = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
      final end = DateTime(e.endDate.year, e.endDate.month, e.endDate.day);
      if (!pickedDate.isBefore(start) && !pickedDate.isAfter(end)) {
        return e.periodeId;
      }
    }
    return null;
  }

  TextEditingController _getOrCreatePropertyController(int propertyId) {
    if (!_propertyControllers.containsKey(propertyId)) {
      final ctrl = TextEditingController();
      ctrl.addListener(_syncParams);
      _propertyControllers[propertyId] = ctrl;
    }
    return _propertyControllers[propertyId]!;
  }

  FocusNode _getOrCreatePropertyFocusNode(int propertyId) {
    return _propertyFocusNodes.putIfAbsent(propertyId, () => FocusNode());
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('contact_form');
    _init();
  }



  void _init() async {
    _addControllerListeners();
    final contactId = widget.args.dataContact?.contactId;
    final contactState = context.read<ContactBloc>().state;
    final currentDetail = contactState.contactDetail;

    
    final hasLatestDetail =
        currentDetail != null && currentDetail.contactId == contactId;

    if (widget.args.page == 1) {
      
      if (hasLatestDetail) {
        await _fillForm(currentDetail);
      } else if (widget.args.dataContact != null) {
        await _fillForm(widget.args.dataContact!);
        
        if (!_unitsLoaded && contactId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<ContactBloc>().add(FetchContactDetailEvent(contactId));
          });
        }
      }
      _formInitialized = true;
      if (widget.args.focusField != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToField(widget.args.focusField!);
            setState(() => _highlightedField = widget.args.focusField);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _highlightedField = null);
            });
          }
        });
      }
    } else if (widget.args.page == 2 && widget.args.dataContact != null) {
      
      
      
      if (hasLatestDetail) {
        await _fillForm(currentDetail);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ContactBloc>().add(FetchContactDetailEvent(contactId!));
        });
      }
    }

    if (context.read<ProspectStatusBloc>().state.status !=
        ProspectStatusEnum.loaded) {

      context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
    } else {

    }

    if (context.read<InfoSourceBloc>().state.sourcesMap[1] == null) {
      context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
    }

    if (context.read<InfoSourceBloc>().state.sourcesMap[2] == null) {
      context.read<InfoSourceBloc>().add(FetchInfoSourcesEvent(type: 2, userId: selectedOwnerId, salesChannel: selectedSource1Name, all: widget.args.page == 1));
    }


    final townshipState = context.read<TownshipBloc>().state;
    if (townshipState is! TownshipLoaded) {
      
      context.read<TownshipBloc>().add(GetTownshipsEvent());
    } else if (widget.args.page == 0 && selectFirstProject == null && townshipState.townships.isNotEmpty) {
      final first = townshipState.townships.first;
      setState(() {
        selectFirstProject = first.name;
        selectFirstTownshipId = first.id;
      });
    }
    if (context.read<ContactPropertiesBloc>().state.status != ContactPropertiesStatus.loaded) {
      
      context.read<ContactPropertiesBloc>().add(FetchContactPropertiesEvent());
    } else {
      
    }
    if (context.read<LostReasonBloc>().state.status != LostReasonStatus.loaded) {
      
      context.read<LostReasonBloc>().add(FetchLostReasonsEvent());
    }

    if (widget.args.page == 0) {
      final statusState = context.read<ProspectStatusBloc>().state;
      if (statusState.status == ProspectStatusEnum.loaded && statusState.statuses.isNotEmpty) {
        setState(() {
          selectedStatusId = statusState.statuses.first.statusProspectId;
          selectedStatusProspectName = statusState.statuses.first.statusProspectName;
        });
      }
    }

    if (widget.args.page == 0 && widget.args.dataContact == null) {
      final today = DateHelper.formatDate(AppTime.now());

      setState(() {
        if (firstApptDateTC.text.isEmpty) firstApptDateTC.text = today;
        if (firstVisitorDateTC.text.isEmpty) firstVisitorDateTC.text = today;
        if (fspTC.text.isEmpty) fspTC.text = today;
        if (lspTC.text.isEmpty) lspTC.text = today;
        if (fakadTC.text.isEmpty) fakadTC.text = today;
        if (lakadTC.text.isEmpty) lakadTC.text = today;
        if (createAdTC.text.isEmpty) createAdTC.text = today;
        if (lastLostDateTC.text.isEmpty) lastLostDateTC.text = today;

        
        if (dealValueTC.text.isEmpty) dealValueTC.text = "0";
        if (vCountTC.text.isEmpty) vCountTC.text = "0";

        selectedSalutation ??= "Bapak";
      });
    }

     _scrollController.addListener(() {
      if (_scrollController.offset > _lastOffset &&
          _scrollController.offset > 50) {
        if (!_hideWhatsappField) {
          setState(() => _hideWhatsappField = true);
        }
      } else {
        if (_hideWhatsappField) {
          setState(() => _hideWhatsappField = false);
        }
      }

      _lastOffset = _scrollController.offset;
    });
  }

  Future<void> _fillForm(ContactEntity contact) async {
    
    
    if (contact.units != null) {
      _allUnits = List.of(contact.units!);
      _selectedUnits = _activeUnitsForTownship(contact.lastProjectId);
      _unitsLoaded = true;
    }
    fullNameTC.text = contact.fullName ?? '';
    emailTC.text = contact.primaryEmail ?? '';
    waTC.text = contact.whatsappNumber ?? '';
    fBlockNoTC.text = contact.firstBlokNo ?? '';
    selectFirstProject = contact.firstProject?.isNotEmpty == true ? contact.firstProject : null;
    selectLastProject = contact.lastProject?.isNotEmpty == true ? contact.lastProject : null;
    generalNotesTC.text = contact.generalNotes ?? '';
    lBlockNoTC.text = contact.lastBlokNo ?? '';
    noKTPTC.text = contact.noKtp ?? '';
    ktpAddressTC.text = contact.ktpAddress ?? '';
    selectedSource1Name = contact.sumberInformasi1;
    selectedSource1Id = contact.salesChannelId;
    selectedSource2Name = contact.sumberInformasi2Name;
    selectedSource2Id = int.tryParse(contact.sumberInformasi2 ?? '');
    final source2ForPrefill = _findInfoSource(2, selectedSource2Id);
    if (source2ForPrefill?.periodePameranId != null) {
      final fallbackNow = AppTime.now();
      periodePameranDateTC.text = DateHelper.formatDate(fallbackNow);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<PameranAktifCubit>().load(lokasiPameran: source2ForPrefill!.name, userId: selectedOwnerId, all: widget.args.page == 1);
        if (!mounted) return;
        final ps = context.read<PameranAktifCubit>().state;
        final list = ps is PameranAktifLoaded ? ps.data : <PameranAktifEntity>[];
        // _notifyIfNoPameranAktif(list);
        setState(() {
          _applyPameranDate(list, fallbackNow);
        });
      });
    }
    volumePlanTC.text = contact.volumePlan?.toString() ?? '';
    vCountTC.text = contact.visitCount?.toString() ?? '';
    nameSPTC.text = contact.nameSP ?? '';
    
    firstVisitorDateTC.text = contact.firstVisitDate != null ? DateHelper.formatDate(DateTime.parse(contact.firstVisitDate!)) : '';
    lastVisitorDateTC.text = contact.lastVisitDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastVisitDate!)) : '';
    firstApptDateTC.text = contact.firstApptDate != null ? DateHelper.formatDate(DateTime.parse(contact.firstApptDate!)) : '';
    lastApptDateTC.text = contact.lastApptDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastApptDate!)) : '';
    
    dealValueTC.text = contact.dealValue ?? '';
    
    reserveDateTC.text = contact.lastReserveDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastReserveDate!)) : '';
    firstReserveDateTC.text = contact.firstReserveDate != null ? DateHelper.formatDate(DateTime.parse(contact.firstReserveDate!)) : '';
    lossReasonNoteTC.text = contact.lostReasonNote ?? '';
    fspTC.text = contact.firstSpDate != null ? DateHelper.formatDate(DateTime.parse(contact.firstSpDate!)) : '';
    lspTC.text = contact.lastSpDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastSpDate!)) : '';
    fakadTC.text = contact.firstAkadDate != null ? DateHelper.formatDate(DateTime.parse(contact.firstAkadDate!)) : '';
    lakadTC.text = contact.lastAkadDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastAkadDate!)) : '';
    createAdTC.text = contact.createdAt != null ? DateHelper.formatDate(DateTime.parse(contact.createdAt!)) : '';
    lastLostDateTC.text = contact.lastLostDate != null ? DateHelper.formatDate(DateTime.parse(contact.lastLostDate!)) : '';

    setState(() {
      selectedSalutation = contact.salutation;
      selectedOwnerId = contact.ownerId ?? contact.salesExecutiveId;
      selectedStatusId = contact.statusProspectId;
      selectedSalesExecutiveId = contact.salesExecutiveId;
      selectedSalesManagerId = contact.salesManagerId;
      selectedSupervisorId = contact.salesSupervisorId;
      selectedGeneralManagerId = contact.salesGeneralManagerId;
      selectedTeamId = contact.salesTeamId;
      selectedLostReasonId = contact.lostReasonId;
      if (contact.lostReasonId != null) {
        final lostState = context.read<LostReasonBloc>().state;
        if (lostState.status == LostReasonStatus.loaded) {
          final match = lostState.reasons.where((e) => e.lostReasonId == contact.lostReasonId).toList();
          if (match.isNotEmpty) selectedLostReasonName = match.first.lostReasonName;
        }
      }

      
      if ((contact.projectName ?? '').isNotEmpty) selectFirstProject = contact.projectName;
      if ((contact.firstProject ?? '').isNotEmpty) selectFirstProject = contact.firstProject;
      if ((contact.lastProject ?? '').isNotEmpty) selectLastProject = contact.lastProject;

      selectFirstProjectCategory = contact.firstProjectCategory?.isNotEmpty == true ? contact.firstProjectCategory : null;
      selectLastProjectCategory = contact.lastProjectCategory?.isNotEmpty == true ? contact.lastProjectCategory : null;
      selectFirstProjectProduct = contact.firstProduct?.isNotEmpty == true ? contact.firstProduct : null;
      selectLastProjectProduct = contact.lastProduct?.isNotEmpty == true ? contact.lastProduct : null;
      selectProductType = contact.productType?.isNotEmpty == true ? contact.productType : null;

      _existingFirstProjectId = contact.firstProjectId;
      _existingFirstClusterId = contact.firstClusterId;
      _existingFirstCommercialId = contact.firstCommercialId;
      _existingFirstProductId = contact.firstProductId;
      selectLastClusterId = contact.lastClusterId;
      selectLastCommercialId = contact.lastCommercialId;
      selectLastProductId = contact.lastProductId;

      
      if (contact.firstProjectId != null) selectFirstTownshipId = contact.firstProjectId;
      if (contact.lastProjectId != null) selectLastTownshipId = contact.lastProjectId;

      final townshipState = context.read<TownshipBloc>().state;
      if (townshipState is TownshipLoaded) {
        for (final t in townshipState.townships) {
          if (selectFirstTownshipId == null &&
              selectFirstProject != null &&
              t.name.trim().toLowerCase() == selectFirstProject!.trim().toLowerCase()) {
            selectFirstTownshipId = t.id;
          }
          if (selectLastTownshipId == null &&
              selectLastProject != null &&
              t.name.trim().toLowerCase() == selectLastProject!.trim().toLowerCase()) {
            selectLastTownshipId = t.id;
          }
        }
      }

      if (selectLastTownshipId != null) {
        context.read<PropertyUnitCubit>().load(
          selectLastTownshipId!,
          isCommercial: selectLastProjectCategory?.toLowerCase() == 'commercial',
        );
      }

      if ((contact.blokNo ?? '').isNotEmpty) {
        fBlockNoTC.text = contact.blokNo!;
      }

      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded) {
        final user = profileState.profile;

        
        String? findName(int? id) {
          if (id == null) return null;
          if (user.salesPersonId == id) return user.fullName;

          HierarchyNodeEntity? foundSub;
          void searchSub(List<HierarchyNodeEntity> subs) {
            for (var s in subs) {
              if (s.salesPersonId == id) foundSub = s;
              if (foundSub == null && s.subordinates.isNotEmpty)
                searchSub(s.subordinates);
            }
          }

          searchSub(user.subordinates);
          if (foundSub != null) return foundSub!.fullName;

          HierarchyNodeEntity? foundAtasan;
          void searchAtasan(HierarchyNodeEntity? current) {
            while (current != null) {
              if (current.salesPersonId == id) {
                foundAtasan = current;
                break;
              }
              current = current.parent;
            }
          }

          for (var role in user.salesRoles) {
            searchAtasan(role);
            if (foundAtasan != null) break;
          }
          if (foundAtasan != null) return foundAtasan!.fullName;

          return null;
        }

        
        String? findNameByUserId(int? userId) {
          if (userId == null) return null;
          if (user.userId == userId) return user.fullName;

          HierarchyNodeEntity? foundSub;
          void searchSub(List<HierarchyNodeEntity> subs) {
            for (var s in subs) {
              if (s.userId == userId) foundSub = s;
              if (foundSub == null && s.subordinates.isNotEmpty)
                searchSub(s.subordinates);
            }
          }

          searchSub(user.subordinates);
          if (foundSub != null) return foundSub!.fullName;

          HierarchyNodeEntity? foundAtasan;
          void searchAtasan(HierarchyNodeEntity? current) {
            while (current != null) {
              if (current.userId == userId) {
                foundAtasan = current;
                break;
              }
              current = current.parent;
            }
          }

          for (var role in user.salesRoles) {
            searchAtasan(role);
            if (foundAtasan != null) break;
          }
          if (foundAtasan != null) return foundAtasan!.fullName;

          return null;
        }

        selectedOwnerName = contact.ownerName ?? findNameByUserId(selectedOwnerId);
        selectedSalesExecutiveName = contact.salesExecutiveName ?? findName(selectedSalesExecutiveId);
        selectedSalesManagerName = contact.salesManagerName ?? findName(selectedSalesManagerId);

        
        if (widget.args.page != 0) {
          salesInfoFields.clear();
          if (contact.salesTeamName != null) {
            salesInfoFields.add({'label': 'Sales Team', 'name': contact.salesTeamName!, 'id': contact.salesTeamId});
          }
          if (contact.salesExecutiveName != null || contact.salesExecutiveId != null) {
            salesInfoFields.add({'label': 'Sales Executive', 'name': contact.salesExecutiveName ?? findName(contact.salesExecutiveId) ?? '', 'id': contact.salesExecutiveId});
          }
          if (contact.salesSupervisorName != null || contact.salesSupervisorId != null) {
            salesInfoFields.add({'label': 'Sales Supervisor', 'name': contact.salesSupervisorName ?? findName(contact.salesSupervisorId) ?? '', 'id': contact.salesSupervisorId});
          }
          if (contact.salesManagerName != null || contact.salesManagerId != null) {
            salesInfoFields.add({'label': 'Sales Manager', 'name': contact.salesManagerName ?? findName(contact.salesManagerId) ?? '', 'id': contact.salesManagerId});
          }
          if (contact.salesGeneralManagerName != null || contact.salesGeneralManagerId != null) {
            salesInfoFields.add({'label': 'General Manager', 'name': contact.salesGeneralManagerName ?? findName(contact.salesGeneralManagerId) ?? '', 'id': contact.salesGeneralManagerId});
          }
        }
      }

      final statusState = context.read<ProspectStatusBloc>().state;
      if (statusState.status == ProspectStatusEnum.loaded) {
        selectedStatusProspectName = statusState.statuses
            .cast<ProspectStatusEntity?>()
            .firstWhere(
              (e) => e?.statusProspectId == selectedStatusId,
              orElse: () => null,
            )
            ?.statusProspectName;
      }
      
      try {
        final groups = contact.propertyGroupsJson;
        if (groups != null) {
          for (final g in groups) {
            final props = (g['contact_properties'] as List<dynamic>?) ?? [];
            for (final p in props) {
              final pid = p['property_id'];
              final val = p['property_value'];
              if (pid != null) {
                final ctrl = _getOrCreatePropertyController(pid as int);
                if (val != null)
                  ctrl.text = val.toString();
              }
            }
          }
        }
      } catch (e) {
        
      }

      try {
        final pj = contact.propertiesJson;
        if (pj != null) {
          dynamic parsed;
          if (pj is String) {
            parsed = jsonDecode(pj);
          } else {
            parsed = pj;
          }

          if (parsed is List) {
            for (final p in parsed) {
              try {
                final pid = p['property_id'] ?? p['id'];
                final val =
                    p['property_value'] ?? p['value'] ?? p['propertyValue'];
                if (pid != null) {
                  final id = int.tryParse(pid.toString()) ?? pid as int;
                  final ctrl = _getOrCreatePropertyController(id);
                  if (val != null)
                    ctrl.text = val.toString();
                }
              } catch (_) {}
            }
          } else if (parsed is Map) {
            
            parsed.forEach((k, v) {
              try {
                final id = int.tryParse(k.toString());
                if (id != null) {
                  final ctrl = _getOrCreatePropertyController(id);
                  if (v != null) ctrl.text = v.toString();
                }
              } catch (_) {}
            });
          }
        }
      } catch (e) {
        
      }

      
      if (widget.args.page == 0 && selectedOwnerId != null) {
        final profileState = context.read<ProfileBloc>().state;
        if (profileState is ProfileLoaded) {
          _updateSalesInformation(selectedOwnerId!, profileState.profile);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ps = context.read<ProfileBloc>().state;
            if (ps is ProfileLoaded)
              _updateSalesInformation(selectedOwnerId!, ps.profile);
          });
        }
      }
    });
  }

  void _autoFillFromProfile() {
      final profileState = context.read<ProfileBloc>().state;

      if (profileState is ProfileLoaded) {
        final user = profileState.profile;

        if (widget.args.page == 0) {
          final List<OwnerDropdownItem> ownerItems = [];

          ownerItems.add(OwnerDropdownItem(id: user.userId, name: user.fullName, subtitle: user.positionName));

          void addSubs(List<HierarchyNodeEntity> subs) {
            for (var s in subs) {
              ownerItems.add(OwnerDropdownItem(id: s.userId, name: s.fullName, subtitle: s.positionName));

              if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
            }
          }

          addSubs(user.subordinates);

          
          if (selectedOwnerId == null && ownerItems.isNotEmpty) {
            setState(() {
              selectedOwnerId = ownerItems.first.id;
              selectedOwnerName = ownerItems.first.name;
            });

            _updateSalesInformation(ownerItems.first.id ?? 0, user);
          }
        }
      }
    }
  
  bool _guardSalesChain(List<bool> priorFilled, List<String> priorLabels) {
    for (var i = 0; i < priorFilled.length; i++) {
      if (!priorFilled[i]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Isi ${priorLabels[i]} terlebih dahulu')),
        );
        return false;
      }
    }
    return true;
  }

  void _updateSalesInformation(int ownerUserId, UserProfileEntity user) {
    List<HierarchyNodeEntity> chain = [];

    List<HierarchyNodeEntity>? findPath(
      List<HierarchyNodeEntity> nodes,
      int userId,
    ) {
      for (var node in nodes) {
        if (node.userId == userId) return [node];
        var subPath = findPath(node.subordinates, userId);
        if (subPath != null) return [node, ...subPath];
      }
      return null;
    }

    
    var subordinatePath = findPath(user.subordinates, ownerUserId);
    if (subordinatePath != null) {
      
      final superiors = <HierarchyNodeEntity>[];
      if (user.salesRoles.isNotEmpty) {
        HierarchyNodeEntity? current = user.salesRoles.first;
        bool isRoot = true;
        while (current != null) {
          
          
          if (isRoot && current.salesPersonParentId != null) {
            superiors.add(HierarchyNodeEntity(
              salesPersonId: current.salesPersonParentId!,
              fullName: current.fullName,
              positionName: current.positionName,
              salesTeamId: current.salesTeamId,
              salesTeamName: current.salesTeamName,
            ));
          } else {
            superiors.add(current);
          }
          isRoot = false;
          current = current.parent;
        }
      }

      
      
      
      if (user.salesPersonId != null) {
        final userNode = HierarchyNodeEntity(
          salesPersonId: user.salesPersonId!,
          fullName: user.fullName,
          positionName: user.positionName,
        );
        chain = [...superiors.reversed, userNode, ...subordinatePath];
      } else {
        chain = [...superiors.reversed, ...subordinatePath];
      }
    } else if (user.userId == ownerUserId) {
      
      final userNode = HierarchyNodeEntity(
        salesPersonId: user.salesPersonId!,
        userId: user.userId,
        fullName: user.fullName,
        positionName: user.positionName,
      );
      chain = [userNode];

      if (user.salesRoles.isNotEmpty) {
        HierarchyNodeEntity? current = user.salesRoles.first;
        bool isRoot = true;
        while (current != null) {
          if (isRoot && current.salesPersonParentId != null) {
            chain.add(HierarchyNodeEntity(
              salesPersonId: current.salesPersonParentId!,
              fullName: current.fullName,
              positionName: current.positionName,
              salesTeamId: current.salesTeamId,
              salesTeamName: current.salesTeamName,
            ));
          } else {
            chain.add(current);
          }
          isRoot = false;
          current = current.parent;
        }
      }
    } else {
      
      for (var role in user.salesRoles) {
        HierarchyNodeEntity? current = role;
        List<HierarchyNodeEntity> temp = [];
        bool found = false;
        while (current != null) {
          temp.add(current);
          if (current.userId == ownerUserId) {
            found = true;
            break;
          }
          current = current.parent;
        }
        if (found) {
          chain = temp;
          break;
        }
      }
    }

    setState(() {
      salesInfoFields.clear();
      if (chain.isNotEmpty) {
        List<HierarchyNodeEntity> displayChain;
        if (subordinatePath != null) {
          displayChain = chain.reversed.toList();
        } else {
          displayChain = chain;
        }

        final ownerNode = subordinatePath?.last;
        final teamName = user.salesTeamName ?? ownerNode?.salesTeamName;
        final teamId = user.salesTeamId ?? ownerNode?.salesTeamId;
        if (teamName != null) {
          salesInfoFields.add({'label': 'Sales Team', 'name': teamName, 'id': null});
        }

        for (var node in displayChain) {
          salesInfoFields.add({
            'label': node.positionName ?? 'Sales',
            'name': node.fullName,
            'id': node.salesPersonId,
          });
        }

        selectedSalesExecutiveId = null;
        selectedSalesExecutiveName = displayChain.first.fullName;
        selectedTeamId = teamId;
        selectedSupervisorId = null;
        selectedSalesManagerId = null;
        selectedSalesManagerName = null;
        selectedGeneralManagerId = null;

        for (final node in displayChain) {
          final pos = (node.positionName ?? '').toLowerCase();
          if (pos.contains('general')) {
            selectedGeneralManagerId = node.salesPersonId;
          } else if (pos.contains('manager')) {
            if (selectedSalesManagerId == null) {
              selectedSalesManagerId = node.salesPersonId;
              selectedSalesManagerName = node.fullName;
            }
          } else if (pos.contains('supervisor')) {
            selectedSupervisorId = node.salesPersonId;
          } else {
            
            selectedSalesExecutiveId = node.salesPersonId;
          }
        }
      }
    });

  }

  void dispose() {
    fullNameTC.dispose();
    emailTC.dispose();
    waTC.dispose();
    fBlockNoTC.dispose();
    salesExecutiveTC.dispose();
    salesManagerTC.dispose();
    generalNotesTC.dispose();

    fullNameFN.dispose();
    emailFN.dispose();
    waFN.dispose();
    fBlockNoFN.dispose();
    salesExecutiveFN.dispose();
    salesManagerFN.dispose();
    generalNotesFN.dispose();
    fspTC.dispose();
    lspTC.dispose();
    fakadTC.dispose();
    lakadTC.dispose();

    lBlockNoFN.dispose();
    noKTPFN.dispose();
    ktpAddressFN.dispose();
    volumePlanFN.dispose();
    vCountFN.dispose();
    firstVisitorDateFN.dispose();
    lastVisitorDateFN.dispose();
    firstApptDateFN.dispose();
    lastApptDateFN.dispose();
    dealValueFN.dispose();
    reserveDateFN.dispose();
    firstReserveDateFN.dispose();
    firstReserveDateTC.dispose();
    lossReasonNoteFN.dispose();
    fspFN.dispose();
    lspFN.dispose();
    fakadFN.dispose();
    lakadFN.dispose();
    lastLostDateTC.dispose();
    periodePameranDateTC.dispose();
    periodePameranDateFN.dispose();
    nameSPTC.dispose();
    nameSPFN.dispose();

    selectFirstProject = null;
    selectLastProject = null;
    selectedChannelId = null;
    selectedOwnerId = null;
    selectedProject = null;
    selectedSource1Id = null;
    selectedSource2Id = null;
    selectedLostReasonId = null;
    selectedStatusId = null;
    selectedGeneralManagerId = null;

    for (final c in _propertyControllers.values) {
      c.dispose();
    }
    for (final fn in _propertyFocusNodes.values) {
      fn.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+62')) return '62${cleaned.substring(3)}';
    if (cleaned.startsWith('08')) return '628${cleaned.substring(2)}';
    return cleaned;
  }

 Future<_DuplicateAction> _showDuplicateContactDialog(ContactEntity duplicate) async {
  final result = await showDialog<_DuplicateAction>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(primaryColor).withValues(alpha: .1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_search_rounded,
                color: Color(primaryColor),
                size: 30,
              ),
            ),

            const SizedBox(height: 20),

            /// Title
            Text(
              'Nomor HP Sudah Terdaftar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(blackColor),
              ),
            ),

            const SizedBox(height: 18),

            /// Description Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(grey2Color),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Nomor HP ini sudah terdaftar atas nama ',
                    ),
                    TextSpan(
                      text: '"${duplicate.fullName ?? '-'}"',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(blackColor),
                      ),
                    ),
                    const TextSpan(
                      text: '.\n\nApa yang ingin dilakukan?',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            /// Tetap Lanjutkan
            customButton(
              () => Navigator.of(dialogContext).pop(
                _DuplicateAction.proceed,
              ),
              'Tetap Lanjutkan',
            ),

            const SizedBox(height: 12),

            /// Buka Kontak
            customButton(
              () => Navigator.of(dialogContext).pop(
                _DuplicateAction.openExisting,
              ),
              'Buka Kontak',
              colorBg: Color(whiteColor),
              colorText: Color(primaryColor),
            ),

            const SizedBox(height: 12),

            /// Batal
            customButton(
              () => Navigator.of(dialogContext).pop(
                _DuplicateAction.cancel,
              ),
              'Batal',
              colorBg: Colors.grey.shade100,
              colorText: Color(grey5Color),
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? _DuplicateAction.cancel;
}

  bool _validateEmail() {
    final email = emailTC.text.trim();
    if (email.isEmpty) return true;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _importFromContacts() async {
    AnalyticsService.logEvent('contact_form_import_from_contacts');
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin akses kontak diperlukan')),
        );
      }
      return;
    }
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || !mounted) return;

      final full = await FlutterContacts.getContact(contact.id, withProperties: true);
      if (full == null || !mounted) return;

      final name = full.displayName;
      final rawPhone = full.phones.isNotEmpty ? full.phones.first.number : '';
      String phone = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (phone.startsWith('+62')) {
        phone = '62${phone.substring(3)}';
      } else if (phone.startsWith('08')) {
        phone = '628${phone.substring(2)}';
      }

      setState(() {
        if (name.isNotEmpty) fullNameTC.text = name;
        if (phone.isNotEmpty) waTC.text = phone;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengakses buku kontak')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final today = DateHelper.formatDate(AppTime.now());
    final isCreate = widget.args.page == 0;
    final isUpdate = widget.args.page == 1;

    setState(() => _showValidation = true);

    bool invalidId(int? id) => id == null || id == 0;
    final projectValid = isCreate ? selectFirstProject != null : selectLastProject != null;
    if (fullNameTC.text.isEmpty ||
        waTC.text.isEmpty ||
        selectedSalutation == null ||
        selectedOwnerId == null ||
        selectedStatusId == null ||
        !projectValid ||
        invalidId(selectedSource1Id) ||
        invalidId(selectedSource2Id) ||
        generalNotesTC.text.isEmpty) {
      return;
    }
    if (!_validateEmail()) return;

    
    final group     = _statusGroup(selectedStatusId);
    final isAppt    = group == 'appt';
    final isReserve = group == 'reserve';
    final isVisit   = group == 'visit';
    final isSP      = group == 'sp';
    final isLost    = group == 'lost';

    
    final existing        = widget.args.dataContact;
    final firstApptEmpty  = isCreate || existing?.firstApptDate == null   || (existing!.firstApptDate?.isEmpty   ?? true);
    final firstVisitEmpty = isCreate || existing?.firstVisitDate == null  || (existing!.firstVisitDate?.isEmpty  ?? true);
    final firstReserveEmpty = isCreate || existing?.firstReserveDate == null || (existing!.firstReserveDate?.isEmpty ?? true);
    final firstSPEmpty    = isCreate || existing?.firstSpDate == null     || (existing!.firstSpDate?.isEmpty     ?? true);

    
    String dateOr(String fieldValue) => fieldValue.isNotEmpty ? fieldValue : today;

    
    final List<Map<String, dynamic>> propertiesJson = [];
    _propertyControllers.forEach((id, ctrl) {
      if (ctrl.text.isNotEmpty) propertiesJson.add({'property_id': id, 'property_value': ctrl.text});
    });

    final params = CreateContactParams(
      salutation: selectedSalutation ?? '',
      fullName: fullNameTC.text.isNotEmpty ? fullNameTC.text : null,
      primaryPhone: waTC.text.isNotEmpty ? _normalizePhone(waTC.text) : null,
      whatsappNumber: waTC.text.isNotEmpty ? _normalizePhone(waTC.text) : null,
      primaryEmail: emailTC.text.isNotEmpty ? emailTC.text : null,

      ownerId: selectedOwnerId,
      salesExecutiveId: selectedSalesExecutiveId,
      salesManagerId: selectedSalesManagerId,
      salesSupervisorId: selectedSupervisorId,
      salesGeneralManagerId: selectedGeneralManagerId,
      salesTeamId: selectedTeamId,

      statusProspectId: selectedStatusId,

      lastProject: isUpdate ? selectLastProject : selectFirstProject,
      firstProject: isUpdate ? null : selectFirstProject,
      lastProjectCategory: isUpdate ? selectLastProjectCategory : null,
      firstProjectCategory: isUpdate ? null : selectFirstProjectCategory,
      productType: selectProductType,
      lastProduct: isUpdate ? selectLastProjectProduct : null,
      firstProduct: isUpdate ? null : selectFirstProjectProduct,
      lastBlokNo: isUpdate ? (lBlockNoTC.text.isNotEmpty ? lBlockNoTC.text : null) : (fBlockNoTC.text.isNotEmpty ? fBlockNoTC.text : null),
      firstBlokNo: isUpdate ? null : (fBlockNoTC.text.isNotEmpty ? fBlockNoTC.text : null),
      lastProjectId: isUpdate ? selectLastTownshipId : selectFirstTownshipId,
      firstProjectId: _existingFirstProjectId == null ? selectFirstTownshipId : null,
      lastClusterId: isUpdate ? selectLastClusterId : null,
      firstClusterId: isUpdate ? (_existingFirstClusterId == null ? selectLastClusterId : null) : null,
      lastCommercialId: isUpdate ? selectLastCommercialId : null,
      firstCommercialId: isUpdate ? (_existingFirstCommercialId == null ? selectLastCommercialId : null) : null,
      lastProductId: isUpdate ? selectLastProductId : null,
      firstProductId: isUpdate ? (_existingFirstProductId == null ? selectLastProductId : null) : null,

      salesChannelId: selectedSource1Id,
      sumberInformasi2: selectedSource2Id?.toString(),

      generalNotes: generalNotesTC.text.isNotEmpty ? generalNotesTC.text : null,

      lostReasonId: selectedLostReasonId,
      lostReasonNote: lossReasonNoteTC.text.isNotEmpty ? lossReasonNoteTC.text : null,

      
      lastApptDate:  isAppt ? _toBackendDate(dateOr(isUpdate ? lastApptDateTC.text : firstApptDateTC.text)) : null,
      firstApptDate: isAppt && firstApptEmpty ? _toBackendDate(dateOr(firstApptDateTC.text)) : null,

      
      lastVisitDate:  isVisit ? _toBackendDate(dateOr(isUpdate ? lastVisitorDateTC.text : firstVisitorDateTC.text)) : null,
      firstVisitDate: isVisit && firstVisitEmpty ? _toBackendDate(dateOr(firstVisitorDateTC.text)) : null,

      
      reserveDate:      isReserve ? _toBackendDate(dateOr(reserveDateTC.text)) : null,
      lastReserveDate:  isReserve ? _toBackendDate(dateOr(reserveDateTC.text)) : null,
      firstReserveDate: isReserve && firstReserveEmpty? _toBackendDate(dateOr(firstReserveDateTC.text.isNotEmpty ? firstReserveDateTC.text : reserveDateTC.text)): null,

      
      lastSPDate:  isSP ? _toBackendDate(dateOr(lspTC.text)) : null,
      firstSPDate: isSP && firstSPEmpty ? _toBackendDate(dateOr(fspTC.text)) : null,

      
      lastAkadDate:  isUpdate ? _toBackendDate(lakadTC.text) : null,
      firstAkadDate: isUpdate && (existing?.firstAkadDate == null || (existing!.firstAkadDate?.isEmpty ?? true))? _toBackendDate(fakadTC.text): null,

      
      lostDate:     isLost ? _toBackendDate(dateOr(lastLostDateTC.text)) : null,
      lastLostDate: isLost ? _toBackendDate(dateOr(lastLostDateTC.text)) : null,

      dealValue: dealValueTC.text.isNotEmpty ? dealValueTC.text : null,
      visitCount: vCountTC.text.isNotEmpty ? int.tryParse(vCountTC.text) : null,
      volumePlan: volumePlanTC.text.isNotEmpty ? volumePlanTC.text : null,
      nameSP: nameSPTC.text.isNotEmpty ? nameSPTC.text : null,
      noKtp: noKTPTC.text.isNotEmpty ? noKTPTC.text : null,
      ktpAddress: ktpAddressTC.text.isNotEmpty ? ktpAddressTC.text : null,
      propertiesJson: propertiesJson.isNotEmpty ? propertiesJson : null,
      periodePameranDate: _isPameranSource1(selectedSource1Id) ? _periodePameranDateBackend : null,
      periodePameranId: _isPameranSource1(selectedSource1Id) ? _resolvePeriodePameranId() : null,

      units: ((widget.args.page == 0 && _selectedUnits.isNotEmpty) || (widget.args.page != 0 && _unitsTouched)) ? _selectedUnits.map((u) => u.toApiJson()).toList() : null,
    );

    if (selectedOwnerId != null && waTC.text.isNotEmpty) {
      final duplicate = await context.read<ContactBloc>().checkDuplicateContact(
            ownerId: selectedOwnerId!,
            phone: _normalizePhone(waTC.text),
          );
      if (!mounted) return;

      if (duplicate != null && duplicate.contactId != widget.args.dataContact?.contactId) {
        final action = await _showDuplicateContactDialog(duplicate);
        if (action != _DuplicateAction.proceed) {
          if (action == _DuplicateAction.openExisting && mounted) {
            context.pushNamed('detailContact', extra: ContactDetailArgs(dataContact: duplicate, page: 2));
          }
          return;
        }
        if (!mounted) return;
      }
    }

    setState(() => _isSaving = true);
    AnalyticsService.logEvent('contact_form_save_contact', parameters: {'mode': isUpdate ? 'update' : 'create'});
    if (isUpdate) {
      context.read<ContactBloc>().add(UpdateContactEvent(widget.args.dataContact!.contactId!, params));
    } else {
      context.read<ContactBloc>().add(CreateContactEvent(params));
    }
  }


  DateTime _parseDateOrToday(String? value) {
    if (value == null || value.isEmpty) return AppTime.now();
    try {
      return DateTime.parse(value);
    } catch (_) {}
    try {
      return DateFormat('dd MMMM yyyy', 'en_US').parse(value);
    } catch (_) {}
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (_) {}
    return AppTime.now();
  }

  String? _toBackendDate(String value) {
    if (value.isEmpty) return null;
    final dt = _parseDateOrToday(value);
    final now = AppTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return '${DateHelper.formatNumericCompact(dt)} $time';
  }

  
  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactBloc, ContactState>(
      listener: (context, state) {
        if (state.status == ContactStatus.createSuccess && widget.args.page == 0) {
          setState(() => _isSaving = false);
          
          if (state.contactDetail?.contactId != null) {
            SalesbookSyncService.syncContact(state.contactDetail!.contactId!);
          }
          this.context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true));
          final newContact = state.contactDetail;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (newContact != null) {
              this.context.pushReplacementNamed(
                'detailContact',
                extra: ContactDetailArgs(dataContact: newContact, initialTab: 0),
              );
            } else {
              this.context.pop();
            }
          });
        } else if (state.status == ContactStatus.updateSuccess && widget.args.page == 1) {
          setState(() => _isSaving = false);
          
          if (state.contactDetail?.contactId != null) {
            SalesbookSyncService.syncContact(state.contactDetail!.contactId!);
          }
          this.context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true));
          final newContact = state.contactDetail;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
             this.context.pushReplacementNamed(
                'detailContact',
                extra: ContactDetailArgs(dataContact: newContact, initialTab: 0),
              );
          });
        } else if (state.status == ContactStatus.detailLoaded &&
            state.contactDetail != null &&
            !_formInitialized) {
          _fillForm(state.contactDetail!);
        } else if (widget.args.page == 1 &&
            state.status == ContactStatus.detailLoaded &&
            !_unitsLoaded &&
            state.contactDetail != null) {
          
          
          
          _fillForm(state.contactDetail!);
        } else if (state.status == ContactStatus.error && widget.args.page != 2) {
          setState(() => _isSaving = false);
          if (_isDialogShowing) {
            _isDialogShowing = false;
            Navigator.of(this.context).pop();
          }
          
          
          final msg = (state.errorMessage ?? '').replaceFirst('Exception: ', '').trim();
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text(msg.isNotEmpty ? msg : 'Gagal menyimpan data kontak')),
          );
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded && widget.args.page == 0) {
                _autoFillFromProfile();
              }
            },
          ),
          BlocListener<TownshipBloc, TownshipState>(
            listener: (context, state) {
              if (state is TownshipLoaded &&
                  widget.args.page == 0 &&
                  selectFirstProject == null &&
                  state.townships.isNotEmpty) {
                final first = state.townships.first;
                setState(() {
                  selectFirstProject = first.name;
                  selectFirstTownshipId = first.id;
                });
              }
            },
          ),
          BlocListener<ProspectStatusBloc, ProspectStatusState>(
            listener: (context, state) {
              if (state.status == ProspectStatusEnum.loaded) {
                if (widget.args.page == 0 &&
                    selectedStatusId == null &&
                    state.statuses.isNotEmpty) {
                  setState(() {
                    selectedStatusId = state.statuses.first.statusProspectId;
                    selectedStatusProspectName = state.statuses.first.statusProspectName;
                  });
                }

                if (widget.args.page != 0) {
                  final contact = context.read<ContactBloc>().state.contactDetail ?? widget.args.dataContact;
                  if (contact != null) _fillForm(contact);
                }
              }
            },
          ),
          BlocListener<InfoSourceBloc, InfoSourceState>(
            listener: (context, state) {
              if (widget.args.page == 2 && state.sourcesMap[2] != null) {
                final contact = context.read<ContactBloc>().state.contactDetail ?? widget.args.dataContact;
                if (contact != null) _fillForm(contact);
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            if (profileState is ProfileLoading) {
              return Scaffold(
                body: buildFormShimmer(),
              );
            }
            if (profileState is ProfileLoaded &&
                widget.args.page == 0 &&
                selectedOwnerId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _autoFillFromProfile();
              });
            }
            return BlocConsumer<ContactBloc, ContactState>(
              listenWhen: (prev, curr) =>
                  widget.args.page == 2 &&
                  curr.status == ContactStatus.error &&
                  prev.status != ContactStatus.error,
              listener: (context, contactState) {
                
                showErrorDialog(context, 'Gagal memuat data kontak').then((_) {
                  if (context.mounted) context.pop();
                });
              },
              builder: (context, contactState) {
                final statusState = context.watch<ProspectStatusBloc>().state.status;
                final statusLoading = statusState == ProspectStatusEnum.initial || statusState == ProspectStatusEnum.loading;
                final propertiesState = context.watch<ContactPropertiesBloc>().state.status;
                final propertiesLoading = propertiesState == ContactPropertiesStatus.initial || propertiesState == ContactPropertiesStatus.loading;
                if (propertiesState == ContactPropertiesStatus.error) debugPrint('[ContactForm] ContactProperties ERROR: ${context.watch<ContactPropertiesBloc>().state.errorMessage}');
                if (statusState == ProspectStatusEnum.error) debugPrint('[ContactForm] ProspectStatus ERROR');
                final detailLoading = contactState.status == ContactStatus.loadingDetail ||
                    contactState.status == ContactStatus.initial;

                
                final showDetailLoading = widget.args.page == 2 && detailLoading;

                if ((widget.args.page == 1 || widget.args.page == 2) &&
                    (showDetailLoading || statusLoading || propertiesLoading)) {
                  return Scaffold(
                    body: buildFormShimmer(),
                  );
                }

                return Scaffold(
                  body: (showDetailLoading || statusLoading || propertiesLoading)
                      ? buildFormShimmer()
                      : SafeArea(child: widget.args.page == 0?_createContact(profileState): _editContact(profileState)),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _editContact(ProfileState profileState) {
    return Column(
      children: [
        if (widget.args.page != 2) _headerContact(title: "Edit Contact"),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Column(
                  children: [
                    CustomDropdownGroupContact(
                      hint: "Contact Information",
                      child: Column(
                        children: [
                           _buildFieldDown(
                            label: "Salutation",
                            value: selectedSalutation ?? "Pilih Salutation",
                            isError: _showValidation && (selectedSalutation?.isEmpty ?? true),
                            errorText: (_showValidation && (selectedSalutation?.isEmpty ?? true)) ? 'Wajib diisi' : null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_salutation');
                              final items = [
                                OwnerDropdownItem(id: 1, name: 'Bapak'),
                                OwnerDropdownItem(id: 2, name: 'Ibu'),
                              ];
                              final result = await context.pushNamed(
                                'detailContactDropdown',
                                extra: ContactDropdownArgs(
                                  title: 'Pilih Salutation',
                                  items: items,
                                  selectedId: selectedSalutation == 'Ibu' ? 2 : selectedSalutation == 'Bapak' ? 1 : null,
                                ),
                              );
                              if (result != null) {
                                final sel = result as OwnerDropdownItem;
                                setState(() {
                                  selectedSalutation = sel.name;
                                });
                              }
                            },
                          ),
                          _buildField(
                            label: "Full Name",
                            controller: fullNameTC,
                            focusNode: fullNameFN,
                            isError: _showValidation && fullNameTC.text.isEmpty,
                            errorText: (_showValidation && fullNameTC.text.isEmpty) ? 'Wajib diisi' : null,
                          ),
                          _buildField(
                            label: "Hp/Whatsapp",
                            controller: waTC,
                            focusNode: waFN,
                            isError: _showValidation && waTC.text.isEmpty,
                            errorText: (_showValidation && waTC.text.isEmpty) ? 'Wajib diisi' : null,
                            fieldType: 'int',
                          ),
                           _buildField(
                            label: "Email",
                            controller: emailTC,
                            focusNode: emailFN,
                            fieldType: 'text',
                            isError: _showValidation && emailTC.text.isNotEmpty && !_validateEmail(),
                            errorText: (_showValidation && emailTC.text.isNotEmpty && !_validateEmail()) ? 'Format email tidak valid' : null,
                          ),
                          _buildFieldDown(
                            label: "Owner",
                            value: selectedOwnerName,
                            isError: _showValidation && selectedOwnerId == null,
                            errorText: (_showValidation && selectedOwnerId == null) ? 'Wajib diisi' : null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_owner');
                              if (profileState is ProfileLoaded) {
                                final user = profileState.profile;

                                final modifyScope = PermissionsHelper.scopeLevel('Contacts', 'Modify');
                                final List<OwnerDropdownItem> ownerItems = [];
                                ownerItems.add(
                                  OwnerDropdownItem(
                                    id: user.userId,
                                    name: '${user.fullName} (me)',
                                    subtitle: user.positionName,
                                  ),
                                );
                                if (modifyScope == 'team' || modifyScope == 'any') {
                                  void addSubs(List<HierarchyNodeEntity> subs) {
                                    for (var s in subs) {
                                      ownerItems.add(
                                        OwnerDropdownItem(
                                          id: s.userId,
                                          name: s.fullName,
                                          subtitle: s.positionName,
                                        ),
                                      );
                                      if (s.subordinates.isNotEmpty)
                                        addSubs(s.subordinates);
                                    }
                                  }
                                  addSubs(user.subordinates);
                                }
                
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Pilih Owner',
                                    items: ownerItems,
                                    selectedId: selectedOwnerId,
                                  ),
                                );
                                if (result != null) {
                                  final owner = result as OwnerDropdownItem;
                                  final ownerChanged = selectedOwnerId != owner.id;
                                  setState(() {
                                    selectedOwnerId = owner.id;
                                    selectedOwnerName = owner.name;
                                    // if (ownerChanged) {
                                    //   selectLastProject = null;
                                    //   selectLastTownshipId = null;
                                    //   selectLastProjectCategory = null;
                                    //   selectLastProjectProduct = null;
                                    //   selectProductType = null;
                                    //   selectedSource1Id = null;
                                    //   selectedSource1Name = null;
                                    //   selectedSource2Id = null;
                                    //   selectedSource2Name = null;
                                    //   _periodePameranDateBackend = null;
                                    //   periodePameranDateTC.text = '';
                                    // }
                                  });
                                  // if (ownerChanged) {
                                  //   context.read<PameranAktifCubit>().reset();
                                  //   context.read<InfoSourceBloc>().add(const ResetInfoSourcesEvent([1, 2]));
                                  // }
                                  _updateSalesInformation(owner.id ?? 0, user);
                                }
                              }
                            },
                          ),
                          _buildFieldDown(
                            label: "Status Prospect",
                            value: selectedStatusProspectName,
                            isError: _showValidation && selectedStatusId == null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_status_prospect');
                              final statusState = context.read<ProspectStatusBloc>().state;
                              if (statusState.status == ProspectStatusEnum.loaded) {
                                final statusItems = statusState.statuses.map((e) => OwnerDropdownItem(id: e.statusProspectId, name: e.statusProspectName)).toList();
                          
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Pilih Status Prospect',
                                    items: statusItems,
                                    selectedId: selectedStatusId,
                                  ),
                                );
                          
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  final picked = statusState.statuses
                                      .cast<ProspectStatusEntity?>()
                                      .firstWhere(
                                        (e) => e?.statusProspectId == selected.id,
                                        orElse: () => null,
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      selectedStatusId = picked.statusProspectId;
                                      selectedStatusProspectName = picked.statusProspectName;
                                    });
                                  }
                                }
                              } else {
                                context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memuat daftar status...')));
                              }
                            },
                          ),
                           _buildFieldDown(
                            label: "Project",
                            value: selectLastProject,
                            isError: _showValidation && selectLastProject == null,
                            errorText: (_showValidation && selectLastProject == null) ? 'Wajib diisi' : null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_project');
                              if (!_guardSalesChain([selectedOwnerId != null], ['Owner'])) return;
                              final townshipState = context.read<TownshipBloc>().state;
                              if (townshipState is TownshipLoaded) {
                                final items = townshipState.townships .map((t) => OwnerDropdownItem(id: t.id, name: t.name)) .toList();
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Pilih Project',
                                    items: items,
                                    selectedId: selectLastTownshipId,
                                  ),
                                );
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  final projectChanged = selectLastTownshipId != selected.id;
                                  // setState(() {
                                  //   selectLastProject = selected.name;
                                  //   selectLastTownshipId = selected.id;
                                  //   selectLastProjectCategory = null;
                                  //   selectLastProjectProduct = null;
                                  //   selectProductType = null;


                                  //   if (projectChanged) {
                                  //     _selectedUnits = _activeUnitsForTownship(selected.id);
                                  //     selectedSource1Id = null;
                                  //     selectedSource1Name = null;
                                  //     selectedSource2Id = null;
                                  //     selectedSource2Name = null;
                                  //     _periodePameranDateBackend = null;
                                  //     periodePameranDateTC.text = '';
                                  //   }
                                  // });
                                  // context.read<PropertyUnitCubit>().load(
                                  //   selected.id!,
                                  //   isCommercial: selectLastProjectCategory?.toLowerCase() == 'commercial',
                                  // );
                                }
                              } else {
                                context.read<TownshipBloc>().add(GetTownshipsEvent());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memuat data project...')),
                                );
                              }
                            },
                          ),
                          
                          _buildUnitField(),
                          if (_isVisitorWi(selectedStatusId))
                            _buildFieldDown(
                              label: "Berapa kali datang",
                              value: vCountTC.text.isEmpty ? null : (vCountTC.text == '5' ? '>5' : vCountTC.text),
                              onTap: () async {
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Berapa kali datang',
                                    items: itemsJmlDatang,
                                    selectedId: null,
                                  ),
                                );
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  setState(() {
                                    vCountTC.text = selected.name == '>5' ? '5' : selected.name;
                                  });
                                }
                              },
                            ),
                          if (_statusGroup(selectedStatusId) == 'appt' ||
                              _statusGroup(selectedStatusId) == 'reserve')
                            _buildFieldDown(
                              label: "Berapa kali appt",
                              value: volumePlanTC.text.isEmpty ? null : (volumePlanTC.text == '5' ? '>5' : volumePlanTC.text),
                              onTap: () async {
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Berapa kali appt',
                                    items: itemsVolume,
                                    selectedId: null,
                                  ),
                                );
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  setState(() {
                                    volumePlanTC.text = selected.name == '>5' ? '5' : selected.name;
                                  });
                                }
                              },
                            ),
                         
                            

                           _buildFieldDown(
                            label: "Sales Channel",
                            value: selectedSource1Name,
                            isError: _showValidation && (selectedSource1Id == null || selectedSource1Id == 0),
                            errorText: (_showValidation && (selectedSource1Id == null || selectedSource1Id == 0)) ? 'Wajib diisi' : null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_info_source', parameters: {'field': 'sales_channel'});
                              if (!_guardSalesChain([selectedOwnerId != null, selectLastTownshipId != null], ['Owner', 'Project'])) return;
                              final sourceState = context.read<InfoSourceBloc>().state;
                              final sources = sourceState.sourcesMap[1];
                              if (sources != null) {
                                final sourceItems = sources.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Pilih Sales Channel',
                                    items: sourceItems,
                                    selectedId: selectedSource1Id,
                                  ),
                                );
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  final channelChanged = selectedSource1Id != selected.id;
                                  setState(() {
                                    selectedSource1Id = selected.id;
                                    selectedSource1Name = selected.name;
                                    if (channelChanged) {
                                      selectedSource2Id = null;
                                      selectedSource2Name = null;
                                      _periodePameranDateBackend = null;
                                      periodePameranDateTC.text = '';
                                    }
                                  });
                                  if (channelChanged) {
                                    context.read<InfoSourceBloc>().add(const ResetInfoSourcesEvent([2]));
                                    context.read<PameranAktifCubit>().reset();
                                  }
                                }
                              } else {
                                context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
                              }
                            },
                          ),
                          Builder(builder: (context) {
                            final sources2 = context.watch<InfoSourceBloc>().state.sourcesMap[2];
                            final noSalesChannelDetail = sources2 != null && sources2.isEmpty;
                            return _buildFieldDown(
                            label: "Sales Channel Detail",
                            value: selectedSource2Name,
                            isError: _showValidation && (selectedSource2Id == null || selectedSource2Id == 0),
                            readOnly: noSalesChannelDetail,
                            errorText: noSalesChannelDetail
                                ? 'Tidak ada pameran aktif'
                                : (_showValidation && (selectedSource2Id == null || selectedSource2Id == 0)) ? 'Wajib diisi' : null,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_info_source', parameters: {'field': 'sales_channel_detail'});
                              if (!_guardSalesChain([selectedOwnerId != null, selectLastTownshipId != null, selectedSource1Id != null && selectedSource1Id != 0], ['Owner', 'Project', 'Sales Channel'])) return;
                              final sourceState = context.read<InfoSourceBloc>().state;
                              final sources = sourceState.sourcesMap[2];
                              if (sources != null) {
                                final sourceItems = _dedupeByName(sources).map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Pilih Sales Channel Detail',
                                    items: sourceItems,
                                    selectedId: selectedSource2Id,
                                  ),
                                );
                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;
                                  final matched = sources.cast<InfoSource?>().firstWhere((e) => e?.id == selected.id, orElse: () => null);
                                  final isPameran = matched?.periodePameranId != null;
                                  if (isPameran) {
                                    final fallbackNow = AppTime.now();
                                    await context.read<PameranAktifCubit>().load(lokasiPameran: matched!.name, userId: selectedOwnerId, all: true);
                                    if (!mounted) return;
                                    final ps = context.read<PameranAktifCubit>().state;
                                    final list = ps is PameranAktifLoaded ? ps.data : <PameranAktifEntity>[];
                                    _applyPameranDate(list, fallbackNow);
                                  } else {
                                    _periodePameranDateBackend = null;
                                    periodePameranDateTC.text = '';
                                  }
                                  setState(() {
                                    selectedSource2Id = selected.id;
                                    selectedSource2Name = selected.name;
                                  });
                                }
                              } else {
                                context.read<InfoSourceBloc>().add(FetchInfoSourcesEvent(type: 2, userId: selectedOwnerId, salesChannel: selectedSource1Name, all: true));
                              }
                            },
                            );
                          }),
                          if (_isPameranSource1(selectedSource1Id))
                            Builder(builder: (context) {
                              final ps = context.watch<PameranAktifCubit>().state;
                              final list = ps is PameranAktifLoaded ? ps.data : [];
                              final noPameranAktif = ps is PameranAktifLoaded && list.isEmpty;
                              final firstDate = list.isNotEmpty ? list.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b) : null;
                              final lastDate = list.isNotEmpty ? list.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;
                              return _buildField(
                                label: "Periode Pameran Date",
                                controller: periodePameranDateTC,
                                focusNode: periodePameranDateFN,
                                fieldType: 'date',
                                dateFirstDate: firstDate,
                                dateLastDate: lastDate,
                                readOnly: noPameranAktif,
                                errorText: noPameranAktif ? 'Tidak ada pameran aktif' : null,
                                guard: () => _guardSalesChain(
                                  [selectedOwnerId != null, selectLastTownshipId != null, selectedSource1Id != null && selectedSource1Id != 0, selectedSource2Id != null && selectedSource2Id != 0],
                                  ['Owner', 'Project', 'Sales Channel', 'Sales Channel Detail'],
                                ),
                              );
                            }),
                           _buildField(
                            label: "Note",
                            controller: generalNotesTC,
                            focusNode: generalNotesFN,
                            isError: _showValidation && generalNotesTC.text.isEmpty,
                            errorText: (_showValidation && generalNotesTC.text.isEmpty) ? 'Wajib diisi' : null,
                            minLines: 3,
                          ),
                          _buildField(
                              label: "Name SP",
                              controller: nameSPTC,
                              focusNode: nameSPFN,
                            ),
                         _buildFieldDown(
                            label: "Lost Reason",
                            value: selectedLostReasonName,
                            onTap: () async {
                              AnalyticsService.logEvent('contact_form_select_lost_reason');
                              final state = context.read<LostReasonBloc>().state;

                              if (state.status == LostReasonStatus.loaded) {
                                final items = state.reasons.map((e) => OwnerDropdownItem(id: e.lostReasonId,name: e.lostReasonName,),).toList();
                                final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Lost Reason',items: items,selectedId: selectedLostReasonId,),);

                                if (result != null) {
                                  final selected = result as OwnerDropdownItem;

                                  final picked = state.reasons.firstWhere((e) => e.lostReasonId == selected.id,);
                                  setState(() {
                                    selectedLostReasonId = picked.lostReasonId;
                                    selectedLostReasonName = picked.lostReasonName;
                                  });
                                }
                              } else {
                                context.read<LostReasonBloc>().add(FetchLostReasonsEvent());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memuat daftar alasan...')),
                                );
                              }
                            },
                          ),
                           _buildField(
                            label: "Loss Reason Note",
                            controller: lossReasonNoteTC,
                            focusNode: lossReasonNoteFN,
                          ),
                          _buildField(
                            label: "Create Date",
                            controller: createAdTC,
                            focusNode: createAdFN,
                            readOnly: true,
                          ),
                           _buildField(
                            label: "Appt Date",
                            controller: lastApptDateTC,
                            focusNode: lastApptDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(group: 'appt'),
                          ),
                           _buildField(
                            label: "Visitor/WI Date",
                            controller: lastVisitorDateTC,
                            focusNode: lastVisitorDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(group: 'visit'),
                          ),
                           _buildField(
                            label: "Reserve Date",
                            controller: reserveDateTC,
                            focusNode: reserveDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(group: 'reserve'),
                          ),

                           _buildField(
                            label: "SP Date",
                            controller: lspTC,
                            focusNode: lspFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(group: 'sp'),
                          ),
                          
                          
                          
                          
                          
                          
                          _buildField(
                            label: "Lost Date",
                            controller: lastLostDateTC,
                            focusNode: lastLostDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(group: 'lost'),
                          ),
                         


                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                         
                          
                         
                          if (widget.args.page == 1) ...[
                            _buildField(
                              label: "First Appt Date",
                              controller: firstApptDateTC,
                              focusNode: firstApptDateFN,
                              fieldType: 'date',
                              readOnly: true,
                            ),
                            _buildField(
                              label: "First Visitor Date",
                              controller: firstVisitorDateTC,
                              focusNode: firstVisitorDateFN,
                              fieldType: 'date',
                              readOnly: true,
                            ),
                            _buildField(
                              label: "First Reserve Date",
                              controller: firstReserveDateTC,
                              focusNode: firstReserveDateFN,
                              fieldType: 'date',
                              readOnly: true,
                            ),
                            _buildField(
                              label: "First SP Date",
                              controller: fspTC,
                              focusNode: fspFN,
                              fieldType: 'date',
                              readOnly: true,
                            ),
                            _buildField(
                              label: "First Akad Date",
                              controller: fakadTC,
                              focusNode: fakadFN,
                              fieldType: 'date',
                              readOnly: true,
                            ),

                          ],
                
                          ],
                      ),
                    ),
                   
                    CustomDropdownGroupContact(
                      hint: "Sales Information",
                      child: Column(
                        children: [
                          _buildFieldDown(
                            label: "Sales Team",
                            value: salesInfoFields.firstWhere(
                              (f) => (f['label'] as String? ?? '').toLowerCase().contains('team'),
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            onTap: null,
                            readOnly: true,
                          ),
                          _buildFieldDown(
                            label: "General Manager",
                            value: salesInfoFields.firstWhere(
                              (f) => (f['label'] as String? ?? '').toLowerCase().contains('general'),
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            onTap: null,
                            readOnly: true,
                          ),
                          _buildFieldDown(
                            label: "Sales Manager",
                            value: salesInfoFields.firstWhere(
                              (f) {
                                final l = (f['label'] as String? ?? '').toLowerCase();
                                return l.contains('manager') && !l.contains('general');
                              },
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            onTap: null,
                            readOnly: true,
                          ),
                          _buildFieldDown(
                            label: "Sales Supervisor",
                            value: salesInfoFields.firstWhere(
                              (f) => (f['label'] as String? ?? '').toLowerCase().contains('supervisor'),
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            onTap: null,
                            readOnly: true,
                          ),
                          _buildFieldDown(
                            label: "Sales Executive",
                            value: salesInfoFields.firstWhere(
                              (f) => (f['label'] as String? ?? '').toLowerCase().contains('executive'),
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            onTap: null,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                     BlocBuilder<ContactPropertiesBloc, ContactPropertiesState>(
                      builder: (context, state) {
                        if (state.status == ContactPropertiesStatus.loading) {
                          return const SizedBox.shrink();
                        }
                        if (state.status == ContactPropertiesStatus.error) {
                          
                          return const Padding(padding: EdgeInsets.all(8.0), child: Text('Gagal memuat properties'));
                        }

                        
                        if (state.status == ContactPropertiesStatus.loaded &&
                            widget.args.focusField != null &&
                            widget.args.page == 1 &&
                            !_propertyFocusHandled) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted || _propertyFocusHandled) return;
                            _propertyFocusHandled = true;
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (!mounted) return;
                              _scrollToField(widget.args.focusField!);
                              setState(() => _highlightedField = widget.args.focusField);
                              Future.delayed(const Duration(seconds: 3), () {
                                if (mounted) setState(() => _highlightedField = null);
                              });
                            });
                          });
                        }
                
                        final groups = state.groups.where((g) => g.name != 'sales_information' && g.name != 'contact_information').toList();
                
                        return Column(
                          children: groups.map((group) {
                            return CustomDropdownGroupContact(
                              hint: group.label,
                              child: Column(
                                children: group.properties.map((prop) {
                                  final propCtrl = _getOrCreatePropertyController(prop.propertyId);
                                  final propFN = _getOrCreatePropertyFocusNode(prop.propertyId);

                                  if (prop.fieldType == 'date') {
                                    return _buildField(
                                      label: prop.label,
                                      controller: propCtrl,
                                      focusNode: propFN,
                                      fieldType: 'date',
                                    );
                                  }

                                  if (prop.fieldType == 'number') {
                                    return _buildField(
                                      label: prop.label,
                                      controller: propCtrl,
                                      focusNode: propFN,
                                      fieldType: 'int',
                                    );
                                  }

                                  if (prop.fieldType == 'select' || prop.fieldType == 'lookup') {
                                    return _buildPropertySelectField(prop, propCtrl);
                                  }

                                  if (prop.fieldType == 'file') {
                                    return _buildPropertyFileField(prop.propertyId, prop.label);
                                  }

                                  if (prop.fieldType == 'textarea') {
                                    return _buildField(
                                      label: prop.label,
                                      controller: propCtrl,
                                      focusNode: propFN,
                                      minLines: 3,
                                    );
                                  }

                                  
                                  return _buildField(
                                    label: prop.label,
                                    controller: propCtrl,
                                    focusNode: propFN,
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _createContact(ProfileState profileState){
    return Column(
      children: [
         _headerContact(title: "Create Contact"),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children:[
              CustomDropdownGroupContact(
              hint: "Contact Information",
                 child: Column(
                   children: [
                    _buildFieldDown(
                       label: "Salutation",
                       value: selectedSalutation ?? "Pilih Salutation",
                       isError: _showValidation && (selectedSalutation?.isEmpty ?? true),
                       errorText: (_showValidation && (selectedSalutation?.isEmpty ?? true)) ? 'Wajib diisi' : null,
                       onTap: () async {
                         AnalyticsService.logEvent('contact_form_select_salutation');
                         final items = [OwnerDropdownItem(id: 1, name: 'Bapak'),OwnerDropdownItem(id: 2, name: 'Ibu'),];
                         final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Salutation',items: items,selectedId: selectedSalutation == 'Ibu'? 2: selectedSalutation == 'Bapak'? 1: null));
                         if (result != null) {
                           final sel = result as OwnerDropdownItem;
                           setState(() {
                             selectedSalutation = sel.name;
                           });
                         }
                       },
                     ),
                     _buildField(label: "Full Name",controller: fullNameTC,focusNode: fullNameFN,isError: _showValidation && fullNameTC.text.isEmpty,errorText: (_showValidation && fullNameTC.text.isEmpty) ? 'Wajib diisi' : null,),
                     _buildField(label: "Hp/Whatsapp",controller: waTC,focusNode: waFN,isError: _showValidation && waTC.text.isEmpty,errorText: (_showValidation && waTC.text.isEmpty) ? 'Wajib diisi' : null,fieldType: 'int',),
                     _buildFieldDown(
                        label: "Owner",
                        value: selectedOwnerName,
                        isError: _showValidation && selectedOwnerId == null,
                        errorText: (_showValidation && selectedOwnerId == null) ? 'Wajib diisi' : null,
                        onTap: () async {
                          AnalyticsService.logEvent('contact_form_select_owner');
                          if (profileState is ProfileLoaded) {
                            final user = profileState.profile;

                            final modifyScope = PermissionsHelper.scopeLevel('Contacts', 'Modify');
                            final List<OwnerDropdownItem> ownerItems = [];
                            ownerItems.add(OwnerDropdownItem(id: user.userId, name: '${user.fullName} (me)', subtitle: user.positionName));
                            if (modifyScope == 'team' || modifyScope == 'any') {
                              void addSubs(List<HierarchyNodeEntity> subs) {
                                for (var s in subs) {
                                  ownerItems.add(OwnerDropdownItem(id: s.userId, name: s.fullName, subtitle: s.positionName));
                                  if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
                                }
                              }
                              addSubs(user.subordinates);
                            }
                            if (selectedOwnerId == null && ownerItems.isNotEmpty) {
                              selectedOwnerId = ownerItems.first.id;
                              selectedOwnerName = ownerItems.first.name;
                              _updateSalesInformation(ownerItems.first.id ?? 0, user);
                            }
                            final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Owner', items: ownerItems, selectedId: selectedOwnerId),);
                            if (result != null) {
                              final owner = result as OwnerDropdownItem;
                              final ownerChanged = selectedOwnerId != owner.id;
                              setState(() {
                                selectedOwnerId = owner.id;
                                selectedOwnerName = owner.name;
                                if (ownerChanged) {
                                  selectFirstProject = null;
                                  selectFirstTownshipId = null;
                                  selectFirstProjectCategory = null;
                                  selectFirstProjectProduct = null;
                                  selectProductType = null;
                                  selectedSource1Id = null;
                                  selectedSource1Name = null;
                                  selectedSource2Id = null;
                                  selectedSource2Name = null;
                                  _periodePameranDateBackend = null;
                                  periodePameranDateTC.text = '';
                                }
                              });
                              if (ownerChanged) {
                                context.read<PameranAktifCubit>().reset();
                                context.read<InfoSourceBloc>().add(const ResetInfoSourcesEvent([1, 2]));
                              }
                              _updateSalesInformation(owner.id ?? 0, user);
                            }
                          }
                        },
                      ),
                      _buildFieldDown(
                       label: "Project",
                       value: selectFirstProject,
                       isError: _showValidation && selectFirstProject == null,
                       errorText: (_showValidation && selectFirstProject == null) ? 'Wajib diisi' : null,
                       onTap: () async {
                         AnalyticsService.logEvent('contact_form_select_project');
                         if (!_guardSalesChain([selectedOwnerId != null], ['Owner'])) return;
                         final townshipState = context.read<TownshipBloc>().state;
                         if (townshipState is TownshipLoaded) {
                           final items = townshipState.townships
                               .map((t) => OwnerDropdownItem(id: t.id, name: t.name))
                               .toList();
                           final result = await context.pushNamed(
                             'detailContactDropdown',
                             extra: ContactDropdownArgs(
                               title: 'Pilih Project',
                               items: items,
                               selectedId: selectFirstTownshipId,
                             ),
                           );
                           if (result != null) {
                             final selected = result as OwnerDropdownItem;
                             final projectChanged = selectFirstTownshipId != selected.id;
                             setState(() {
                               selectFirstProject = selected.name;
                               selectFirstTownshipId = selected.id;
                               selectFirstProjectCategory = null;
                               selectFirstProjectProduct = null;
                               selectProductType = null;
                               if (projectChanged) {
                                 selectedSource1Id = null;
                                 selectedSource1Name = null;
                                 selectedSource2Id = null;
                                 selectedSource2Name = null;
                                 _periodePameranDateBackend = null;
                                 periodePameranDateTC.text = '';
                               }
                             });
                           }
                         } else {
                           context.read<TownshipBloc>().add(GetTownshipsEvent());
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Memuat data project...')),
                           );
                         }
                       },
                     ),
                      _buildFieldDown(
                        label: "Sales Channel",
                        value: selectedSource1Name,
                        isError: _showValidation && (selectedSource1Id == null || selectedSource1Id == 0),
                        errorText: (_showValidation && (selectedSource1Id == null || selectedSource1Id == 0)) ? 'Wajib diisi' : null,
                        onTap: () async {
                          AnalyticsService.logEvent('contact_form_select_info_source', parameters: {'field': 'sales_channel'});
                          if (!_guardSalesChain([selectedOwnerId != null, selectFirstTownshipId != null], ['Owner', 'Project'])) return;
                          final sourceState = context.read<InfoSourceBloc>().state;
                          final sources = sourceState.sourcesMap[1];
                          if (sources != null) {
                            final sourceItems = sources.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                            final result = await context.pushNamed(
                              'detailContactDropdown',
                              extra: ContactDropdownArgs(
                                title: 'Pilih Sales Channel',
                                items: sourceItems,
                                selectedId: selectedSource1Id,
                              ),
                            );
                            if (result != null) {
                              final selected = result as OwnerDropdownItem;
                              final channelChanged = selectedSource1Id != selected.id;
                              setState(() {
                                selectedSource1Id = selected.id;
                                selectedSource1Name = selected.name;
                                if (channelChanged) {
                                  selectedSource2Id = null;
                                  selectedSource2Name = null;
                                  _periodePameranDateBackend = null;
                                  periodePameranDateTC.text = '';
                                }
                              });
                              if (channelChanged) {
                                context.read<InfoSourceBloc>().add(const ResetInfoSourcesEvent([2]));
                                context.read<PameranAktifCubit>().reset();
                              }
                            }
                          } else {
                            context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
                          }
                        },
                      ),
                      Builder(builder: (context) {
                        final sources2 = context.watch<InfoSourceBloc>().state.sourcesMap[2];
                        final noSalesChannelDetail = sources2 != null && sources2.isEmpty;
                        return _buildFieldDown(
                        label: "Sales Channel Detail",
                        value: selectedSource2Name,
                        isError: _showValidation && (selectedSource2Id == null || selectedSource2Id == 0),
                        readOnly: noSalesChannelDetail,
                        errorText: noSalesChannelDetail
                            ? 'Tidak ada pameran aktif'
                            : (_showValidation && (selectedSource2Id == null || selectedSource2Id == 0)) ? 'Wajib diisi' : null,
                        onTap: () async {
                          AnalyticsService.logEvent('contact_form_select_info_source', parameters: {'field': 'sales_channel_detail'});
                          if (!_guardSalesChain([selectedOwnerId != null, selectFirstTownshipId != null, selectedSource1Id != null && selectedSource1Id != 0], ['Owner', 'Project', 'Sales Channel'])) return;
                          final sourceState = context.read<InfoSourceBloc>().state;
                          final sources = sourceState.sourcesMap[2];
                          if (sources != null) {
                            final sourceItems = _dedupeByName(sources).map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                            final result = await context.pushNamed(
                              'detailContactDropdown',
                              extra: ContactDropdownArgs(
                                title: 'Pilih Sales Channel Detail',
                                items: sourceItems,
                                selectedId: selectedSource2Id,
                              ),
                            );
                            if (result != null) {
                              final selected = result as OwnerDropdownItem;
                              final matched = sources.cast<InfoSource?>().firstWhere((e) => e?.id == selected.id, orElse: () => null);
                              final isPameran = matched?.periodePameranId != null;
                              if (isPameran) {
                                final fallbackNow = AppTime.now();
                                await context.read<PameranAktifCubit>().load(lokasiPameran: matched!.name, userId: selectedOwnerId);
                                if (!mounted) return;
                                final ps = context.read<PameranAktifCubit>().state;
                                final list = ps is PameranAktifLoaded ? ps.data : <PameranAktifEntity>[];
                                _applyPameranDate(list, fallbackNow);
                              } else {
                                _periodePameranDateBackend = null;
                                periodePameranDateTC.text = '';
                              }
                              setState(() {
                                selectedSource2Id = selected.id;
                                selectedSource2Name = selected.name;
                              });
                            }
                          } else {
                            context.read<InfoSourceBloc>().add(FetchInfoSourcesEvent(type: 2, userId: selectedOwnerId, salesChannel: selectedSource1Name));
                          }
                        },
                        );
                      }),
                      if (_isPameranSource1(selectedSource1Id))
                        Builder(builder: (context) {
                          final ps = context.watch<PameranAktifCubit>().state;
                          final list = ps is PameranAktifLoaded ? ps.data : [];
                          final noPameranAktif = ps is PameranAktifLoaded && list.isEmpty;
                          final firstDate = list.isNotEmpty ? list.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b) : null;
                          final lastDate = list.isNotEmpty ? list.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;
                          return _buildField(
                            label: "Periode Pameran Date",
                            controller: periodePameranDateTC,
                            focusNode: periodePameranDateFN,
                            fieldType: 'date',
                            dateFirstDate: firstDate,
                            dateLastDate: lastDate,
                            readOnly: noPameranAktif,
                            errorText: noPameranAktif ? 'Tidak ada pameran aktif' : null,
                            guard: () => _guardSalesChain(
                              [selectedOwnerId != null, selectFirstTownshipId != null, selectedSource1Id != null && selectedSource1Id != 0, selectedSource2Id != null && selectedSource2Id != 0],
                              ['Owner', 'Project', 'Sales Channel', 'Sales Channel Detail'],
                            ),
                          );
                        }),
                     _buildField(
                       label: "Note",
                       controller: generalNotesTC,
                       focusNode: generalNotesFN,
                       isError: _showValidation && generalNotesTC.text.isEmpty,
                       errorText: (_showValidation && generalNotesTC.text.isEmpty) ? 'Wajib diisi' : null,
                       minLines: 3,
                     ),
                   ],
                 ),
               ),

               CustomDropdownGroupContact(
                 hint: "Sales Information",
                 child: Column(
                   children: [
                     _buildFieldDown(
                       label: "Sales Team",
                       value: salesInfoFields.firstWhere(
                         (f) => (f['label'] as String? ?? '').toLowerCase().contains('team'),
                         orElse: () => {'name': null},
                       )['name'] as String?,
                       onTap: null,
                       readOnly: true,
                     ),
                     _buildFieldDown(
                       label: "General Manager",
                       value: salesInfoFields.firstWhere(
                         (f) => (f['label'] as String? ?? '').toLowerCase().contains('general'),
                         orElse: () => {'name': null},
                       )['name'] as String?,
                       onTap: null,
                       readOnly: true,
                     ),
                     _buildFieldDown(
                       label: "Sales Manager",
                       value: salesInfoFields.firstWhere(
                         (f) {
                           final l = (f['label'] as String? ?? '').toLowerCase();
                           return l.contains('manager') && !l.contains('general');
                         },
                         orElse: () => {'name': null},
                       )['name'] as String?,
                       onTap: null,
                       readOnly: true,
                     ),
                     _buildFieldDown(
                       label: "Sales Supervisor",
                       value: salesInfoFields.firstWhere(
                         (f) => (f['label'] as String? ?? '').toLowerCase().contains('supervisor'),
                         orElse: () => {'name': null},
                       )['name'] as String?,
                       onTap: null,
                       readOnly: true,
                     ),
                     _buildFieldDown(
                       label: "Sales Executive",
                       value: salesInfoFields.firstWhere(
                         (f) => (f['label'] as String? ?? '').toLowerCase().contains('executive'),
                         orElse: () => {'name': null},
                       )['name'] as String?,
                       onTap: null,
                       readOnly: true,
                     ),
                   ],
                 ),
               ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _headerContact({required String title} ){
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Color(whiteColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AnalyticsService.logEvent('contact_form_back');
                  context.pop();
                },
                child: Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
              ),
              const SizedBox(width: 10),
              Text(widget.args.page != 0 ? "Edit Contact" : "Create Contact",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              if (widget.args.page == 0 && !kIsWeb) ...[
                GestureDetector(
                  onTap: _importFromContacts,
                  child: Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(primaryColor)),
                    ),
                    child: Icon(Icons.contact_phone_rounded, size: 20, color: Color(primaryColor)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: _isSaving ? null : _handleSave,
                child: Container(
                  height: 36,
                  width: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Color(blue3Color),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(whiteColor),
                          ),
                        )
                      : Text("Save",
                          style: TextStyle(color: Color(whiteColor), fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFieldDown({
    required String label,
    String? value,
    bool isError = false,
    String? errorText,
    VoidCallback? onTap,
    bool? readOnly,
  }) {
    final bool isRequired = _requiredLabels.contains(label);
    final isEmpty = value == null || value.isEmpty;
    final bool isReadOnly = readOnly == true || widget.args.page == 2;
    final bool isDisplayGrey = widget.args.page == 2;
    final bool canNavigate = widget.args.page == 2 && label != "Create Date";
    final bool isHighlighted = !isError && _highlightedField == label;
    final fieldKey = _fieldKeys.putIfAbsent(label, () => GlobalKey());

    return GestureDetector(
    onTap: (label == 'Status Prospect' && widget.args.dataContact != null)
    ? () => _goEditStatus()
    : canNavigate ? () => _goToEdit(isUpdate: false, focusField: label) : (widget.args.page == 2 ? null : (readOnly == true ? null : onTap)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            key: fieldKey,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              color: isHighlighted ? Color(primaryColor).withValues(alpha: 0.06) : Color(whiteColor),
              border: Border(bottom: BorderSide(width: isHighlighted ? 2 : 1, color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey9Color))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEmpty) RichText(text: TextSpan(style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700), children: [TextSpan(text: label, style: TextStyle(color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color))), if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontSize: 10, fontWeight: FontWeight.w700))])),
                      isEmpty
                        ? RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700), children: [TextSpan(text: label, style: TextStyle(color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color))), if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontSize: 12, fontWeight: FontWeight.w700))]))
                        : Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : isDisplayGrey ? Color(blackColor) : (readOnly == true ? Color(grey2Color) : Color(blackColor)))),
                    ],
                  ),
                ),
                if (!isReadOnly) const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
          if (errorText != null)
            Container(
              decoration: BoxDecoration(color: Color(whiteColor)),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, left: 16, bottom: 4),
                child: Text(errorText, style: TextStyle(fontSize: 11, color: Color(redColor))),
              ),
            ),
        ],
      ),
    );
  }

  void _showPropertySelectSheet(ContactProperty prop, TextEditingController ctrl) async {
    final items = prop.options.asMap().entries.map((e) =>
      OwnerDropdownItem(id: e.key, name: e.value['label'] ?? ''),
    ).toList();

    final currentIdx = prop.options.indexWhere((o) => o['value'] == ctrl.text);

    final result = await context.pushNamed(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Pilih ${prop.label}',
        items: items,
        selectedId: currentIdx >= 0 ? currentIdx : null,
      ),
    );

    if (result != null && mounted) {
      final selected = result as OwnerDropdownItem;
      final value = prop.options[selected.id!]['value'] ?? '';
      setState(() => ctrl.text = value);
    }
  }

  void _showPropertyFilePicker(int propertyId) async {
    AnalyticsService.logEvent('contact_form_upload_property_file');
    final result = await CustomFilePicker.show(context);
    if (result != null && mounted) setState(() => _propertyFiles[propertyId] = result);
  }

  void _scrollToField(String fieldLabel) {
    final key = _fieldKeys[fieldLabel];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
      
      
      
      
      final fn = <String, FocusNode>{
        'Full Name': fullNameFN,
        'Hp/Whatsapp': waFN,
        'Email': emailFN,
        'Note': generalNotesFN,
        'Blok No': lBlockNoFN,
        'Loss Reason Note': lossReasonNoteFN,
      }[fieldLabel];
      fn?.requestFocus();
    }
  }

  void _goToEdit({bool isUpdate = false, String? focusField}) async {
    if (!isUpdate) {
      _goEditForm(focusField: focusField);
    } else {
      _goEditStatus();
    }
  }

  void _goEditForm({String? focusField}) async {
    if (!PermissionsHelper.canEditContact) return;
    AnalyticsService.logEvent('contact_form_navigate_to_edit_field');
    await context.pushNamed(
      'formContact',
      extra: ContactDetailArgs(
        page: 1,
        dataContact: widget.args.dataContact,
        initialTab: 1,
        focusField: focusField,
      ),
    );
    if (mounted && widget.args.dataContact != null) {
      context.read<ContactBloc>().add(
        FetchContactDetailEvent(widget.args.dataContact!.contactId!),
      );
    }
  }

  
  
  String _statusGroup(int? id) {
    if (id == null) return 'db';
    final st = context.read<ProspectStatusBloc>().state;
    if (st.status != ProspectStatusEnum.loaded) return 'db';
    for (final s in st.statuses) {
      if (s.statusProspectId == id) return s.group;
    }
    return 'db';
  }

  
  
  bool _isVisitorWi(int? id) {
    if (id == null) return false;
    final st = context.read<ProspectStatusBloc>().state;
    if (st.status != ProspectStatusEnum.loaded) return false;
    for (final s in st.statuses) {
      if (s.statusProspectId == id) return s.isVisitorWi;
    }
    return false;
  }

  
  List<int> _statusIdsForGroup(String group) {
    final st = context.read<ProspectStatusBloc>().state;
    if (st.status != ProspectStatusEnum.loaded) return const [];
    return st.statuses
        .where((e) => e.group == group)
        .map((e) => e.statusProspectId)
        .toList();
  }

  
  
  void _goEditStatus({String? group}) async {
    if (!PermissionsHelper.canEditContact) return;
    
    
    final stateDetail = context.read<ContactBloc>().state.contactDetail;
    final contact = (stateDetail != null && stateDetail.contactId == widget.args.dataContact?.contactId)
        ? stateDetail
        : widget.args.dataContact;
    if (contact == null) return;

    
    int? resolvedStatusId = selectedStatusId;
    if (group != null) {
      final ids = _statusIdsForGroup(group);
      if (ids.isNotEmpty) {
        resolvedStatusId = ids.contains(selectedStatusId) ? selectedStatusId : ids.first;
      }
    }

    await context.pushNamed(
      'addContact',
      extra: ContactDetailArgs(
        
        
        dataContact: contact.copyWith(statusProspectId: resolvedStatusId),
        page: 6,
        sourceRoute: 'editContact',
        createContactParams: createContactParams,
      ),
    );
    if (!mounted || contact.contactId == null) return;
    context.read<ContactBloc>().add(FetchContactDetailEvent(contact.contactId!));
    context.read<ContactDetailActivityBloc>().add(
      FetchActivitiesEvent(contactId: contact.contactId!, isRefresh: true),
    );
  }

  Widget _buildPropertySelectField(ContactProperty prop, TextEditingController ctrl) {
    final bool canNavigate = widget.args.page == 2;
    final bool isHighlighted = _highlightedField == prop.label;
    final fieldKey = _fieldKeys.putIfAbsent(prop.label, () => GlobalKey());
    final String selectedValue = ctrl.text;
    final bool isEmpty = selectedValue.isEmpty;
    final String displayLabel = isEmpty
        ? prop.label
        : (prop.options.firstWhere(
            (o) => o['value'] == selectedValue,
            orElse: () => {'label': selectedValue, 'value': selectedValue},
          )['label'] ?? selectedValue);

    return GestureDetector(
      onTap: canNavigate
          ? () => _goToEdit(focusField: prop.label)
          : () => _showPropertySelectSheet(prop, ctrl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        key: fieldKey,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: isHighlighted ? Color(primaryColor).withValues(alpha: 0.06) : Color(whiteColor),
          border: Border(bottom: BorderSide(width: isHighlighted ? 2 : 1, color: isHighlighted ? Color(primaryColor) : Color(grey9Color))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEmpty)
                    Text(prop.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isHighlighted ? Color(primaryColor) : Color(grey2Color))),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted ? Color(primaryColor) : isEmpty ? Color(grey2Color) : Color(blackColor),
                    ),
                  ),
                ],
              ),
            ),
            if (!canNavigate) const Icon(Icons.arrow_drop_down, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFileField(int propertyId, String label) {
    final bool canNavigate = widget.args.page == 2;
    final bool isHighlighted = _highlightedField == label;
    final fieldKey = _fieldKeys.putIfAbsent(label, () => GlobalKey());
    final picked = _propertyFiles[propertyId];
    final existingUrl = _getOrCreatePropertyController(propertyId).text;
    final hasExisting = existingUrl.isNotEmpty;
    final hasFile = picked != null || hasExisting;

    return GestureDetector(
      onTap: canNavigate ? () => _goToEdit(focusField: label) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        key: fieldKey,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: isHighlighted ? Color(primaryColor).withValues(alpha: 0.06) : Color(whiteColor),
          border: Border(bottom: BorderSide(width: isHighlighted ? 2 : 1, color: isHighlighted ? Color(primaryColor) : Color(grey9Color))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isHighlighted ? Color(primaryColor) : Color(grey2Color))),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: hasFile
                      ? GestureDetector(
                          onTap: canNavigate
                              ? null
                              : () {
                                  final url = picked != null ? null : existingUrl;
                                  if (url != null && url.isNotEmpty) {
                                    context.pushNamed('attachmentWebView', extra: url);
                                  } else if (picked != null) {
                                    
                                    _showPropertyFilePicker(propertyId);
                                  }
                                },
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file_rounded, size: 16, color: Color(primaryColor)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  picked != null ? picked.name : 'Lihat File',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(primaryColor)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (!canNavigate) ...[
                  if (hasFile)
                    GestureDetector(
                      onTap: () {
                        AnalyticsService.logEvent('contact_form_remove_property_file');
                        setState(() {
                          _propertyFiles[propertyId] = null;
                          _getOrCreatePropertyController(propertyId).clear();
                        });
                      },
                      child: Icon(Icons.close, color: Color(redColor), size: 20),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showPropertyFilePicker(propertyId),
                    child: Icon(Icons.upload_file_rounded, color: Color(grey2Color), size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }


  

  Widget _buildField({required String label,required TextEditingController controller,required FocusNode focusNode,String fieldType = 'text',bool isError = false,String? errorText,bool? readOnly, int? minLines, DateTime? dateFirstDate, DateTime? dateLastDate, VoidCallback? onViewTap, bool Function()? guard,}) {
    final bool isRequired = _requiredLabels.contains(label);
    final bool isReadOnly = readOnly == true || widget.args.page == 2;
    final bool isDisplayGrey = widget.args.page == 2;
    final bool canNavigate = widget.args.page == 2 && label != "Create Date";
    final bool isHighlighted = !isError && _highlightedField == label;
    final fieldKey = _fieldKeys.putIfAbsent(label, () => GlobalKey());

    return GestureDetector(
      onTap: canNavigate ? (onViewTap ?? () => _goToEdit(focusField: label)) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            key: fieldKey,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              color: isHighlighted ? Color(primaryColor).withValues(alpha: 0.06) : Color(whiteColor),
              border: Border(bottom: BorderSide(width: isHighlighted ? 2 : 1, color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey9Color))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
          
                    children: [
                      Builder(
                        builder: (context) {
                          
                          if (fieldType == 'date') {
                            return GestureDetector(
                              onTap: isReadOnly
                                  ? null
                                  : () async {
                                      if (guard != null && !guard()) return;
                                      focusNode.unfocus();
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _parseDateOrToday(controller.text),
                                        firstDate: dateFirstDate ?? DateTime(1900),
                                        lastDate: dateLastDate ?? DateTime(2100),
                                      );
                                      if (picked != null) {
                                        controller.text = DateHelper.formatDate(picked);
                                      }
                                    },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  readOnly: isReadOnly,
                                  maxLines: null,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : isDisplayGrey ? Color(blackColor) : (readOnly == true ? Color(grey2Color) : Color(blackColor))),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    label: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700), children: [TextSpan(text: label, style: TextStyle(color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color))), if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontSize: 12, fontWeight: FontWeight.w700))])),
                                    floatingLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color)),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            );
                          }

                          
                          if (fieldType == 'int') {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              readOnly: isReadOnly,
                              enabled: !isReadOnly,
                              maxLines: null,

                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12, color: isHighlighted ? Color(primaryColor) : isDisplayGrey ? Color(grey2Color) : Color(blackColor), fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                isDense: true,
                                label: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700), children: [TextSpan(text: label, style: TextStyle(color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color))), if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontSize: 12, fontWeight: FontWeight.w700))])),
                                floatingLabelStyle: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            );
                          }

                          
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            readOnly: isReadOnly,
                            enabled: !isReadOnly,
                            minLines: minLines,
                            maxLines: null,
                            style: TextStyle(fontSize: 12, color: isHighlighted ? Color(primaryColor) : (readOnly == true ? Color(grey2Color) : Color(blackColor)), fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              isDense: true,
                              label: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700), children: [TextSpan(text: label, style: TextStyle(color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color))), if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Color(redColor), fontSize: 12, fontWeight: FontWeight.w700))])),
                              floatingLabelStyle: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: isError ? Color(redColor) : isHighlighted ? Color(primaryColor) : Color(grey2Color)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          );
                        },
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null)
          Container(
            width: double.infinity,
            color: Color(whiteColor),
            child: Padding(
            padding: const EdgeInsets.only(top: 2, left: 16),
            child: Text(errorText, style: TextStyle(fontSize: 11, color: Color(redColor))),
            ),
          ),
        ],
      ),
    );
  }
}
