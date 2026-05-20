import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool isOpenRedential = true;
  bool isOpenCommercial = true;

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
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  _buildButtonBorder(
                    title: "Price List",
                    colorBg: whiteColor,
                    colorTitle: primaryColor,
                    logo: icPriceList,
                    isDisabled: args.priceList == null,
                    onTap: () => _openUrl(args.priceList, "Price List"),
                  ),
                  SizedBox(height: 15),
                  _buildButtonBorder(
                    title: "EBrouchure",
                    colorBg: whiteColor,
                    colorTitle: primaryColor,
                    logo: icEBrouchure,
                    isDisabled: args.brochure == null,
                    onTap: () => _openUrl(args.brochure, "EBrouchure"),
                  ),
                  SizedBox(height: 15),
                  _buildButtonBorder(
                    title: "Product Knowledge",
                    colorBg: whiteColor,
                    colorTitle: primaryColor,
                    logo: icProductKnowlage,
                    isDisabled: args.productKnowledge == null,
                    onTap: () => _openUrl(args.productKnowledge, "Product Knowledge"),
                  ),
                  SizedBox(height: 30),
                  _buildButtonBorder(
                    title: "Share",
                    colorBg: blue3Color,
                    colorTitle: whiteColor,
                    logo: icShare,
                    onTap: () {},
                  ),
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
    return BlocBuilder<SalesKitDetailBloc, SalesKitDetailState>(
      builder: (context, state) {
        return Column(
          children: [
            customHeader(
              context,
              widget.args.title ?? "SalesKit",
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
            Text(state.message, textAlign: TextAlign.center),
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _dropdown(
          "Residential",
          () => setState(() => isOpenRedential = !isOpenRedential),
          isOpenRedential,
          Column(
            children: [
              SizedBox(height: 5),
              ...clusters.map(
                (cluster) => Column(
                  children: [
                    _buildResidentialNetwork(
                      imageUrl: ApiConstants.clusterImageUrl(
                        widget.args.townshipSlug ?? '',
                        cluster.logo,
                      ),
                      name: cluster.name,
                      onTap: () => context.pushNamed(
                        "salesKit",
                        extra: SalesKitDetailArgs(
                          page: 2,
                          title: cluster.name,
                          brochure: cluster.brochure,
                          productKnowledge: cluster.productKnowledge,
                          priceList: cluster.priceList,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                  ],
                ),
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
        _dropdown(
          "Commercial",
          () => setState(() => isOpenCommercial = !isOpenCommercial),
          isOpenCommercial,
          Column(
            children: [
              SizedBox(height: 5),
              ...commercials.map(
                (commercial) => Column(
                  children: [
                    _buildResidentialNetwork(
                      imageUrl: ApiConstants.commercialImageUrl(widget.args.townshipSlug ?? '',commercial.logo),
                      name: commercial.name,
                      onTap: () => context.pushNamed(
                        "salesKit",
                        extra: SalesKitDetailArgs(
                          page: 2,
                          title: commercial.name,
                          brochure: commercial.brochure,
                          productKnowledge: commercial.productKnowledge,
                          priceList: commercial.priceList,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String hint, VoidCallback onTap, bool isOpen, Widget child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(blackColor).withOpacity(0.06),
            blurRadius: 58,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              color: Color(whiteColor),
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 35,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) Container(width: double.infinity, child: child),
        ],
      ),
    );
  }

  Widget _buildResidentialNetwork({
    required String imageUrl,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        height: 137,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              height: 100,
              width: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(blue2Color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _builSalsesKitScreen() {
    return BlocBuilder<TownshipBloc, TownshipState>(
      builder: (context, state) {
        return Column(
          children: [
            customHeader(context, "SalesKit", isBack: false),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
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
            Text(state.message, textAlign: TextAlign.center),
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
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(backgroundImageUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                  color: Color(blue2Color),
                ),
              ),
              Container(
                height: height,
                width: double.infinity,
                color: Color(blue2Color).withOpacity(0.7),
              ),
              SizedBox(
                height: height,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      logoImageUrl,
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.white),
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
