/* tools/serve.js - a tiny static server for public/ (local preview only). */
var http = require('http'), fs = require('fs'), path = require('path');
var root = path.join(__dirname, '..', 'public'), port = +process.env.PORT || 8790;
var types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json',
  '.png': 'image/png', '.webmanifest': 'application/manifest+json', '.webp': 'image/webp', '.mp3': 'audio/mpeg' };
http.createServer(function (req, res) {
  var p = decodeURIComponent(req.url.split('?')[0]);
  if (p.slice(-1) === '/') { p += 'index.html'; }
  var f = path.join(root, p);
  if (f.indexOf(root) !== 0) { res.writeHead(403); return res.end(); }
  fs.readFile(f, function (err, data) {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
    res.end(data);
  });
}).listen(port, function () { console.log('serving public/ on http://localhost:' + port + '/'); });
