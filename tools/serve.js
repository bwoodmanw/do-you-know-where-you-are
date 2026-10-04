/* tools/serve.js - a tiny static server for public/ (local preview only).
   POST /__save?name=x.png with a data: URL body writes art/reference/x.png
   (used to export the code-drawn reference sheets from a browser). */
var http = require('http'), fs = require('fs'), path = require('path');
var root = path.join(__dirname, '..', 'public'), port = +process.env.PORT || 8790;
var refDir = path.join(__dirname, '..', 'art', 'reference');
var types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json',
  '.png': 'image/png', '.webmanifest': 'application/manifest+json', '.webp': 'image/webp', '.mp3': 'audio/mpeg' };
http.createServer(function (req, res) {
  var p = decodeURIComponent(req.url.split('?')[0]);
  if (req.method === 'POST' && p === '/__save') {
    var name = (req.url.split('name=')[1] || '').replace(/[^a-z0-9_.-]/gi, '');
    if (!/\.png$/.test(name)) { res.writeHead(400); return res.end('name must end .png'); }
    var body = '';
    req.on('data', function (c) { body += c; });
    req.on('end', function () {
      var b64 = body.replace(/^data:image\/png;base64,/, '');
      fs.mkdirSync(refDir, { recursive: true });
      fs.writeFileSync(path.join(refDir, name), Buffer.from(b64, 'base64'));
      res.writeHead(200); res.end('saved ' + name);
    });
    return;
  }
  if (p.slice(-1) === '/') { p += 'index.html'; }
  var f = path.join(root, p);
  if (f.indexOf(root) !== 0) { res.writeHead(403); return res.end(); }
  fs.readFile(f, function (err, data) {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
    res.end(data);
  });
}).listen(port, function () { console.log('serving public/ on http://localhost:' + port + '/'); });
