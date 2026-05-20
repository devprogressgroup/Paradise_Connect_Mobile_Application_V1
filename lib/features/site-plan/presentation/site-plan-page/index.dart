import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
import '../state/siteplan_bloc.dart';
import '../state/siteplan_event.dart';
import '../state/siteplan_state.dart';

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
  _LocalProxy? _proxy;
  ProjectSite? _selectedSite;
  bool _isLoading = false;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    context.read<SiteplanBloc>().add(LoadSiteplanEvent());
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
    setState(() {
      _selectedSite = site;
      _isLoading = true;
    });

    _proxy?.stop();
    _proxy = null;

    if (site.url.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    if (site.headers.isNotEmpty) {
      final originalUri = Uri.parse(site.url);
      _proxy = _LocalProxy();
      final port = await _proxy!.start(
        targetHost: originalUri.host,
        headers: site.headers,
      );
      final localUri = originalUri.replace(scheme: 'http', host: '127.0.0.1', port: port);
      await _controller.loadRequest(localUri);
    } else {
      await _controller.loadRequest(Uri.parse(site.url));
    }
  }

  void _openProjectList(List<ProjectSite> sites) async {
    final result = await context.pushNamed('projectList', extra: sites);
    if (result != null && result is ProjectSite) {
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
    return BlocConsumer<SiteplanBloc, SiteplanState>(
      listener: (context, state) {
        if (state is SiteplanLoaded && state.sites.isNotEmpty && _selectedSite == null) {
          _loadSite(state.sites.first);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, 'Site Plan'),
                if (state is SiteplanLoading)
                  buildSiteplanShimmer()
                else ...[
                  if (_selectedSite != null)
                    GestureDetector(
                      onTap: () => _openProjectList(
                        state is SiteplanLoaded ? state.sites : [],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        color: Color(whiteColor),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSite!.groupName,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    _selectedSite!.unitName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
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
                  if (state is SiteplanError)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<SiteplanBloc>().add(LoadSiteplanEvent()),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_selectedSite != null && _selectedSite!.url.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text("Siteplan belum tersedia", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: Stack(
                        children: [
                          WebViewWidget(controller: _controller),
                          if (_isLoading && _loadingProgress < 0.9)
                            Container(color: Colors.white, child: buildSiteplanShimmer()),
                        ],
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
}
