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

// Handles background / terminated notifications on web
messaging.onBackgroundMessage(function(payload) {
  const title = (payload.notification && payload.notification.title)
    || (payload.data && payload.data.title)
    || 'Paradise Connect';

  const body = (payload.notification && payload.notification.body)
    || (payload.data && payload.data.body)
    || '';

  return self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    requireInteraction: false,
  });
});

// Navigate to the app when notification is clicked
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // Focus existing open tab if found
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if ('focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new tab
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
