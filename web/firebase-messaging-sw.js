// Background FCM service worker for Taheri Committee web app.
// Receives push payloads while the page is closed/background and shows
// a system notification.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBFWm20LDY-Wp6vmFHLzZi9nW_q9nvy6fY',
  authDomain: 'taheri-committee-app.firebaseapp.com',
  projectId: 'taheri-committee-app',
  storageBucket: 'taheri-committee-app.firebasestorage.app',
  messagingSenderId: '919937026676',
  appId: '1:919937026676:web:2c5cb3e06a34d2f5ad1f21',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.title || 'Taheri Committee';
  const isHighPriority =
    data.requiresResponse === 'true' ||
    data.type === 'event_rsvp' ||
    data.type === 'announcement' ||
    data.type === 'auth_audit';
  const options = {
    body: notification.body || data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    image: data.image || undefined,
    data: data,
    // Stay on screen until user interacts (Chrome supports this).
    requireInteraction: isHighPriority,
    // Re-show even if a notif with the same tag already exists, and play
    // the OS notification sound again.
    renotify: true,
    silent: false,
    // Vibrate on mobile Chrome (ignored on desktop). Pattern in ms.
    vibrate: [200, 100, 200],
    // Group same-type notifications together.
    tag: data.type
      ? `taheri-${data.type}-${data.eventId || data.announcementId || data.contribId || data.transferId || Date.now()}`
      : `taheri-${Date.now()}`,
    timestamp: Date.now(),
  };
  if (data.requiresResponse === 'true') {
    options.actions = [
      { action: 'respond', title: 'Respond' },
      { action: 'dismiss', title: 'Dismiss' },
    ];
  }
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  let target = '/';
  switch (data.type) {
    case 'event_rsvp':
      target = '/events/detail';
      break;
    case 'announcement':
      target = '/announcements';
      break;
    case 'contribution':
      target = '/contributions/mine';
      break;
    case 'transfer':
      target = '/transfers/raise';
      break;
    default:
      target = '/notifications';
  }
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((wins) => {
      for (const w of wins) {
        if ('focus' in w) {
          w.focus();
          return w.navigate ? w.navigate(target) : null;
        }
      }
      return clients.openWindow(target);
    }),
  );
});
