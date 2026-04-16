import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
import '../../domain/repositories/site_plan_repository_impl.dart';

class SitePlanPage extends StatefulWidget {
  const SitePlanPage({super.key});

  @override
  State<SitePlanPage> createState() => _SitePlanPageState();
}

class _SitePlanPageState extends State<SitePlanPage> {
  late final WebViewController _controller;
  final _repository = SitePlanRepositoryImpl();
  late List<ProjectSite> _sites;
  late ProjectSite _selectedSite;
  bool _isLoading = true;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _sites = _repository.getAvailableSites();
    _selectedSite = _sites.first;
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _loadingProgress = p / 100),
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(_selectedSite.url));
  }

  void _openProjectList() async {
    final result = await context.pushNamed('projectList', extra: _sites);

    if (result != null && result is ProjectSite) {
      setState(() {
        _selectedSite = result;
      });
      _controller.loadRequest(Uri.parse(result.url));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Site Plan'),
            GestureDetector(
              onTap: _openProjectList,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedSite.groupName, 
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_selectedSite.unitName, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Color(blackColor), size: 40),
                  ],
                ),
              ),
            ),

      
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),

            // WebView Area
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading && _loadingProgress < 0.9) _buildLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}