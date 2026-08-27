import 'dart:convert';
import 'dart:html' as html;

/// True kalau PWA ini lagi jalan DI DALAM <iframe> — dipakai deteksi kasus siteplan (docs/
/// site-plan-mobile-pwa.md §16): redirect vendor ke "/siteplan-key" bikin PWA ini boot ULANG
/// nested di dalam iframe siteplan, bukan di outer app.
bool get isInsideIframe {
  try {
    return html.window.parent != html.window;
  } catch (_) {
    return false;
  }
}

/// Relay data unit (Map hasil decrypt, SAMA format dgn parameter `data` SitePlanBlank) ke
/// window PARENT (outer app yang render iframe siteplan) lewat postMessage — supaya outer app
/// bisa render halaman detail unit di navigasi-nya SENDIRI (full-screen, back button benar),
/// bukan nested kecil di dalam kotak iframe. Pola & source tag SAMA seperti bridge script PHP
/// (PropertyController::siteplanBridgeScript()) supaya ditangkap listener yang sudah ada
/// (index_web.dart::_listenSiteplanBridge()).
///
/// `data` di-jsonEncode dulu jadi String (BUKAN dikirim sebagai Map/object JS langsung) —
/// structured-clone postMessage bisa balikin nested map dgn tipe key yang tidak persis
/// `Map<String, dynamic>` di sisi penerima (`LinkedHashMap<Object?, Object?>`), yang bikin cast
/// eksplisit gagal runtime. String + jsonDecode() di penerima jauh lebih aman & konsisten
/// dengan cara `UnitDetail.decryptPayload()` sendiri parse data (jsonDecode selalu balikin
/// `Map<String, dynamic>` bersih, termasuk semua level nested-nya).
void postUnitDetailToParent(Map<String, dynamic> data) {
  try {
    html.window.parent?.postMessage(
      {'source': 'paradiseSiteplan', 'type': 'unitDetailFromBlank', 'payload': jsonEncode(data)},
      '*',
    );
  } catch (_) {}
}

/// Vendor SEKARANG navigasi LANGSUNG ke domain app kita (bukan lewat proxy Laravel lagi —
/// lihat komentar di router.dart), bawa siteplan_id/company_id/product_id/property_id PLAIN
/// (tanpa enkripsi) sebagai query param. PWA ini BOOT ULANG nested di dalam iframe siteplan
/// (persis kasus §16, cuma trigger-nya beda) — relay id-nya ke parent SEBELUM sempat kena gate
/// login/render halaman apa pun, supaya outer app yang urus render halaman detail unit-nya.
void postPlainUnitParamsToParent({
  required String siteplanId,
  required String companyId,
  required String productId,
  required String propertyId,
}) {
  try {
    html.window.parent?.postMessage(
      {
        'source': 'paradiseSiteplan',
        'type': 'unitDetailPlainParams',
        'payload': {
          'siteplan_id': siteplanId,
          'company_id': companyId,
          'product_id': productId,
          'property_id': propertyId,
        },
      },
      '*',
    );
  } catch (_) {}
}
