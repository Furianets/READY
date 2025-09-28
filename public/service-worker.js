const CACHE_NAME = 'ready-app-v1.0.0';
const urlsToCache = [
  '.',
  'main.dart.js',
  'flutter_service_worker.js',
  'manifest.json',
  'assets/whistle.mp3'
];

self.addEventListener('install', (event) => {
  console.log('Service Worker installing.');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      }
    )
  );
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker activating.');
});