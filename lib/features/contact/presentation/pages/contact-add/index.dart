import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/utils/helpers/image_url.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/attandance/data/arguments/attandance_args.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_params.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
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
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../data/arguments/contact_detail_args.dart';

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
  String? selectedStatusValueProspect;

  String? selectedProject;
  String? selectedProduct;
  String jmlDatang = "1";
  String? selectedBlockNo;
  String? selectedProjectCategory;

  File? selectedFile;
  String? selectedFileName;
  bool isPdf = false;
  List<File> selectedImages = [];

  List<OwnerDropdownItem> itemsJmlDatang = [
    OwnerDropdownItem(name: "1"),
    OwnerDropdownItem(name: "2"),
    OwnerDropdownItem(name: "3"),
    OwnerDropdownItem(name: "4"),
    OwnerDropdownItem(name: ">5"),
  ];

  List<OwnerDropdownItem> itemsProject = [
    OwnerDropdownItem(id: 1, name: "Paradise Serpong City 1"),
    OwnerDropdownItem(id: 2, name: "Paradise Serpong City 2"),
    OwnerDropdownItem(id: 3, name: "Paradise Resort City"),
  ];

  List<OwnerDropdownItem> itemsProjectCategory = [
    OwnerDropdownItem(id: 1, name: "Residential"),
    OwnerDropdownItem(id: 2, name: "Commercial"),
  ];

  List<OwnerDropdownItem> itemsProduct = [
    OwnerDropdownItem(id: 1, name: "Evanto"),
    OwnerDropdownItem(id: 2, name: "Aris"),
    OwnerDropdownItem(id: 3, name: "Vireo"),
    OwnerDropdownItem(id: 4, name: "The Althea"),
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    if (widget.args.dataActivity?.notes != null) {
      descFormActivityTC.text = widget.args.dataActivity!.notes!;
    }
    _init();
  }

  DateTime? _getSelectedDateByStatus(dynamic data) {
    final statusId = data.statusProspectId;

    try {
      // APPOINTMENT
      if (statusId == 60 || statusId == 53) {
        if (data.lastApptDate != null && data.lastApptDate.isNotEmpty) {
          return DateTime.parse(data.lastApptDate);
        }
      }

      // RESERVE
      if ([54, 70, 71, 72].contains(statusId)) {
        if (data.lastReserveDate != null && data.lastReserveDate.isNotEmpty) {
          return DateTime.parse(data.lastReserveDate);
        }
      }

      // VISIT
      if ([63, 64, 65, 66].contains(statusId)) {
        if (data.lastVisitDate != null && data.lastVisitDate.isNotEmpty) {
          return DateTime.parse(data.lastVisitDate);
        }
      }

      // SP
      if (statusId == 74) {
        if (data.lastSpDate != null && data.lastSpDate.isNotEmpty) {
          return DateTime.parse(data.lastSpDate);
        }
      }

      // LOST
      if ([
        55,
        56,
        57,
        58,
        61,
        62,
        67,
        68,
        69,
        73,
        75,
        77,
        78,
      ].contains(statusId)) {
        if (data.lostDate != null && data.lostDate.isNotEmpty) {
          return DateTime.parse(data.lostDate);
        }
      }
    } catch (_) {}

    return null;
  }

  void _autoSelectStatusIfNeeded(List<ProspectStatusEntity> statuses) {
    if (widget.args.page != 4) return;

    const allowedIds = [63, 64, 65];

    final isValid =
        selectedStatusId != null && allowedIds.contains(selectedStatusId);

    if (!isValid && statuses.isNotEmpty) {
      final validStatuses = statuses
          .where((e) => allowedIds.contains(e.statusProspectId))
          .toList();

      if (validStatuses.isNotEmpty) {
        final defaultStatus = validStatuses.firstWhere(
          (e) => e.statusProspectId == 63,
          orElse: () => validStatuses.first,
        );
        setState(() {
          selectedStatusId = defaultStatus.statusProspectId;
          selectedStatusName = defaultStatus.statusProspectName;
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
            selectedDate = DateTime.parse(activity.nextFollowUpDate!);
          } catch (_) {}
        } else if (activity.activityDate.isNotEmpty) {
          try {
            selectedDate = DateTime.parse(activity.activityDate);
          } catch (_) {}
        }
      });
    }

    if ((widget.args.page == 6 || widget.args.page <= 4) &&
        widget.args.dataContact != null) {
      final data = widget.args.dataContact!;

      setState(() {
        selectedProject = data.lastProject ?? data.firstProject;
        selectedProduct = data.lastProduct;
        const _visitAllowedIds = [63, 64, 65];
        final rawStatusId = data.statusProspectId;
        selectedStatusId = (widget.args.page == 4 && !_visitAllowedIds.contains(rawStatusId))
            ? 63
            : rawStatusId;
        selectedBlockNo = data.lastBlokNo;
        selectedProjectCategory = data.lastProjectCategory;
        lBlockNoTC.text = data.lastBlokNo ?? '';
        jmlDatang = data.visitCount?.toString() ?? "1";
        descTC.text = data.generalNotes ?? "";
        volumeTC.text = data.volumePlan != null
            ? data.volumePlan.toString()
            : '0';
        selectedLostReasonId = data.lostReasonId;
        lostReasonNoteTC.text = data.lostReasonNote ?? '';

        // Resolusi Nama Status
        final statusState = context.read<ProspectStatusBloc>().state;
        if (statusState.status == ProspectStatusEnum.loaded) {
          for (final s in statusState.statuses) {
            if (s.statusProspectId == selectedStatusId) {
              selectedStatusName = s.statusProspectName;
              break;
            }
          }
        }

        // Resolusi Nama Alasan Lost
        final reasonState = context.read<LostReasonBloc>().state;
        if (reasonState.status == LostReasonStatus.loaded) {
          for (final r in reasonState.reasons) {
            if (r.lostReasonId == data.lostReasonId) {
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

      context.read<ContactBloc>().add(FetchContactDetailEvent(data.contactId!));
    }

    if (widget.args.page == 5 && widget.args.dataAttachment != null) {
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      setState(() {
        selectedFile = file;
        selectedFileName = result.files.single.name;
        isPdf = selectedFileName!.toLowerCase().endsWith('.pdf');
      });
    }
  }

  Future<void> _openCamera() async {
    final result = await context.pushNamed(
      'camera',
      extra: AttandanceArgs(
        type: "Visit",
        time: DateFormat('HH:mm').format(DateTime.now()),
        isReturnImage: true,
        skipPreview: true,
      ),
    );

    if (result != null) {
      final file = File(result as String);
      setState(() {
        selectedImages.add(file);
      });
    }
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        now.hour,
        now.minute,
        now.second,
      );
    });
  }

  void _submitActivity({
    required String activityType,
    required DateTime activityDate,
    required TextEditingController notesTC,
    required bool isFollowUp,
    required DateTime? followUpDate,
  }) {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;

    String mappedType = activityType;
    String finalNotes = notesTC.text.trim();

    if (!['Call','WhatsApp','Visit','Meeting','Note','Email','Task','Other',].contains(activityType)) {
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

  void _submitAttachment() {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId == null) return;

    final isEdit = widget.args.page == 6;

    if (selectedTypeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih tipe attachment')));
      return;
    }

    if (!isEdit && selectedImage == null && selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih file')));
      return;
    }
    final fileToUpload = selectedFile ?? selectedImage;
    final params = UploadAttachmentParams(
      contactId: contactId,
      attachmentTypeId: selectedTypeId!,
      attachmentNote: descTC.text.isEmpty ? null : descTC.text,
      file: fileToUpload,
    );

    context.read<UploadAttachmentBloc>().add(
      SubmitAttachmentEvent(
        params: params,
        attachmentId: isEdit
            ? widget.args.dataAttachment?.contactAttachmentId
            : null,
      ),
    );
  }

  void _submitUpdateStatus(BuildContext context) {
    final contact = widget.args.dataContact;

    final firstApptDate =(selectedStatusId == 60 || selectedStatusId == 53) &&(contact?.firstApptDate == null && selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;
    final lastApptDate =(selectedStatusId == 60 || selectedStatusId == 53) &&selectedDate != null? DateFormat('yyyy-MM-dd').format(selectedDate!): null;

    final firstReserveDate =(selectedStatusId == 54 ||selectedStatusId == 70 ||selectedStatusId == 71 ||selectedStatusId == 72) &&(contact?.firstReserveDate == null && selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;
    final lastReserveDate =(selectedStatusId == 54 ||selectedStatusId == 70 ||selectedStatusId == 71 ||selectedStatusId == 72) &&(selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;

    final firstVisitDate =(selectedStatusId == 63 ||selectedStatusId == 64 ||selectedStatusId == 65 ||selectedStatusId == 66) &&(contact?.firstVisitDate == null && selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;
    final lastVisitDate =(selectedStatusId == 63 ||selectedStatusId == 64 ||selectedStatusId == 65 ||selectedStatusId == 66) &&(selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;

    final firstSPDate =(selectedStatusId == 74) &&(contact?.firstSpDate == null && selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;
    final lastSPDate = (selectedStatusId == 74) && (selectedDate != null) ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null;

    final firstLostDate = contact?.firstLostDate != null && selectedDate != null? DateFormat('yyyy-MM-dd').format(selectedDate!): null;
    final lostDate =(selectedStatusId == 55 ||selectedStatusId == 56 ||selectedStatusId == 57 ||selectedStatusId == 58 ||selectedStatusId == 61 ||selectedStatusId == 62 ||selectedStatusId == 67 ||selectedStatusId == 68 ||selectedStatusId == 69 ||selectedStatusId == 73 ||selectedStatusId == 77 ||selectedStatusId == 78 ||selectedStatusId == 75) &&(selectedDate != null)? DateFormat('yyyy-MM-dd').format(selectedDate!): null;

    if (contact == null) return;

    final params = CreateContactParams(
      statusProspectId: selectedStatusId,

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

      visitCount: int.tryParse(jmlDatang),
      lastBlokNo: lBlockNoTC.text,
      lastProject: selectedProject,
      lastProduct: selectedProduct,
      lastProjectCategory: selectedProjectCategory,
      generalNotes: descTC.text,
      lostReasonId: selectedLostReasonId,
      nameSP: nameSPTC.text,
      lostReasonNote: lostReasonNoteTC.text,
    );

    print(
      "data update Status Prospect: \n${const JsonEncoder.withIndent('  ').convert(params.toJson())}",
    );

    const visitStatusIds = [63, 64, 65, 66, 67, 68, 69];
    final isVisitStatus = visitStatusIds.contains(selectedStatusId);

    if (isVisitStatus) {
      final paramsVisit = CreateVisitParams(
        contactId: widget.args.dataContact!.contactId!,
        statusProspectId: selectedStatusId!,
        visitCount: int.parse(jmlDatang),
        activityDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!),
        notes: descTC.text,
        files: selectedImages,
      );
      context.read<ActivityVisitBloc>().add(CreateVisitEvent(paramsVisit));
    } else {
      context.read<ContactBloc>().add(
        UpdateContactEvent(contact.contactId!, params),
      );
    }
  }

  void _submitVisit(BuildContext context) {
    if (selectedStatusId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status wajib dipilih')));
      return;
    }

    final params = CreateVisitParams(
      contactId: widget.args.dataContact!.contactId!,
      statusProspectId: selectedStatusId!,
      visitCount: int.parse(jmlDatang),
      activityDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate!),
      notes: descTC.text,
      files: selectedImages,
    );

    context.read<ActivityVisitBloc>().add(CreateVisitEvent(params));
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
              context.pop();
            } else if (state.status == ActivityStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Gagal menambahkan activity',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<UploadAttachmentBloc, UploadAttachmentState>(
          listener: (ctx, state) {
            if (state is UploadAttachmentSuccess) {
              context.pop(2);
            } else if (state is UploadAttachmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<ContactBloc, ContactState>(
          listener: (ctx, state) {
            if (state.status == ContactStatus.updateSuccess) {
              context.pop();
            } else if (state.status == ContactStatus.detailLoaded &&
                state.contactDetail != null) {
              final data = state.contactDetail!;
              setState(() {
                selectedProject = data.projectName ?? data.firstProject;
                const _visitAllowedIds = [63, 64, 65];
                final rawId = data.statusProspectId;
                selectedStatusId = (widget.args.page == 4 && !_visitAllowedIds.contains(rawId))
                    ? 63
                    : rawId;
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
                selectedProduct = data.lastProduct;
                selectedProjectCategory = data.lastProjectCategory;
                lBlockNoTC.text = data.lastBlokNo ?? '';
                jmlDatang = data.visitCount?.toString() ?? "1";
                volumeTC.text = data.volumePlan?.toString() ?? "0";
                descTC.text = data.generalNotes ?? "";
                final autoDate = _getSelectedDateByStatus(data);
                if (autoDate != null) {
                  selectedDate = autoDate;
                }
              });
            } else if (state.status == ContactStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<ActivityVisitBloc, VisitState>(
          listener: (ctx, state) {
            if (state is VisitSuccess) {
              context.pop();
            } else if (state is VisitError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
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
              final attachmentState = context
                  .watch<UploadAttachmentBloc>()
                  .state;
              final visitState = context.watch<ActivityVisitBloc>().state;

              final isLoading =
                  activityState.status == ActivityStatus.creating ||
                  attachmentState is UploadAttachmentLoading ||
                  visitState is VisitLoading;

              return Stack(
                children: [
                  Column(
                    children: [
                      customHeader(
                        context,
                        widget.args.page == 0
                            ? "Call"
                            : widget.args.page == 1
                            ? "WhatsApp"
                            : widget.args.page == 2
                            ? "Meeting"
                            : widget.args.page == 3
                            ? "Task"
                            : widget.args.page == 4
                            ? "Visit"
                            : widget.args.page == 5
                            ? "Attachment"
                            : selectedStatusName,
                        isBack: true,
                        colorBack: Color(primaryColor),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (widget.args.page == 5)
                                  _buildAttachment()
                                else if (widget.args.page == 4)
                                  _buildVisit()
                                else if (widget.args.page == 6)
                                  _buildUpdateStatusProspect()
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
                        color: Colors.white,
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
        if (selectedStatusId != 66) _buildVisitPhotos(),
        _fieldStatusProspect(),
        SizedBox(height: 12),
        _fieldDate(),
        SizedBox(height: 12),
        if (selectedStatusId != 66) _fieldJumlahDatang(),
        SizedBox(height: 12),
        _fieldProject(),
        SizedBox(height: 12),
        _fieldBlockUnitSelected(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        Container(child:selectedStatusId == 77 ||selectedStatusId == 78 ||selectedStatusId == 75? _buildLostForm(): Container(),),
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
        _fieldBlockUnitSelected(),
        SizedBox(height: 12),
        _fieldNameSP(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        Container(
          child:selectedStatusId == 77 ||selectedStatusId == 78 ||selectedStatusId == 75? _buildLostForm(): Container(),
        ),
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
        _fieldBlockUnitSelected(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        Container(
          child: selectedStatusId == 73 || selectedStatusId == 43 
              ? _buildLostForm()
              : Container(),
        ),
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
        _fieldDate(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        _fieldVolume(),
        SizedBox(height: 12),
        Container(
          child: selectedStatusId == 61 || selectedStatusId == 62
              ? _buildLostForm()
              : Container(),
        ),
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
        _fieldDate(),
        SizedBox(height: 12),
        _fieldNote(),
        SizedBox(height: 12),
        Container(
          child:
              selectedStatusId == 55 ||
                  selectedStatusId == 56 ||
                  selectedStatusId == 57 ||
                  selectedStatusId == 58
              ? _buildLostForm()
              : Container(),
        ),
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
            Container(
              child:
                  (selectedStatusId == 48 ||selectedStatusId == 49 ||selectedStatusId == 50 ||selectedStatusId == 51 ||selectedStatusId == 52 ||selectedStatusId == 55 ||selectedStatusId == 56 ||selectedStatusId == 57 ||selectedStatusId == 58)? _buildFormDB():
                  (selectedStatusId == 54 ||selectedStatusId == 76 ||selectedStatusId == 53 ||selectedStatusId == 60 ||selectedStatusId == 61 ||selectedStatusId == 62)? _buildFormAppt() :
                  (selectedStatusId == 70 ||selectedStatusId == 71 ||selectedStatusId == 72 ||selectedStatusId == 73 ||selectedStatusId == 43)? _buildFormReserved() :
                  (selectedStatusId == 74 || selectedStatusId == 75)? _buildFormSP() :
                  (selectedStatusId == 63 ||selectedStatusId == 64 ||selectedStatusId == 65 ||selectedStatusId == 66 ||selectedStatusId == 67 ||selectedStatusId == 68 ||selectedStatusId == 69)? _buildFormVisit2() :
                  selectedStatusId == null ?
                  buildFormShimmer() :
                  Container(child: Text("not found ${selectedStatusId} ${selectedStatusName} form",),),
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
          "Appt Volume",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          maxLines: 1,
          minLines: 1,
          controller: volumeTC,
          focusNode: volumeFN,
          onTapOutside: (event) => volumeFN.unfocus(),
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Volume...",
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

  Widget _buildLostForm() {
    return Column(
      children: [
        _fieldLostReason(),
        SizedBox(height: 12),
        _fieldLostReasonNote(),
        SizedBox(height: 12),
      ],
    );
  }



  Widget _buildButtonSave() {
    return BlocBuilder<ContactBloc, ContactState>(
      builder: (context, contactState) {
        return BlocBuilder<ActivityVisitBloc, VisitState>(
          builder: (context, visitState) {
            const visitStatusIds = [63, 64, 65, 66, 67, 68, 69];
            final isVisitFlow =
                widget.args.page == 4 ||
                visitStatusIds.contains(selectedStatusId);

            final isContactLoading =
                contactState.status == ContactStatus.creating;
            final isVisitLoading = visitState is VisitLoading;
            final isLoading = isVisitFlow ? isVisitLoading : isContactLoading;

            return customButton(
              isLoading
                  ? null
                  : () => widget.args.page == 4
                        ? _submitVisit(context)
                        : _submitUpdateStatus(context),
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
          "Alasan Lost",
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
            hintText: "Alasan Lost....",
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
                  selectedDate != null? DateHelper.formatDate(selectedDate!): DateHelper.nowFull(),
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
            final statusState = context.read<ProspectStatusBloc>().state;
            if (statusState.status == ProspectStatusEnum.loaded) {
              final allowedIds = widget.args.page == 4 ? [63, 64, 65] : null;
              final statusItems = statusState.statuses
                  .where(
                    (e) => allowedIds == null
                        ? true
                        : allowedIds.contains(e.statusProspectId),
                  )
                  .map(
                    (e) => OwnerDropdownItem(
                      id: e.statusProspectId,
                      name: e.statusProspectName,
                    ),
                  )
                  .toList();

              if (widget.args.page == 4) {
                final allowedIds = [63, 64, 65];
                final isValid = allowedIds.contains(selectedStatusId);

                if (!isValid && statusItems.isNotEmpty) {
                  selectedStatusId = statusItems.first.id;
                  selectedStatusName = statusItems.first.name;
                }
              }
              final result = await context.pushNamed(
                'detailContactDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih Status',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedStatusName,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedStatusName == "Select status"
                        ? Color(grey2Color)
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
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
          "Alasan Lost",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
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
                  title: 'Pilih Alasan',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedLostReasonName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedLostReasonName == null
                        ? Color(grey2Color)
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
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
            final selectedItem = itemsProject.firstWhere(
              (e) => e.name == selectedProject,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Project',
                items: itemsProject,
                selectedId: selectedItem.id,
              ),
            );
            if (result != null) {
              final selected = result as OwnerDropdownItem;
              setState(() {
                selectedProject = selected.name;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedProject ?? "Select project",
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedProject == null
                        ? Color(grey2Color)
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
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
          "Jumlah Datang",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final selectedItem = itemsJmlDatang.firstWhere(
              (e) => e.name == jmlDatang,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Jumlah Datang',
                items: selectedStatusId == 65
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${jmlDatang}",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _fieldBlockUnitSelected() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Project Category",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final selectedItem = itemsProjectCategory.firstWhere(
              (e) => e.name == selectedProjectCategory,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Project Category',
                items: itemsProjectCategory,
                selectedId: selectedItem.id,
              ),
            );
            if (result != null) {
              final selected = result as OwnerDropdownItem;

              setState(() {
                selectedProjectCategory = selected.name;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedProjectCategory ?? "Select category",
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedProjectCategory == null
                        ? Color(grey2Color)
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Product",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final selectedItem = itemsProduct.firstWhere(
              (e) => e.name == selectedProduct,
              orElse: () => OwnerDropdownItem(id: 0, name: ''),
            );
            final result = await context.pushNamed(
              'detailContactDropdown',
              extra: ContactDropdownArgs(
                title: 'Product',
                items: itemsProduct,
                selectedId: selectedItem.id,
              ),
            );
            if (result != null) {
              final selected = result as OwnerDropdownItem;

              setState(() {
                selectedProduct = selected.name;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedProduct ?? "Select product",
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedProduct == null
                        ? Color(grey2Color)
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(grey2Color),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Block No",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(grey2Color),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: lBlockNoTC,
          focusNode: lBlockNoFN,
          onTapOutside: (event) => lBlockNoFN.unfocus(),
          decoration: InputDecoration(
            hintText: "Enter block no",
            hintStyle: TextStyle(color: Color(grey2Color), fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(grey8Color)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(grey8Color)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(primaryColor)),
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
                child:
                    (selectedFile != null ||
                        selectedImage != null ||
                        existingImageUrl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (selectedFile != null && isPdf)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    selectedFileName ?? "PDF File",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : (selectedFile != null || selectedImage != null)
                            ? Image.file(
                                selectedFile ?? selectedImage!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                convertDriveUrl(existingImageUrl!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(Icons.broken_image),
                                  );
                                },
                              ),
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(blue2Color),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

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
                    if (state is AttachmentTypeLoaded) {
                      final items = state.data
                          .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
                          .toList();

                      final result = await context.pushNamed(
                        'detailContactDropdown',
                        extra: ContactDropdownArgs(
                          title: 'Attachment Type',
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
                        Text(
                          selectedTypeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedTypeName == "Select type"
                                ? Color(grey2Color)
                                : Colors.black,
                          ),
                        ),
                        if (state is AttachmentTypeLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(grey2Color),
                            size: 30,
                          ),
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
            widget.args.page == 0
                ? "Call"
                : widget.args.page == 1
                ? "WhatsApp"
                : widget.args.page == 2
                ? "Meeting"
                : widget.args.page == 3
                ? "Task"
                : widget.args.page == 4
                ? "Visit"
                : widget.args.page == 5
                ? "Attachment"
                : "Update Status Prospect",
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
            decoration: InputDecoration(
              hintText:
                  "Describe the ${widget.args.page == 0? "call": widget.args.page == 1? "whatsapp": widget.args.page == 2? "meeting": widget.args.page == 3? "task": widget.args.page == 4? "visit": widget.args.page == 5? "attachment": "update status prospect"}...",
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
                  DateHelper.nowFull(),
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
                    "Follow Up Task",
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
                              ? DateHelper.formatDate(selectedDate!)
                              : DateHelper.nowFull(),
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
                  final isFollowUpFlow = widget.args.buttonLabel == 'Followed Up';
                  final isLoading = isFollowUpFlow
                      ? state.status == ActivityStatus.followUpLoading
                      : state.status == ActivityStatus.creating;

                  return customButton(isLoading ? null : () {
                      if (isFollowUpFlow && widget.args.dataActivity != null) {
                        context.read<ActivityBloc>().add(
                          PostStatusFollowEvent([widget.args.dataActivity!.activityId]),
                        );
                      } else {
                        _submitActivity(activityType: widget.args.namePage ?? '',activityDate: DateTime.now(),notesTC: descFormActivityTC,isFollowUp: isFollowUp,followUpDate: selectedDate,);
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
    final hasImages = selectedImages.isNotEmpty && (widget.args.page == 4 || widget.args.page == 6);

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
              IconButton(
                onPressed: _openCamera,
                icon: Icon(Icons.camera_alt, color: Color(primaryColor)),
                tooltip: 'Take Photo',
              ),
          ],
        ),
        SizedBox(height: 6),
        if (hasImages)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
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
            onTap: _openCamera,
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
