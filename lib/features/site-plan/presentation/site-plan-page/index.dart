import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
import '../../domain/repositories/site_plan_repository_impl.dart';

/// Local HTTP proxy that forwards all WebView sub-requests to the target server
/// with the required auth headers (X-App-Token, etc.).
class _LocalProxy {
  HttpServer? _server;
  HttpClient? _client;

  Future<int> start({
    required String targetHost,
    required Map<String, String> headers,
  }) async {
    _client = HttpClient();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    _server!.listen((req) async {
      try {
        final targetUri = Uri(
          scheme: 'http',
          host: targetHost,
          path: req.uri.path,
          query: req.uri.query.isEmpty ? null : req.uri.query,
        );

        final proxyReq = await _client!.getUrl(targetUri);
        headers.forEach(proxyReq.headers.add);

        final proxyRes = await proxyReq.close();
        req.response.statusCode = proxyRes.statusCode;

        const skipHeaders = {'transfer-encoding', 'connection', 'keep-alive'};
        proxyRes.headers.forEach((name, values) {
          if (!skipHeaders.contains(name.toLowerCase())) {
            try {
              req.response.headers.set(name, values.join(', '));
            } catch (_) {}
          }
        });

        await proxyRes.pipe(req.response);
      } catch (_) {
        try {
          req.response.statusCode = 500;
          await req.response.close();
        } catch (_) {}
      }
    });

    return _server!.port;
  }

  void stop() {
    _client?.close(force: true);
    _server?.close(force: true);
    _client = null;
    _server = null;
  }
}

class SitePlanPage extends StatefulWidget {
  const SitePlanPage({super.key});

  @override
  State<SitePlanPage> createState() => _SitePlanPageState();
}

class _SitePlanPageState extends State<SitePlanPage> {
  late final WebViewController _controller;
  final _repository = SitePlanRepositoryImpl();
  _LocalProxy? _proxy;
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
    _loadSite(_selectedSite);
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _loadingProgress = p / 100),
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
      ));
  }

  Future<void> _loadSite(ProjectSite site) async {
    setState(() => _isLoading = true);

    _proxy?.stop();
    _proxy = null;

    if (site.headers.isNotEmpty) {
      final originalUri = Uri.parse(site.url);
      _proxy = _LocalProxy();
      final port = await _proxy!.start(
        targetHost: originalUri.host,
        headers: site.headers,
      );

      final localUri = originalUri.replace(
        scheme: 'http',
        host: '127.0.0.1',
        port: port,
      );
      await _controller.loadRequest(localUri);
    } else {
      await _controller.loadRequest(Uri.parse(site.url));
    }
  }

  void _openProjectList() async {
    final result = await context.pushNamed('projectList', extra: _sites);
    if (result != null && result is ProjectSite) {
      setState(() => _selectedSite = result);
      _loadSite(result);
    }
  }

  @override
  void dispose() {
    _proxy?.stop();
    super.dispose();
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
                  color: Color(whiteColor),
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
      child: buildSiteplanShimmer(),
    );
  }
}
