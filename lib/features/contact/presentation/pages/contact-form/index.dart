import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/services/salesbook_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_event.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_block.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_event.dart';
import 'package:progress_group/features/contact/presentation/state/product_type/product_type_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/product_type/product_type_state.dart';
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
import 'package:progress_group/features/contact/presentation/state/property_unit/property_unit_state.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import '../../../../../core/utils/widget/custom_file_picker.dart';
import '../../state/activity/activity_bloc.dart';
import '../../state/activity/activity_event.dart';
import '../../state/pameran_aktif/pameran_aktif_cubit.dart';

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
  static const List<int> _pameranIds = [29, 30, 31, 32];
  static const Set<String> _requiredLabels = {'Salutation', 'Full Name', 'Hp/Whatsapp', 'Owner', 'Project', 'Sales Channel', 'Sales Channel Detail', 'Note'};

  bool _showValidation = false;
  bool _isSaving = false;
  String? _highlightedField;

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
      periodePameranDate: _pameranIds.contains(selectedSource1Id) ? _periodePameranDateBackend : null,
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
    final now = DateTime.now();
    final combined = DateTime(parsed.year, parsed.month, parsed.day, now.hour, now.minute, now.second);
    _periodePameranDateBackend = '${DateHelper.formatNumericCompact(combined)} ${DateFormat('HH:mm:ss').format(combined)}';
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
    _init();
  }



  void _init() async {
    _addControllerListeners();
    final contactId = widget.args.dataContact?.contactId;
    final contactState = context.read<ContactBloc>().state;
    final currentDetail = contactState.contactDetail;

    // Check if we already have the correct detail in state
    final hasLatestDetail =
        currentDetail != null && currentDetail.contactId == contactId;

    if (widget.args.page == 1) {
      // Edit mode: Use latest detail from bloc if available, otherwise fallback to args
      if (hasLatestDetail) {
        await _fillForm(currentDetail);
      } else if (widget.args.dataContact != null) {
        await _fillForm(widget.args.dataContact!);
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
      // About tab (View mode):
      // If we already have the detail in bloc, just fill form.
      // If not, fetch it.
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
      print('[ContactForm] fetching ProspectStatuses');
      context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
    } else {
      print('[ContactForm] ProspectStatuses already loaded');
    }

    // Load townships for project dropdown
    final townshipState = context.read<TownshipBloc>().state;
    if (townshipState is! TownshipLoaded) {
      print('[ContactForm] fetching Townships');
      context.read<TownshipBloc>().add(GetTownshipsEvent());
    } else if (widget.args.page == 0 && selectFirstProject == null && townshipState.townships.isNotEmpty) {
      final first = townshipState.townships.first;
      setState(() {
        selectFirstProject = first.name;
        selectFirstTownshipId = first.id;
      });
    }
    if (context.read<ContactPropertiesBloc>().state.status != ContactPropertiesStatus.loaded) {
      print('[ContactForm] fetching ContactProperties');
      context.read<ContactPropertiesBloc>().add(FetchContactPropertiesEvent());
    } else {
      print('[ContactForm] ContactProperties already loaded');
    }
    if (context.read<LostReasonBloc>().state.status != LostReasonStatus.loaded) {
      print('[ContactForm] fetching LostReasons');
      context.read<LostReasonBloc>().add(FetchLostReasonsEvent());
    }

    // Auto-select first prospect status for Create mode if already loaded
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
      final today = DateHelper.formatDate(DateTime.now());

      setState(() {
        if (firstApptDateTC.text.isEmpty) firstApptDateTC.text = today;
        if (firstVisitorDateTC.text.isEmpty) firstVisitorDateTC.text = today;
        if (fspTC.text.isEmpty) fspTC.text = today;
        if (lspTC.text.isEmpty) lspTC.text = today;
        if (fakadTC.text.isEmpty) fakadTC.text = today;
        if (lakadTC.text.isEmpty) lakadTC.text = today;
        if (createAdTC.text.isEmpty) createAdTC.text = today;
        if (lastLostDateTC.text.isEmpty) lastLostDateTC.text = today;

        // Defaults for Deal Value and Visit Count
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
    if (_pameranIds.contains(selectedSource1Id)) {
      final now = DateTime.now();
      _periodePameranDateBackend = '${DateHelper.formatNumericCompact(now)} ${DateFormat('HH:mm:ss').format(now)}';
      periodePameranDateTC.text = DateHelper.formatDate(now);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PameranAktifCubit>().load();
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

      // Project / category / product dropdowns
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

      // Use stored IDs directly when available, fall back to name lookup
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

        // Find name by sales_person_id (for SE, Manager)
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

        // Find name by user_id (for owner)
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

        // For edit mode: build salesInfoFields directly from contact detail (don't use hierarchy auto-fill)
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
      // Auto-fill property controllers from property_groups if provided in detail response
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
        // ignore parsing errors
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
            // map keyed by property id: {"23": "City"}
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
        // ignore
      }

      // Auto-fill sales information based on ownerId — only for new contacts
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

          /// 🔹 AUTO PILIH INDEX PERTAMA
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

    // Check if owner is a subordinate
    var subordinatePath = findPath(user.subordinates, ownerUserId);
    if (subordinatePath != null) {
      // Collect superiors from salesRoles (bottom-up: immediate boss first)
      final superiors = <HierarchyNodeEntity>[];
      if (user.salesRoles.isNotEmpty) {
        HierarchyNodeEntity? current = user.salesRoles.first;
        bool isRoot = true;
        while (current != null) {
          // Root sales_roles node: salesPersonId is the subordinate's own ID,
          // salesPersonParentId is the actual supervisor's ID.
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

      // Chain top-to-bottom: [GM, ..., User, Sub1, ..., Owner]
      // reversed later to display bottom-to-top
      // Skip userNode if sales_person_id is null (e.g. superadmin)
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
      // 3. Case: Selecting themselves. Chain: [User, Boss, Grandboss...]
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
      // 4. Case: Maybe owner is a superior? Search in salesRoles parent chain
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
            // sales executive or unknown position
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

  bool _validateEmail() {
    final email = emailTC.text.trim();
    if (email.isEmpty) return true;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _importFromContacts() async {
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
    final today = DateHelper.formatDate(DateTime.now());
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

    // Status group flags (same grouping as contact-add _submitUpdateStatus)
    const apptIds    = [53, 60,];
    const reserveIds = [54, 70, 71, 72];
    const visitIds   = [63, 64, 65, 66];
    const spIds      = [74];
    const lostIds    = [55, 56, 57, 58, 61, 62, 67, 68, 69, 73, 75, 77, 78];

    final isAppt    = apptIds.contains(selectedStatusId);
    final isReserve = reserveIds.contains(selectedStatusId);
    final isVisit   = visitIds.contains(selectedStatusId);
    final isSP      = spIds.contains(selectedStatusId);
    final isLost    = lostIds.contains(selectedStatusId);

    // first* date: kirim hanya jika status cocok DAN existing kosong (atau create mode)
    final existing        = widget.args.dataContact;
    final firstApptEmpty  = isCreate || existing?.firstApptDate == null   || (existing!.firstApptDate?.isEmpty   ?? true);
    final firstVisitEmpty = isCreate || existing?.firstVisitDate == null  || (existing!.firstVisitDate?.isEmpty  ?? true);
    final firstReserveEmpty = isCreate || existing?.firstReserveDate == null || (existing!.firstReserveDate?.isEmpty ?? true);
    final firstSPEmpty    = isCreate || existing?.firstSpDate == null     || (existing!.firstSpDate?.isEmpty     ?? true);

    // Helper: pakai nilai field, fallback ke today jika kosong
    String dateOr(String fieldValue) => fieldValue.isNotEmpty ? fieldValue : today;

    // Mapping Dynamic Properties
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

      // Appt dates — kirim hanya jika status appt
      lastApptDate:  isAppt ? _toBackendDate(dateOr(isUpdate ? lastApptDateTC.text : firstApptDateTC.text)) : null,
      firstApptDate: isAppt && firstApptEmpty ? _toBackendDate(dateOr(firstApptDateTC.text)) : null,

      // Visit dates — kirim hanya jika status visit
      lastVisitDate:  isVisit ? _toBackendDate(dateOr(isUpdate ? lastVisitorDateTC.text : firstVisitorDateTC.text)) : null,
      firstVisitDate: isVisit && firstVisitEmpty ? _toBackendDate(dateOr(firstVisitorDateTC.text)) : null,

      // Reserve dates — kirim hanya jika status reserve
      reserveDate:      isReserve ? _toBackendDate(dateOr(reserveDateTC.text)) : null,
      lastReserveDate:  isReserve ? _toBackendDate(dateOr(reserveDateTC.text)) : null,
      firstReserveDate: isReserve && firstReserveEmpty
          ? _toBackendDate(dateOr(firstReserveDateTC.text.isNotEmpty ? firstReserveDateTC.text : reserveDateTC.text))
          : null,

      // SP dates — kirim hanya jika status SP
      lastSPDate:  isSP ? _toBackendDate(dateOr(lspTC.text)) : null,
      firstSPDate: isSP && firstSPEmpty ? _toBackendDate(dateOr(fspTC.text)) : null,

      // Akad dates — hanya dikirim saat edit
      lastAkadDate:  isUpdate ? _toBackendDate(lakadTC.text) : null,
      firstAkadDate: isUpdate && (existing?.firstAkadDate == null || (existing!.firstAkadDate?.isEmpty ?? true))
          ? _toBackendDate(fakadTC.text)
          : null,

      // Lost dates — kirim hanya jika status lost
      lostDate:     isLost ? _toBackendDate(dateOr(lastLostDateTC.text)) : null,
      lastLostDate: isLost ? _toBackendDate(dateOr(lastLostDateTC.text)) : null,

      dealValue: dealValueTC.text.isNotEmpty ? dealValueTC.text : null,
      visitCount: vCountTC.text.isNotEmpty ? int.tryParse(vCountTC.text) : null,
      volumePlan: volumePlanTC.text.isNotEmpty ? volumePlanTC.text : null,
      nameSP: nameSPTC.text.isNotEmpty ? nameSPTC.text : null,
      noKtp: noKTPTC.text.isNotEmpty ? noKTPTC.text : null,
      ktpAddress: ktpAddressTC.text.isNotEmpty ? ktpAddressTC.text : null,
      propertiesJson: propertiesJson.isNotEmpty ? propertiesJson : null,
      periodePameranDate: _pameranIds.contains(selectedSource1Id) ? _periodePameranDateBackend : null,
    );
    print('=== SAVE PARAMS ===');
    print('ownerId: ${params.ownerId}');
    print('salesExecutiveId: ${params.salesExecutiveId}');
    print('salesManagerId: ${params.salesManagerId}');
    print('salesSupervisorId: ${params.salesSupervisorId}');
    print('salesGeneralManagerId: ${params.salesGeneralManagerId}');
    print('salesTeamId: ${params.salesTeamId}');
    print('===================');

    setState(() => _isSaving = true);
    if (isUpdate) {
      context.read<ContactBloc>().add(UpdateContactEvent(widget.args.dataContact!.contactId!, params));
    } else {
      context.read<ContactBloc>().add(CreateContactEvent(params));
    }
  }


  DateTime _parseDateOrToday(String? value) {
    if (value == null || value.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(value);
    } catch (_) {}
    try {
      return DateFormat('dd MMMM yyyy', 'en_US').parse(value);
    } catch (_) {}
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (_) {}
    return DateTime.now();
  }

  String? _toBackendDate(String value) {
    if (value.isEmpty) return null;
    final dt = _parseDateOrToday(value);
    return '${DateHelper.formatNumericCompact(dt)} 00:00:00';
  }

  
  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactBloc, ContactState>(
      listener: (context, state) {
        if (state.status == ContactStatus.createSuccess && widget.args.page == 0) {
          setState(() => _isSaving = false);
          debugPrint('[ContactForm] CREATE success — contact_id: ${state.contactDetail?.contactId} ${state.contactDetail?.fullName}');
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
          print('[ContactForm] UPDATE success — contact_id: ${state.contactDetail?.contactId}');
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
        } else if (state.status == ContactStatus.error && widget.args.page != 2) {
          setState(() => _isSaving = false);
          if (_isDialogShowing) {
            _isDialogShowing = false;
            Navigator.of(this.context).pop();
          }
          debugPrint('ContactFormError: ${state.errorMessage}');
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan data kontak')),
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
                debugPrint('ContactFormDetailError: ${contactState.errorMessage}');
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
                if (statusState == ProspectStatusEnum.error) print('[ContactForm] ProspectStatus ERROR');
                final detailLoading = contactState.status == ContactStatus.loadingDetail ||
                    contactState.status == ContactStatus.initial;

                // page 2 needs detailLoading (fetches fresh); page 1 always has data from args
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
                              if (profileState is ProfileLoaded) {
                                final user = profileState.profile;
                                final List<OwnerDropdownItem> ownerItems = [];
                                ownerItems.add(
                                  OwnerDropdownItem(
                                    id: user.userId,
                                    name: '${user.fullName} (me)',
                                    subtitle: user.positionName,
                                  ),
                                );
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
                
                                if (ownerItems.length == 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Anda tidak memiliki bawahan untuk dipilih.',
                                      ),
                                    ),
                                  );
                                  return;
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
                                  setState(() {
                                    selectedOwnerId = owner.id;
                                    selectedOwnerName = owner.name;
                                  });
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
                                  setState(() {
                                    selectLastProject = selected.name;
                                    selectLastTownshipId = selected.id;
                                    selectLastProjectCategory = null;
                                    selectLastProjectProduct = null;
                                    selectProductType = null;
                                  });
                                  context.read<PropertyUnitCubit>().load(
                                    selected.id!,
                                    isCommercial: selectLastProjectCategory?.toLowerCase() == 'commercial',
                                  );
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
                            label: "Project Category",
                            value: selectLastProjectCategory,
                            onTap: () async {
                              final result = await context.pushNamed(
                                'detailContactDropdown',
                                extra: ContactDropdownArgs(
                                  title: 'Pilih Project Category',
                                  items: itemsLastProjectCategory,
                                  selectedName: selectLastProjectCategory,
                                ),
                              );
                              if (result != null) {
                                final selected = result as OwnerDropdownItem;
                                setState(() {
                                  selectLastProjectCategory = selected.name;
                                  selectLastProjectProduct = null;
                                  selectProductType = null;
                                });
                                if (selectLastTownshipId != null) {
                                  context.read<PropertyUnitCubit>().load(
                                    selectLastTownshipId!,
                                    isCommercial: selected.name.toLowerCase() == 'commercial',
                                  );
                                }
                              }
                            },
                          ),

                          _buildFieldDown(
                            label: "Product Type",
                            value: selectProductType,
                            onTap: () async {
                              final ptState = context.read<ProductTypeBloc>().state;
                              final items = ptState.types
                                  .asMap()
                                  .entries
                                  .map((e) => OwnerDropdownItem(id: e.key, name: e.value))
                                  .toList();
                              if (ptState.status == ProductTypeStatus.loading) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memuat data product type...')),
                                );
                                return;
                              }
                              if (items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Data product type tidak tersedia')),
                                );
                                return;
                              }
                              final result = await context.pushNamed(
                                'detailContactDropdown',
                                extra: ContactDropdownArgs(
                                  title: 'Pilih Product Type',
                                  items: items,
                                  selectedName: selectProductType,
                                ),
                              );
                              if (result != null) {
                                final selected = result as OwnerDropdownItem;
                                setState(() => selectProductType = selected.name);
                              }
                            },
                          ),

                          _buildFieldDown(
                            label: "Product",
                            value: selectLastProjectProduct,
                            onTap: () async {
                              if (selectLastTownshipId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pilih Project terlebih dahulu')),
                                );
                                return;
                              }

                              final puState = context.read<PropertyUnitCubit>().state;

                              if (puState is PropertyUnitLoading) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memuat data product...')),
                                );
                                return;
                              }

                              if (puState is! PropertyUnitLoaded) {
                                context.read<PropertyUnitCubit>().load(
                                  selectLastTownshipId!,
                                  isCommercial: selectLastProjectCategory?.toLowerCase() == 'commercial',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memuat data product...')),
                                );
                                return;
                              }

                              if (puState.items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tidak ada produk tersedia untuk project ini')),
                                );
                                return;
                              }

                              final result = await context.pushNamed(
                                'detailContactDropdown',
                                extra: ContactDropdownArgs(
                                  title: 'Pilih Product',
                                  items: puState.items,
                                  selectedId: selectLastProductId,
                                ),
                              );
                              if (result != null) {
                                final selected = result as OwnerDropdownItem;
                                final parentId = int.tryParse(selected.typeData ?? '');
                                final isCommercial = selectLastProjectCategory?.toLowerCase() == 'commercial';
                                setState(() {
                                  selectLastProjectProduct = selected.name;
                                  selectLastProductId = selected.id;
                                  selectLastClusterId = isCommercial ? null : parentId;
                                  selectLastCommercialId = isCommercial ? parentId : null;
                                });
                              }
                            },
                          ),
                          _buildField(
                            label: "Blok No",
                            controller: lBlockNoTC,
                            focusNode: lBlockNoFN,
                          ),
                          if (const [63, 64, 65, 66, 67, 68, 69].contains(selectedStatusId))
                            _buildFieldDown(
                              label: "Jumlah Datang",
                              value: vCountTC.text.isEmpty ? null : (vCountTC.text == '5' ? '>5' : vCountTC.text),
                              onTap: () async {
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Jumlah Datang',
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
                          if (const [53, 54, 60, 61, 62, 76].contains(selectedStatusId))
                            _buildFieldDown(
                              label: "Appt Volume",
                              value: volumePlanTC.text.isEmpty ? null : (volumePlanTC.text == '5' ? '>5' : volumePlanTC.text),
                              onTap: () async {
                                final result = await context.pushNamed(
                                  'detailContactDropdown',
                                  extra: ContactDropdownArgs(
                                    title: 'Appt Volume',
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
                                  final isPameran = _pameranIds.contains(selected.id);
                                  if (isPameran) {
                                    final now = DateTime.now();
                                    _periodePameranDateBackend = '${DateHelper.formatNumericCompact(now)} ${DateFormat('HH:mm:ss').format(now)}';
                                    periodePameranDateTC.text = DateHelper.formatDate(now);
                                    context.read<PameranAktifCubit>().load();
                                  } else {
                                    _periodePameranDateBackend = null;
                                    periodePameranDateTC.text = '';
                                  }
                                  setState(() {
                                    selectedSource1Id = selected.id;
                                    selectedSource1Name = selected.name;
                                  });
                                }
                              } else {
                                context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
                              }
                            },
                          ),
                          _buildFieldDown(
                            label: "Sales Channel Detail",
                            value: selectedSource2Name,
                            isError: _showValidation && (selectedSource2Id == null || selectedSource2Id == 0),
                            errorText: (_showValidation && (selectedSource2Id == null || selectedSource2Id == 0)) ? 'Wajib diisi' : null,
                            onTap: () async {
                              final sourceState = context.read<InfoSourceBloc>().state;
                              final sources = sourceState.sourcesMap[2];
                              if (sources != null) {
                                final sourceItems = sources.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
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
                                  setState(() {
                                    selectedSource2Id = selected.id;
                                    selectedSource2Name = selected.name;
                                  });
                                }
                              } else {
                                context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 2));
                              }
                            },
                          ),
                          if (_pameranIds.contains(selectedSource1Id))
                            Builder(builder: (context) {
                              final ps = context.watch<PameranAktifCubit>().state;
                              final list = ps is PameranAktifLoaded ? ps.data : [];
                              if (list.isNotEmpty) {
                                for (final e in list) {
                                  print('PameranAktif startDate: ${e.startDate}, endDate: ${e.endDate}');
                                }
                              }
                              final firstDate = list.isNotEmpty ? list.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b) : null;
                              final lastDate = list.isNotEmpty ? list.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;
                              print('firstDate: $firstDate, lastDate: $lastDate');
                              return _buildField(
                                label: "Periode Pameran Date",
                                controller: periodePameranDateTC,
                                focusNode: periodePameranDateFN,
                                fieldType: 'date',
                                dateFirstDate: firstDate,
                                dateLastDate: lastDate,
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
                            onViewTap: () => _goEditStatus(statusIds: [53, 60, 76]),
                          ),
                           _buildField(
                            label: "Visitor/WI Date",
                            controller: lastVisitorDateTC,
                            focusNode: lastVisitorDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(statusIds: [63, 64, 65, 66, 67, 68, 69]),
                          ),
                           _buildField(
                            label: "Reserve Date",
                            controller: reserveDateTC,
                            focusNode: reserveDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(statusIds: [54, 70, 71, 72]),
                          ),

                           _buildField(
                            label: "SP Date",
                            controller: lspTC,
                            focusNode: lspFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(statusIds: [74]),
                          ),
                          //  _buildField(
                          //   label: "Akad Date",
                          //   controller: lakadTC,
                          //   focusNode: lakadFN,
                          //   fieldType: 'date',
                          // ),
                          _buildField(
                            label: "Lost Date",
                            controller: lastLostDateTC,
                            focusNode: lastLostDateFN,
                            fieldType: 'date',
                            onViewTap: () => _goEditStatus(statusIds: [43, 55, 56, 57, 58, 61, 62, 67, 68, 69, 73, 75, 77, 78]),
                          ),
                         


                          // _buildField(
                          //   label: "No KTP",
                          //   controller: noKTPTC,
                          //   focusNode: noKTPFN,
                          //   fieldType: 'int',
                          //   isError: _showValidation && noKTPTC.text.isEmpty,
                          // ),
                          // _buildField(
                          //   label: "KTP Address",
                          //   controller: ktpAddressTC,
                          //   focusNode: ktpAddressFN,
                          //   isError: _showValidation && ktpAddressTC.text.isEmpty,
                          // ),
                          
                         
                          
                         
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
                          debugPrint('ContactPropertiesError: ${state.errorMessage}');
                          return const Padding(padding: EdgeInsets.all(8.0), child: Text('Gagal memuat properties'));
                        }

                        // Auto-scroll + highlight when arriving from view mode with a focusField
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

                                  // default text
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
                          if (profileState is ProfileLoaded) {
                            final user = profileState.profile;
                            final List<OwnerDropdownItem> ownerItems = [];
                            ownerItems.add(OwnerDropdownItem(id: user.userId, name: '${user.fullName} (me)', subtitle: user.positionName));
                            void addSubs(List<HierarchyNodeEntity> subs) {
                              for (var s in subs) {
                                ownerItems.add(OwnerDropdownItem(id: s.userId, name: s.fullName, subtitle: s.positionName));
                                if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
                              }
                            }
                            addSubs(user.subordinates);
                            if (selectedOwnerId == null && ownerItems.isNotEmpty) {
                              selectedOwnerId = ownerItems.first.id;
                              selectedOwnerName = ownerItems.first.name;
                              _updateSalesInformation(ownerItems.first.id ?? 0, user);
                            }
                            if (ownerItems.length == 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Anda tidak memiliki bawahan untuk dipilih.')),
                              );
                              return;
                            }
                            final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Owner', items: ownerItems, selectedId: selectedOwnerId),);
                            if (result != null) {
                              final owner = result as OwnerDropdownItem;
                              setState(() {
                                selectedOwnerId = owner.id;
                                selectedOwnerName = owner.name;
                              });
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
                             setState(() {
                               selectFirstProject = selected.name;
                               selectFirstTownshipId = selected.id;
                               selectFirstProjectCategory = null;
                               selectFirstProjectProduct = null;
                               selectProductType = null;
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
                              final isPameran = _pameranIds.contains(selected.id);
                              if (isPameran) {
                                final now = DateTime.now();
                                _periodePameranDateBackend = '${DateHelper.formatNumericCompact(now)} ${DateFormat('HH:mm:ss').format(now)}';
                                periodePameranDateTC.text = DateHelper.formatDate(now);
                                context.read<PameranAktifCubit>().load();
                              } else {
                                _periodePameranDateBackend = null;
                                periodePameranDateTC.text = '';
                              }
                              setState(() {
                                selectedSource1Id = selected.id;
                                selectedSource1Name = selected.name;
                              });
                            }
                          } else {
                            context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
                          }
                        },
                      ),
                      _buildFieldDown(
                        label: "Sales Channel Detail",
                        value: selectedSource2Name,
                        isError: _showValidation && (selectedSource2Id == null || selectedSource2Id == 0),
                        errorText: (_showValidation && (selectedSource2Id == null || selectedSource2Id == 0)) ? 'Wajib diisi' : null,
                        onTap: () async {
                          final sourceState = context.read<InfoSourceBloc>().state;
                          final sources = sourceState.sourcesMap[2];
                          if (sources != null) {
                            final sourceItems = sources.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
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
                              setState(() {
                                selectedSource2Id = selected.id;
                                selectedSource2Name = selected.name;
                              });
                            }
                          } else {
                            context.read<InfoSourceBloc>().add( FetchInfoSourcesEvent(type: 2));
                          }
                        },
                      ),
                      if (_pameranIds.contains(selectedSource1Id))
                        Builder(builder: (context) {
                          final ps = context.watch<PameranAktifCubit>().state;
                          final list = ps is PameranAktifLoaded ? ps.data : [];
                          final firstDate = list.isNotEmpty ? list.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b) : null;
                          final lastDate = list.isNotEmpty ? list.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;
                          return _buildField(
                            label: "Periode Pameran Date",
                            controller: periodePameranDateTC,
                            focusNode: periodePameranDateFN,
                            fieldType: 'date',
                            dateFirstDate: firstDate,
                            dateLastDate: lastDate,
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
                onTap: () => context.pop(),
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
                            color: Colors.white,
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
      // Only request focus for plain text/int fields.
      // Date fields use AbsorbPointer + date picker — focusing them programmatically
      // shows a stray text keyboard instead of the date picker.
      // Dropdown fields have no keyboard at all.
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

  void _goEditStatus({List<int>? statusIds}) async {
    if (!PermissionsHelper.canEditContact) return;
    final contact = widget.args.dataContact;
    if (contact == null) return;

    // Jika statusIds diberikan, pakai status saat ini kalau cocok, otherwise pakai yang pertama
    final int? resolvedStatusId = statusIds != null && statusIds.isNotEmpty
        ? (statusIds.contains(selectedStatusId) ? selectedStatusId : statusIds.first)
        : selectedStatusId;

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
            // Label kecil di atas (sama seperti _buildFieldDown)
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
                                    // new picked file — no URL yet, just re-pick
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
                      onTap: () => setState(() {
                        _propertyFiles[propertyId] = null;
                        _getOrCreatePropertyController(propertyId).clear();
                      }),
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


  

  Widget _buildField({required String label,required TextEditingController controller,required FocusNode focusNode,String fieldType = 'text',bool isError = false,String? errorText,bool? readOnly, int? minLines, DateTime? dateFirstDate, DateTime? dateLastDate, VoidCallback? onViewTap,}) {
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
                          // Date field: open date picker and fill controller
                          if (fieldType == 'date') {
                            return GestureDetector(
                              onTap: isReadOnly
                                  ? null
                                  : () async {
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

                          // Integer field: restrict to digits
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

                          // Default: text input
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
