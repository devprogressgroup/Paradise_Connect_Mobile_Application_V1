import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/saleskit/domain/entities/cluster_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/commercial_entity.dart';
import 'package:progress_group/features/saleskit/domain/entities/township_entity.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/saleskit_detail/saleskit_detail_state.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_bloc.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_event.dart';
import 'package:progress_group/features/saleskit/presentation/state/township/township_state.dart';

import '../../../../core/utils/widget/webview_page.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/widget/custom_search_field.dart';
import '../../../../core/utils/widget/shimmer_loading.dart';
import '../../data/arguments/saleskit_detail_args.dart';

class SalesKitPage extends StatefulWidget {
  final SalesKitDetailArgs args;
  const SalesKitPage({super.key, required this.args});

  @override
  State<SalesKitPage> createState() => _SalesKitPageState();
}

class _SalesKitPageState extends State<SalesKitPage> {
  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();
  @override
  void initState() {
    super.initState();
    if (widget.args.page == 1 && widget.args.townshipId != null) {
      context.read<SalesKitDetailBloc>().add(
        LoadSalesKitDetailEvent(widget.args.townshipId!),
      );
    }
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    context.pushNamed('salesKit', extra: args);
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

  Widget _buildShare() {
    final args = widget.args;
    return Column(
      children: [
        customHeader(context, args.title!, isBack: true),
        SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(FetchPermissionsEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (args.priceList != null && args.priceList!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Price List",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icPriceList,
                      onTap: () => _openUrl(args.priceList, "Price List ${args.title ?? ''}".trim()),
                    ),
                  ],
                  if (args.brochure != null && args.brochure!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "EBrouchure",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icEBrouchure,
                      onTap: () => _openUrl(args.brochure, "E Brochure ${args.title ?? ''}".trim()),
                    ),
                  ],
                  if (args.productKnowledge != null && args.productKnowledge!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Product Knowledge",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icProductKnowlage,
                      onTap: () => _openUrl(args.productKnowledge, "Product Knowledge ${args.title ?? ''}".trim()),
                    ),
                  ],
                  if (args.other != null && args.other!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    _buildButtonBorder(
                      title: "Promotion Kit",
                      colorBg: whiteColor,
                      colorTitle: primaryColor,
                      logo: icAttacment,
                      onTap: () => _openUrl(args.other, "Promotion Kit ${args.title ?? ''}".trim()),
                    ),
                  ],

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
          debugPrint('SalesKitDetailError: ${state.message}');
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            customHeader(
              context,
              widget.args.title??"-",
              isBack: true,
            ),
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
              onPressed: _onRefresh,
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
          style: TextStyle(color: Colors.grey),
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
                      errorWidget: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
    return BlocConsumer<TownshipBloc, TownshipState>(
      listener: (context, state) {
        if (state is TownshipError) {
          debugPrint('TownshipError: ${state.message}');
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
                  context.read<TownshipBloc>().add(GetTownshipsEvent());
                },
                child: _buildTownshipContent(state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTownshipContent(TownshipState state) {
    if (state is TownshipLoading) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [buildSaleskitShimmer()],
        ),
      );
    }

    if (state is TownshipError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gagal memuat data project', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<TownshipBloc>().add(GetTownshipsEvent()),
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    final townships = state is TownshipLoaded
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
                style: TextStyle(color: Colors.grey),
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
              context.pushNamed(
                "salesKit",
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
              // Background image — DriveImage pakai <img> tag di web (bypass CORS)
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
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                      child: DriveImage(
                        url: logoImageUrl,
                        height: 140,
                        width: 140,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        onTap: ontap,
                        errorWidget: const Icon(Icons.broken_image, color: Colors.white),
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
