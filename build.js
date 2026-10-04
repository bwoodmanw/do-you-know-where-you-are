/* build.js - inlines rules, rooms and game into one public/index.html,
   stamps the build id, and refuses code that is not ES5-style.
   Run: node build.js */
var fs = require('fs');
var path = require('path');
var cp = require('child_process');

var root = __dirname;
function read(p) { return fs.readFileSync(path.join(root, p), 'utf8'); }
function write(p, s) {
  var full = path.join(root, p);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full + '.tmp', s);
  fs.renameSync(full + '.tmp', full);
}

var hash = 'nogit';
try { hash = cp.execSync('git rev-parse --short HEAD', { cwd: root }).toString().trim(); } catch (e) { /* no commits */ }
var stamp = new Date().toISOString().replace(/[-:]/g, '').slice(0, 13);
var BUILD = stamp + '-' + hash;

// ES5 guard: older Silk. Strips strings and comments before looking.
function es5Check(name, src) {
  var code = src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/[^\n]*/g, '')
    .replace(/'(?:\\.|[^'\\\n])*'/g, "''")
    .replace(/"(?:\\.|[^"\\\n])*"/g, '""');
  var bad = [[/=>/, 'arrow function'], [/`/, 'template literal'], [/\blet\s/, 'let'], [/\bconst\s/, 'const'],
    [/\bclass\s+[A-Z]/, 'class'], [/\?\./, 'optional chaining'], [/\?\?/, 'nullish ??']];
  var problems = [];
  bad.forEach(function (b) {
    var m = code.match(b[0]);
    if (m) { problems.push(b[1]); }
  });
  if (problems.length) { throw new Error(name + ' is not ES5-style: ' + problems.join(', ')); }
}

var files = { RULES: 'src/rules.js', ROOMS: 'src/rooms.js', GAME: 'src/game.js' };
var html = read('src/shell.html');
Object.keys(files).forEach(function (k) {
  var src = read(files[k]);
  es5Check(files[k], src);
  var anchor = '/*' + k + '*/';
  if (html.indexOf(anchor) < 0) { throw new Error('shell.html is missing ' + anchor); }
  if (src.indexOf('</script') >= 0) { throw new Error(files[k] + ' contains </script'); }
  html = html.split(anchor).join(src);
});
html = html.split('__BUILD__').join(BUILD);
var sw = read('src/sw.js');
es5Check('src/sw.js', sw);
sw = sw.split('__BUILD__').join(BUILD);

write('public/index.html', html);
write('public/sw.js', sw);
write('public/manifest.webmanifest', read('src/manifest.webmanifest'));
write('public/build-id.json', JSON.stringify({ build: BUILD }) + '\n');
['icon-192.png', 'icon-512.png', 'icon-maskable-512.png'].forEach(function (f) {
  var src = path.join(root, 'icons', f);
  if (!fs.existsSync(src)) { throw new Error('missing icons/' + f + ' - run python tools/make_icons.py'); }
  fs.mkdirSync(path.join(root, 'public/icons'), { recursive: true });
  fs.copyFileSync(src, path.join(root, 'public/icons', f));
});
console.log('built ' + BUILD + '  index.html ' + Math.round(html.length / 1024) + ' KB');
