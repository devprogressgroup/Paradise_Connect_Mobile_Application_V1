import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/web_debug_util.dart' as web_debug;
import '../../../../core/utils/route_observer.dart';
import '../../domain/entities/project_site.dart';
import '../unit-detail/index.dart';
import '../state/siteplan_bloc.dart';
import '../state/siteplan_event.dart';
import '../state/siteplan_state.dart';

class SitePlanPage extends StatefulWidget {
  const SitePlanPage({super.key});

  @override
  State<SitePlanPage> createState() => _SitePlanPageState();
}

class _SitePlanPageState extends State<SitePlanPage> with RouteAware {
  late final WebViewController _controller;
  List<ProjectSite> _sites = [];
  ProjectSite? _selectedSite;
  bool _isWebviewLoading = false;
  bool _isUnitDetailSheetOpen = false;
  double _loadingProgress = 0;
  String? _currentSiteUrl;
  OverlayEntry? _rawHrefOverlay;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('site_plan');
    _initWebViewController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kalau data site plan SUDAH ada di Bloc (mis. widget ini dibuat ulang setelah
      // kembali dari SitePlanBlank, yang didaftarkan DI LUAR ShellRoute — router.dart —
      // sehingga branch ShellRoute ini kena rebuild), pakai itu LANGSUNG, JANGAN reset +
      // fetch ulang dari nol. Sebelumnya selalu reset ke sites.first + reload WebView dari
      // kosong tiap initState jalan — itu yang bikin balik dari Detail Unit jadi terlihat
      // putih & cluster yang tampil balik ke default (bukan yang terakhir dipilih user).
      // Pola SAMA seperti index_web.dart (sudah benar dari awal, tidak kena bug ini).
      final state = context.read<SiteplanBloc>().state;
      if (state is SiteplanLoaded && state.sites.isNotEmpty) {
        _initFromSites(state.sites);
      } else {
        context.read<SiteplanBloc>().add(LoadSiteplanEvent());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _rawHrefOverlay?.remove();
    super.dispose();
  }

  // Kembali dari halaman lain yang ditumpuk di atas (mis. SitePlanBlank) — WebView di Android
  // SERING jadi blank/putih persis setelah itu, walau controller & isi peta-nya SEBENARNYA masih
  // hidup di memori (bug dikenal `webview_flutter`: platform view/texture-nya yang berhenti
  // repaint, bukan datanya yang hilang). JANGAN panggil _loadSite() lagi di sini — itu justru
  // bikin nunggu network 3-4 detik lagi tiap kali balik (persis yang dikomplain user). Cukup
  // paksa Flutter rebuild widget-nya (setState kosong) supaya platform view WebView ikut
  // di-re-attach & repaint sendiri oleh framework, tanpa reload konten apa pun.
  //
  // Unit Detail SEKARANG bottom sheet (showUnitDetailSheet, route non-opaque) — route di
  // baliknya TETAP ke-paint (didimming lewat barrier modal), tidak pernah kena bug blank di
  // atas, jadi rebuild ini pun tidak perlu — di-skip pakai flag ini supaya tidak ada
  // flicker/rebuild yang kelihatan seperti "reset" tiap sheet ditutup.
  @override
  void didPopNext() {
    if (_isUnitDetailSheetOpen) return;
    if (mounted) setState(() {});
  }

  // Body dari event 'unitDetailResponse' itu teks HTML mentah (bridge script yang biasa
  // di-generate PropertyController::forwardToSiteplan()) — bukan object siap pakai. Ambil
  // query/location/sourceParams/redirectParams-nya pakai regex, lalu json-decode tiap nilainya
  // (semua sudah di-json_encode satu-satu di sisi PHP, jadi escaping-nya valid JSON per-field,
  // meski pembungkusnya bukan JSON object literal). Sama persis dengan index_web.dart.
  Map<String, dynamic> _parseBridgeHtml(String html) {
    String? extractJsonString(String key) {
      final match = RegExp('$key:\\s*"((?:[^"\\\\]|\\\\.)*)"').firstMatch(html);
      if (match == null) return null;
      try {
        return jsonDecode('"${match.group(1)}"') as String;
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic>? extractJsonObject(String key) {
      final match = RegExp('$key:\\s*(\\{[^}]*\\})').firstMatch(html);
      if (match == null) return null;
      try {
        return jsonDecode(match.group(1)!) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return {
      'query': extractJsonString('query'),
      'location': extractJsonString('location'),
      'sourceParams': extractJsonObject('sourceParams'),
      'redirectParams': extractJsonObject('redirectParams'),
    };
  }

  // Overlay.insert() SENGAJA dipakai, BUKAN showDialog() — showDialog mendorong route baru ke
  // Navigator, dan biarpun WebView native jarang kena bug detach-reload seperti iframe web,
  // konsisten pakai mekanisme yang sama-sama TIDAK LEWAT Navigator di kedua platform.
  void _showRawHrefDialog(String href) {
    _rawHrefOverlay?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: const Color(whiteColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Href Tombol "Lihat Selengkapnya"',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        entry.remove();
                        _rawHrefOverlay = null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(href, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
    _rawHrefOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  // Tampilkan UnitDetailPage (fetch LIVE dari /property-pricing) sebagai bottom sheet, pakai id
  // unit yang di-relay dari klik pin/tombol "Lihat Selengkapnya" di WebView siteplan — lihat
  // channel 'SiteplanBridge' & onNavigationRequest di atas. SENGAJA bottom sheet (bukan
  // route/pushNamed) — WebView native jarang kena bug detach-reload seperti iframe web, tapi
  // tetap konsisten dengan versi web supaya perilakunya sama di kedua platform.
  void _openUnitDetailFromParams(Map params) {
    int? toInt(dynamic v) => v is int ? v : int.tryParse('$v');
    final siteplanId = toInt(params['siteplan_id']);
    final companyId = toInt(params['company_id']);
    final productId = toInt(params['product_id']);
    final propertyId = toInt(params['property_id']);
    if (siteplanId == null || companyId == null || productId == null || propertyId == null) {
      return;
    }
    if (!mounted) return;
    AnalyticsService.logEvent('site_plan_open_unit_detail');
    _isUnitDetailSheetOpen = true;
    showUnitDetailSheet(
      context,
      siteplanId: siteplanId,
      companyId: companyId,
      productId: productId,
      propertyId: propertyId,
    ).whenComplete(() => _isUnitDetailSheetOpen = false);
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
      // Backend (PropertyController::siteplanBridgeScript()) inject script ke tiap halaman
      // siteplan yang di-proxy, yang relay data unit yang lagi dilihat user (hasil tap pin /
      // klik "Lihat Selengkapnya") lewat channel ini — WebView native BISA nerima JS channel
      // custom (beda dari iframe browser yang cuma bisa postMessage), jadi dipakai langsung.
      ..addJavaScriptChannel(
        'SiteplanBridge',
        onMessageReceived: (JavaScriptMessage message) {
          if (kDebugMode) debugPrint('[SitePlan][bridge] ${message.message}');
          web_debug.logDebugInfo('[SitePlan][bridge] ${message.message}');

          // Klik "Lihat Selengkapnya" versi BARU (vendor sudah diubah pakai fetch() alih-alih
          // window.location.href) — WebView TIDAK PERNAH navigasi, peta tidak pernah hilang.
          // Pesannya lewat channel ini (bukan onNavigationRequest lagi), format JSON string
          // {source, type, payload, ts} — dikirim siteplanBridgeScript()::relayToFlutter().
          try {
            final decoded = jsonDecode(message.message);
            // Vendor SEKARANG bisa fetch() langsung ke domain app kita sendiri (siteplan_id/
            // company_id/product_id/property_id plain di query) — kalau ini lewat fetch()
            // (bukan navigasi asli), onNavigationRequest TIDAK PERNAH ke-trigger, jadi harus
            // ditangkap di sini juga. Cuma tampilkan di overlay — TIDAK PERNAH pushNamed/navigasi
            // pakai href ini.
            if (decoded is Map && decoded['type'] == 'unitDetailPlainParams') {
              final payload = decoded['payload'];
              if (payload is Map) {
                _openUnitDetailFromParams(payload);
              }
            }
            if (decoded is Map && decoded['type'] == 'unitDetailResponse') {
              final payload = decoded['payload'];
              final body = payload is Map ? payload['body'] : null;
              if (body is String && body.contains('paradiseSiteplan')) {
                final parsed = _parseBridgeHtml(body);
                final location = parsed['location'] as String?;
                final redirectParams = parsed['redirectParams'] as Map<String, dynamic>?;
                if (redirectParams != null && redirectParams.isNotEmpty) {
                  _openUnitDetailFromParams(redirectParams);
                } else if (mounted && location != null) {
                  _showRawHrefDialog(location);
                }
              }
            }
          } catch (_) {}
        },
      )
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
          // Tombol popup unit (mis. "Lihat Selengkapnya") di-render oleh konten HTML server
          // siteplan, bukan Flutter — vendor navigasi (window.location.href) ke
          // ".../siteplan-key?=<payload terenkripsi>" (dikonfirmasi lewat komentar di kode
          // vendor sendiri: "biar WebView beneran pindah ke halaman Paradise Connect setelah
          // redirect"). Sebelumnya URL ini SELALU diizinkan navigate — karena endpoint
          // "/siteplan-key" itu belum pernah di-wire ke halaman apa pun, WebView jadi nyasar
          // ke halaman kosong/blank. Match cuma dari PATH (bukan host) — pola sama seperti
          // `_appLinkPathRoutes` di router.dart — supaya tidak perlu hardcode domain.
          // Filter isMainFrame + url tidak kosong: konten siteplan pakai iframe internal
          // yang juga memicu onNavigationRequest berkali-kali dengan url kosong, bikin spam.
          onNavigationRequest: (request) {
            if (!request.isMainFrame || request.url.isEmpty) {
              return NavigationDecision.navigate;
            }
            if (kDebugMode) debugPrint('[SitePlan] onNavigationRequest: ${request.url}');
            web_debug.logDebugInfo('[SitePlan] navigate: ${request.url}');

            final uri = Uri.tryParse(request.url);
            // Redirect vendor sekarang ada 2 bentuk (lihat forwardToSiteplan() di backend):
            // "/siteplan-key?=<ciphertext>" (lama) ATAU root domain app dengan query PLAIN
            // (siteplan_id/company_id/product_id/property_id, tanpa enkripsi). Match query-nya
            // (bukan cuma path) supaya bentuk baru juga tercegat, tidak WebView ikut navigasi
            // ke domain app sendiri (yang bisa bikin WebView nampilin PWA vendor, bukan peta).
            final hasPlainUnitParams = uri != null &&
                uri.queryParameters.containsKey('siteplan_id') &&
                uri.queryParameters.containsKey('company_id') &&
                uri.queryParameters.containsKey('product_id') &&
                uri.queryParameters.containsKey('property_id');
            if (uri != null && (uri.path == '/siteplan-key' || hasPlainUnitParams)) {
              // Bentuk baru (siteplan_id/company_id/product_id/property_id plain di query) —
              // langsung navigasi ke UnitDetailPage. Bentuk lama (/siteplan-key, terenkripsi,
              // menuju halaman berbeda) tetap tampilkan href mentahnya buat debug.
              if (hasPlainUnitParams) {
                _openUnitDetailFromParams(uri.queryParameters);
              } else if (mounted) {
                _showRawHrefDialog(request.url);
              }
              // .prevent DI SINI cuma nyetop HOP KEDUA (redirect ke /siteplan-key atau root app).
              // HOP PERTAMA (navigasi ke "unit_detail_link" yang responsnya HTML kosong berisi
              // script bridge ini) SUDAH KEBURU jalan & ke-render duluan (path-nya tidak match,
              // jadi lolos di bawah) — WebView jadi nyangkut nampilin halaman kosong itu terus,
              // bukan .prevent yang salah. Reload eksplisit balik ke situs asli biar peta
              // muncul lagi.
              if (_currentSiteUrl != null) {
                _controller.loadRequest(Uri.parse(_currentSiteUrl!));
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
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

    if (kDebugMode) debugPrint('[SitePlan] loading url: ${site.url}');

    // site.url sudah menunjuk ke proxy Laravel (/property/siteplan-proxy) — backend yang
    // menyisipkan header X-App-Token ke server siteplan asli, WebView tidak perlu (dan
    // tidak bisa lagi) kirim header custom sendiri. Sama seperti jalur web (iframe).
    await _controller.loadRequest(Uri.parse(site.url));
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
                  colorIconLeft: Color(blackColor),
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
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(redAccentColor)),
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
