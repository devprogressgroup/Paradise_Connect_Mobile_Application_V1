importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAED1oPCnC4UooAu5E_XhJ6ESi5szeEsdo",
  authDomain: "paradise-connect-mobile-6effd.firebaseapp.com",
  projectId: "paradise-connect-mobile-6effd",
  storageBucket: "paradise-connect-mobile-6effd.firebasestorage.app",
  messagingSenderId: "729428932735",
  appId: "1:729428932735:web:baa1b4577aa0ca01a6274a"
});

const messaging = firebase.messaging();

// Kirim pesan ke semua tab yang sedang terbuka (termasuk yang tidak fokus)
function postToClients(message) {
  return self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
    clientList.forEach(function(client) { client.postMessage(message); });
  });
}

// Handles background / terminated notifications on web
messaging.onBackgroundMessage(function(payload) {
  const title = (payload.notification && payload.notification.title)
    || (payload.data && payload.data.title)
    || 'Paradise Connect';

  const body = (payload.notification && payload.notification.body)
    || (payload.data && payload.data.body)
    || '';

  // Relay ke tab yang sedang terbuka (tapi tidak fokus) supaya notifikasi ini juga
  // tersimpan ke daftar notifikasi di dalam app — tanpa ini, push yang masuk saat
  // tab background cuma tampil sebagai notifikasi OS dan hilang dari list.
  postToClients({ type: 'fcm_background_message', title: title, body: body, data: payload.data || {} });

  return self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    requireInteraction: false,
  });
});

// Resolve target URL based on notification data type
function getTargetUrl(data) {
  const type = data && data.type;
  if (type === 'approval_pending' || type === 'attendance_null_location') {
    return '/attandance/approval';
  }
  if (type === 'attendance') {
    const action = data.action || '';
    if (action === 'clock_out') return '/attandance?initialTab=2';
    if (action === 'checkin_activity') return '/attandance?initialTab=1';
    return '/attandance';
  }
  return '/';
}

// Navigate to the app when notification is clicked
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const data      = event.notification.data || {};
  const targetUrl = getTargetUrl(data);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // Tab Flutter sudah terbuka: cukup fokuskan lalu suruh SPA-nya sendiri yang
      // pindah halaman lewat postMessage. client.navigate() sebelumnya me-reload
      // seluruh app dari nol (itu penyebab notifikasi terasa lambat saat diklik).
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url && 'focus' in client) {
          client.postMessage({ type: 'fcm_notification_click', data: data });
          return client.focus();
        }
      }
      // Tidak ada tab yang terbuka sama sekali: baru buka tab baru ke target URL.
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
