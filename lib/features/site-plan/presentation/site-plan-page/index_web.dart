
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
  static int _iframeCounter = 0;

  List<ProjectSite> _sites   = [];
  ProjectSite? _selectedSite;
  String? _currentViewId;

  bool _isLoading          = false;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;
  StreamSubscription<html.MessageEvent>? _bridgeSub;

  @override
  void initState() {
    super.initState();
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

        // Klik "Lihat Selengkapnya": proxy Laravel (PropertyController::forwardToSiteplan(),
        // docs §17) MENCEGAT redirect ke "/siteplan-key" SEBELUM browser sempat navigasi ke
        // sana — jadi TIDAK ADA reload PWA/webview apa pun. Query string (MASIH terenkripsi)
        // di-relay ke sini, decrypt-nya baru terjadi di Dart (key AES cuma ada di sini).
        if (data['type'] == 'unitDetailRedirect') {
          final payload = data['payload'];
          final query = payload is Map ? payload['query'] as String? : null;
          if (query != null && query.isNotEmpty) {
            final unitData = UnitDetail.decryptPayload(
              query.startsWith('=') ? query.substring(1) : query,
            );
            if (unitData != null && mounted) {
              AnalyticsService.logEvent('site_plan_unit_detail_from_siteplan');
              context.pushNamed('site_plan_blank', extra: unitData);
            }
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

  void _openSitePlanBlank() {
    AnalyticsService.logEvent('site_plan_open_blank_preview');
    final unitData = UnitDetail.decryptKeyUrlToJson(sampleEncryptedSiteplanKeyUrl);
    context.pushNamed('site_plan_blank', extra: unitData);
  }

  void _retryLoadSite() {
    if (_selectedSite != null) {
      AnalyticsService.logEvent('site_plan_retry_from_fallback');
      _loadSite(_selectedSite!);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _bridgeSub?.cancel();
    super.dispose();
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
                  // iconLeft: Icons.visibility_outlined,
                  colorIconLeft: Color(blackColor),
                  // iconLeftOnTap: _openSitePlanBlank,
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
