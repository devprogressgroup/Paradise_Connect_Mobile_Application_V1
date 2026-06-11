import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/helpers/error_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_approval_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../../../core/utils/widget/custom_search_field.dart';
import '../../../../../core/utils/widget/shimmer_loading.dart';


class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final noteController = TextEditingController();
  final FocusNode _searchFN = FocusNode();
  Timer? _debounce;
  String? _selectedStatus;
  int? _selectedFlag;

  static const _statusIdMap = {'pending': 1, 'approved': 2, 'rejected': 3};
  static const _statusValueMap = {1: 'pending', 2: 'approved', 3: 'rejected'};
  static const _statusLabelMap = {'pending': 'Pending', 'approved': 'Approved', 'rejected': 'Rejected'};
  static const _flagLabelMap = {0: 'Clock In', 1: 'Clock Out'};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      context.read<AttendanceApprovalCubit>().load();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<AttendanceApprovalCubit>().loadMore();
    }
  }

  void _applyFilters() {
    context.read<AttendanceApprovalCubit>().load(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _selectedStatus,
      flag: _selectedFlag,
    );
  }

  Future<void> _openStatusFilter() async {
    final items = [
      OwnerDropdownItem(id: 1, name: 'Pending'),
      OwnerDropdownItem(id: 2, name: 'Approved'),
      OwnerDropdownItem(id: 3, name: 'Rejected'),
    ];
    final result = await context.pushNamed<dynamic>(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Status',
        items: items,
        selectedId: _selectedStatus != null ? _statusIdMap[_selectedStatus] : null,
        allowClear: _selectedStatus != null,
      ),
    );
    if (result == null) return;
    if (result is List) {
      setState(() => _selectedStatus = null);
    } else if (result is OwnerDropdownItem) {
      setState(() => _selectedStatus = _statusValueMap[result.id]);
    }
    _applyFilters();
  }

  Future<void> _openFlagFilter() async {
    final items = [
      OwnerDropdownItem(id: 0, name: 'Clock In'),
      OwnerDropdownItem(id: 1, name: 'Clock Out'),
    ];
    final result = await context.pushNamed<dynamic>(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Type',
        items: items,
        selectedId: _selectedFlag,
        allowClear: _selectedFlag != null,
      ),
    );
    if (result == null) return;
    if (result is List) {
      setState(() => _selectedFlag = null);
    } else if (result is OwnerDropdownItem) {
      setState(() => _selectedFlag = result.id);
    }
    _applyFilters();
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(primaryColor) : const Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(primaryColor) : Colors.transparent,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(blackColor),
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected ? Colors.white : const Color(blackColor),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFN.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              'Approval',
              colorBg: const Color(primaryColor),
              colorBack: const Color(whiteColor),
              colorTitle: const Color(whiteColor),
              iconRight: Icons.arrow_back,
              iconRightOnTap: () => context.pop(),
              colorIconRight: const Color(whiteColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: customSearchField(
                      controller: _searchController,
                      focusNode: _searchFN,
                      hintText: 'Search...',
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _selectedStatus != null ? _statusLabelMap[_selectedStatus]! : 'Status',
                    isSelected: _selectedStatus != null,
                    onTap: _openStatusFilter,
                    onClear: _selectedStatus != null
                        ? () { setState(() => _selectedStatus = null); _applyFilters(); }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _selectedFlag != null ? _flagLabelMap[_selectedFlag]! : 'Type',
                    isSelected: _selectedFlag != null,
                    onTap: _openFlagFilter,
                    onClear: _selectedFlag != null
                        ? () { setState(() => _selectedFlag = null); _applyFilters(); }
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<AttendanceApprovalCubit, AttendanceApprovalState>(
                listenWhen: (prev, curr) => curr is AttendanceApprovalError && prev is! AttendanceApprovalError,
                listener: (context, state) {
                  if (state is AttendanceApprovalError) {
                    debugPrint('AttendanceApprovalError: ${state.message}');
                  }
                },
                builder: (context, state) {
                  if (state is AttendanceApprovalLoading) {
                    return SingleChildScrollView(child: buildApprovalShimmer());
                  } else if (state is AttendanceApprovalError) {
                    return const Center(child: Text('Gagal memuat data approval'));
                  } else if (state is AttendanceApprovalLoaded) {
                    final logs = state.logs;
                    if (logs.isEmpty) {
                      return const Center(child: Text('No approval data found.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<AuthBloc>().add(FetchPermissionsEvent());
                        context.read<AttendanceApprovalCubit>().load();
                      },
                      child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == logs.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final item = logs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: const Color(whiteColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: () => _showAttendanceDetailDialog(item, button: 0),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.fullName ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.flag == 0
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.flagLabel ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.flag == 0
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.attendanceDatetime != null ? DateHelper.formatTime(DateTime.parse(item.attendanceDatetime!)) : '-',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.locationName ?? '-',
                                          style: const TextStyle(color: Colors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.noteValidasi != null && item.noteValidasi!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.note, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.noteValidasi ?? '-',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  if (item.isApprove == 1)
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Approved by ${item.approveName ?? 'Unknown'}',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    )
                                  else if (item.isReject == 1)
                                    Row(
                                      children: [
                                        const Icon(Icons.cancel, size: 16, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Rejected by ${item.rejectName ?? 'Unknown'}',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.pending, size: 16, color: Colors.orange),
                                            SizedBox(width: 4),
                                            Text(
                                              'Pending Approval',
                                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showAttendanceDetailDialog(item),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _showAttendanceDetailDialog(item),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Approve'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApprovalNoteDialog(int logId, int approve) async {
    final isReject = approve == 0;
    noteController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReject ? 'Alasan Penolakan' : 'Catatan Persetujuan'),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isReject ? 'Tulis alasan penolakan...' : 'Tulis catatan (opsional)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isReject ? 'Reject' : 'Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final noteText = noteController.text.trim();
      try {
        await context.read<AttendanceApprovalCubit>().submitApproval(
          logId, approve,
          note: noteText.isEmpty ? null : noteText,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${cleanErrorMessage(e)}')));
        }
      }
    }
  }

  void _showAttendanceDetailDialog(AttendanceApprovalEntity item, {int? button}) {
    final String? displayImage = (item.fileAttachment != null && item.fileAttachment!.isNotEmpty)
        ? item.fileAttachment!.first
        : null;
    final String displayTime = item.attendanceDatetime != null
        ? DateHelper.formatTime(DateTime.parse(item.attendanceDatetime!))
        : '-';
    final String displayDate = item.attendanceDatetime != null
        ? DateHelper.formatDate(DateTime.parse(item.attendanceDatetime!))
        : '-';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: displayImage != null
                            ? DriveImage(
                                url: displayImage,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                onTap: () => _showImagePreview(displayImage),
                              )
                            : Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                              ),
                      ),
                      if (displayImage != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _showImagePreview(displayImage),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time_filled,
                    displayTime,
                    Color(item.flag == 0 ? greenPercentColor : redPeriodColor),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, displayDate, const Color(primaryColor)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.map, item.locationName ?? '-', const Color(primaryColor)),
                  if (item.noteValidasi != null && item.noteValidasi!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.notes, item.noteValidasi!, const Color(primaryColor)),
                  ],
                  if (item.isApprove == 1 || item.isReject == 1) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      item.isApprove == 1 ? Icons.check_circle : Icons.cancel,
                      item.isApprove == 1
                          ? 'Approved${item.approveName != null ? ' by ${item.approveName}' : ''}'
                          : 'Rejected${item.rejectName != null ? ' by ${item.rejectName}' : ''}',
                      item.isApprove == 1 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if(button != 0)Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showApprovalNoteDialog(item.logId, 0);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showApprovalNoteDialog(item.logId, 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImagePreview(String url) {
    final screen = MediaQuery.of(context).size;
    final imgW = screen.width - 20;
    final imgH = screen.height - 120;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const SizedBox.expand(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: DriveImage(
                      url: url,
                      width: imgW,
                      height: imgH,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}