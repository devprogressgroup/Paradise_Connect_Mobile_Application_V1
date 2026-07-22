import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:progress_group/core/utils/helpers/youtube_helper.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/saleskit/domain/entities/cluster_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/commercial_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/township_entity.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_township/saleskit_township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_township/saleskit_township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_township/saleskit_township_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_overview/cluster_media_overview_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_overview/cluster_media_overview_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_overview/cluster_media_overview_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/cluster_media_overview/media_group_section.dart';
import 'package:progress_group/features/saleskit/data/arguments/cluster_media_list_args.dart';
import 'package:progress_group/features/saleskit/presentation/cluster-media-list-page/index.dart';

import '../../../../core/utils/widget/webview_page.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/widget/custom_search_field.dart';
import '../../../../core/utils/widget/shimmer_loading.dart';
import '../../data/arguments/saleskit_detail_args.dart';
import 'package:progress_group/core/services/analytics_service.dart';

typedef _StaticSalesKitItem = ({String title, String logo, String? url, String event});

class SalesKitPage extends StatefulWidget {
  final SalesKitDetailArgs args;
  const SalesKitPage({super.key, required this.args});

  @override
  State<SalesKitPage> createState() => _SalesKitPageState();
}

class _SalesKitPageState extends State<SalesKitPage> {
  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();
  final Map<int, ScrollController> _sectionScrollControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.args.page == 1 && widget.args.townshipId != null) {
      context.read<SalesKitDetailBloc>().add(
        LoadSalesKitDetailEvent(widget.args.townshipId!),
      );
    }
    if (widget.args.page == 2 && widget.args.clusterId != null) {
      context.read<ClusterMediaOverviewBloc>().add(
        LoadClusterMediaOverviewEvent(widget.args.clusterId!, ownerType: widget.args.ownerType),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _sectionScrollControllers.values) {
      controller.dispose();
    }
    searchTC.dispose();
    searchFN.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<AuthBloc>().add(FetchPermissionsEvent());
    if (widget.args.page == 1 && widget.args.townshipId != null) {
      context.read<SalesKitDetailBloc>().add(
        LoadSalesKitDetailEvent(widget.args.townshipId!),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: widget.args.page == 1
            ? _buildDetail()
            : widget.args.page == 2
            ? _buildShare()
            : _builSalsesKitScreen(),
      ),
    );
  }

  bool _hasContent(String? brochure, String? priceList, String? productKnowledge, String? other) {
    bool hasValue(String? v) => v != null && v.isNotEmpty;
    return hasValue(brochure) || hasValue(priceList) || hasValue(productKnowledge) || hasValue(other);
  }

  void _navigateToDetail(SalesKitDetailArgs args) {
    if (!_hasContent(args.brochure, args.priceList, args.productKnowledge, args.other)) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Informasi'),
          content: const Text('Dokumen belum tersedia untuk produk ini.'),
          actions: [
            TextButton(
              onPressed: () {
                AnalyticsService.logEvent('sales_kit_error_dialog_ok');
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    context.pushNamed('sales_kit', extra: args);
  }

  void _openUrl(String? url, String title) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(url: url, title: title),
      ),
    );
  }

  List<_StaticSalesKitItem> _staticSalesKitItems(SalesKitDetailArgs args) => [
        if (args.priceList != null && args.priceList!.isNotEmpty)
          (title: "Price List", logo: icPriceList, url: args.priceList, event: 'sales_kit_open_price_list'),
        if (args.brochure != null && args.brochure!.isNotEmpty)
          (title: "E-Brochure", logo: icEBrouchure, url: args.brochure, event: 'sales_kit_open_e_brochure'),
        if (args.productKnowledge != null && args.productKnowledge!.isNotEmpty)
          (title: "Product Knowledge", logo: icProductKnowlage, url: args.productKnowledge, event: 'sales_kit_open_product_knowledge'),
        if (args.other != null && args.other!.isNotEmpty)
          (title: "Promotion Kit", logo: icAttacment, url: args.other, event: 'sales_kit_open_promotion_kit'),
      ];

  static const double _horizontalRowSpacing = 12;
  static const double _horizontalRowPadding = 32; 

  
  double _rowItemWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - _horizontalRowPadding - _horizontalRowSpacing) / 1.8;
  }

  Widget _buildShare() {
    final args = widget.args;
    final staticItems = _staticSalesKitItems(args);
    final itemWidth = _rowItemWidth(context);
    final staticCardHeight = itemWidth * 0.75;
    return Column(
      children: [
        customHeader(context, args.title!, isBack: true),
        SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(FetchPermissionsEvent());
              if (args.clusterId != null) {
                context.read<ClusterMediaOverviewBloc>().add(
                  LoadClusterMediaOverviewEvent(args.clusterId!, ownerType: args.ownerType),
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (staticItems.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildSectionHeader("SalesKit", onSeeAll: () => _openStaticSalesKitList(staticItems)),
                    SizedBox(height: 12),
                    SizedBox(
                      height: staticCardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: staticItems.length,
                        separatorBuilder: (_, __) => SizedBox(width: _horizontalRowSpacing),
                        itemBuilder: (context, i) => _buildStaticCard(staticItems[i], itemWidth),
                      ),
                    ),
                  ],
                   if (args.priceList != null && args.priceList!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Price List",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icPriceList,
                      onTap: () {
                        AnalyticsService.logEvent('sales_kit_open_price_list');
                        _openUrl(args.priceList, "Price List ${args.title ?? ''}".trim());
                      },
                    ),
                  ],
                  if (args.brochure != null && args.brochure!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "EBrouchure",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icEBrouchure,
                      onTap: () {
                        AnalyticsService.logEvent('sales_kit_open_e_brochure');
                        _openUrl(args.brochure, "E Brochure ${args.title ?? ''}".trim());
                      },
                    ),
                  ],
                  if (args.productKnowledge != null && args.productKnowledge!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Product Knowledge",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icProductKnowlage,
                      onTap: () {
                        AnalyticsService.logEvent('sales_kit_open_product_knowledge');
                        _openUrl(args.productKnowledge, "Product Knowledge ${args.title ?? ''}".trim());
                      },
                    ),
                  ],
                  if (args.other != null && args.other!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Promotion Kit",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icAttacment,
                      onTap: () {
                        AnalyticsService.logEvent('sales_kit_open_promotion_kit');
                        _openUrl(args.other, "Promotion Kit ${args.title ?? ''}".trim());
                      },
                    ),
                  ],

                  if (args.clusterId != null) _buildMediaSections(args.clusterId!, args.ownerType, itemWidth),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildButtonBorder({
    required String title,
    required int colorBg,
    required int colorTitle,
    required VoidCallback onTap,
    required String logo,
    bool isDisabled = false,
  }) {
    final effectiveColorTitle = isDisabled ? grey4Color : colorTitle;
    final effectiveColorBg = isDisabled ? grey8Color : colorBg;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(effectiveColorBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDisabled ? Color(grey4Color) : Color(primaryColor)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(logo, height: 20, color: Color(effectiveColorTitle)),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(effectiveColorTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(blue2Color)),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            "See All",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(primaryColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticCard(_StaticSalesKitItem item, double width) {
    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent(item.event);
        _openUrl(item.url, "${item.title} ${widget.args.title ?? ''}".trim());
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(primaryColor)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(item.logo, height: 36, color: Color(primaryColor)),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStaticSalesKitList(List<_StaticSalesKitItem> items) {
    AnalyticsService.logEvent('sales_kit_static_see_all');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, "SalesKit", isBack: true),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) => _buildStaticListTile(items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticListTile(_StaticSalesKitItem item) {
    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent(item.event);
        _openUrl(item.url, "${item.title} ${widget.args.title ?? ''}".trim());
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Color(grey6Color).withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Color(grey11Color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Image.asset(item.logo, height: 32, color: Color(primaryColor))),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(blue2Color)),
              ),
            ),
            IconButton(
              onPressed: () {
                if (item.url == null || item.url!.isEmpty) return;
                AnalyticsService.logEvent('${item.event}_share');
                Share.share(item.url!, subject: item.title);
              },
              icon: Image.asset(icShare, height: 20, color: Color(primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  ScrollController _controllerFor(int clusterId, MediaOwnerType ownerType, int mediaGroupId) {
    return _sectionScrollControllers.putIfAbsent(mediaGroupId, () {
      final controller = ScrollController();
      controller.addListener(() {
        if (!controller.hasClients) return;
        if (controller.position.pixels >= controller.position.maxScrollExtent - 100) {
          context.read<ClusterMediaOverviewBloc>().add(
            LoadMoreGroupMediaEvent(clusterId: clusterId, ownerType: ownerType, mediaGroupId: mediaGroupId),
          );
        }
      });
      return controller;
    });
  }

  Widget _buildMediaSections(int clusterId, MediaOwnerType ownerType, double itemWidth) {
    return BlocBuilder<ClusterMediaOverviewBloc, ClusterMediaOverviewState>(
      builder: (context, state) {
        if (state is ClusterMediaOverviewLoading || state is ClusterMediaOverviewInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ClusterMediaOverviewError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<ClusterMediaOverviewBloc>().add(
                      LoadClusterMediaOverviewEvent(clusterId, ownerType: ownerType),
                    ),
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            ),
          );
        }
        final loaded = state as ClusterMediaOverviewLoaded;
        if (loaded.clusterId != clusterId || loaded.ownerType != ownerType || loaded.sections.isEmpty) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: loaded.sections.map((section) => _buildMediaGroupSection(clusterId, ownerType, section, itemWidth)).toList(),
        );
      },
    );
  }

  Widget _buildMediaGroupSection(int clusterId, MediaOwnerType ownerType, MediaGroupSection section, double itemWidth) {
    final thumbHeight = itemWidth * 0.62;
    final rowHeight = thumbHeight + 52;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(section.groupName, onSeeAll: () => _openMediaList(clusterId, ownerType, section)),
          SizedBox(height: 12),
          SizedBox(
            height: rowHeight,
            child: ListView.separated(
              controller: _controllerFor(clusterId, ownerType, section.mediaGroupId),
              scrollDirection: Axis.horizontal,
              itemCount: section.items.length + (section.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(width: _horizontalRowSpacing),
              itemBuilder: (context, i) {
                if (i >= section.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                return _buildMediaCard(section.items[i], itemWidth, thumbHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(MediaItemEntity item, double width, double thumbHeight) {
    final isVideo = item.groupName.toLowerCase().contains('youtube') || item.groupName.toLowerCase().contains('video');
    return GestureDetector(
      onTap: () => _openMediaItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(blackColor).withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        width: width,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: width,
                height: thumbHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DriveImage(
                      url: item.thumbnail ?? '',
                      width: width,
                      height: thumbHeight,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Color(grey11Color),
                        child: const Icon(Icons.image_not_supported, color: Color(greyShade500)),
                      ),
                    ),
                    if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 36)),
                    
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                ),
                 GestureDetector(
                  onTap: () => _shareMediaItem(item),
                
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Color(whiteColor), shape: BoxShape.circle),
                    child: Image.asset(icShare, height: 16, color: Color(primaryColor)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMediaItem(MediaItemEntity item) {
    AnalyticsService.logEvent('sales_kit_media_open_item');
    final link = item.link;
    if (link != null && link.isNotEmpty && isYoutubeUrl(link)) {
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      return;
    }
    _openUrl(item.link, item.name);
  }

  void _shareMediaItem(MediaItemEntity item) {
    if (item.link == null || item.link!.isEmpty) return;
    AnalyticsService.logEvent('sales_kit_media_share_item');
    final captionName = item.captions.isNotEmpty ? item.captions.first.name : '';
    final text = captionName.isNotEmpty ? '${item.link}\n$captionName\n' : item.link!;
    Share.share(text, subject: item.name);
    if (item.captions.isNotEmpty) {
      context.read<ClusterMediaOverviewBloc>().shareCaptionUseCase(item.captions.first.captionId);
    }
  }

  void _openMediaList(int clusterId, MediaOwnerType ownerType, MediaGroupSection section) {
    AnalyticsService.logEvent('sales_kit_media_see_all');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClusterMediaListPage(
          args: ClusterMediaListArgs(
            clusterId: clusterId,
            ownerType: ownerType,
            mediaGroupId: section.mediaGroupId,
            groupName: section.groupName,
            propertyTitle: widget.args.title ?? '',
          ),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    return BlocConsumer<SalesKitDetailBloc, SalesKitDetailState>(
      listener: (context, state) {
        if (state is SalesKitDetailLoaded) {
          final clusters = state.clusters.where((c) => c.showOnMobile == 1);
          final commercials = state.commercials.where((c) => c.showOnMobile == 1);
          if (clusters.isEmpty && commercials.isEmpty) {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Informasi'),
                content: const Text('Data tidak tersedia untuk produk ini.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent('sales_kit_confirm_leave_dialog');
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
        if (state is SalesKitDetailError) {
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            customHeader(   context,   widget.args.title??"-",   isBack: true, ),
            SizedBox(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _buildDetailContent(state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailContent(SalesKitDetailState state) {
    if (state is SalesKitDetailLoading) {
      return buildSaleskitDetailShimmer();
    }

    if (state is SalesKitDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gagal memuat data saleskit', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                AnalyticsService.logEvent('sales_kit_retry_load_saleskit');
                _onRefresh();
              },
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    final clusters = state is SalesKitDetailLoaded
        ? state.clusters
        : <ClusterEntity>[];
    final commercials = state is SalesKitDetailLoaded
        ? state.commercials
        : <CommercialEntity>[];

    final items = [
      ...clusters.where((c) => c.showOnMobile == 1).map((c) => (
        imageUrl: ApiConstants.clusterImageUrl(widget.args.townshipSlug ?? '', c.logoMobile),
        name: c.name,
        args: SalesKitDetailArgs(
          page: 2,
          title: c.name,
          clusterId: c.id,
          brochure: c.brochure,
          productKnowledge: c.productKnowledge,
          priceList: c.priceList,
          other: c.other,
        ),
      )),
      ...commercials.where((c) => c.showOnMobile == 1).map((c) => (
        imageUrl: ApiConstants.commercialImageUrl(c.logoMobile),
        name: c.name,
        args: SalesKitDetailArgs(
          page: 2,
          title: c.name,
          clusterId: c.id,
          ownerType: MediaOwnerType.commercial,
          brochure: c.brochure,
          productKnowledge: c.productKnowledge,
          priceList: c.priceList,
          other: c.other,
        ),
      )),
    ];


    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data produk',
          style: TextStyle(color: Color(greyShade500)),
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(26),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildResidentialNetwork(
          imageUrl: item.imageUrl,
          name: item.name,
          onTap: () => _navigateToDetail(item.args),
        );
      },
    );
  }

  Widget _buildResidentialNetwork({
    required String imageUrl,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: Color(whiteColor),
            boxShadow: [
              BoxShadow(
                color: Color(grey6Color).withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: LayoutBuilder(
                    builder: (_, constraints) => DriveImage(
                      url: imageUrl,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      onTap: onTap,
                      errorWidget: const Icon(Icons.broken_image, size: 40, color: Color(greyShade500)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(blue2Color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _builSalsesKitScreen() {
    return BlocConsumer<SalesKitTownshipBloc, SalesKitTownshipState>(
      listener: (context, state) {
        if (state is SalesKitTownshipError) {
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            customHeader(context, "SalesKit", isBack: false),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(FetchPermissionsEvent());
                  context.read<SalesKitTownshipBloc>().add(GetSalesKitTownshipsEvent());
                },
                child: _buildTownshipContent(state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTownshipContent(SalesKitTownshipState state) {
    if (state is SalesKitTownshipLoading) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [buildSaleskitShimmer()],
        ),
      );
    }

    if (state is SalesKitTownshipError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gagal memuat data project', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                AnalyticsService.logEvent('sales_kit_retry_load_saleskit');
                context.read<SalesKitTownshipBloc>().add(GetSalesKitTownshipsEvent());
              },
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    final townships = state is SalesKitTownshipLoaded
        ? state.townships
        : <TownshipEntity>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        customSearchField(controller: searchTC, focusNode: searchFN),
        SizedBox(height: 15),
        Text(
          "Projects",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(blue2Color),
          ),
        ),
        SizedBox(height: 15),
        if (townships.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'Tidak ada data project',
                style: TextStyle(color: Color(greyShade500)),
              ),
            ),
          ),
        ...townships.map(
          (township) => buildProjectBanner(
            backgroundImageUrl: ApiConstants.townshipImageUrl(
              township.slug,
              township.groupBanner,
            ),
            logoImageUrl: ApiConstants.townshipImageUrl(
              township.slug,
              township.logo,
            ),
            ontap: () {
              AnalyticsService.logEvent('sales_kit_select_township');
              context.pushNamed(
                "sales_kit",
                extra: SalesKitDetailArgs(
                  page: 1,
                  title: township.name,
                  townshipId: township.id,
                  townshipSlug: township.slug,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildProjectBanner({
    required String backgroundImageUrl,
    required String logoImageUrl,
    String title ='',
    String subtitle = '',
    double height = 141.0,
    required VoidCallback ontap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: ontap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                height: height,
                width: double.infinity,
                child: DriveImage(
                  url: backgroundImageUrl,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  errorWidget: Container(height: height, color: Color(blue2Color)),
                ),
              ),
              Container(
                height: height,
                width: double.infinity,
                color: Color(blue2Color).withValues(alpha: 0.7),
              ),
              SizedBox(
                height: height,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(Color(whiteColor), BlendMode.srcATop),
                      child: DriveImage(
                        url: logoImageUrl,
                        height: 140,
                        width: 140,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        onTap: ontap,
                        errorWidget: const Icon(Icons.broken_image, color: Color(whiteColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
