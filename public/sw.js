/* sw.js - offline support. A versioned shell cache (the page, manifest,
   icons) and a separate unversioned art cache, so a code change never
   re-downloads the art. The shell is stale-while-revalidate: an update
   reaches a tablet one launch late. */
var BUILD = '20261005T1037-94db879';
var SHELL = 'dykwya-shell-' + BUILD;
var ART = 'dykwya-art';
var SHELL_FILES = ['./', 'manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png'];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(SHELL).then(function (c) { return c.addAll(SHELL_FILES); }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (ks) {
    return Promise.all(ks.map(function (k) {
      if (k.indexOf('dykwya-shell-') === 0 && k !== SHELL) { return caches.delete(k); }
    }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener('fetch', function (e) {
  var req = e.request, url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== self.location.origin) { return; }
  if (url.pathname.indexOf('/ws') === 0 || url.search.indexOf('fresh=1') >= 0) { return; }
  if (url.pathname.indexOf('/art/') >= 0) {
    // art: cache first, kept across versions
    e.respondWith(caches.open(ART).then(function (c) {
      return c.match(req).then(function (hit) {
        return hit || fetch(req).then(function (res) { if (res.ok) { c.put(req, res.clone()); } return res; });
      });
    }));
    return;
  }
  // shell: stale-while-revalidate; navigations all map to './'
  var key = req.mode === 'navigate' ? './' : req;
  e.respondWith(caches.open(SHELL).then(function (c) {
    return c.match(key).then(function (hit) {
      var net = fetch(req).then(function (res) {
        if (res.ok && res.type === 'basic') { c.put(key, res.clone()); }
        return res;
      });
      if (hit) { net.catch(function () { /* offline */ }); return hit; }
      return net;
    });
  }));
});
