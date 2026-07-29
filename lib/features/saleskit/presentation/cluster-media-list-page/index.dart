import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/youtube_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/widget/webview_page.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/saleskit/data/arguments/cluster_media_list_args.dart';
import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_list/cluster_media_list_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_list/cluster_media_list_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_list/cluster_media_list_state.dart';

const List<MapEntry<String, String>> _mediaSortOptions = [
  MapEntry('created_desc', 'Dibuat: Terbaru'),
  MapEntry('created_asc', 'Dibuat: Terlama'),
  MapEntry('name_asc', 'Nama: A-Z'),
  MapEntry('name_desc', 'Nama: Z-A'),
];

const String _defaultSortKey = 'created_desc';

({String sortBy, String sortDir}) _resolveSort(String key) {
  switch (key) {
    case 'created_asc':
      return (sortBy: 'created_at', sortDir: 'asc');
    case 'name_asc':
      return (sortBy: 'name', sortDir: 'asc');
    case 'name_desc':
      return (sortBy: 'name', sortDir: 'desc');
    case 'created_desc':
    default:
      return (sortBy: 'created_at', sortDir: 'desc');
  }
}

class ClusterMediaListPage extends StatefulWidget {
  final ClusterMediaListArgs args;
  const ClusterMediaListPage({super.key, required this.args});

  @override
  State<ClusterMediaListPage> createState() => _ClusterMediaListPageState();
}

class _ClusterMediaListPageState extends State<ClusterMediaListPage> {
  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();
  final ScrollController scrollController = ScrollController();
  Timer? _debounce;
  String _sortKey = _defaultSortKey;

  @override
  void initState() {
    super.initState();
    _load();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchTC.dispose();
    searchFN.dispose();
    super.dispose();
  }

  void _load() {
    final sort = _resolveSort(_sortKey);
    context.read<ClusterMediaListBloc>().add(LoadClusterMediaListEvent(
          clusterId: widget.args.clusterId,
          ownerType: widget.args.ownerType,
          mediaGroupId: widget.args.mediaGroupId,
          search: searchTC.text.trim().isEmpty ? null : searchTC.text.trim(),
          sortBy: sort.sortBy,
          sortDir: sort.sortDir,
        ));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _pickSort() async {
    AnalyticsService.logEvent('cluster_media_list_filter_sort');
    final selectedIndex = _mediaSortOptions.indexWhere((e) => e.key == _sortKey);
    final items = List.generate(
      _mediaSortOptions.length,
      (i) => OwnerDropdownItem(id: i, name: _mediaSortOptions[i].value),
    );

    final result = await context.pushNamed(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Urutkan',
        items: items,
        selectedId: selectedIndex >= 0 ? selectedIndex : 0,
        isMultiSelect: false,
        allowClear: _sortKey != _defaultSortKey,
        preserveOrder: true,
      ),
    );

    if (!mounted) return;

    if (result is List) {
      setState(() => _sortKey = _defaultSortKey);
      _load();
      return;
    }

    if (result is OwnerDropdownItem) {
      final key = _mediaSortOptions[result.id!].key;
      setState(() => _sortKey = key);
      _load();
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      context.read<ClusterMediaListBloc>().add(LoadMoreClusterMediaListEvent());
    }
  }

  void _openMedia(MediaItemEntity item) {
    if (item.link == null || item.link!.isEmpty) return;
    AnalyticsService.logEvent('cluster_media_list_open_item');
    if (isYoutubeUrl(item.link!)) {
      launchUrl(Uri.parse(item.link!), mode: LaunchMode.externalApplication);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => WebViewPage(url: item.link!, title: item.name)));
  }

  void _shareMedia(MediaItemEntity item) {
    if (item.link == null || item.link!.isEmpty) return;
    AnalyticsService.logEvent('cluster_media_list_share_item');
    final captionName = item.captions.isNotEmpty ? item.captions.first.name : '';
    final text = captionName.isNotEmpty ? '$captionName\n${item.link}' : item.link!;
    Share.share(text, subject: item.name);
    if (item.captions.isNotEmpty) {
      context.read<ClusterMediaListBloc>().shareCaptionUseCase(item.captions.first.captionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, widget.args.groupName, isBack: true),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: customSearchField(
                controller: searchTC,
                focusNode: searchFN,
                onChanged: _onSearchChanged,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Builder(
                  builder: (context) {
                    final selectedIndex = _mediaSortOptions.indexWhere((e) => e.key == _sortKey);
                    final label = selectedIndex >= 0 ? _mediaSortOptions[selectedIndex].value : 'Urutkan';
                    return CustomFilterButton(
                      label: label,
                      isSelected: _sortKey != _defaultSortKey,
                      onClear: _sortKey != _defaultSortKey
                          ? () {
                              AnalyticsService.logEvent('cluster_media_list_clear_sort_filter');
                              setState(() => _sortKey = _defaultSortKey);
                              _load();
                            }
                          : null,
                      onTap: _pickSort,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<ClusterMediaListBloc, ClusterMediaListState>(
                builder: (context, state) => _buildContent(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ClusterMediaListState state) {
    if (state is ClusterMediaListLoading || state is ClusterMediaListInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ClusterMediaListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message, textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text("Coba Lagi")),
          ],
        ),
      );
    }

    final loaded = state as ClusterMediaListLoaded;
    if (loaded.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada media ditemukan', style: TextStyle(color: Color(greyShade500))),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: loaded.items.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= loaded.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = loaded.items[index];
          return _buildMediaTile(item);
        },
      ),
    );
  }

  Widget _buildMediaTile(MediaItemEntity item) {
    return GestureDetector(
      onTap: () => _openMedia(item),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Color(grey6Color).withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DriveImage(
                      url: item.thumbnail ?? '',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorWidget: Container(
                        color: Color(grey11Color),
                        child: const Icon(Icons.image_not_supported, color: Color(greyShade500)),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28),
                    ),
                  ],
                ),
              ),
            ),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Expanded(
                   child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                    ),
                 ),
                   IconButton(
                  onPressed: () => _shareMedia(item),
                  icon: Image.asset(icShare, height: 20, color: Color(primaryColor)),
                ),
               ],
             ),
            // SizedBox(width: 12),
            // Expanded(
            //   child:
            // ),
           
          ],
        ),
      ),
    );
  }
}
