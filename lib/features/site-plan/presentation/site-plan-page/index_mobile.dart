import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import '../../domain/entities/project_site.dart';
import '../../domain/entities/unit_detail.dart';
import '../state/siteplan_bloc.dart';
import '../state/siteplan_event.dart';
import '../state/siteplan_state.dart';

class SitePlanPage extends StatefulWidget {
  const SitePlanPage({super.key});

  @override
  State<SitePlanPage> createState() => _SitePlanPageState();
}

class _SitePlanPageState extends State<SitePlanPage> {
  late final WebViewController _controller;
  List<ProjectSite> _sites = [];
  ProjectSite? _selectedSite;
  bool _isWebviewLoading = false;
  double _loadingProgress = 0;
  String? _currentSiteUrl;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('site_plan');
    _initWebViewController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedSite = null;
        _sites = [];
      });
      context.read<SiteplanBloc>().add(LoadSiteplanEvent());
    });
  }

  void _initFromSites(List<ProjectSite> sites) {
    setState(() {
      _sites = sites;
      _selectedSite = sites.first;
    });
    _loadSite(sites.first);
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _loadingProgress = p / 100),
          onPageStarted: (_) => setState(() => _isWebviewLoading = true),
          onPageFinished: (_) {
            setState(() => _isWebviewLoading = false);
            _resetZoomToDefault();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            setState(() => _isWebviewLoading = false);
            _showLoadError(error.description);
          },
        ),
      );
  }

  void _showLoadError(String description) {
    final displayUrl = _currentSiteUrl ?? '';
    _controller.loadHtmlString('''
      <html>
        <body style="font-family: sans-serif; padding: 24px; text-align: center;">
          <h3>Halaman web tidak tersedia</h3>
          <p>Halaman web di $displayUrl tidak dapat dimuat karena:</p>
          <p>$description</p>
        </body>
      </html>
    ''');
  }

  void _resetZoomToDefault() {
    _controller.runJavaScript('''
      (function() {
        try {
          var meta = document.querySelector('meta[name="viewport"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            if (document.head) document.head.appendChild(meta);
          }
          var content = meta.getAttribute('content') || '';
          if (content.indexOf('initial-scale') < 0) {
            meta.setAttribute('content', (content ? content + ', ' : '') + 'initial-scale=1.0');
          } else {
            meta.setAttribute('content', content.replace(/initial-scale=[\\d.]+/, 'initial-scale=1.0'));
          }
        } catch(e) {}
      })();
    ''');
  }

  Future<void> _loadSite(ProjectSite site) async {
    setState(() => _isWebviewLoading = true);
    _currentSiteUrl = site.url;

    debugPrint('[SitePlan] loading url: ${site.url}');

    // site.url sudah menunjuk ke proxy Laravel (/property/siteplan-proxy) — backend yang
    // menyisipkan header X-App-Token ke server siteplan asli, WebView tidak perlu (dan
    // tidak bisa lagi) kirim header custom sendiri. Sama seperti jalur web (iframe).
    await _controller.loadRequest(Uri.parse(site.url));
  }

  void _openSitePlanBlank() {
    AnalyticsService.logEvent('site_plan_open_blank_preview');
    final unitData = UnitDetail.decryptKeyUrlToJson(sampleEncryptedSiteplanKeyUrl);
    context.pushNamed('site_plan_blank', extra: unitData);
  }

  void _openProjectList() async {
    AnalyticsService.logEvent('site_plan_open_project_list');
    final result = await context.pushNamed('project_list', extra: {
      'sites': _sites,
      'selected': _selectedSite,
    });
    if (result != null && result is ProjectSite) {
      setState(() => _selectedSite = result);
      _loadSite(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SiteplanBloc, SiteplanState>(
      listener: (context, state) {
        if (state is SiteplanLoaded &&
            state.sites.isNotEmpty &&
            _selectedSite == null) {
          _initFromSites(state.sites);
        }
        if (state is SiteplanError) {
          
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Color(whiteColor),
          body: SafeArea(
            child: Column(
              children: [
                customHeader(
                  context,
                  'Site Plan',
                  iconLeft: Icons.visibility_outlined,
                  colorIconLeft: Color(blackColor),
                  iconLeftOnTap: _openSitePlanBlank,
                ),
                if (state is SiteplanLoading || state is SiteplanInitial) ...[
                  Expanded(
                    child: Container(
                      color: Color(whiteColor),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ] else if (state is SiteplanError) ...[
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Gagal memuat data site plan',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(redAccentColor)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                AnalyticsService.logEvent('site_plan_retry_load_siteplan');
                                context.read<SiteplanBloc>().add(
                                  LoadSiteplanEvent(),
                                );
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedSite != null) ...[
                  _buildSiteSelector(),
                  if (_isWebviewLoading)
                    LinearProgressIndicator(
                      value: _loadingProgress,
                      minHeight: 2,
                      backgroundColor: Color(transparentColor),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(primaryColor),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isWebviewLoading && _loadingProgress < 0.9)
                          _buildLoadingOverlay(),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      color: Color(whiteColor),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiteSelector() {
    return GestureDetector(
      onTap: _openProjectList,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(color: Color(whiteColor)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSite!.groupName,
                    style: const TextStyle(fontSize: 10, color: Color(greyShade500)),
                  ),
                  Text(
                    _selectedSite!.unitName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(blackColor),
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Color(whiteColor),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
