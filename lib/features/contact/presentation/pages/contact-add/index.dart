import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:progress_group/core/services/salesbook_sync_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/utils/widget/error_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/attandance/data/arguments/attandance_args.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_params.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/presentation/pages/unit-picker/index.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_event.dart';
import 'package:progress_group/features/contact/presentation/state/attachment_type/attachment_type_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_event.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_state.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_state.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_block.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_event.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_state.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_event.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_state.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/helpers/app_time.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/helpers/image_compress_helper.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_event.dart';

class ContactAddPage extends StatefulWidget {
  final ContactDetailArgs args;
  const ContactAddPage({super.key, required this.args});

  @override
  State<ContactAddPage> createState() => _ContactAddPageState();
}

class _ContactAddPageState extends State<ContactAddPage> {
  TextEditingController descTC = TextEditingController();
  TextEditingController descFormActivityTC = TextEditingController();
  TextEditingController lostReasonNoteTC = TextEditingController();
  TextEditingController lBlockNoTC = TextEditingController();
  TextEditingController volumeTC = TextEditingController();
  TextEditingController nameSPTC = TextEditingController();
  FocusNode descFN = FocusNode();
  FocusNode descFormActivityFN = FocusNode();
  FocusNode lostReasonNoteFN = FocusNode();
  FocusNode lBlockNoFN = FocusNode();
  FocusNode volumeFN = FocusNode();
  FocusNode spNameFN = FocusNode();

  bool isFollowUp = false;
  bool _noteError = false;
  DateTime? selectedDate;

  File? selectedImage;

  final ImagePicker picker = ImagePicker();
  String? existingImageUrl;
  String selectedTypeName = "Select type";
  String selectedStatusName = "Select status";

  int? selectedTypeId;
  int? selectedLostReasonId;
  String? selectedLostReasonName;
  int? selectedStatusId;
  String? selectedStatusValue;
  String? selectedStatusValueProspect;

  
  
  bool _prefillDateApplied = false;

  // Menunggu CreateVisitEvent (ActivityVisitBloc) dan UpdateContactEvent (ContactBloc)
  // sama-sama sukses sebelum halaman ditutup, supaya tidak ada yang gagal diam-diam
  // saat salah satu request selesai duluan dari yang lain.
  bool _visitActivityDone = false;
  bool _contactUpdateDone = false;

  String? selectedProject;
  String? selectedProduct;
  String? selectedProductType;
  int? selectedTownshipId;
  String jmlDatang = "1";
  String? selectedBlockNo;
  String? selectedProjectCategory;

  
  List<SelectedUnit> _selectedUnits = [];
  List<SelectedUnit> _allUnits = [];
  bool _unitsTouched = false;

  File? selectedFile;
  Uint8List? selectedFileBytes;
  String? selectedFileName;
  bool isPdf = false;
  List<File> selectedImages = [];
  List<Uint8List> selectedImageBytes = [];

  
  List<File> _attachFiles = [];
  List<Uint8List> _attachFileBytes = [];
  List<String> _attachFileNames = [];
  List<bool> _attachFilesIsPdf = [];

  List<OwnerDropdownItem> itemsJmlDatang = [
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

  final List<OwnerDropdownItem> itemsProjectCategory = [
    OwnerDropdownItem(id: 1, name: "Residential"),
    OwnerDropdownItem(id: 2, name: "Commercial"),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('contact_add');
    selectedDate = AppTime.now();
    if (widget.args.dataActivity?.notes != null) {
      descFormActivityTC.text = widget.args.dataActivity!.notes!;
    }
    _init();
  }

  
  
  DateTime? _getSelectedDateByStatus(dynamic data) {
    final group = _resolveStatusGroup(
          context.read<ProspectStatusBloc>().state,
          data.statusProspectId,
        ) ??
        'db';

    String? raw;
    switch (group) {
      case 'appt':
        raw = data.lastApptDate;
        break;
      case 'reserve':
        raw = data.lastReserveDate;
        break;
      case 'visit':
        raw = data.lastVisitDate;
        break;
      case 'sp':
        raw = data.lastSpDate;
        break;
      case 'lost':
        raw = data.lastLostDate;
        break;
      default:
        return null; 
    }

    if (raw == null || raw.isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      
      if (group == 'lost') {
        final n = AppTime.now();
        return d.hour == 0 && d.minute == 0
            ? DateTime(d.year, d.month, d.day, n.hour, n.minute, 0)
            : d;
      }
      return d;
    } catch (_) {
      return null;
    }
  }

  void _autoSelectStatusIfNeeded(List<ProspectStatusEntity> statuses) {
    if (widget.args.page != 4) return;
    if (statuses.isEmpty) return;

    
    
    if (!_isVisitPickerStatus(statuses, selectedStatusId)) {
      final valid = _visitPickerStatuses(statuses);
      if (valid.isNotEmpty) {
        final def = valid.first;
        setState(() {
          selectedStatusId = def.statusProspectId;
          selectedStatusValue = def.statusValue;
          selectedStatusName = def.statusProspectName;
        });
      }
    }
  }

  void _init() async {
    if (widget.args.dataActivity != null) {
      final activity = widget.args.dataActivity!;
      setState(() {
        descTC.text = activity.notes ?? "";
        if (activity.nextFollowUpDate != null &&
            activity.nextFollowUpDate!.isNotEmpty) {
          try {
            isFollowUp = true;
            final d = DateTime.parse(activity.nextFollowUpDate!);
            final n = AppTime.now();
            selectedDate = d.hour == 0 && d.minute == 0
                ? DateTime(d.year, d.month, d.day, n.hour, n.minute, 0)
                : d;
          } catch (_) {}
        } else if (activity.activityDate.isNotEmpty) {
          try {
            final d = DateTime.parse(activity.activityDate);
            final n = AppTime.now();
            selectedDate = d.hour == 0 && d.minute == 0
                ? DateTime(d.year, d.month, d.day, n.hour, n.minute, 0)
                : d;
          } catch (_) {}
        }
      });
    }

    if ((widget.args.page == 6 || widget.args.page <= 4) &&
        widget.args.dataContact != null) {
      final data = widget.args.dataContact!;
      
      
      final params = widget.args.createContactParams;

      setState(() {
        
        
        
        selectedProject = data.lastProject ?? params?.lastProject ?? data.firstProject ?? params?.firstProject;
        selectedProduct = (params?.lastProduct?.isNotEmpty == true)
            ? params!.lastProduct
            : (data.lastProduct?.isNotEmpty == true ? data.lastProduct : null);

        
        
        selectedStatusId = data.statusProspectId;

        selectedBlockNo = params?.lastBlokNo ?? data.lastBlokNo;
        selectedProjectCategory = params?.lastProjectCategory ?? data.lastProjectCategory;
        selectedProductType = params?.productType ?? data.productType;
        lBlockNoTC.text = params?.lastBlokNo ?? data.lastBlokNo ?? '';
        
        _allUnits = data.units ?? [];
        _selectedUnits = _activeUnitsForTownship(data.lastProjectId);
        jmlDatang = (params?.visitCount ?? data.visitCount)?.toString() ?? "1";
        nameSPTC.text = params?.nameSP ?? data.nameSP ?? '';
        descTC.text = params?.generalNotes ?? data.generalNotes ?? "";
        volumeTC.text = params?.volumePlan ?? (data.volumePlan != null ? data.volumePlan.toString() : '0');
        selectedLostReasonId = params?.lostReasonId ?? data.lostReasonId;
        lostReasonNoteTC.text = params?.lostReasonNote ?? data.lostReasonNote ?? '';

        
        final statusState = context.read<ProspectStatusBloc>().state;
        if (statusState.status == ProspectStatusEnum.loaded) {
          for (final s in statusState.statuses) {
            if (s.statusProspectId == selectedStatusId) {
              selectedStatusName = s.statusProspectName;
              break;
            }
          }
        }

        
        final reasonState = context.read<LostReasonBloc>().state;
        if (reasonState.status == LostReasonStatus.loaded) {
          for (final r in reasonState.reasons) {
            if (r.lostReasonId == selectedLostReasonId) {
              selectedLostReasonName = r.lostReasonName;
              break;
            }
          }
        }

        final autoDate = _getSelectedDateByStatus(data);
        if (autoDate != null) {
          selectedDate = autoDate;
        }
      });

      
      
      final cachedStatus = context.read<ProspectStatusBloc>().state;
      if (cachedStatus.status == ProspectStatusEnum.loaded) {
        _autoSelectStatusIfNeeded(cachedStatus.statuses);
      }

      if (selectedProject != null) _loadTownshipClusters(selectedProject!);

      
      
      if (params == null) {
        context.read<ContactBloc>().add(FetchContactDetailEvent(data.contactId!));
      }
    }

    if ((widget.args.page == 5 || widget.args.page == 7) && widget.args.dataAttachment != null) {
      final data = widget.args.dataAttachment!;

      setState(() {
        selectedTypeId = data.attachmentTypeId;
        selectedTypeName = data.attachmentTypeName;
        descTC.text = data.attachmentNote;
        existingImageUrl = data.attachmentUrl;
      });
    }

    context.read<AttachmentTypeBloc>().add(FetchAttachmentTypesEvent());
    context.read<ProspectStatusBloc>().add(const FetchProspectStatusesEvent());
    context.read<LostReasonBloc>().add(FetchLostReasonsEvent());
  }

  Future<void> pickFile() async {
    AnalyticsService.logEvent('contact_add_add_attachment');
    final isEdit = widget.args.page == 7;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb,
      allowMultiple: !isEdit,
    );

    if (result == null) return;

    if (isEdit) {
      
      final picked = result.files.single;
      if (kIsWeb) {
        if (picked.bytes != null) {
          setState(() {
            selectedFileBytes = picked.bytes;
            selectedFile = null;
            selectedFileName = picked.name;
            isPdf = picked.name.toLowerCase().endsWith('.pdf');
          });
        }
      } else {
        if (picked.path != null) {
          setState(() {
            selectedFile = File(picked.path!);
            selectedFileBytes = null;
            selectedFileName = picked.name;
            isPdf = picked.name.toLowerCase().endsWith('.pdf');
          });
        }
      }
      return;
    }

    
    final newFiles = <File>[];
    final newBytes = <Uint8List>[];
    final newNames = <String>[];
    final newIsPdf = <bool>[];

    for (final picked in result.files) {
      final isPdfFile = picked.name.toLowerCase().endsWith('.pdf');
      if (kIsWeb) {
        if (picked.bytes != null) {
          newBytes.add(Uint8List.fromList(picked.bytes!));
          newNames.add(picked.name);
          newIsPdf.add(isPdfFile);
        }
      } else {
        if (picked.path != null) {
          newFiles.add(File(picked.path!));
          newNames.add(picked.name);
          newIsPdf.add(isPdfFile);
        }
      }
    }

    setState(() {
      _attachFiles.addAll(newFiles);
      _attachFileBytes.addAll(newBytes);
      _attachFileNames.addAll(newNames);
      _attachFilesIsPdf.addAll(newIsPdf);
    });
  }

  Future<void> _openCamera() async {
    AnalyticsService.logEvent('contact_add_take_photo');
    final result = await context.pushNamed(
      'camera',
      extra: AttandanceArgs(
        type: "Visit",
        time: DateFormat('HH:mm').format(AppTime.now()),
        isReturnImage: true,
        skipPreview: true,
      ),
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          selectedImageBytes.add(result as Uint8List);
        } else {
          selectedImages.add(File(result as String));
        }
      });
    }
  }

  Future<void> _pickFromGallery() async {
    AnalyticsService.logEvent('contact_add_upload_from_gallery');
    final List<XFile> results = await picker.pickMultiImage(imageQuality: 80);
    if (results.isNotEmpty) {
      if (kIsWeb) {
        for (final x in results) {
          final bytes = await x.readAsBytes();
          selectedImageBytes.add(Uint8List.fromList(bytes));
        }
        setState(() {});
      } else {
        setState(() {
          selectedImages.addAll(results.map((x) => File(x.path)));
        });
      }
    }
  }

  void _showPhotoPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(grey7Color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(primaryColor)),
              title: Text("Camera"),
              onTap: () {
                Navigator.pop(ctx);
                _openCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(primaryColor)),
              title: Text("Upload from Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> pickDateTime(BuildContext context) async {
    AnalyticsService.logEvent('contact_add_pick_datetime');
    final now = AppTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final initialTime = selectedDate != null
        ? TimeOfDay(hour: selectedDate!.hour, minute: selectedDate!.minute)
        : TimeOfDay(hour: now.hour, minute: now.minute);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
        0,
      );
    });
  }

  Future<void> _openGoogleCalendar({
    required String title,
    required DateTime start,
    required String? description,
  }) async {
    final end = start.add(const Duration(hours: 1));
    final fmt = DateFormat("yyyyMMdd'T'HHmmss");
    final dates = '${fmt.format(start)}/${fmt.format(end)}';
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': title,
      'dates': dates,
    };
    if (description != null && description.isNotEmpty) {
      params['details'] = description;
    }
    final uri = Uri.https('calendar.google.com', '/calendar/render', params);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _showAddToCalendarDialog({
    required DateTime followUpDate,
    required String? description,
  }) async {
    final contactName = widget.args.dataContact?.fullName ?? 'Contact';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah ke Google Calendar?'),
        content: Text(
          'Follow up "$contactName" pada ${DateHelper.formatDateTimeShort(followUpDate)}',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _openGoogleCalendar(
        title: 'Follow Up - $contactName',
        start: followUpDate,
        description: description,
      );
    }
  }

  void _submitActivity({
    required String activityType,
    required DateTime activityDate,
    required TextEditingController notesTC,
    required bool isFollowUp,
    required DateTime? followUpDate,
  }) {
    AnalyticsService.logEvent('contact_add_save_activity');
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;

    String mappedType = activityType;
    String finalNotes = notesTC.text.trim();

    if (!['Call','WhatsApp','Visit','Meeting','Note','Email','Reminder','Other',].contains(activityType)) {
      mappedType = 'Other';
      finalNotes = '[$activityType] $finalNotes'.trim();
    }

    final params = CreateActivityParams(
      contactId: contactId,
      dealId: null,
      activityType: mappedType,
      activityDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(activityDate),
      notes: finalNotes.isEmpty ? null : finalNotes,
      nextFollowUpDate: isFollowUp && followUpDate != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(followUpDate)
          : null,
    );

    context.read<ActivityBloc>().add(CreateActivityEvent(params));
  }

  Future<void> _submitAttachment() async {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;

    final isEdit = widget.args.page == 7;

    if (selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tipe attachment')),
      );
      return;
    }

    if (isEdit) {
      
      if (selectedImage == null && selectedFile == null && selectedFileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih file')),
        );
        return;
      }

      File? finalFile = selectedFile ?? selectedImage;
      Uint8List? finalBytes = selectedFileBytes;

      if (!isPdf) {
        if (!kIsWeb && finalFile != null) {
          finalBytes = await compressImageFile(finalFile.path);
          finalFile = null;
        } else if (kIsWeb && finalBytes != null) {
          finalBytes = await compressImageBytes(finalBytes);
        }
      }
      if (!mounted) return;

      final params = UploadAttachmentParams(
        contactId: contactId,
        attachmentTypeId: selectedTypeId!,
        attachmentNote: descTC.text.isEmpty ? null : descTC.text,
        file: finalFile,
        fileBytes: finalBytes,
        fileName: selectedFileName,
      );

      context.read<UploadAttachmentBloc>().add(
        SubmitAttachmentEvent(
          params: params,
          attachmentId: widget.args.dataAttachment?.contactAttachmentId,
        ),
      );
      return;
    }

    
    if (_attachFiles.isEmpty && _attachFileBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu file')),
      );
      return;
    }

    final compressedBytes = <Uint8List>[];
    if (!kIsWeb) {
      for (int i = 0; i < _attachFiles.length; i++) {
        if (_attachFilesIsPdf[i]) {
          compressedBytes.add(await _attachFiles[i].readAsBytes());
        } else {
          compressedBytes.add(await compressImageFile(_attachFiles[i].path));
        }
      }
    } else {
      for (int i = 0; i < _attachFileBytes.length; i++) {
        if (_attachFilesIsPdf[i]) {
          compressedBytes.add(_attachFileBytes[i]);
        } else {
          compressedBytes.add(await compressImageBytes(_attachFileBytes[i]));
        }
      }
    }

    if (!mounted) return;

    final params = UploadAttachmentParams(
      contactId: contactId,
      attachmentTypeId: selectedTypeId!,
      attachmentNote: descTC.text.isEmpty ? null : descTC.text,
      filesBytesList: compressedBytes,
      fileNames: List<String>.from(_attachFileNames),
    );

    context.read<UploadAttachmentBloc>().add(
      SubmitAttachmentEvent(params: params, attachmentId: null),
    );
  }

  Future<({List<File>? files, List<Uint8List>? bytesData})> _compressVisitImages() async {
    if (!kIsWeb && selectedImages.isNotEmpty) {
      final compressed = <Uint8List>[];
      for (final f in selectedImages) {
        compressed.add(await compressImageFile(f.path));
      }
      return (files: null, bytesData: compressed);
    } else if (kIsWeb && selectedImageBytes.isNotEmpty) {
      final compressed = <Uint8List>[];
      for (final b in selectedImageBytes) {
        compressed.add(await compressImageBytes(b));
      }
      return (files: null, bytesData: compressed);
    }
    return (
      files: selectedImages.isEmpty ? null : selectedImages,
      bytesData: selectedImageBytes.isEmpty ? null : selectedImageBytes,
    );
  }

  Future<void> _submitUpdateStatus(BuildContext context) async {

    final contact = widget.args.dataContact;
    
    final editParams = widget.args.createContactParams;

    
    
    
    final group = _currentStatusGroup();
    final d = _buildMilestoneDates(group, contact);
    final firstApptDate    = d['firstApptDate'];
    final lastApptDate     = d['lastApptDate'];
    final firstReserveDate = d['firstReserveDate'];
    final lastReserveDate  = d['lastReserveDate'];
    final firstVisitDate   = d['firstVisitDate'];
    final lastVisitDate    = d['lastVisitDate'];
    final firstSPDate      = d['firstSPDate'];
    final lastSPDate       = d['lastSPDate'];
    final firstLostDate    = d['firstLostDate'];
    final lostDate         = d['lostDate'];


    if (contact == null) return;

    final params = CreateContactParams(
      
      salutation: editParams?.salutation,
      fullName: editParams?.fullName,
      primaryPhone: editParams?.primaryPhone,
      whatsappNumber: editParams?.whatsappNumber,
      primaryEmail: editParams?.primaryEmail,
      salesExecutiveId: editParams?.salesExecutiveId,
      salesManagerId: editParams?.salesManagerId,
      salesSupervisorId: editParams?.salesSupervisorId,
      salesTeamId: editParams?.salesTeamId,
      salesChannelId: editParams?.salesChannelId,
      sumberInformasi2: editParams?.sumberInformasi2,
      dealValue: editParams?.dealValue,
      noKtp: editParams?.noKtp,
      ktpAddress: editParams?.ktpAddress,
      propertiesJson: editParams?.propertiesJson,
      firstProjectId: editParams?.firstProjectId,
      firstClusterId: editParams?.firstClusterId,
      firstCommercialId: editParams?.firstCommercialId,
      firstProductId: editParams?.firstProductId,
      firstBlokNo: editParams?.firstBlokNo,
      firstProject: editParams?.firstProject,
      firstProjectCategory: editParams?.firstProjectCategory,
      firstProduct: editParams?.firstProduct,

      
      statusProspectId: selectedStatusId,
      generalNotes: descTC.text.isNotEmpty ? descTC.text : null,
      lastBlokNo: lBlockNoTC.text.isNotEmpty ? lBlockNoTC.text : null,
      lastProject: selectedProject,
      lastProjectId: selectedTownshipId,
      lastProduct: selectedProduct,
      lastProjectCategory: selectedProjectCategory,
      productType: selectedProductType,
      
      units: _unitsTouched ? _selectedUnits.map((u) => u.toApiJson()).toList() : null,
      volumePlan: volumeTC.text.isNotEmpty ? volumeTC.text : null,
      visitCount: _parseVisitCount(jmlDatang),
      lostReasonId: selectedLostReasonId,
      nameSP: nameSPTC.text.isNotEmpty ? nameSPTC.text : null,
      lostReasonNote: lostReasonNoteTC.text.isNotEmpty ? lostReasonNoteTC.text : null,

      
      firstApptDate: firstApptDate,
      firstLostDate: firstLostDate,
      firstReserveDate: firstReserveDate,
      firstSPDate: firstSPDate,
      firstVisitDate: firstVisitDate,
      lastApptDate: lastApptDate,
      lastLostDate: lostDate,
      lastReserveDate: lastReserveDate,
      lastSPDate: lastSPDate,
      lastVisitDate: lastVisitDate,
      lostDate: lostDate,
    );

    
    
    

    
    
    final isVisitStatus = _isVisitGroup(selectedStatusId);

    _visitActivityDone = false;
    _contactUpdateDone = false;

    if (isVisitStatus) {
      final visitImages = await _compressVisitImages();
      if (!mounted) return;
      final paramsVisit = CreateVisitParams(
        contactId: widget.args.dataContact!.contactId!,
        statusProspectId: selectedStatusId!,
        visitCount: _parseVisitCount(jmlDatang),
        activityDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!),
        notes: descTC.text,
        files: visitImages.files,
        filesBytesData: visitImages.bytesData,
      );
      context.read<ActivityVisitBloc>().add(CreateVisitEvent(paramsVisit));
      
      context.read<ContactBloc>().add(UpdateContactEvent(contact.contactId!, params));
    } else {
      context.read<ContactBloc>().add(UpdateContactEvent(contact.contactId!, params), );
    }

    SalesbookSyncService.syncContact(contact.contactId!);
  }

  Future<void> _submitVisit(BuildContext context) async {
    if (selectedStatusId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status wajib dipilih')));
      return;
    }

    final contact = widget.args.dataContact;
    final editParams = widget.args.createContactParams;

    if (contact == null) return;

    
    final firstVisitDate = (contact.firstVisitDate == null && selectedDate != null)
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!)
        : null;
    final lastVisitDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!)
        : null;

    final visitImages = await _compressVisitImages();
    if (!mounted) return;

    _visitActivityDone = false;
    _contactUpdateDone = false;


    
    
    
    
    
    
    
    

    final paramsVisit = CreateVisitParams(
      contactId: contact.contactId!,
      statusProspectId: selectedStatusId!,
      visitCount: _parseVisitCount(jmlDatang),
      
      activityDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!),
      notes: descTC.text,
      files: visitImages.files,
      filesBytesData: visitImages.bytesData,
    );

    final paramsContact = CreateContactParams(
      salutation: editParams?.salutation,
      fullName: editParams?.fullName,
      primaryPhone: editParams?.primaryPhone,
      whatsappNumber: editParams?.whatsappNumber,
      primaryEmail: editParams?.primaryEmail,
      salesExecutiveId: editParams?.salesExecutiveId,
      salesManagerId: editParams?.salesManagerId,
      salesSupervisorId: editParams?.salesSupervisorId,
      salesTeamId: editParams?.salesTeamId,
      salesChannelId: editParams?.salesChannelId,
      sumberInformasi2: editParams?.sumberInformasi2,
      dealValue: editParams?.dealValue,
      noKtp: editParams?.noKtp,
      ktpAddress: editParams?.ktpAddress,
      propertiesJson: editParams?.propertiesJson,
      firstProjectId: editParams?.firstProjectId,
      firstClusterId: editParams?.firstClusterId,
      firstCommercialId: editParams?.firstCommercialId,
      firstProductId: editParams?.firstProductId,
      firstBlokNo: editParams?.firstBlokNo,
      firstProject: editParams?.firstProject,
      firstProjectCategory: editParams?.firstProjectCategory,
      firstProduct: editParams?.firstProduct,
      statusProspectId: selectedStatusId,
      generalNotes: descTC.text.isNotEmpty ? descTC.text : null,
      lastBlokNo: lBlockNoTC.text.isNotEmpty ? lBlockNoTC.text : null,
      lastProject: selectedProject,
      lastProjectId: selectedTownshipId,
      lastProduct: selectedProduct,
      lastProjectCategory: selectedProjectCategory,
      productType: selectedProductType,
      
      units: _unitsTouched ? _selectedUnits.map((u) => u.toApiJson()).toList() : null,
      volumePlan: volumeTC.text.isNotEmpty ? volumeTC.text : null,
      visitCount: _parseVisitCount(jmlDatang),
      firstVisitDate: firstVisitDate,
      lastVisitDate: lastVisitDate,
    );

    context.read<ActivityVisitBloc>().add(CreateVisitEvent(paramsVisit));
    context.read<ContactBloc>().add(UpdateContactEvent(contact.contactId!, paramsContact));

    
  }

  @override
  void dispose() {
    descTC.dispose();
    lostReasonNoteTC.dispose();
    lBlockNoTC.dispose();
    volumeTC.dispose();
    descFN.dispose();
    lBlockNoFN.dispose();
    volumeFN.dispose();
    nameSPTC.dispose();
    spNameFN.dispose();
    lostReasonNoteFN.dispose();
    descFormActivityTC.dispose();
    descFormActivityFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ActivityBloc, ActivityState>(
          listener: (ctx, state) {
            if (state.status == ActivityStatus.createSuccess || state.status == ActivityStatus.followUpSuccess) {
              if (state.status == ActivityStatus.createSuccess && widget.args.page == 3 && selectedDate != null) {
                _showAddToCalendarDialog(
                  followUpDate: selectedDate!,
                  description: descFormActivityTC.text.trim().isEmpty ? null : descFormActivityTC.text.trim(),
                ).then((_) => context.pop());
              } else if (state.status == ActivityStatus.followUpSuccess) {
                context.pushReplacementNamed(
                  'detailContact',
                  extra: ContactDetailArgs(
                    dataContact: widget.args.dataContact,
                    initialTab: 0,
                  ),
                );
              } else {
                context.pop();
              }
            } else if (state.status == ActivityStatus.error) {
              showErrorDialog(context, state.errorMessage ?? 'Gagal menambahkan activity');
            }
          },
        ),
        BlocListener<UploadAttachmentBloc, UploadAttachmentState>(
          listener: (ctx, state) {
            if (state is UploadAttachmentSuccess) {
              context.pop(2);
            } else if (state is UploadAttachmentError) {
              showErrorDialog(context, state.message);
            }
          },
        ),
        BlocListener<ContactBloc, ContactState>(
          listener: (ctx, state) {
            if (state.status == ContactStatus.updateSuccess) {
              final needsVisitActivity = widget.args.page == 4 || _isVisitGroup(selectedStatusId);
              if (!needsVisitActivity) {
                context.pop(0);
              } else {
                _contactUpdateDone = true;
                if (_visitActivityDone) context.pop(0);
              }
            } else if (state.status == ContactStatus.detailLoaded &&
                state.contactDetail != null) {
              final data = state.contactDetail!;
              setState(() {
                selectedProject = data.projectName ?? data.firstProject;
                
                selectedStatusId = data.statusProspectId;
                final statusState = context.read<ProspectStatusBloc>().state;
                if (statusState.status == ProspectStatusEnum.loaded) {
                  for (final s in statusState.statuses) {
                    if (s.statusProspectId == selectedStatusId) {
                      selectedStatusName = s.statusProspectName;
                      break;
                    }
                  }
                }

                selectedLostReasonId = data.lostReasonId;
                lostReasonNoteTC.text = data.lostReasonNote ?? '';
                final lostReasonState = context.read<LostReasonBloc>().state;
                if (lostReasonState.status == LostReasonStatus.loaded) {
                  for (final r in lostReasonState.reasons) {
                    if (r.lostReasonId == data.lostReasonId) {
                      selectedLostReasonName = r.lostReasonName;
                      break;
                    }
                  }
                }

                selectedBlockNo = data.lastBlokNo;
                selectedProject = data.lastProject ?? data.firstProject;
                selectedProduct = (data.lastProduct?.isNotEmpty == true) ? data.lastProduct : null;
                selectedProjectCategory = data.lastProjectCategory;
                selectedProductType = data.productType?.isNotEmpty == true ? data.productType : null;
                lBlockNoTC.text = data.lastBlokNo ?? '';
                
                _allUnits = data.units ?? [];
                _selectedUnits = _activeUnitsForTownship(data.lastProjectId);
                jmlDatang = data.visitCount?.toString() ?? "1";
                nameSPTC.text = data.nameSP ?? '';
                volumeTC.text = data.volumePlan?.toString() ?? "0";
                descTC.text = data.generalNotes ?? "";
                final autoDate = _getSelectedDateByStatus(data);
                if (autoDate != null) {
                  selectedDate = autoDate;
                }
              });
              
              final ssDetail = context.read<ProspectStatusBloc>().state;
              if (ssDetail.status == ProspectStatusEnum.loaded) {
                _autoSelectStatusIfNeeded(ssDetail.statuses);
              }
              if (selectedProject != null) _loadTownshipClusters(selectedProject!);
            } else if (state.status == ContactStatus.error) {
              showErrorDialog(context, state.errorMessage ?? 'Gagal memperbarui data kontak');
            }
          },
        ),
        BlocListener<ActivityVisitBloc, VisitState>(
          listener: (ctx, state) {
            if (state is VisitSuccess) {
              _visitActivityDone = true;
              if (_contactUpdateDone) context.pop(0);
            } else if (state is VisitError) {
              showErrorDialog(context, state.message);
            }
          },
        ),
        BlocListener<ProspectStatusBloc, ProspectStatusState>(
          listener: (context, state) {
            if (state.status == ProspectStatusEnum.loaded &&
                selectedStatusId != null) {
              for (final s in state.statuses) {
                if (s.statusProspectId == selectedStatusId) {
                  setState(() {
                    selectedStatusName = s.statusProspectName;
                  });
                  break;
                }
              }
            }
            if (state.status == ProspectStatusEnum.loaded) {
              _autoSelectStatusIfNeeded(state.statuses);
              
              if (!_prefillDateApplied && widget.args.dataContact != null) {
                _prefillDateApplied = true;
                final autoDate = _getSelectedDateByStatus(widget.args.dataContact);
                if (autoDate != null) {
                  setState(() => selectedDate = autoDate);
                }
              }
            }
          },
        ),
        BlocListener<LostReasonBloc, LostReasonState>(
          listener: (context, state) {
            if (state.status == LostReasonStatus.loaded &&
                selectedLostReasonId != null) {
              for (final r in state.reasons) {
                if (r.lostReasonId == selectedLostReasonId) {
                  setState(() {
                    selectedLostReasonName = r.lostReasonName;
                  });
                  break;
                }
              }
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final activityState = context.watch<ActivityBloc>().state;
              final attachmentState = context.watch<UploadAttachmentBloc>().state;
              final visitState = context.watch<ActivityVisitBloc>().state;

              final isLoading =activityState.status == ActivityStatus.creating ||attachmentState is UploadAttachmentLoading ||visitState is VisitLoading;

              return Stack(
                children: [
                  Column(
                    children: [
                      customHeader(
                        context,
                        widget.args.page == 0? "Call": widget.args.page == 1? "WhatsApp": widget.args.page == 2? "Meeting": widget.args.page == 3? "Reminder": widget.args.page == 4? "Visit": (widget.args.page == 5 || widget.args.page == 7)? "Attachment": selectedStatusName,
                        isBack: true,
                        colorBack: Color(primaryColor),
                        onBack: () {
                          AnalyticsService.logEvent('contact_add_back');
                          context.pop();
                        },
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (widget.args.page == 5 || widget.args.page == 7)
                                  _buildAttachment()
                                else if (widget.args.page == 4)
                                  _buildVisit()
                                else if (widget.args.page == 6)
                                  _buildUpdateStatusProspect()
                                else if (widget.args.page == 3)
                                  _buildReminderForm()
                                else
                                  _buildForm(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Color(whiteColor),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormVisit2() {
    return Column(
      children: [
        if (_currentIsVisitFormStatus()) _buildVisitPhotos(),
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        if (_currentIsVisitFormStatus()) _fieldJumlahDatang(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldUnitPicker(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        _buildButtonSave(),
      ],
    );
  }

  Widget _buildFormSP() {
    return Column(
      children: [
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldUnitPicker(),
        SizedBox(height: 12),
        _fieldNameSP(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        _buildButtonSave(),
      ],
    );
  }

  Widget _buildFormReserved() {
    return Column(
      children: [
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldUnitPicker(),
        SizedBox(height: 12),
        _fieldNameSP(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),

        _buildButtonSave(),
      ],
    );
  }

  Widget _buildFormAppt() {
    return Column(
      children: [
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldUnitPicker(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        _fieldVolume(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        _buildButtonSave(),
      ],
    );
  }

  Widget _buildFormDB() {
    return Column(
      children: [
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldUnitPicker(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),

        _buildButtonSave(),
      ],
    );
  }

  Widget _fieldNameSP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Name SP",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          maxLines: 1,
          controller: nameSPTC,
          focusNode: spNameFN,
          onTapOutside: (event) => spNameFN.unfocus(),
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Name SP...",
            hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(primaryColor)),
            ),
          ),
        ),
      ],
    );
  }

  
  
  
  String? _resolveStatusGroup(ProspectStatusState statusState, int? statusId) {
    if (statusId == null || statusState.status != ProspectStatusEnum.loaded) {
      return null;
    }
    for (final s in statusState.statuses) {
      if (s.statusProspectId == statusId) return s.group;
    }
    return 'db'; 
  }

  
  String _currentStatusGroup() => _resolveStatusGroup(context.read<ProspectStatusBloc>().state, selectedStatusId) ?? 'db';

  
  bool _isVisitGroup(int? id) => _resolveStatusGroup(context.read<ProspectStatusBloc>().state, id) == 'visit';

  
  
  
  
  List<ProspectStatusEntity> _visitPickerStatuses(List<ProspectStatusEntity> all) {
    final flagged = all.where((e) => e.isVisitForm).toList();
    if (flagged.isNotEmpty) return flagged;
    return all.where((e) => e.group == 'visit').toList();
  }

  
  bool _isVisitPickerStatus(List<ProspectStatusEntity> all, int? statusId) {
    if (statusId == null) return false;
    return _visitPickerStatuses(all).any((e) => e.statusProspectId == statusId);
  }

  
  
  bool _currentIsVisitFormStatus() {
    final st = context.read<ProspectStatusBloc>().state;
    return st.status == ProspectStatusEnum.loaded &&
        _isVisitPickerStatus(st.statuses, selectedStatusId);
  }

  
  
  bool _currentIsVisitorWi() {
    final st = context.read<ProspectStatusBloc>().state;
    if (st.status != ProspectStatusEnum.loaded) return false;
    for (final s in st.statuses) {
      if (s.statusProspectId == selectedStatusId) return s.isVisitorWi;
    }
    return false;
  }

  
  
  
  
  Map<String, String?> _buildMilestoneDates(String group, dynamic contact) {
    final picked = selectedDate != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!)
        : null;
    return {
      'firstApptDate':    (group == 'appt'    && contact?.firstApptDate    == null) ? picked : null,
      'lastApptDate':     group == 'appt'    ? picked : null,
      'firstReserveDate': (group == 'reserve' && contact?.firstReserveDate == null) ? picked : null,
      'lastReserveDate':  group == 'reserve' ? picked : null,
      'firstVisitDate':   (group == 'visit'   && contact?.firstVisitDate   == null) ? picked : null,
      'lastVisitDate':    group == 'visit'   ? picked : null,
      'firstSPDate':      (group == 'sp'      && contact?.firstSpDate      == null) ? picked : null,
      'lastSPDate':       group == 'sp'      ? picked : null,
      'firstLostDate':    (group == 'lost'    && contact?.firstLostDate    == null) ? picked : null,
      'lostDate':         group == 'lost'    ? picked : null,
    };
  }

  Widget _buildUpdateStatusProspect() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            BlocBuilder<ProspectStatusBloc, ProspectStatusState>(
              builder: (context, statusState) {
                final group = _resolveStatusGroup(statusState, selectedStatusId);
                if (group == null) {
                  return buildFormShimmer(showHeader: false);
                }
                switch (group) {
                  case 'appt':
                    return _buildFormAppt();
                  case 'reserve':
                    return _buildFormReserved();
                  case 'sp':
                    return _buildFormSP();
                  case 'visit':
                    return _buildFormVisit2();
                  case 'lost':
                    return _buildLostForm();
                  case 'db':
                  default:
                    return _buildFormDB(); 
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldVolume() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentStatusGroup() == 'appt' ? "Berapa kali appt" :
          _currentStatusGroup() == 'reserve' ? "Reserved Volume" : "Volume",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            AnalyticsService.logEvent('contact_add_select_volume');
            final selectedItem = itemsVolume.firstWhere(
              (e) => e.name == volumeTC.text,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Pilih berapa kali appt',
                items: itemsVolume,
                selectedId: selectedItem.id,
              ),
            );
            if (result != null) {
              final selected = result as OwnerDropdownItem;
              setState(() {
                volumeTC.text = selected.name.startsWith('>') ? selected.name.substring(1) : selected.name;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    volumeTC.text.isEmpty ? "Select volume" : volumeTC.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: volumeTC.text.isEmpty ? Color(grey2Color) : Color(blackColor),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLostForm() {
    return Column(
      children: [
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        _fieldLostReason(),
        SizedBox(height: 12),
        _fieldLostReasonNote(),
        SizedBox(height: 12),
        _buildButtonSave(),
      ],
    );
  }



  Widget _buildButtonSave() {
    return BlocBuilder<ContactBloc, ContactState>(
      builder: (context, contactState) {
        return BlocBuilder<ActivityVisitBloc, VisitState>(
          builder: (context, visitState) {
            
            final isVisitFlow = widget.args.page == 4 || _isVisitGroup(selectedStatusId);

            final isContactLoading = contactState.status == ContactStatus.creating;
            final isVisitLoading = visitState is VisitLoading;
            final isLoading = isVisitFlow ? (isVisitLoading || isContactLoading) : isContactLoading;

            return customButton(
              isLoading ? null : () {
                AnalyticsService.logEvent('contact_add_save_activity');
                widget.args.page == 4
                    ? _submitVisit(context)
                    : _submitUpdateStatus(context);
              },
              widget.args.buttonLabel ?? 'Save',
            );
          },
        );
      },
    );
  }

  Widget _fieldLostReasonNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lost Reaseon Note",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          maxLines: 4,
          minLines: 3,
          controller: lostReasonNoteTC,
          focusNode: lostReasonNoteFN,
          onTapOutside: (event) => lostReasonNoteFN.unfocus(),
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: "Lost Reaseon Note....",
            hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(primaryColor)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Note",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          maxLines: 4,
          minLines: 3,
          controller: descTC,
          focusNode: descFN,
          onTapOutside: (event) => descFN.unfocus(),
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: "Note...",
            hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(grey7Color)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(primaryColor)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldDate() {
    String displayStatus(String? value) {
      if (value == null) return '';
      if (!value.contains('-')) return value;
      return value.split('-').last.trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tanggal ${displayStatus(selectedStatusName)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () => pickDateTime(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(grey7Color)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateHelper.formatDateTimeShort(selectedDate!)
                      : DateHelper.formatDateTimeShort(AppTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(blackColor),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Color(primaryColor),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldStatusProspect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Status Prospect",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            AnalyticsService.logEvent('contact_add_select_status_prospect');
            final statusState = context.read<ProspectStatusBloc>().state;
            if (statusState.status == ProspectStatusEnum.loaded) {
              
              final isPage4 = widget.args.page == 4;
              final source = isPage4
                  ? _visitPickerStatuses(statusState.statuses)
                  : statusState.statuses;
              final statusItems = source
                  .map(
                    (e) => OwnerDropdownItem(
                      id: e.statusProspectId,
                      name: e.statusProspectName,
                    ),
                  )
                  .toList();

              if (isPage4 &&
                  !_isVisitPickerStatus(statusState.statuses, selectedStatusId) &&
                  statusItems.isNotEmpty) {
                selectedStatusId = statusItems.first.id;
                selectedStatusName = statusItems.first.name;
              }
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
                    selectedStatusName = picked.statusProspectName;
                  });
                }
              }
            } else {
              context.read<ProspectStatusBloc>().add(
                const FetchProspectStatusesEvent(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memuat daftar status...')),
              );
            }
          },
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedStatusName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedStatusName == "Select status"
                          ? Color(grey2Color)
                          : Color(blackColor),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLostReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lost Reason",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            AnalyticsService.logEvent('contact_add_select_lost_reason');
            final state = context.read<LostReasonBloc>().state;

            if (state.status == LostReasonStatus.loaded) {
              final items = state.reasons
                  .map(
                    (e) => OwnerDropdownItem(
                      id: e.lostReasonId,
                      name: e.lostReasonName,
                    ),
                  )
                  .toList();

              final result = await context.pushNamed(
                'detailContactDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih Lost Reason',
                  items: items,
                  selectedId: selectedLostReasonId,
                ),
              );

              if (result != null) {
                final selected = result as OwnerDropdownItem;

                final picked = state.reasons.firstWhere(
                  (e) => e.lostReasonId == selected.id,
                );

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
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLostReasonName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedLostReasonName == null
                          ? Color(grey2Color)
                          : Color(blackColor),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _parseVisitCount(String val) {
    final cleaned = val.startsWith('>') ? val.substring(1) : val;
    return int.tryParse(cleaned) ?? 1;
  }

  void _loadTownshipClusters(String projectName) {
    final townshipState = context.read<TownshipBloc>().state;
    if (townshipState is TownshipLoaded) {
      for (final t in townshipState.townships) {
        if (t.name.trim().toLowerCase() == projectName.trim().toLowerCase()) {
          selectedTownshipId = t.id;
          context.read<SalesKitDetailBloc>().add(LoadSalesKitDetailEvent(t.id));
          break;
        }
      }
    }
  }

  
  List<SelectedUnit> _activeUnitsForTownship(int? townshipId) =>
      _allUnits.where((u) => !u.isLost && (townshipId == null || u.townshipId == townshipId)).toList();

  
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

  Future<void> _openUnitPicker() async {
    final tid = selectedTownshipId;
    if (tid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Project terlebih dahulu')),
      );
      return;
    }
    AnalyticsService.logEvent('contact_add_select_unit');
    final result = await Navigator.of(context).push<List<SelectedUnit>>(
      MaterialPageRoute(
        builder: (_) => UnitPickerScreen(
          townshipId: tid,
          townshipName: selectedProject ?? 'Project',
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

  
  Widget _fieldUnitPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Produk/Unit",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: _openUnitPicker,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: _selectedUnits.isEmpty
                      ? Text("Pilih unit",
                          style: TextStyle(fontSize: 14, color: Color(grey2Color)))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final u in _selectedUnits)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(_unitDisplay(u),
                                    style: const TextStyle(fontSize: 14, color: Color(blackColor))),
                              ),
                          ],
                        ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldProject() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Project",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            AnalyticsService.logEvent('contact_add_select_township');
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
                  selectedId: selectedTownshipId,
                ),
              );
              if (result != null) {
                final selected = result as OwnerDropdownItem;
                final projectChanged = selectedTownshipId != selected.id;
                setState(() {
                  selectedProject = selected.name;
                  selectedTownshipId = selected.id;
                  selectedProduct = null;
                  selectedProductType = null;
                  lBlockNoTC.clear();
                  
                  if (projectChanged) {
                    _selectedUnits = _activeUnitsForTownship(selected.id);
                  }
                });
                context.read<SalesKitDetailBloc>().add(
                  LoadSalesKitDetailEvent(selected.id!),
                );
              }
            } else {
              context.read<TownshipBloc>().add(GetTownshipsEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memuat data project...')),
              );
            }
          },
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedProject ?? "Select project",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedProject == null
                          ? Color(grey2Color)
                          : Color(blackColor),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldJumlahDatang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Berapa kali datang",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            AnalyticsService.logEvent('contact_add_select_visit_count');
            final selectedItem = itemsJmlDatang.firstWhere(
              (e) => e.name == jmlDatang,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Pilih berapa kali datang',
                
                items: _currentIsVisitorWi()
                    ? itemsJmlDatang
                    : (itemsJmlDatang.isNotEmpty ? [itemsJmlDatang.first] : []),
                selectedId: selectedItem.id,
              ),
            );
            if (result != null) {
              final selected = result as OwnerDropdownItem;
              setState(() {
                jmlDatang = selected.name;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(grey8Color)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${jmlDatang}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Color(blackColor)),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 28),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildVisit() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildFormVisit2()],
        ),
      ),
    );
  }

  Widget _buildMultiFileArea() {
    final totalFiles = kIsWeb ? _attachFileBytes.length : _attachFiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Files",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
            ),
            if (totalFiles > 0)
              TextButton.icon(
                onPressed: pickFile,
                icon: Icon(Icons.add, size: 16, color: Color(primaryColor)),
                label: Text("Tambah", style: TextStyle(color: Color(primaryColor), fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
          ],
        ),
        SizedBox(height: 6),
        if (totalFiles == 0)
          GestureDetector(
            onTap: pickFile,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Color(grey9Color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(grey7Color)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(whiteColor),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(primaryColor)),
                    ),
                    child: Image.asset(icUpload, height: 24, width: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Upload Files",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(blue2Color)),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalFiles,
              itemBuilder: (context, index) {
                final isPdfFile = _attachFilesIsPdf[index];
                final fileName = _attachFileNames[index];

                Widget preview;
                if (isPdfFile) {
                  preview = Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Color(grey9Color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(grey7Color)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 36, color: Color(redAccentColor)),
                        SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: Color(grey2Color)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (kIsWeb) {
                  preview = Image.memory(
                    _attachFileBytes[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                } else {
                  preview = Image.file(
                    _attachFiles[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                }

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: preview,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          AnalyticsService.logEvent('contact_add_remove_attachment');
                          setState(() {
                            if (kIsWeb) {
                              _attachFileBytes.removeAt(index);
                            } else {
                              _attachFiles.removeAt(index);
                            }
                            _attachFileNames.removeAt(index);
                            _attachFilesIsPdf.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration:  BoxDecoration(
                            color: Color(blackColor).withAlpha(54),
                            shape: BoxShape.circle,
                          ),
                          child:  Icon(Icons.close, color: Color(whiteColor), size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAttachment() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.args.page == 7)
              GestureDetector(
                onTap: pickFile,
                child: Container(
                  width: double.infinity,
                  height: 130,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(grey9Color),
                    border: Border.all(color: Color(grey7Color)),
                  ),
                  child: (selectedFile != null || selectedFileBytes != null || selectedImage != null || existingImageUrl != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isPdf
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf, size: 60, color: Color(redAccentColor)),
                                    const SizedBox(height: 8),
                                    Text(selectedFileName ?? "PDF File", textAlign: TextAlign.center),
                                  ],
                                )
                              : selectedFileBytes != null
                              ? Image.memory(selectedFileBytes!, width: double.infinity, fit: BoxFit.cover)
                              : (selectedFile != null || selectedImage != null)
                              ? Image.file(selectedFile ?? selectedImage!, width: double.infinity, fit: BoxFit.cover)
                              : DriveImage(url: existingImageUrl!, width: double.infinity, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 58,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(whiteColor),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Color(primaryColor)),
                              ),
                              child: Image.asset(icUpload, height: 24, width: 24),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Upload Files",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(blue2Color)),
                            ),
                          ],
                        ),
                ),
              )
            else
              _buildMultiFileArea(),

            SizedBox(height: 12),
            Text(
              "Attachment Type",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(grey2Color),
              ),
            ),
            SizedBox(height: 6),
            BlocBuilder<AttachmentTypeBloc, AttachmentTypeState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () async {
                    AnalyticsService.logEvent('contact_add_select_attachment_type');
                    if (state is AttachmentTypeLoaded) {
                      final items = state.data
                          .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
                          .toList();

                      final result = await context.pushNamed(
                        'detailContactDropdown',
                        extra: ContactDropdownArgs(
                          title: 'Pilih Attachment Type',
                          items: items,
                          selectedId: selectedTypeId,
                        ),
                      );

                      if (result != null) {
                        final sel = result as OwnerDropdownItem;
                        setState(() {
                          selectedTypeId = sel.id;
                          selectedTypeName = sel.name;
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memuat attachment types...'),
                        ),
                      );
                      context.read<AttachmentTypeBloc>().add(
                        FetchAttachmentTypesEvent(),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(grey8Color)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            selectedTypeName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedTypeName == "Select type"
                                  ? Color(grey2Color)
                                  : Color(blackColor),
                            ),
                          ),
                        ),
                        if (state is AttachmentTypeLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.arrow_drop_down, size: 28),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            Text(
              "Description",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(grey2Color),
              ),
            ),
            SizedBox(height: 6),
            TextField(
              maxLines: 4,
              minLines: 3,
              controller: descTC,
              focusNode: descFN,
              onTapOutside: (event) => descFN.unfocus(),
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Describe the attachment...",
                hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(grey7Color)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(grey7Color)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(primaryColor)),
                ),
              ),
            ),
            SizedBox(height: 20),
            BlocBuilder<UploadAttachmentBloc, UploadAttachmentState>(
              builder: (context, state) {
                return customButton(() {
                  _submitAttachment();
                }, 'Save');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.args.page == 0? "Call": widget.args.page == 1? "WhatsApp": widget.args.page == 2? "Meeting": widget.args.page == 3? "Reminder": widget.args.page == 4? "Visit": widget.args.page == 5? "Attachment": "Update Status Prospect",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(grey2Color),
            ),
          ),
          SizedBox(height: 6),
          TextField(
            maxLines: 4,
            minLines: 3,
            controller: descFormActivityTC,
            focusNode: descFormActivityFN,
            onTapOutside: (event) => descFormActivityFN.unfocus(),
            textInputAction: TextInputAction.newline,
            onChanged: (_) {
              if (_noteError) setState(() => _noteError = false);
            },
            decoration: InputDecoration(
              hintText: "Describe the ${widget.args.page == 0? "call": widget.args.page == 1? "whatsapp": widget.args.page == 2? "meeting": widget.args.page == 3? "reminder": widget.args.page == 4? "visit": widget.args.page == 5? "attachment": "update status prospect"}...",
              hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
              errorText: _noteError ? 'Note tidak boleh kosong' : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(grey7Color)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _noteError ? Color(redAccentColor) : Color(grey7Color)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _noteError ? Color(redAccentColor) : Color(primaryColor)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(redAccentColor)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(redAccentColor)),
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(grey7Color)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateHelper.formatDateTimeShort(AppTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(grey2Color),
                  ),
                ),
                Icon(Icons.calendar_today, color: Color(grey2Color), size: 16),
              ],
            ),
          ),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Follow Up Reminder",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(grey2Color),
                    ),
                  ),
                  SizedBox(width: 12),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: isFollowUp,
                      activeTrackColor: Color(primaryColor),
                      onChanged: (value) {
                        setState(() {
                          isFollowUp = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (isFollowUp) ...[
                SizedBox(height: 5),
                Text(
                  "Follow Up In",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(grey2Color),
                  ),
                ),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: () => pickDateTime(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(grey7Color)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateHelper.formatDateTimeShort(selectedDate!)
                              : DateHelper.formatDateTimeShort(AppTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(blackColor),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Color(primaryColor),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 32),
              BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  final isFollowUpFlow = widget.args.buttonLabel == 'Complete';
                  final isLoading = isFollowUpFlow? state.status == ActivityStatus.followUpLoading: state.status == ActivityStatus.creating;

                  return customButton(isLoading ? null : () {
                      if (isFollowUpFlow && widget.args.dataActivity != null) {
                        context.read<ActivityBloc>().add(PostStatusFollowEvent([widget.args.dataActivity!.activityId]), );
                      } else {
                        if (descFormActivityTC.text.trim().isEmpty) {
                          setState(() => _noteError = true);
                          return;
                        }
                        _submitActivity(activityType: widget.args.namePage ?? '',activityDate: AppTime.now(),notesTC: descFormActivityTC,isFollowUp: isFollowUp,followUpDate: selectedDate,);
                      }
                    },
                    isLoading ? 'Menyimpan...' : (widget.args.buttonLabel ?? 'Save'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Follow Up",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(grey2Color),
            ),
          ),
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => pickDateTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(grey7Color)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? DateHelper.formatDateTimeShort(selectedDate!)
                        : DateHelper.formatDateTimeShort(AppTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(blackColor),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Color(primaryColor),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Description",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(grey2Color),
            ),
          ),
          SizedBox(height: 6),
          TextField(
            maxLines: 4,
            minLines: 3,
            controller: descFormActivityTC,
            focusNode: descFormActivityFN,
            onTapOutside: (event) => descFormActivityFN.unfocus(),
            textInputAction: TextInputAction.newline,
            onChanged: (_) {
              if (_noteError) setState(() => _noteError = false);
            },
            decoration: InputDecoration(
              hintText: "Describe the ${widget.args.page == 0? "call": widget.args.page == 1? "whatsapp": widget.args.page == 2? "meeting": widget.args.page == 3? "reminder": widget.args.page == 4? "visit": widget.args.page == 5? "attachment": "update status prospect"}...",
              hintStyle: TextStyle(color: Color(grey2Color), fontSize: 14),
              errorText: _noteError ? 'Note tidak boleh kosong' : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(grey7Color)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _noteError ? Color(redAccentColor) : Color(grey7Color)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _noteError ? Color(redAccentColor) : Color(primaryColor)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(redAccentColor)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(redAccentColor)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32),
              BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  final isFollowUpFlow = widget.args.buttonLabel == 'Complete';
                  final isLoading = isFollowUpFlow? state.status == ActivityStatus.followUpLoading: state.status == ActivityStatus.creating;

                  return customButton(isLoading ? null : () {
                      if (isFollowUpFlow && widget.args.dataActivity != null) {
                        context.read<ActivityBloc>().add(
                          PostStatusFollowEvent([widget.args.dataActivity!.activityId]),
                        );
                      } else {
                        if (descFormActivityTC.text.trim().isEmpty) {
                          setState(() => _noteError = true);
                          return;
                        }
                        _submitActivity(activityType: widget.args.namePage ?? '',activityDate: AppTime.now(),notesTC: descFormActivityTC,isFollowUp: true,followUpDate: selectedDate ?? AppTime.now(),);
                      }
                    },
                    isLoading ? 'Menyimpan...' : (widget.args.buttonLabel ?? 'Save'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitPhotos() {
    final totalImages = selectedImages.length + selectedImageBytes.length;
    final hasImages = totalImages > 0 && (widget.args.page == 4 || widget.args.page == 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Visit Photos",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(grey2Color),
              ),
            ),
            if (hasImages)
              Row(
                children: [
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.photo_library, color: Color(primaryColor)),
                    tooltip: 'Upload from Gallery',
                  ),
                  IconButton(
                    onPressed: _openCamera,
                    icon: Icon(Icons.camera_alt, color: Color(primaryColor)),
                    tooltip: 'Take Photo',
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 6),
        if (hasImages)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages,
              itemBuilder: (context, index) {
                final isFileBased = index < selectedImages.length;
                final bytesIndex = index - selectedImages.length;

                final imageWidget = isFileBased
                    ? Image.file(selectedImages[index], width: 100, height: 100, fit: BoxFit.cover)
                    : Image.memory(selectedImageBytes[bytesIndex], width: 100, height: 100, fit: BoxFit.cover);

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageWidget,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          AnalyticsService.logEvent('contact_add_remove_photo');
                          setState(() {
                            if (isFileBased) {
                              selectedImages.removeAt(index);
                            } else {
                              selectedImageBytes.removeAt(bytesIndex);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(blackColor).withAlpha(54),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Color(whiteColor),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: _showPhotoPickerBottomSheet,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Color(grey9Color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(grey7Color)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Color(primaryColor)),
                  SizedBox(height: 4),
                  Text(
                    "Add Photos",
                    style: TextStyle(color: Color(grey2Color), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 12),
      ],
    );
  }
}
