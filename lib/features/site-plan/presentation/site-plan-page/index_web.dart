
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import '../../../../core/utils/route_observer.dart';
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

class _SitePlanPageState extends State<SitePlanPage> with RouteAware {
  static int _iframeCounter = 0;
  // `static` SENGAJA — bertahan lintas rebuild `_SitePlanPageState` (kembali dari
  // `SitePlanBlank`/`/site-plan/blank`, yang DI LUAR ShellRoute, bikin branch ShellRoute ini
  // kena rebuild PENUH — initState jalan lagi, instance State lama dibuang). `SiteplanBloc`
  // sendiri TIDAK ikut rebuild (di-provide di atas router, lihat main.dart), jadi `state.sites`
  // dari Bloc tetap List<ProjectSite> yang SAMA — referensi ini masih valid buat dicari lagi.
  static ProjectSite? _lastSelectedSite;

  List<ProjectSite> _sites   = [];
  ProjectSite? _selectedSite;
  String? _currentViewId;

  bool _isLoading          = false;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;
  StreamSubscription<html.MessageEvent>? _bridgeSub;
  OverlayEntry? _rawHrefOverlay;

  @override
  void initState() {
    super.initState();
    // debugPrint (BUKAN web_debug.logDebugInfo) — script debug panel Eruda di web/index.html
    // SAAT INI di-comment semua, jadi logDebugInfo diam-diam no-op (try/catch nelan error JS
    // "logDebugLine is not defined"). debugPrint tetap muncul di terminal `flutter run` tanpa
    // bergantung ke itu.
    debugPrint('[SitePlan] initState (widget baru/rebuild)');
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
        debugPrint('[SitePlan][bridge] ${data['type']}: ${data['payload']}');

        // Klik "Lihat Selengkapnya" — SEMENTARA dimatiin (navigasi ke SitePlanBlank tidak
        // jalan dulu), cuma tampilkan href mentahnya di dialog buat verifikasi/debug.
        if (data['type'] == 'unitDetailRedirect') {
          final payload = data['payload'];
          final query = payload is Map ? payload['query'] as String? : null;
          if (query != null && query.isNotEmpty) {
            // Redirect MENTAH dari backend (PropertyController::forwardToSiteplan()) — persis
            // URL yang dituju window.location.href di fallback non-iframe-nya (mobile).
            final rawLocation = payload['location'] as String?;
            // BARU: vendor sekarang bisa generate redirect_target PLAIN (siteplan_id/company_id/
            // product_id/property_id langsung di query, TANPA enkripsi) — kalau ini kasusnya,
            // redirectParams sudah berisi ke-4 id itu, tidak perlu decrypt apa pun lagi.
            final redirectParams = payload is Map ? payload['redirectParams'] as Map? : null;
            debugPrint('TOMBOL REDIRECT: ${rawLocation ?? '(kosong)'} | redirectParams: $redirectParams');
            if (mounted) {
              final label = (redirectParams != null && redirectParams.isNotEmpty)
                  ? '${rawLocation ?? query}\n\nsiteplan_id: ${redirectParams['siteplan_id']}\ncompany_id: ${redirectParams['company_id']}\nproduct_id: ${redirectParams['product_id']}\nproperty_id: ${redirectParams['property_id']}'
                  : (rawLocation ?? query);
              _showRawHrefDialog(label);
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
            debugPrint('TOMBOL REDIRECT (fetch): ${location ?? '(kosong)'} | redirectParams: $redirectParams');
            if (mounted && (location != null || (redirectParams != null && redirectParams.isNotEmpty))) {
              final label = (redirectParams != null && redirectParams.isNotEmpty)
                  ? '${location ?? '(kosong)'}\n\nsiteplan_id: ${redirectParams['siteplan_id']}\ncompany_id: ${redirectParams['company_id']}\nproduct_id: ${redirectParams['product_id']}\nproperty_id: ${redirectParams['property_id']}'
                  : location!;
              _showRawHrefDialog(label);
            }
          }
        }

        // Vendor SEKARANG navigasi LANGSUNG ke domain app kita (siteplan_id/company_id/
        // product_id/property_id plain di query, TIDAK LEWAT proxy Laravel sama sekali) —
        // PWA boot ulang nested di dalam iframe (SitePlanRelayPage, lihat router.dart), yang
        // relay id-nya ke sini APA ADANYA, tidak perlu decrypt/parsing apa pun.
        if (data['type'] == 'unitDetailPlainParams') {
          final payload = data['payload'];
          // Cuma tampilkan di overlay (_showRawHrefDialog) — TIDAK PERNAH context.push/go ke
          // mana pun pakai href ini, biar tidak ada navigasi/pindah halaman sama sekali.
          if (payload is Map && mounted) {
            final href = payload['href'] as String?;
            final label = '${href ?? '(href kosong)'}\n\nsiteplan_id: ${payload['siteplan_id']}\ncompany_id: ${payload['company_id']}\nproduct_id: ${payload['product_id']}\nproperty_id: ${payload['property_id']}';
            debugPrint('UNIT DETAIL PLAIN PARAMS: $label');
            _showRawHrefDialog(label);
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
    // Pertahankan cluster yang terakhir dipilih user (kalau masih ada di daftar) — jangan
    // selalu reset ke sites.first tiap kali branch ShellRoute ini rebuild (lihat komentar
    // _lastSelectedSite), soalnya itu bikin cluster balik ke default pas user kembali dari
    // SitePlanBlank walau sebelumnya dia sudah pindah ke cluster lain.
    final last = _lastSelectedSite;
    final restored = last != null && sites.any((s) => identical(s, last)) ? last : sites.first;
    setState(() {
      _sites        = sites;
      _selectedSite = restored;
    });
    _lastSelectedSite = restored;
    _loadSite(restored);
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
      _lastSelectedSite = result;
      _loadSite(result);
    }
  }

  void _openSitePlanBlank() {
    AnalyticsService.logEvent('site_plan_open_blank_preview');
    final unitData = UnitDetail.decryptKeyUrlToJson(sampleEncryptedSiteplanKeyUrl);
    unitData?['_rawHref'] = sampleEncryptedSiteplanKeyUrl;
    context.pushNamed('site_plan_blank', extra: unitData);
  }
    void _openUnitDetailPreview() {
    AnalyticsService.logEvent('site_plan_open_unit_detail_preview');
    context.pushNamed('unit_detail', extra: const {
      'siteplan_id': 15,
      'company_id': 24,
      'product_id': 103,
      'property_id': 1275,
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

  // Kembali dari halaman lain yang ditumpuk di atas (SitePlanBlank/Detail Unit) — BEDA dari
  // WebView native (mobile), iframe di web itu elemen DOM asli: dicabut dari document lalu
  // dipasang ulang DIANGGAP BROWSER SEBAGAI NAVIGASI BARU, otomatis reload src-nya dari nol
  // (bukan sesuatu yang bisa "diperbaiki" dari sisi Flutter — setState kosong saja TIDAK CUKUP,
  // sudah dicoba & tetap putih). Jadi terima konsekuensinya: reload eksplisit di sini.
  @override
  void didPopNext() {
    debugPrint('[SitePlan] didPopNext (state lama masih hidup, bukan rebuild)');
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
                  iconLeft: Icons.visibility_outlined,
                  colorIconLeft: Color(blackColor),
                  iconLeftOnTap: _openSitePlanBlank,
                  // Tombol preview UnitDetailPage (halaman harga & simulasi yang fetch LIVE
                  // dari /property-pricing) — belum ada pemicu asli (tap pin di WebView siteplan
                  // belum relay product/property id lewat SiteplanBridge), jadi dibuka pakai
                  // contoh id sesuai unit contoh di SitePlanBlank (Ariawood 36/60) supaya bisa
                  // dites tanpa itu dulu.
                  iconLeft2: Icons.payments_outlined,
                  colorIconLeft2: Color(blackColor),
                  iconLeft2OnTap: _openUnitDetailPreview,
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
                            const Text('Gagal memuat data site plan',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(redAccentColor))),
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
