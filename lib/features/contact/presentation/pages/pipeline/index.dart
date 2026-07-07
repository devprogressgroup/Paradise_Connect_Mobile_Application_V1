import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/pipeline/pipeline_deal_model.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/state/pipeline/pipeline_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/pipeline/pipeline_state.dart';

class PipelineScreen extends StatefulWidget {
  final List<int>? statusIds;
  final String? title;
  const PipelineScreen({super.key, this.statusIds, this.title});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final _scroll = ScrollController();
  final _searchTC = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PipelineCubit>().load(statusIds: widget.statusIds);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchTC.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<PipelineCubit>().loadMore();
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<PipelineCubit>().setSearch(v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.title?.isNotEmpty == true ? widget.title! : 'Sales Pipeline'),
        backgroundColor: Color(primaryColor),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchTC,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama / telepon / proyek / blok…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<PipelineCubit, PipelineState>(
      builder: (context, state) {
        if (state.status == PipelineStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == PipelineStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.error ?? 'Gagal memuat pipeline', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: () => context.read<PipelineCubit>().refresh(), child: const Text('Coba lagi')),
              ],
            ),
          );
        }
        if (state.items.isEmpty) {
          return const Center(child: Text('Belum ada unit/deal pada stage ini.'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<PipelineCubit>().refresh(),
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: state.items.length + (state.loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i >= state.items.length) {
                return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
              }
              return _dealCard(state.items[i]);
            },
          ),
        );
      },
    );
  }

  Widget _dealCard(PipelineDeal d) {
    final unitPath = [d.clusterName, d.productName].where((e) => (e ?? '').isNotEmpty).join(' › ');
    final String unitSub;
    if ((d.propertyName ?? '').isNotEmpty) {
      unitSub = d.propertyName! + (d.isHoek ? '  •  Hook' : '');
    } else if (d.isWaitingList) {
      unitSub = 'Waiting list';
    } else if (unitPath.isNotEmpty) {
      unitSub = 'Belum tentukan kavling';
    } else {
      unitSub = '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.pushNamed(
          'detailContact',
          extra: ContactDetailArgs(
            dataContact: ContactEntity(
              contactId: d.contactId,
              fullName: d.contactName,
              primaryPhone: d.phone,
              whatsappNumber: d.whatsapp,
            ),
            page: 2,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${d.salutation != null && d.salutation!.isNotEmpty ? '${d.salutation} ' : ''}${d.contactName.isNotEmpty ? d.contactName : '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                _statusChip(d.statusName),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_work_outlined, size: 15, color: Color(blue3Color)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unitPath.isNotEmpty ? unitPath : '–', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                      if (unitSub.isNotEmpty) Text(unitSub, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                if ((d.ownerName ?? '').isNotEmpty) _meta(Icons.person_outline, d.ownerName!),
                if (d.dealValue > 0) _meta(Icons.payments_outlined, _rupiah(d.dealValue)),
                ..._dateChips(d),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData ic, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      );

  List<Widget> _dateChips(PipelineDeal d) {
    final map = {'APPT': d.apptDate, 'Visit': d.visitDate, 'Reserve': d.reserveDate, 'SP': d.spDate, 'Akad': d.akadDate, 'Lost': d.lostDate};
    final out = <Widget>[];
    map.forEach((label, val) {
      if (val != null && val.isNotEmpty && !val.startsWith('0000')) {
        out.add(_meta(Icons.event_outlined, '$label: ${val.length >= 10 ? val.substring(0, 10) : val}'));
      }
    });
    return out;
  }

  Widget _statusChip(String? name) {
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final lower = name.toLowerCase();
    Color bg;
    Color fg;
    if (lower.contains('lost') || lower.contains('batal')) {
      bg = const Color(0xFFFDECEA);
      fg = const Color(0xFFC62828);
    } else if (lower.contains('sp') || lower.contains('akad') || lower.contains('deal') || lower.contains('closing')) {
      bg = const Color(0xFFE7F6EC);
      fg = const Color(0xFF2E7D32);
    } else if (lower.contains('reserve') || lower.contains('booking')) {
      bg = const Color(0xFFFFF6E5);
      fg = const Color(0xFFB26A00);
    } else if (lower.contains('visit') || lower.contains('appoint') || lower.contains('datang')) {
      bg = const Color(0xFFE8F1FF);
      fg = Color(blue3Color);
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(name, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _rupiah(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }
}
