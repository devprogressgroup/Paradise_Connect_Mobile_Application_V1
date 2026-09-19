import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_state.dart';

import '../create/reserve_order_navigation.dart';

/// Halaman pilih Contact sebelum masuk ke wizard Create Reserve Order — dibuka dari FAB list
/// Reserve Order (yang sebelumnya langsung ke `CreateReserveOrderPage` tanpa contact/data
/// dummy). Setelah Contact dipilih, detail lengkap + attachment-nya di-fetch dulu supaya wizard
/// bisa diisi default data yang sama seperti kalau dibuka dari tombol "Reserve Order" di Contact
/// Detail (lihat `navigateToCreateReserveOrder`).
class SelectContactForReserveOrderPage extends StatefulWidget {
  const SelectContactForReserveOrderPage({super.key});

  @override
  State<SelectContactForReserveOrderPage> createState() =>
      _SelectContactForReserveOrderPageState();
}

class _SelectContactForReserveOrderPageState
    extends State<SelectContactForReserveOrderPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;
  bool _loadingSelection = false;

  late ContactBloc _contactBloc;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_select_contact');
    _contactBloc = context.read<ContactBloc>();
    _contactBloc.add(const FetchContactsEvent(isRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _contactBloc.add(ClearContactsEvent());
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = _contactBloc.state;
      if (state.status != ContactStatus.loading && !state.hasReachedMax) {
        _contactBloc.add(const FetchContactsEvent());
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      AnalyticsService.logEvent('reserve_order_select_contact_search');
      _contactBloc.add(
        FetchContactsEvent(search: value.trim(), isRefresh: true),
      );
    });
  }

  Future<ContactState> _waitForDetail(ContactBloc bloc) {
    bool ready(ContactState s) =>
        s.status == ContactStatus.detailLoaded ||
        s.status == ContactStatus.error;
    if (ready(bloc.state)) return Future.value(bloc.state);
    return bloc.stream.firstWhere(ready);
  }

  Future<void> _onSelectContact(ContactEntity contact) async {
    final contactId = contact.contactId;
    if (contactId == null || _loadingSelection) return;

    setState(() => _loadingSelection = true);
    AnalyticsService.logEvent('reserve_order_select_contact_pick');
    try {
      _contactBloc.add(FetchContactDetailEvent(contactId));
      final state = await _waitForDetail(_contactBloc);
      if (!mounted) return;

      final detail = state.contactDetail;
      if (state.status != ContactStatus.detailLoaded || detail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Gagal memuat detail contact.'),
          ),
        );
        return;
      }

      final attachmentCubit = context.read<AttachmentCubit>();
      await attachmentCubit.fetch(contactId, detail.dealId);
      if (!mounted) return;

      final attachmentState = attachmentCubit.state;
      final attachments = attachmentState is AttachmentLoaded
          ? attachmentState.data
          : const <ContactAttachment>[];

      navigateToCreateReserveOrder(
        context,
        contact: detail,
        attachments: attachments,
        replace: true,
      );
    } finally {
      if (mounted) setState(() => _loadingSelection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pilih Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Untuk Reserve Order baru',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(grey4Color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: customSearchField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hintText: 'Cari nama / no. HP contact…',
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ContactBloc, ContactState>(
                builder: (context, state) {
                  if (state.status == ContactStatus.loading &&
                      state.contacts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.contacts.isEmpty) {
                    return const Center(child: Text('Tidak ada data kontak'));
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.hasReachedMax
                        ? state.contacts.length
                        : state.contacts.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= state.contacts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _contactTile(state.contacts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(ContactEntity contact) {
    final project = contact.lastProject ?? contact.firstProject;
    return InkWell(
      onTap: _loadingSelection ? null : () => _onSelectContact(contact),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: _loadingSelection ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(grey10Color)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(primaryColor).withValues(alpha: 0.1),
                child: Text(
                  getInitials(contact.fullName ?? '-'),
                  style: TextStyle(
                    color: Color(primaryColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.fullName ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      contact.whatsappNumber ??
                          contact.primaryPhone ??
                          'No Phone',
                      style: TextStyle(fontSize: 12, color: Color(grey5Color)),
                    ),
                    if (project != null && project.isNotEmpty)
                      Text(
                        project,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(grey5Color),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (_loadingSelection)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
