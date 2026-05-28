// Web-only site plan viewer.
// Menggunakan backend Laravel sebagai proxy (server-to-server) karena
// browser tidak bisa bypass CORS untuk custom header X-App-Token.
//
// Alur:
//   iframe → http://backend:8000/api/property/siteplan-proxy?...
//          → Laravel forward ke dynamics.paradise.id + X-App-Token
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SiteplanBloc>().state;
      if (state is SiteplanLoaded && state.sites.isNotEmpty) {
        _initFromSites(state.sites);
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
      ..src = site.url  // URL backend proxy sudah diset di repository
      ..style.width  = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true');

    iframe.onLoad.listen((_) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
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

  void _openProjectList() async {
    final result = await context.pushNamed('projectList', extra: _sites);
    if (result != null && result is ProjectSite) {
      setState(() => _selectedSite = result);
      _loadSite(result);
    }
  }

  void _openInNewTab() {
    if (_selectedSite != null) html.window.open(_selectedSite!.url, '_blank');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
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
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, 'Site Plan'),

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
                            Text(state.message, textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<SiteplanBloc>().add(LoadSiteplanEvent()),
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
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Gagal dimuat. Buka di tab baru.',
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openInNewTab,
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Buka', style: TextStyle(fontSize: 12)),
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
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
