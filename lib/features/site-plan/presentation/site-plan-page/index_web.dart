
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';
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
  static int _iframeCounter = 0;

  List<ProjectSite> _sites   = [];
  ProjectSite? _selectedSite;
  String? _currentViewId;

  bool _isLoading          = false;
  bool _showFallbackBanner = false;
  bool _isUnitDetailSheetOpen = false;
  Timer? _timeoutTimer;
  StreamSubscription<html.MessageEvent>? _bridgeSub;
  OverlayEntry? _rawHrefOverlay;
  html.IFrameElement? _currentIframe;

  @override
  void initState() {
    super.initState();
    // debugPrint (BUKAN web_debug.logDebugInfo) — script debug panel Eruda di web/index.html
    // SAAT INI di-comment semua, jadi logDebugInfo diam-diam no-op (try/catch nelan error JS
    // "logDebugLine is not defined"). debugPrint tetap muncul di terminal `flutter run` tanpa
    // bergantung ke itu.
    if (kDebugMode) debugPrint('[SitePlan] initState (widget baru/rebuild)');
    AnalyticsService.logScreenView('site_plan');
    _listenSiteplanBridge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SiteplanBloc>().state;
      if (state is SiteplanLoaded && state.sites.isNotEmpty) {
        _initFromSites(state.sites);
      }
    });
  }

  // Backend (PropertyController::siteplanBridgeScript()) inject script ke tiap halaman
  // siteplan yang di-proxy, yang relay data unit yang lagi dilihat user lewat postMessage —
  // dipakai supaya Flutter tahu isi tombol "Lihat Selengkapnya" tanpa perlu proxy/reverse-
  // engineer konten vendor sendiri di sisi Flutter.
  void _listenSiteplanBridge() {
    _bridgeSub?.cancel();
    _bridgeSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map && data['source'] == 'paradiseSiteplan') {
        if (kDebugMode) debugPrint('[SitePlan][bridge] ${data['type']}: ${data['payload']}');

        // Klik "Lihat Selengkapnya" — kalau redirectParams (siteplan_id/company_id/product_id/
        // property_id plain, tanpa enkripsi) sudah ada, langsung navigasi ke UnitDetailPage
        // (fetch LIVE dari /property-pricing). Kalau belum (redirect versi lama, terenkripsi,
        // belum ke-parse di sini), tampilkan raw href-nya saja buat debug.
        if (data['type'] == 'unitDetailRedirect') {
          final payload = data['payload'];
          final query = payload is Map ? payload['query'] as String? : null;
          if (query != null && query.isNotEmpty) {
            // Redirect MENTAH dari backend (PropertyController::forwardToSiteplan()) — persis
            // URL yang dituju window.location.href di fallback non-iframe-nya (mobile).
            final rawLocation = payload['location'] as String?;
            final redirectParams = payload is Map ? payload['redirectParams'] as Map? : null;
            if (redirectParams != null && redirectParams.isNotEmpty) {
              _openUnitDetailFromParams(redirectParams);
            } else if (mounted) {
              _showRawHrefDialog(rawLocation ?? query);
            }
          }
        }

        // Klik "Lihat Selengkapnya" versi BARU (vendor sudah diubah pakai fetch() alih-alih
        // window.location.href) — halaman TIDAK PERNAH navigasi, jadi peta tidak pernah hilang.
        // Body-nya sama persis dengan HTML bridge yang biasa di-generate forwardToSiteplan()
        // (masih ada <script> pembungkusnya), jadi query/location/sourceParams/redirectParams
        // diambil pakai regex, bukan didapat langsung sebagai object siap pakai.
        if (data['type'] == 'unitDetailResponse') {
          final payload = data['payload'];
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

        // Vendor SEKARANG navigasi LANGSUNG ke domain app kita (siteplan_id/company_id/
        // product_id/property_id plain di query, TIDAK LEWAT proxy Laravel sama sekali) —
        // PWA boot ulang nested di dalam iframe (SitePlanRelayPage, lihat router.dart), yang
        // relay id-nya ke sini APA ADANYA, tidak perlu decrypt/parsing apa pun — langsung
        // navigasi ke UnitDetailPage.
        if (data['type'] == 'unitDetailPlainParams') {
          final payload = data['payload'];
          if (payload is Map) {
            _openUnitDetailFromParams(payload);
          }
        }

        // Fallback (jaga-jaga): kalau ternyata redirect-nya SEMPAT lolos jadi navigasi asli
        // (mis. proxy versi lama belum ter-deploy) & PWA boot ulang nested di dalam iframe
        // (docs §16) — SitePlanBlank nested itu (web_iframe_bridge_web.dart) tetap relay data
        // yang SUDAH didecrypt-nya sendiri ke sini, supaya tidak berakhir blank/nyasar.
        if (data['type'] == 'unitDetailFromBlank') {
          final payloadStr = data['payload'];
          if (payloadStr is String && mounted) {
            try {
              final decoded = jsonDecode(payloadStr);
              if (decoded is Map<String, dynamic>) {
                AnalyticsService.logEvent('site_plan_unit_detail_from_siteplan');
                context.pushNamed('site_plan_blank', extra: decoded);
              }
            } catch (_) {}
          }
        }
      }
    });
  }

  // Body dari event 'unitDetailResponse' itu teks HTML mentah (bridge script yang biasa
  // di-generate PropertyController::forwardToSiteplan()) — bukan object siap pakai kayak
  // payload 'unitDetailRedirect'. Ambil query/location/sourceParams/redirectParams-nya pakai
  // regex, lalu json-decode tiap nilainya (semua sudah di-json_encode satu-satu di sisi PHP,
  // jadi escaping-nya valid JSON per-field, meski pembungkusnya bukan JSON object literal).
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

  // Overlay.insert() SENGAJA dipakai, BUKAN showDialog() — showDialog mendorong route BARU ke
  // Navigator, dan push/pop route (bahkan dialog) di web bisa ikut memicu platform view iframe
  // ke-detach/reattach dari DOM (persis bug reset iframe yang sudah dibahas), lepas dari apakah
  // RouteObserver<PageRoute> beneran ke-trigger atau tidak. Overlay TIDAK LEWAT Navigator sama
  // sekali — cuma nambah widget ke Overlay stack yang sudah ada, jadi iframe di baliknya tidak
  // pernah tersentuh/dicabut dari tree, tidak ada alasan buat reset.
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

  void _initFromSites(List<ProjectSite> sites) {
    setState(() {
      _sites        = sites;
      _selectedSite = sites.first;
    });
    _loadSite(sites.first);
  }

  void _loadSite(ProjectSite site) {
    _timeoutTimer?.cancel();

    _iframeCounter++;
    final viewId = 'siteplan-iframe-$_iframeCounter';

    final iframe = html.IFrameElement()
      ..src = site.url
      ..style.width  = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true');
    _currentIframe = iframe;

    iframe.onLoad.listen((_) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
      _resetIframeZoom(iframe);
    });

    ui_web.platformViewRegistry.registerViewFactory(viewId, (_) => iframe);

    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _isLoading) {
        setState(() { _isLoading = false; _showFallbackBanner = true; });
      }
    });

    setState(() {
      _currentViewId       = viewId;
      _isLoading           = true;
      _showFallbackBanner  = false;
    });
  }

  void _resetIframeZoom(html.IFrameElement iframe) {
    try {
      
      iframe.contentWindow?.postMessage({'type': 'resetZoom', 'scale': 1}, '*');
    } catch (_) {}
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


  // Tampilkan UnitDetailPage (fetch LIVE dari /property-pricing) sebagai bottom sheet, pakai id
  // unit yang di-relay dari klik pin/tombol "Lihat Selengkapnya" di WebView siteplan — lihat
  // handler-handler 'unitDetailRedirect'/'unitDetailResponse'/'unitDetailPlainParams' di
  // _listenSiteplanBridge(). SENGAJA bottom sheet (bukan route/pushNamed) — supaya iframe
  // siteplan di baliknya TIDAK ikut ke-navigasi/reload (lihat catatan didPopNext di atas).
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
    // Iframe adalah elemen DOM ASLI (bukan digambar di canvas Flutter) — dia tetap menangkap
    // klik mouse duluan meski secara visual ketutup ModalBarrier bottom sheet, sehingga tap
    // "di luar sheet" (area map) tidak pernah sampai ke barrier & sheet tidak pernah close.
    // pointer-events: none selama sheet terbuka supaya klik itu lolos ke Flutter.
    _currentIframe?.style.pointerEvents = 'none';
    showUnitDetailSheet(
      context,
      siteplanId: siteplanId,
      companyId: companyId,
      productId: productId,
      propertyId: propertyId,
    ).whenComplete(() {
      _isUnitDetailSheetOpen = false;
      _currentIframe?.style.pointerEvents = 'auto';
    });
  }

  void _retryLoadSite() {
    if (_selectedSite != null) {
      AnalyticsService.logEvent('site_plan_retry_from_fallback');
      _loadSite(_selectedSite!);
    }
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
    _timeoutTimer?.cancel();
    _bridgeSub?.cancel();
    _rawHrefOverlay?.remove();
    super.dispose();
  }

  // Kembali dari halaman lain yang ditumpuk di atas (mis. project-list) — BEDA dari WebView
  // native (mobile), iframe di web itu elemen DOM asli: dicabut dari document lalu dipasang
  // ulang DIANGGAP BROWSER SEBAGAI NAVIGASI BARU, otomatis reload src-nya dari nol (bukan
  // sesuatu yang bisa "diperbaiki" dari sisi Flutter — setState kosong saja TIDAK CUKUP, sudah
  // dicoba & tetap putih). Jadi terima konsekuensinya: reload eksplisit di sini.
  //
  // Unit Detail SEKARANG bottom sheet (showUnitDetailSheet, route non-opaque) — beda dari route
  // halaman biasa, route di baliknya TETAP kelihatan/ke-paint (didimming lewat barrier modal),
  // TIDAK pernah dicabut dari DOM, jadi TIDAK butuh reload. RouteObserver tetap memicu
  // didPopNext saat sheet ditutup (dianggap sama seperti pop biasa), makanya reload di-skip
  // pakai flag ini — kalau tidak, peta ikut reload tiap kali sheet ditutup padahal tidak perlu.
  @override
  void didPopNext() {
    if (kDebugMode) debugPrint('[SitePlan] didPopNext (state lama masih hidup, bukan rebuild)');
    if (_isUnitDetailSheetOpen) return;
    if (mounted && _selectedSite != null) _loadSite(_selectedSite!);
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
                if (state is SiteplanLoading || state is SiteplanInitial)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (state is SiteplanError)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(redAccentColor))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                AnalyticsService.logEvent('site_plan_retry_load_siteplan');
                                context.read<SiteplanBloc>().add(LoadSiteplanEvent());
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_selectedSite != null) ...[
                  _buildSiteSelector(),

                  if (_showFallbackBanner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: const Color(0xFFFFF8E1),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(orangeAccentColor)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gagal dimuat.',
                              style: TextStyle(fontSize: 11, color: Color(blackColor).withAlpha(87)),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _retryLoadSite,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Muat Ulang', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(primaryColor),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Color(transparentColor),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(primaryColor)),
                    ),

                  if (_currentViewId != null)
                    Expanded(child: HtmlElementView(viewType: _currentViewId!))
                  else
                    const Expanded(child: Center(child: CircularProgressIndicator())),
                ]
                else
                  const Expanded(child: Center(child: CircularProgressIndicator())),
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
        decoration: const BoxDecoration(color: Color(whiteColor)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedSite!.groupName,
                      style: const TextStyle(fontSize: 10, color: Color(greyShade500))),
                  Text(_selectedSite!.unitName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(blackColor), size: 40),
          ],
        ),
      ),
    );
  }
}
