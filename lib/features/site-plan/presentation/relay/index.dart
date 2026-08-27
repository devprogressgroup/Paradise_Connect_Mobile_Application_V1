import 'package:flutter/material.dart';

import '../../../../core/utils/web_iframe_bridge.dart';

/// Tujuan sementara instance PWA yang boot ULANG nested di dalam iframe siteplan — vendor
/// sekarang navigasi langsung ke domain app kita bawa siteplan_id/company_id/product_id/
/// property_id PLAIN di query (lihat router.dart::redirect() & docs/site-plan-mobile-pwa.md
/// §16, trigger-nya beda tapi masalahnya sama). Halaman ini SATU-SATUNYA tugasnya: relay ke
/// window PARENT (outer app) lewat postMessage, lalu diam — TIDAK render apa pun yang berarti,
/// supaya instance nested ini (kelihatan kecil di dalam kotak iframe) tidak menyesatkan user
/// dengan UI yang salah (mis. layar login).
class SitePlanRelayPage extends StatefulWidget {
  final String? siteplanId;
  final String? companyId;
  final String? productId;
  final String? propertyId;

  const SitePlanRelayPage({
    super.key,
    this.siteplanId,
    this.companyId,
    this.productId,
    this.propertyId,
  });

  @override
  State<SitePlanRelayPage> createState() => _SitePlanRelayPageState();
}

class _SitePlanRelayPageState extends State<SitePlanRelayPage> {
  @override
  void initState() {
    super.initState();
    final siteplanId = widget.siteplanId;
    final companyId = widget.companyId;
    final productId = widget.productId;
    final propertyId = widget.propertyId;
    if (isInsideIframe &&
        siteplanId != null &&
        companyId != null &&
        productId != null &&
        propertyId != null) {
      postPlainUnitParamsToParent(
        siteplanId: siteplanId,
        companyId: companyId,
        productId: productId,
        propertyId: propertyId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
