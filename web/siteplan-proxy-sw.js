// Service Worker — pengganti dart:io HttpServer untuk web.
// Intercept semua request dari iframe site plan dan tambah X-App-Token header.
// Konsep sama dengan mobile local proxy, tapi berjalan di dalam browser.

const SITEPLAN_TOKEN = 'd9f82b7a4c6e11ec94660242ac120002XSitePlan';
const PROXY_SCOPE    = '/siteplan-proxy/';

self.addEventListener('install',  () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // Hanya intercept request dengan prefix /siteplan-proxy/
  const scopeOrigin = self.location.origin + PROXY_SCOPE;
  if (!url.startsWith(scopeOrigin)) return;

  // Ekstrak target URL dari path: /siteplan-proxy/{scheme}/{host}/{path}
  // Format: /siteplan-proxy/http:/dynamics.paradise.id/paradise_api/...
  const suffix      = url.slice(scopeOrigin.length);   // "http:/dynamics.paradise.id/..."
  const targetUrl   = suffix.replace(/^(https?):\/([^/])/, '$1://$2'); // fix double-slash

  event.respondWith(
    fetch(targetUrl, {
      method:      event.request.method,
      headers: {
        'X-App-Token': SITEPLAN_TOKEN,
        'Accept':      event.request.headers.get('Accept') || '*/*',
      },
      // credentials: 'omit' agar tidak kirim cookie kita ke server lain
      credentials: 'omit',
    })
    .then((resp) => {
      // Clone response dan tambah CORS header agar iframe bisa baca konten
      const headers = new Headers(resp.headers);
      headers.set('Access-Control-Allow-Origin', '*');

      return new Response(resp.body, {
        status:     resp.status,
        statusText: resp.statusText,
        headers:    headers,
      });
    })
    .catch(() => new Response('Proxy error', { status: 502 }))
  );
});
