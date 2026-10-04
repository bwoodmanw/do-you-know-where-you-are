/* game.js - screens, drawing, input, sound, saving and the Check screen.
   ES5 only (older Silk): var, function, no arrows, classes or template literals. */
(function () {
  'use strict';

  var BUILD = '__BUILD__';
  var KEY = 'dykwya.';
  var SHELL_CACHE = 'dykwya-shell-' + BUILD;
  var ART_CACHE = 'dykwya-art';

  function $(id) { return document.getElementById(id); }
  function load(k, d) {
    try { var v = localStorage.getItem(KEY + k); return v ? JSON.parse(v) : d; } catch (e) { return d; }
  }
  function save(k, v) {
    try { localStorage.setItem(KEY + k, JSON.stringify(v)); return true; } catch (e) { return false; }
  }
  function show(id) {
    var s = document.querySelectorAll('.screen'), i;
    for (i = 0; i < s.length; i++) { s[i].className = 'screen' + (s[i].id === id ? ' on' : ''); }
  }

  // ---- ?fresh=1 empties everything and reloads a clean copy ----
  if (/[?&]fresh=1/.test(location.search)) {
    var jobs = [];
    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
      jobs.push(navigator.serviceWorker.getRegistrations().then(function (rs) {
        return Promise.all(rs.map(function (r) { return r.unregister(); }));
      }));
    }
    if (window.caches) {
      jobs.push(caches.keys().then(function (ks) {
        return Promise.all(ks.map(function (k) { return caches.delete(k); }));
      }));
    }
    Promise.all(jobs).then(function () { location.replace(location.pathname); },
      function () { location.replace(location.pathname); });
    return;
  }

  // ---- characters ----
  var CHARS = {
    tinker: { name: 'Tinker', skill: 'Picks locks', badge: '🔧',
      look: { body: '#f28c28', outfit: '#3b6fd8', eyes: 'goggles', hat: 'cap', hatColor: '#3b6fd8' } },
    shadow: { name: 'Shadow', skill: 'Hard to spot', badge: '🌙',
      look: { body: '#8a6bd1', outfit: '#2b2140', eyes: 'sleepy', hat: 'mask', hatColor: '#221a33' } },
    brainy: { name: 'Brainy', skill: 'Cracks codes', badge: '🧠',
      look: { body: '#4fb3e8', outfit: '#f2f2f2', eyes: 'glasses', hat: 'propeller', hatColor: '#e8423f' } },
    muscle: { name: 'Muscle', skill: 'Shoves heavy things', badge: '💪',
      look: { body: '#e8505b', outfit: '#3d3d3d', eyes: 'fierce', hat: 'headband', hatColor: '#ffd23f' } },
    glow: { name: 'Glow', skill: 'Lights up secrets', badge: '💡',
      look: { body: '#b8e05a', outfit: '#3a7d44', eyes: 'big', hat: 'antenna', hatColor: '#fff27a' } }
  };
  var ORDER = ['tinker', 'shadow', 'brainy', 'muscle', 'glow'];
  var COLOR_HEX = { red: '#ff4d5e', blue: '#3d8bff', yellow: '#ffd23f', green: '#46d160' };
  var COLOR_WORD = { red: 'RED', blue: 'BLUE', yellow: 'YELLOW', green: 'GREEN' };

  // ---- drawing helpers ----
  function rr(g, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    g.beginPath();
    g.moveTo(x + r, y);
    g.arcTo(x + w, y, x + w, y + h, r);
    g.arcTo(x + w, y + h, x, y + h, r);
    g.arcTo(x, y + h, x, y, r);
    g.arcTo(x, y, x + w, y, r);
    g.closePath();
  }
  function ell(g, x, y, rx, ry) {
    g.beginPath();
    g.save(); g.translate(x, y); g.scale(rx, ry); g.arc(0, 0, 1, 0, Math.PI * 2); g.restore();
  }
  function circ(g, x, y, r, fill) { g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fillStyle = fill; g.fill(); }

  // A character with its feet at (cx, cy); s is one cell.
  function drawChar(g, cx, cy, s, key, o) {
    o = o || {};
    var L = CHARS[key].look, t = o.t || 0;
    var bob = o.moving ? Math.abs(Math.sin(t * 14)) * s * 0.07 : Math.sin(t * 2.2) * s * 0.015;
    var w = s * 0.74, h = s * 0.84, x = cx, y = cy - bob, top = y - h, left = x - w / 2;
    var ey = top + h * 0.4, ex = w * 0.2, er = s * 0.11, look = (o.look || 0) * er * 0.35, i;
    g.save();
    if (o.alpha !== undefined) { g.globalAlpha = o.alpha; }
    g.fillStyle = 'rgba(0,0,0,.35)'; ell(g, cx, cy, w * 0.46, s * 0.08); g.fill();
    if (o.selected) {
      g.strokeStyle = '#7be36b'; g.lineWidth = Math.max(2, s * 0.06);
      ell(g, cx, cy, w * 0.62, s * 0.14); g.stroke();
    }
    // body + outfit
    rr(g, left, top, w, h, w * 0.44);
    g.fillStyle = L.body; g.fill();
    g.save(); rr(g, left, top, w, h, w * 0.44); g.clip();
    g.fillStyle = L.outfit; g.fillRect(left, top + h * 0.68, w, h * 0.4);
    g.fillStyle = 'rgba(255,255,255,.18)'; ell(g, x - w * 0.18, top + h * 0.22, w * 0.16, h * 0.1); g.fill();
    g.restore();
    // feet
    g.fillStyle = '#2a1d1d';
    ell(g, x - w * 0.2, cy - s * 0.02, w * 0.16, s * 0.06); g.fill();
    ell(g, x + w * 0.2, cy - s * 0.02, w * 0.16, s * 0.06); g.fill();
    // things behind the eyes
    if (L.hat === 'mask') {
      g.fillStyle = L.hatColor; g.fillRect(left - s * 0.02, ey - er * 1.3, w + s * 0.04, er * 2.6);
      g.beginPath(); g.moveTo(left + w, ey - er * 0.6); g.lineTo(left + w + s * 0.2, ey - er * 1.6 + Math.sin(t * 5) * 3);
      g.lineTo(left + w + s * 0.18, ey + er * 0.2); g.closePath(); g.fill();
    }
    if (L.hat === 'headband') {
      g.fillStyle = L.hatColor; g.fillRect(left + w * 0.02, top + h * 0.13, w * 0.96, h * 0.1);
      g.beginPath(); g.moveTo(left + w * 0.05, top + h * 0.17); g.lineTo(left - s * 0.14, top + h * 0.3 + Math.sin(t * 6) * 2);
      g.lineTo(left - s * 0.08, top + h * 0.12); g.closePath(); g.fill();
    }
    // eyes
    for (i = -1; i <= 1; i += 2) {
      var px = x + i * ex;
      if (L.eyes === 'goggles') {
        circ(g, px, ey, er * 1.45, '#7a4a1e');
        circ(g, px, ey, er * 1.1, '#cfefff');
      } else {
        circ(g, px, ey, L.eyes === 'big' ? er * 1.35 : er, '#ffffff');
      }
      if (o.scared) {
        circ(g, px, ey, er * 0.35, '#111');
      } else {
        circ(g, px + look, ey + er * 0.1, (L.eyes === 'big' ? er * 0.7 : er * 0.55), '#111');
        circ(g, px + look - er * 0.2, ey - er * 0.2, er * 0.18, '#fff');
      }
      if (L.eyes === 'sleepy') {
        g.fillStyle = L.body; g.fillRect(px - er * 1.1, ey - er * 1.2, er * 2.2, er * 1.05);
        g.strokeStyle = '#111'; g.lineWidth = Math.max(1, s * 0.025);
        g.beginPath(); g.moveTo(px - er, ey - er * 0.15); g.lineTo(px + er, ey - er * 0.15); g.stroke();
      }
      if (L.eyes === 'glasses') {
        g.strokeStyle = '#111'; g.lineWidth = Math.max(1.5, s * 0.035);
        g.beginPath(); g.arc(px, ey, er * 1.35, 0, Math.PI * 2); g.stroke();
      }
      if (L.eyes === 'fierce') {
        g.strokeStyle = '#3a1010'; g.lineWidth = Math.max(2, s * 0.05);
        g.beginPath(); g.moveTo(px - i * er * 1.2, ey - er * 1.5); g.lineTo(px + i * er * 0.9, ey - er * 1.0); g.stroke();
      }
    }
    if (L.eyes === 'glasses') {
      g.beginPath(); g.moveTo(x - ex + er * 1.35, ey); g.lineTo(x + ex - er * 1.35, ey); g.stroke();
    }
    if (L.eyes === 'goggles') {
      g.fillStyle = '#7a4a1e'; g.fillRect(left, ey - er * 0.3, w * 0.08, er * 0.6); g.fillRect(left + w * 0.92, ey - er * 0.3, w * 0.08, er * 0.6);
    }
    // mouth
    g.strokeStyle = '#3a1010'; g.lineWidth = Math.max(1.5, s * 0.035); g.lineCap = 'round';
    if (o.scared) {
      g.fillStyle = '#3a1010'; ell(g, x, top + h * 0.62, s * 0.06, s * 0.08); g.fill();
    } else {
      g.beginPath(); g.arc(x, top + h * 0.55, s * 0.1, 0.15 * Math.PI, 0.85 * Math.PI); g.stroke();
    }
    // hats on top
    if (L.hat === 'cap') {
      g.fillStyle = L.hatColor;
      g.beginPath(); g.arc(x, top + h * 0.14, w * 0.36, Math.PI, 0); g.closePath(); g.fill();
      g.fillRect(x, top + h * 0.11, w * 0.5, h * 0.06);
      circ(g, x, top + h * 0.14 - w * 0.36, s * 0.035, '#ffd23f');
    } else if (L.hat === 'propeller') {
      g.fillStyle = L.hatColor;
      g.beginPath(); g.arc(x, top + h * 0.12, w * 0.3, Math.PI, 0); g.closePath(); g.fill();
      g.fillStyle = '#ffd23f'; g.fillRect(x - s * 0.015, top + h * 0.12 - w * 0.3 - s * 0.08, s * 0.03, s * 0.08);
      var pw = Math.cos(t * 9) * s * 0.2;
      g.fillStyle = '#3d8bff'; ell(g, x, top + h * 0.12 - w * 0.3 - s * 0.08, Math.abs(pw) + 1, s * 0.035); g.fill();
    } else if (L.hat === 'antenna') {
      g.strokeStyle = '#2a4d2f'; g.lineWidth = Math.max(1.5, s * 0.03);
      g.beginPath(); g.moveTo(x, top + h * 0.04); g.quadraticCurveTo(x + s * 0.1, top - s * 0.12, x + s * 0.04, top - s * 0.2); g.stroke();
      var glow = 0.6 + 0.4 * Math.sin(t * 4);
      circ(g, x + s * 0.04, top - s * 0.22, s * 0.11, 'rgba(255,242,122,' + (0.25 * glow) + ')');
      circ(g, x + s * 0.04, top - s * 0.22, s * 0.06, L.hatColor);
    }
    g.restore();
  }

  // The party host: tall, pumpkin mask, party hat. Feet at (cx, cy).
  function drawCreature(g, cx, cy, s, o) {
    o = o || {};
    var t = o.t || 0, hunt = o.mode === 'hunt', H = s * 1.75, step = o.moving ? Math.sin(t * 10) * s * 0.06 : 0;
    var hy = cy - H + s * 0.38, hr = s * 0.38, i;
    g.save();
    g.fillStyle = 'rgba(0,0,0,.4)'; ell(g, cx, cy, s * 0.42, s * 0.1); g.fill();
    // legs
    g.fillStyle = '#16121d';
    g.fillRect(cx - s * 0.2, cy - s * 0.62 + step, s * 0.14, s * 0.62 - step);
    g.fillRect(cx + s * 0.06, cy - s * 0.62 - step, s * 0.14, s * 0.62 + step);
    // suit
    g.fillStyle = '#2d2438';
    g.beginPath();
    g.moveTo(cx - s * 0.24, hy + hr * 0.7); g.lineTo(cx + s * 0.24, hy + hr * 0.7);
    g.lineTo(cx + s * 0.34, cy - s * 0.55); g.lineTo(cx - s * 0.34, cy - s * 0.55); g.closePath(); g.fill();
    g.fillStyle = '#f1e6d0';
    g.beginPath(); g.moveTo(cx - s * 0.08, hy + hr * 0.75); g.lineTo(cx + s * 0.08, hy + hr * 0.75); g.lineTo(cx, hy + hr * 0.75 + s * 0.3); g.closePath(); g.fill();
    g.fillStyle = '#8a3fd1';
    g.beginPath(); g.moveTo(cx, hy + hr * 0.85); g.lineTo(cx - s * 0.1, hy + hr * 0.75); g.lineTo(cx - s * 0.1, hy + hr * 0.95); g.closePath(); g.fill();
    g.beginPath(); g.moveTo(cx, hy + hr * 0.85); g.lineTo(cx + s * 0.1, hy + hr * 0.75); g.lineTo(cx + s * 0.1, hy + hr * 0.95); g.closePath(); g.fill();
    // long arms, white gloves
    var reach = hunt ? s * 0.2 : 0;
    g.strokeStyle = '#2d2438'; g.lineWidth = s * 0.09; g.lineCap = 'round';
    g.beginPath(); g.moveTo(cx - s * 0.24, hy + hr * 0.9); g.lineTo(cx - s * 0.42 - reach, cy - s * 0.75 - reach); g.stroke();
    g.beginPath(); g.moveTo(cx + s * 0.24, hy + hr * 0.9); g.lineTo(cx + s * 0.42 + reach, cy - s * 0.75 - reach); g.stroke();
    circ(g, cx - s * 0.42 - reach, cy - s * 0.75 - reach, s * 0.08, '#f4f4f4');
    circ(g, cx + s * 0.42 + reach, cy - s * 0.75 - reach, s * 0.08, '#f4f4f4');
    // pumpkin head with ridges
    var grd = g.createRadialGradient(cx - hr * 0.3, hy - hr * 0.3, hr * 0.2, cx, hy, hr * 1.1);
    grd.addColorStop(0, '#ffb04d'); grd.addColorStop(1, '#d9600b');
    g.fillStyle = grd; ell(g, cx, hy, hr * 1.12, hr); g.fill();
    g.strokeStyle = 'rgba(120,45,0,.55)'; g.lineWidth = Math.max(1, s * 0.025);
    for (i = -1; i <= 1; i += 2) { ell(g, cx, hy, hr * 0.5, hr * 0.98); g.stroke(); ell(g, cx + i * 0.01, hy, hr * 0.85, hr * 0.99); g.stroke(); }
    // melting drips
    g.fillStyle = '#e8700f';
    for (i = 0; i < 3; i++) {
      var dx = cx + (i - 1) * hr * 0.6, dl = hr * (0.25 + 0.15 * ((Math.sin(t * 1.3 + i * 2) + 1) / 2));
      rr(g, dx - s * 0.022, hy + hr * 0.78, s * 0.044, dl, s * 0.022); g.fill();
    }
    // face
    var eye = hunt ? '#ff3b30' : '#ffe14d';
    g.fillStyle = eye;
    g.shadowColor = eye; g.shadowBlur = s * 0.25;
    for (i = -1; i <= 1; i += 2) {
      g.beginPath();
      g.moveTo(cx + i * hr * 0.42, hy - hr * 0.42);
      g.lineTo(cx + i * hr * 0.66, hy - hr * 0.02);
      g.lineTo(cx + i * hr * 0.18, hy - hr * 0.02);
      g.closePath(); g.fill();
    }
    g.beginPath();
    g.moveTo(cx - hr * 0.6, hy + hr * 0.22);
    for (i = 0; i <= 6; i++) { g.lineTo(cx - hr * 0.6 + i * hr * 0.2, hy + hr * (i % 2 ? 0.36 : 0.5)); }
    g.lineTo(cx + hr * 0.6, hy + hr * 0.22);
    g.lineTo(cx, hy + hr * 0.32);
    g.closePath(); g.fill();
    g.shadowBlur = 0;
    // stem + party hat, tilted
    g.fillStyle = '#4a7a2a'; g.fillRect(cx - s * 0.03, hy - hr - s * 0.06, s * 0.06, s * 0.08);
    g.save(); g.translate(cx + hr * 0.45, hy - hr * 0.78); g.rotate(0.45 + (o.stunned ? Math.sin(t * 20) * 0.3 : 0));
    g.fillStyle = '#7be36b';
    g.beginPath(); g.moveTo(-s * 0.13, 0); g.lineTo(s * 0.13, 0); g.lineTo(0, -s * 0.38); g.closePath(); g.fill();
    g.strokeStyle = '#ff4d5e'; g.lineWidth = s * 0.035;
    g.beginPath(); g.moveTo(-s * 0.09, -s * 0.1); g.lineTo(s * 0.07, -s * 0.16); g.stroke();
    g.beginPath(); g.moveTo(-s * 0.05, -s * 0.22); g.lineTo(s * 0.04, -s * 0.26); g.stroke();
    circ(g, 0, -s * 0.39, s * 0.05, '#ffd23f');
    g.restore();
    g.restore();
  }

  function portrait(cv, key) {
    var g = cv.getContext('2d'), s = cv.width;
    g.clearRect(0, 0, cv.width, cv.height);
    if (key === 'creature') {
      drawCreature(g, s * 0.5, s * 1.55, s * 0.9, { t: 0 });
    } else {
      drawChar(g, s * 0.5, s * 0.94, s * 0.8, key, { t: 0 });
    }
  }

  // ---- sound (Web Audio, synthesised) ----
  var AC = null, master = null;
  function audio() {
    if (!AC) {
      var C = window.AudioContext || window.webkitAudioContext;
      if (C) {
        try { AC = new C(); master = AC.createGain(); master.gain.value = 0.7; master.connect(AC.destination); } catch (e) { AC = null; }
      }
    }
    if (AC && AC.state === 'suspended' && AC.resume) { AC.resume(); }
    return AC;
  }
  function tone(f, dur, type, vol, f2, delay) {
    var a = audio(); if (!a) { return; }
    var t0 = a.currentTime + (delay || 0), o = a.createOscillator(), gn = a.createGain();
    o.type = type || 'sine';
    o.frequency.setValueAtTime(f, t0);
    if (f2) { o.frequency.exponentialRampToValueAtTime(f2, t0 + dur); }
    gn.gain.setValueAtTime(0.0001, t0);
    gn.gain.exponentialRampToValueAtTime(vol || 0.3, t0 + 0.01);
    gn.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(gn); gn.connect(master);
    o.start(t0); o.stop(t0 + dur + 0.05);
  }
  var noiseBuf = null;
  function noise(dur, vol, freq, delay, q) {
    var a = audio(); if (!a) { return; }
    var i, d, t0 = a.currentTime + (delay || 0);
    if (!noiseBuf) {
      noiseBuf = a.createBuffer(1, a.sampleRate, a.sampleRate);
      d = noiseBuf.getChannelData(0);
      for (i = 0; i < d.length; i++) { d[i] = Math.random() * 2 - 1; }
    }
    var src = a.createBufferSource(), f = a.createBiquadFilter(), gn = a.createGain();
    src.buffer = noiseBuf;
    f.type = 'bandpass'; f.frequency.value = freq || 1000; f.Q.value = q || 1;
    gn.gain.setValueAtTime(vol || 0.3, t0);
    gn.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(f); f.connect(gn); gn.connect(master);
    src.start(t0); src.stop(t0 + dur + 0.05);
  }
  var SFX = {
    click: function () { tone(660, 0.06, 'square', 0.08); },
    step: function (v) { noise(0.12, 0.05 + 0.25 * v, 140, 0, 2); tone(70, 0.12, 'sine', 0.05 + 0.2 * v); },
    heart: function () { tone(58, 0.12, 'sine', 0.35); tone(52, 0.14, 'sine', 0.28, 0, 0.18); },
    pop: function () { noise(0.15, 0.6, 2200, 0, 0.8); tone(900, 0.08, 'triangle', 0.2, 300); },
    stinger: function () { noise(0.9, 0.5, 600, 0, 0.5); tone(220, 0.9, 'sawtooth', 0.25, 55); tone(233, 0.9, 'sawtooth', 0.2, 58); },
    boing: function () { tone(180, 0.35, 'triangle', 0.35, 720); tone(720, 0.25, 'triangle', 0.2, 240, 0.3); },
    clank: function () { tone(140, 0.4, 'square', 0.18, 90); noise(0.3, 0.3, 3000, 0, 6); },
    chime: function () { tone(784, 0.25, 'triangle', 0.25); tone(988, 0.25, 'triangle', 0.25, 0, 0.1); tone(1318, 0.4, 'triangle', 0.25, 0, 0.2); },
    cheer: function () { var n = [523, 659, 784, 1046], i; for (i = 0; i < 4; i++) { tone(n[i], 0.22, 'square', 0.1, 0, i * 0.09); } },
    buzz: function () { tone(110, 0.45, 'sawtooth', 0.25); tone(116, 0.45, 'sawtooth', 0.2); },
    sparkle: function () { var i; for (i = 0; i < 5; i++) { tone(1200 + i * 220, 0.12, 'sine', 0.12, 0, i * 0.05); } },
    press: function (c) { tone({ red: 392, blue: 494, yellow: 587, green: 698 }[c] || 500, 0.15, 'square', 0.12); },
    laugh: function () { var i; for (i = 0; i < 4; i++) { tone(300 - i * 20, 0.1, 'sawtooth', 0.12, 240 - i * 20, i * 0.13); } }
  };
  document.addEventListener('pointerdown', function () { audio(); }, true);

  // ---- saving ----
  var prog = load('save', null) || { points: 0, xp: {}, runs: 0, wins: 0 };
  function saveProgress() { save('save', prog); }

  // ---- title ----
  (function () {
    var t = 'Do You Know Where You Are?', h = '', i;
    for (i = 0; i < t.length; i++) {
      h += t.charAt(i) === ' ' ? ' ' : '<span style="animation-delay:' + (i * 0.08).toFixed(2) + 's">' + t.charAt(i) + '</span>';
    }
    $('ttl').innerHTML = h;
  })();
  function drawTitle() {
    var cv = $('tcv'), g = cv.getContext('2d'), now = Date.now() / 1000;
    g.clearRect(0, 0, cv.width, cv.height);
    g.fillStyle = '#ffe9a8'; circ(g, 410, 50, 26, '#ffe9a8');
    g.fillStyle = '#1a1026'; circ(g, 398, 44, 22, '#2a1a3d');
    // the house at the end of the lane
    g.fillStyle = '#120a1b';
    g.fillRect(150, 120, 180, 150);
    g.beginPath(); g.moveTo(135, 125); g.lineTo(240, 50); g.lineTo(345, 125); g.closePath(); g.fill();
    g.fillStyle = '#ffd23f'; g.fillRect(180, 160, 30, 34); g.fillRect(270, 160, 30, 34);
    g.fillStyle = '#ff8a1f'; g.fillRect(222, 205, 36, 65);
    circ(g, 160, 128, 10, '#ff4d5e'); circ(g, 172, 118, 10, '#3d8bff'); circ(g, 184, 128, 10, '#ffd23f');
    drawChar(g, 70, 290, 90, 'tinker', { t: now });
    drawChar(g, 120, 292, 70, 'brainy', { t: now + 1 });
    var peek = 30 + Math.max(0, Math.sin(now * 0.8)) * 60;
    g.save(); g.beginPath(); g.rect(330, 0, 150, 300); g.clip();
    drawCreature(g, 480 - peek, 300, 110, { t: now });
    g.restore();
  }
  $('totPts').textContent = prog.points ? ('⭐ ' + prog.points + ' points saved') : '';

  // ---- squad picker ----
  var picked = load('squad', ['tinker', 'brainy', 'muscle']), spook = load('spook', 'giggly');
  function buildCards() {
    var box = $('cards'), i;
    box.innerHTML = '';
    for (i = 0; i < ORDER.length; i++) {
      (function (key) {
        var d = document.createElement('button'), cv = document.createElement('canvas');
        d.className = 'card'; cv.width = 192; cv.height = 192;
        d.innerHTML = '<span class="num"></span>';
        d.appendChild(cv);
        d.insertAdjacentHTML('beforeend', '<b>' + CHARS[key].badge + ' ' + CHARS[key].name + '</b><i>' + CHARS[key].skill + '</i>');
        portrait(cv, key);
        d.onclick = function () {
          var at = picked.indexOf(key);
          if (at >= 0) { picked.splice(at, 1); } else if (picked.length < 3) { picked.push(key); }
          SFX.click(); paintCards();
        };
        d.setAttribute('data-k', key);
        box.appendChild(d);
      })(ORDER[i]);
    }
    paintCards();
  }
  function paintCards() {
    var cs = $('cards').children, i, k, at;
    for (i = 0; i < cs.length; i++) {
      k = cs[i].getAttribute('data-k'); at = picked.indexOf(k);
      cs[i].className = 'card' + (at >= 0 ? ' pick' : '');
      cs[i].firstChild.textContent = at >= 0 ? (at + 1) : '';
    }
    $('bStart').disabled = picked.length === 0;
    $('tGiggly').className = 'toggle' + (spook === 'giggly' ? ' on' : '');
    $('tSpooky').className = 'toggle' + (spook === 'spooky' ? ' on' : '');
  }
  $('tGiggly').onclick = function () { spook = 'giggly'; SFX.boing(); paintCards(); };
  $('tSpooky').onclick = function () { spook = 'spooky'; SFX.stinger(); paintCards(); };

  // ---- the game ----
  var T = null, S = null, room = null, sel = null, lastEv = 0, cell = 40, W = 0, H = 0, dpr = 1;
  var cv = $('cv'), g = cv.getContext('2d'), bg = document.createElement('canvas'), dark = document.createElement('canvas');
  var rp = {}, kp = null, parts = [], shake = 0, lastTap = { t: 0, x: -9, y: -9 }, hintEl = null, banked = false;
  var lastStepKey = '', lastHeart = 0, gameOn = false;

  function LocalTransport(state) {
    var st = state, fns = [], timer = null, last = 0, acc = 0;
    function emit() { var i; for (i = 0; i < fns.length; i++) { fns[i](st); } }
    return {
      send: function (m) { st = Rules.apply(st, m); emit(); },
      onState: function (f) { fns.push(f); f(st); },
      start: function () {
        if (timer) { return; }
        last = Date.now(); acc = 0;
        timer = setInterval(function () {
          var now = Date.now(), n = 0;
          acc += now - last; last = now;
          while (acc >= 100 && n < 5) { st = Rules.tick(st); acc -= 100; n++; }
          if (acc > 500) { acc = 0; }
          if (n) { emit(); }
        }, 50);
      },
      stop: function () { if (timer) { clearInterval(timer); timer = null; } }
    };
  }

  function startGame() {
    var squad = [], i;
    for (i = 0; i < picked.length; i++) { squad.push({ id: 'c' + i, char: picked[i], owner: 'me' }); }
    save('squad', picked); save('spook', spook);
    var st = Rules.init({ room: 'hall', squad: squad, seed: (Date.now() & 0x7fffffff) || 1, spook: spook });
    room = Rules.getRoom('hall');
    if (T) { T.stop(); }
    T = LocalTransport(st);
    S = st; lastEv = st.evn; sel = 'c0'; rp = {}; kp = null; parts = []; banked = false;
    $('rname').textContent = room.name;
    $('over').style.display = 'none';
    buildBar();
    show('game');
    layout();
    T.onState(onState);
    T.start();
    gameOn = true;
  }

  function buildBar() {
    var bar = $('bar'), i, c;
    bar.innerHTML = '';
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      (function (id, key) {
        var b = document.createElement('button'), pv = document.createElement('canvas');
        b.className = 'sq'; b.id = 'sq_' + id; pv.width = 104; pv.height = 104;
        b.appendChild(pv); portrait(pv, key);
        b.insertAdjacentHTML('beforeend', '<div class="info"><div class="nm">' + CHARS[key].name + ' <span class="stt"></span></div>' +
          '<div class="meter st"><i></i></div><div class="meter en"><i></i></div></div>');
        b.onclick = function () {
          var ch = Rules.charById(S, id);
          if (ch && !ch.caged && !ch.escaped) { sel = id; SFX.click(); paintBar(); }
        };
        bar.appendChild(b);
      })(c.id, c.char);
    }
  }
  function paintBar() {
    var i, c, b, m;
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i]; b = $('sq_' + c.id); if (!b) { continue; }
      b.className = 'sq' + (c.id === sel ? ' sel' : '');
      m = b.querySelectorAll('.meter i');
      m[0].style.width = Math.round(c.stamina) + '%';
      m[0].style.background = c.tired ? '#ff4d5e' : '';
      m[1].style.width = Math.round(c.energy) + '%';
      b.querySelector('.stt').textContent = c.escaped ? '✅' : c.caged ? '🔒' : c.hidden ? '🙈' : (c.shield ? '🛡️' : '') + (S.tick < c.freeRunUntil ? '🍬' : '');
    }
    $('bClue').textContent = '💡 Clue (' + S.cluesLeft + ')';
    $('bClue').disabled = S.cluesLeft <= 0;
  }

  function layout() {
    var st = $('stage'), w = st.clientWidth, h = st.clientHeight;
    if (!room || !w || !h) { return; }
    cell = Math.floor(Math.min(w / room.w, h / room.h));
    W = cell * room.w; H = cell * room.h;
    dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.width = Math.round(W * dpr); cv.height = Math.round(H * dpr);
    cv.style.width = W + 'px'; cv.style.height = H + 'px';
    cv.style.left = Math.floor((w - W) / 2) + 'px'; cv.style.top = Math.floor((h - H) / 2) + 'px';
    bg.width = cv.width; bg.height = cv.height;
    dark.width = cv.width; dark.height = cv.height;
    drawBg();
  }
  window.addEventListener('resize', function () { layout(); });

  // static floor, walls and table
  function drawBg() {
    var b = bg.getContext('2d'), x, y, c, s = cell;
    b.setTransform(dpr, 0, 0, dpr, 0, 0);
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        c = room.map[y].charAt(x);
        if (c === '#' || c === 'D' || c === 'H' || c === 'C') {
          b.fillStyle = (x + y) % 2 ? '#3b2752' : '#36234c';
          b.fillRect(x * s, y * s, s, s);
          b.fillStyle = 'rgba(255,138,31,.08)';
          b.fillRect(x * s + s * 0.2, y * s, s * 0.12, s);
          b.fillRect(x * s + s * 0.65, y * s, s * 0.12, s);
        } else {
          b.fillStyle = (y % 2) ? '#5a3d2b' : '#553a29';
          b.fillRect(x * s, y * s, s, s);
          b.fillStyle = 'rgba(0,0,0,.18)';
          b.fillRect(x * s + ((y * 7) % 3) * s * 0.33, y * s, 1, s);
          b.fillRect(x * s, y * s + s - 1, s, 1);
        }
      }
    }
    // wall shadow on the floor
    b.fillStyle = 'rgba(0,0,0,.25)';
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        if (room.map[y].charAt(x) === '.' && y > 0 && room.map[y - 1].charAt(x) !== '.' && room.map[y - 1].charAt(x) !== 'T') {
          b.fillRect(x * s, y * s, s, s * 0.18);
        }
      }
    }
    // the creature's doorway
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        if (room.map[y].charAt(x) === 'C') {
          b.fillStyle = '#07040b'; rr(b, x * s + s * 0.15, y * s + s * 0.05, s * 0.7, s * 0.9, s * 0.2); b.fill();
          b.fillStyle = 'rgba(255,40,40,.5)'; circ(b, x * s + s * 0.38, y * s + s * 0.4, s * 0.04, 'rgba(255,60,60,.6)'); circ(b, x * s + s * 0.58, y * s + s * 0.4, s * 0.04, 'rgba(255,60,60,.6)');
        }
      }
    }
    // the table: find its bounds
    var tx0 = 99, ty0 = 99, tx1 = -1, ty1 = -1;
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        if (room.map[y].charAt(x) === 'T') { tx0 = Math.min(tx0, x); ty0 = Math.min(ty0, y); tx1 = Math.max(tx1, x); ty1 = Math.max(ty1, y); }
      }
    }
    if (tx1 >= 0) {
      var X = tx0 * s, Y = ty0 * s, TW = (tx1 - tx0 + 1) * s, TH = (ty1 - ty0 + 1) * s;
      b.fillStyle = 'rgba(0,0,0,.3)'; rr(b, X + s * 0.1, Y + s * 0.2, TW, TH, s * 0.2); b.fill();
      b.fillStyle = '#f2e9f7'; rr(b, X, Y, TW, TH, s * 0.15); b.fill();
      b.fillStyle = '#ff8a1f';
      for (x = 0; x < (tx1 - tx0 + 1) * 2; x++) {
        b.beginPath(); b.arc(X + s * 0.25 + x * s * 0.5, Y + TH, s * 0.25, 0, Math.PI); b.fill();
      }
      // cake and plates
      b.fillStyle = '#f7c6d9'; rr(b, X + TW / 2 - s * 0.5, Y + TH / 2 - s * 0.45, s, s * 0.7, s * 0.12); b.fill();
      b.fillStyle = '#8a3fd1'; b.fillRect(X + TW / 2 - s * 0.5, Y + TH / 2 - s * 0.1, s, s * 0.12);
      b.fillStyle = '#fff'; b.fillRect(X + TW / 2 - s * 0.03, Y + TH / 2 - s * 0.75, s * 0.06, s * 0.3);
      circ(b, X + TW / 2, Y + TH / 2 - s * 0.8, s * 0.06, '#ffd23f');
      circ(b, X + s * 0.5, Y + s * 0.5, s * 0.25, '#ffffff'); circ(b, X + TW - s * 0.5, Y + TH - s * 0.6, s * 0.25, '#ffffff');
    }
  }

  function objOf(id) { return Rules.objById(room, id); }

  function drawObjects(t) {
    var s = cell, i, o, st, X, Y, k;
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i]; st = S.obj[o.id] || {}; X = o.x * s; Y = o.y * s;
      if (o.kind === 'door') {
        if (S.doorOpen) {
          g.fillStyle = '#ffe9a8'; g.fillRect(X + s * 0.1, Y, s * 0.8, s);
          g.fillStyle = 'rgba(255,233,168,.25)'; g.fillRect(X - s * 0.3, Y + s, s * 1.6, s * 0.8);
        } else {
          g.fillStyle = '#7a4a1e'; rr(g, X + s * 0.08, Y + s * 0.02, s * 0.84, s * 0.98, s * 0.12); g.fill();
          g.fillStyle = '#5c3614'; g.fillRect(X + s * 0.18, Y + s * 0.12, s * 0.28, s * 0.36); g.fillRect(X + s * 0.54, Y + s * 0.12, s * 0.28, s * 0.36);
          circ(g, X + s * 0.78, Y + s * 0.62, s * 0.06, '#ffd23f');
          // keypad
          g.fillStyle = '#222'; rr(g, X + s * 0.22, Y + s * 0.56, s * 0.42, s * 0.38, s * 0.06); g.fill();
          var kc = ['red', 'blue', 'yellow', 'green'];
          for (k = 0; k < 4; k++) { circ(g, X + s * (0.33 + (k % 2) * 0.2), Y + s * (0.67 + Math.floor(k / 2) * 0.16), s * 0.06, COLOR_HEX[kc[k]]); }
        }
      } else if (o.kind === 'hole') {
        if (S.holeOpen) { g.fillStyle = '#07040b'; rr(g, X + s * 0.05, Y + s * 0.2, s * 0.9, s * 0.75, s * 0.3); g.fill(); }
      } else if (o.kind === 'cabinet') {
        var off = st.moved ? s * 0.85 : 0;
        g.fillStyle = 'rgba(0,0,0,.35)'; g.fillRect(X + s * 0.1, Y + off + s * 0.85, s * 0.9, s * 0.15);
        g.fillStyle = '#6b4226'; rr(g, X + s * 0.05, Y + off - s * 0.3, s * 0.9, s * 1.2, s * 0.08); g.fill();
        g.fillStyle = '#4e2f1a'; g.fillRect(X + s * 0.15, Y + off - s * 0.2, s * 0.7, s * 0.45); g.fillRect(X + s * 0.15, Y + off + s * 0.32, s * 0.7, s * 0.45);
        circ(g, X + s * 0.5, Y + off + s * 0.05, s * 0.05, '#d9b26f'); circ(g, X + s * 0.5, Y + off + s * 0.55, s * 0.05, '#d9b26f');
      } else if (o.kind === 'cage') {
        g.fillStyle = '#2b2b33'; g.fillRect(X - s * 0.05, Y + s * 0.85, s * 1.1, s * 0.15);
        g.fillStyle = '#2b2b33'; g.fillRect(X - s * 0.05, Y - s * 0.25, s * 1.1, s * 0.12);
      } else if (o.kind === 'balloon') {
        var by = Y + s * 0.35 + Math.sin(t * 2 + o.n) * s * 0.06;
        if (!st.popped) {
          g.strokeStyle = '#ddd'; g.lineWidth = 1; g.beginPath(); g.moveTo(X + s * 0.5, by + s * 0.3); g.lineTo(X + s * 0.5, Y + s * 0.95); g.stroke();
          g.fillStyle = '#efe9f5'; ell(g, X + s * 0.5, by, s * 0.27, s * 0.33); g.fill();
          g.fillStyle = 'rgba(255,255,255,.7)'; ell(g, X + s * 0.42, by - s * 0.12, s * 0.06, s * 0.1); g.fill();
          g.fillStyle = '#3a2a4f'; g.font = 'bold ' + Math.round(s * 0.36) + 'px sans-serif';
          g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(String(o.n + 1), X + s * 0.5, by + s * 0.02);
        } else {
          g.fillStyle = COLOR_HEX[S.code[o.n]];
          for (k = 0; k < 7; k++) { g.fillRect(X + s * (0.15 + ((k * 37) % 70) / 100), Y + s * (0.6 + ((k * 23) % 30) / 100), s * 0.1, s * 0.06); }
          g.beginPath(); g.arc(X + s * 0.5, Y + s * 0.55, s * 0.22, 0, Math.PI * 2); g.fill();
          g.fillStyle = '#fff'; g.font = 'bold ' + Math.round(s * 0.3) + 'px sans-serif';
          g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(String(o.n + 1), X + s * 0.5, Y + s * 0.56);
        }
      } else if (o.kind === 'invite') {
        g.save(); g.translate(X + s * 0.5, Y + s * 0.55); g.rotate(-0.08);
        g.fillStyle = '#f7e7c4'; g.fillRect(-s * 0.36, -s * 0.36, s * 0.72, s * 0.62);
        g.fillStyle = '#ff8a1f'; g.fillRect(-s * 0.36, -s * 0.36, s * 0.72, s * 0.1);
        g.strokeStyle = '#8a3fd1'; g.lineWidth = Math.max(1, s * 0.03);
        for (k = 0; k < 3; k++) { g.beginPath(); g.moveTo(-s * 0.26, -s * 0.12 + k * s * 0.13); g.bezierCurveTo(-s * 0.1, -s * 0.2 + k * s * 0.13, s * 0.05, -s * 0.02 + k * s * 0.13, s * 0.26, -s * 0.12 + k * s * 0.13); g.stroke(); }
        g.restore();
      } else if (o.kind === 'uv') {
        if (S.uvLit) {
          g.fillStyle = 'rgba(170,90,255,.35)'; g.fillRect(X - s * 0.4, Y + s * 0.05, s * 1.8, s * 0.9);
          for (k = 0; k < 3; k++) { circ(g, X + s * (0.0 + k * 0.5), Y + s * 0.5, s * 0.18, COLOR_HEX[S.code[k]]); }
        } else {
          g.strokeStyle = 'rgba(200,170,255,.22)'; g.lineWidth = Math.max(1, s * 0.04);
          g.beginPath(); g.moveTo(X - s * 0.2, Y + s * 0.6); g.bezierCurveTo(X + s * 0.2, Y + s * 0.2, X + s * 0.6, Y + s * 0.9, X + s * 1.1, Y + s * 0.4); g.stroke();
        }
      } else if (o.kind === 'present') {
        var lid = st.opened ? -s * 0.25 : 0;
        g.fillStyle = o.boost === 'shield' ? '#3d8bff' : '#e8505b';
        rr(g, X + s * 0.2, Y + s * 0.4, s * 0.6, s * 0.5, s * 0.06); g.fill();
        g.fillStyle = '#ffd23f'; g.fillRect(X + s * 0.46, Y + s * 0.4, s * 0.08, s * 0.5);
        g.fillStyle = o.boost === 'shield' ? '#2c6bd1' : '#c43a45';
        g.fillRect(X + s * 0.15, Y + s * 0.3 + lid, s * 0.7, s * 0.14);
        if (!st.opened) {
          g.fillStyle = '#ffd23f'; ell(g, X + s * 0.4, Y + s * 0.26, s * 0.1, s * 0.07); g.fill(); ell(g, X + s * 0.6, Y + s * 0.26, s * 0.1, s * 0.07); g.fill();
        }
      } else if (o.kind === 'hide') {
        drawHide(o, X, Y, s);
      }
    }
  }

  function drawHide(o, X, Y, s) {
    if (o.look === 'wardrobe') {
      g.fillStyle = '#4e2f1a'; rr(g, X + s * 0.02, Y - s * 0.55, s * 0.96, s * 1.5, s * 0.08); g.fill();
      g.fillStyle = '#6b4226'; g.fillRect(X + s * 0.1, Y - s * 0.45, s * 0.38, s * 1.3); g.fillRect(X + s * 0.52, Y - s * 0.45, s * 0.38, s * 1.3);
      circ(g, X + s * 0.44, Y + s * 0.2, s * 0.04, '#d9b26f'); circ(g, X + s * 0.56, Y + s * 0.2, s * 0.04, '#d9b26f');
    } else if (o.look === 'curtain') {
      g.fillStyle = '#7a1f3d'; g.fillRect(X, Y - s * 0.6, s, s * 1.55);
      g.fillStyle = 'rgba(0,0,0,.25)';
      var k; for (k = 0; k < 4; k++) { g.fillRect(X + s * (0.12 + k * 0.24), Y - s * 0.6, s * 0.06, s * 1.55); }
      g.fillStyle = '#ffd23f'; g.fillRect(X - s * 0.05, Y - s * 0.65, s * 1.1, s * 0.08);
    } else if (o.look === 'cloth') {
      g.fillStyle = '#f2e9f7'; g.fillRect(X - s * 0.05, Y, s * 1.1, s * 0.55);
      g.fillStyle = '#ff8a1f'; g.beginPath(); g.arc(X + s * 0.25, Y + s * 0.55, s * 0.25, 0, Math.PI); g.arc(X + s * 0.75, Y + s * 0.55, s * 0.25, 0, Math.PI); g.fill();
    } else if (o.look === 'sofa') {
      g.fillStyle = '#5b3b8a'; rr(g, X - s * 0.1, Y + s * 0.15, s * 1.2, s * 0.8, s * 0.15); g.fill();
      g.fillStyle = '#7a55b3'; rr(g, X - s * 0.02, Y + s * 0.42, s * 1.04, s * 0.42, s * 0.1); g.fill();
    } else if (o.look === 'box') {
      g.fillStyle = '#c99a5b'; rr(g, X + s * 0.02, Y + s * 0.1, s * 0.96, s * 0.85, s * 0.05); g.fill();
      g.fillStyle = '#a87a40'; g.fillRect(X + s * 0.02, Y + s * 0.1, s * 0.96, s * 0.16);
      g.fillStyle = '#3a2a4f'; g.font = Math.round(s * 0.3) + 'px sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
      g.fillText('?', X + s * 0.5, Y + s * 0.6);
    }
  }

  // peeking eyes for a hidden character
  function drawPeek(o, i, t) {
    var s = cell, X = o.x * s + s * (0.32 + i * 0.36), Y = o.y * s + (o.look === 'wardrobe' || o.look === 'curtain' ? s * 0.0 : s * 0.25);
    var blink = (Math.sin(t * 1.7 + i * 3) > 0.96) ? 0.2 : 1;
    g.fillStyle = '#fff';
    ell(g, X - s * 0.07, Y, s * 0.05, s * 0.06 * blink); g.fill();
    ell(g, X + s * 0.07, Y, s * 0.05, s * 0.06 * blink); g.fill();
    circ(g, X - s * 0.06, Y, s * 0.025, '#111'); circ(g, X + s * 0.08, Y, s * 0.025, '#111');
  }

  function drawCageBars(o) {
    var s = cell, X = o.x * s, Y = o.y * s, k;
    g.strokeStyle = '#9a9aa8'; g.lineWidth = Math.max(2, s * 0.05);
    for (k = 0; k < 6; k++) { g.beginPath(); g.moveTo(X + s * (0.02 + k * 0.19), Y - s * 0.2); g.lineTo(X + s * (0.02 + k * 0.19), Y + s * 0.9); g.stroke(); }
    g.fillStyle = '#ffd23f'; rr(g, X + s * 0.4, Y + s * 0.3, s * 0.22, s * 0.2, s * 0.04); g.fill();
  }

  function frame() {
    requestAnimationFrame(frame);
    if ($('title').className.indexOf('on') >= 0) { drawTitle(); return; }
    if (!gameOn || !S || !room) { return; }
    var t = Date.now() / 1000, dt = Math.min(0.1, t - (frame.last || t)), s = cell, i, c, p, hid = {}, list = [];
    frame.last = t;
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.save();
    if (shake > 0.2) { g.translate((Math.random() - 0.5) * shake, (Math.random() - 0.5) * shake); shake *= 0.88; } else { shake = 0; }
    g.drawImage(bg, 0, 0, W, H);
    drawObjects(t);
    // smooth positions
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      p = rp[c.id] || (rp[c.id] = { x: c.x, y: c.y });
      glide(p, c.x, c.y, c.running ? 5.5 : 2.8, dt);
      if (c.hidden) { hid[c.hideId] = (hid[c.hideId] || 0) + 1; continue; }
      if (c.escaped) { continue; }
      list.push({ y: p.y, c: c, p: p });
    }
    var k = S.creature;
    if (!kp) { kp = { x: k.x, y: k.y }; }
    glide(kp, k.x, k.y, k.mode === 'hunt' ? 3.6 : 2.0, dt);
    if (k.active) { list.push({ y: kp.y, k: true }); }
    list.sort(function (a, b) { return a.y - b.y; });
    for (i = 0; i < list.length; i++) {
      if (list[i].k) {
        drawCreature(g, (kp.x + 0.5) * s, (kp.y + 0.92) * s, s, { t: t, mode: k.mode, moving: Math.abs(kp.x - k.x) + Math.abs(kp.y - k.y) > 0.05, stunned: k.pause > 0 });
      } else {
        c = list[i].c; p = list[i].p;
        drawChar(g, (p.x + 0.5) * s, (p.y + 0.92) * s, s, c.char, {
          t: t + i, moving: Math.abs(p.x - c.x) + Math.abs(p.y - c.y) > 0.05, selected: c.id === sel && !c.caged,
          scared: c.caged || (k.mode === 'hunt' && k.target === c.id), look: k.active ? (k.x < c.x ? -1 : 1) : 0
        });
        if (c.chan) { drawChan(p, c.chan); }
      }
    }
    var cg = objOf('cage');
    drawCageBars(cg);
    for (i = 0; i < room.objects.length; i++) {
      if (room.objects[i].kind === 'hide' && hid[room.objects[i].id]) {
        drawPeek(room.objects[i], 0, t);
        if (hid[room.objects[i].id] > 1) { drawPeek(room.objects[i], 1, t + 2); }
      }
    }
    drawParts(dt);
    drawDark(t);
    drawHint(t);
    g.restore();
    sounds(t);
  }
  function glide(p, x, y, speed, dt) {
    var dx = x - p.x, dy = y - p.y, d = Math.sqrt(dx * dx + dy * dy), m = speed * dt * 1.15;
    if (d > 2.5 || d <= m) { p.x = x; p.y = y; return; }
    p.x += dx / d * m; p.y += dy / d * m;
  }
  function drawChan(p, ch) {
    var s = cell, x = (p.x + 0.5) * s, y = (p.y - 0.2) * s, f = 1 - ch.left / ch.total;
    g.lineWidth = Math.max(3, s * 0.09);
    g.strokeStyle = 'rgba(0,0,0,.5)'; g.beginPath(); g.arc(x, y, s * 0.2, 0, Math.PI * 2); g.stroke();
    g.strokeStyle = '#7be36b'; g.beginPath(); g.arc(x, y, s * 0.2, -Math.PI / 2, -Math.PI / 2 + f * Math.PI * 2); g.stroke();
  }
  function drawDark(t) {
    var i, c, p, r, d, grd, k = S.creature, s = cell;
    if (S.spook !== 'spooky') {
      g.fillStyle = 'rgba(20,8,40,.16)'; g.fillRect(0, 0, W, H);
      return;
    }
    d = dark.getContext('2d');
    d.setTransform(dpr, 0, 0, dpr, 0, 0);
    d.globalCompositeOperation = 'source-over';
    d.clearRect(0, 0, W, H);
    d.fillStyle = 'rgba(4,2,10,.9)'; d.fillRect(0, 0, W, H);
    d.globalCompositeOperation = 'destination-out';
    function hole(x, y, rad) {
      grd = d.createRadialGradient(x, y, rad * 0.25, x, y, rad);
      grd.addColorStop(0, 'rgba(0,0,0,1)'); grd.addColorStop(1, 'rgba(0,0,0,0)');
      d.fillStyle = grd; d.beginPath(); d.arc(x, y, rad, 0, Math.PI * 2); d.fill();
    }
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i]; p = rp[c.id]; if (!p || c.escaped) { continue; }
      r = c.caged ? 1.2 : (c.char === 'glow' ? 5.2 : 3.2);
      hole((p.x + 0.5) * s, (p.y + 0.5) * s, r * s * (1 + Math.sin(t * 3 + i) * 0.03));
    }
    if (S.doorOpen) { var dd = objOf('door'); hole((dd.x + 0.5) * s, (dd.y + 1) * s, 2.5 * s); }
    if (S.uvLit) { var u = objOf('uv'); hole((u.x + 0.5) * s, (u.y + 0.5) * s, 2.2 * s); }
    g.drawImage(dark, 0, 0, W, H);
    // its eyes always show in the dark
    if (k.active && kp) {
      var ex = (kp.x + 0.5) * s, ey = (kp.y + 0.92) * s - s * 1.75 + s * 0.38 - s * 0.08;
      var col = k.mode === 'hunt' ? '#ff3b30' : '#ffe14d';
      g.shadowColor = col; g.shadowBlur = s * 0.3;
      circ(g, ex - s * 0.15, ey, s * 0.05, col); circ(g, ex + s * 0.15, ey, s * 0.05, col);
      g.shadowBlur = 0;
    }
  }
  function drawHint(t) {
    if (!S.hint) { return; }
    var o = objOf(S.hint.obj); if (!o) { return; }
    var s = cell, x = (o.x + 0.5) * s, y = o.y * s - s * 0.3 - Math.abs(Math.sin(t * 4)) * s * 0.3;
    g.strokeStyle = 'rgba(123,227,107,' + (0.5 + 0.5 * Math.sin(t * 6)) + ')'; g.lineWidth = Math.max(3, s * 0.08);
    g.beginPath(); g.arc(x, (o.y + 0.5) * s, s * 0.7, 0, Math.PI * 2); g.stroke();
    g.fillStyle = '#7be36b';
    g.beginPath(); g.moveTo(x - s * 0.25, y - s * 0.3); g.lineTo(x + s * 0.25, y - s * 0.3); g.lineTo(x, y + s * 0.05); g.closePath(); g.fill();
  }
  function burst(x, y, col, n) {
    var i;
    for (i = 0; i < n; i++) {
      parts.push({ x: x, y: y, vx: (Math.random() - 0.5) * 6, vy: -Math.random() * 6, c: col || ['#ff4d5e', '#3d8bff', '#ffd23f', '#46d160'][i % 4], life: 1 });
    }
  }
  function drawParts(dt) {
    var i, q, s = cell;
    for (i = parts.length - 1; i >= 0; i--) {
      q = parts[i];
      q.x += q.vx * dt; q.y += q.vy * dt; q.vy += 9 * dt; q.life -= dt * 0.8;
      if (q.life <= 0) { parts.splice(i, 1); continue; }
      g.globalAlpha = Math.max(0, q.life);
      g.fillStyle = q.c; g.fillRect(q.x * s, q.y * s, s * 0.12, s * 0.08);
    }
    g.globalAlpha = 1;
  }

  // footsteps and heartbeat from the danger level
  function dangerLevel() {
    var k = S.creature, i, c, d, best = 99;
    if (!k.active) { return 0; }
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      if (c.caged || c.escaped) { continue; }
      d = Math.max(Math.abs(k.x - c.x), Math.abs(k.y - c.y));
      if (d < best) { best = d; }
    }
    return best <= 2 ? 5 : best <= 3 ? 4 : best <= 5 ? 3 : best <= 7 ? 2 : best <= 11 ? 1 : 0;
  }
  function sounds(t) {
    var k = S.creature, lv = dangerLevel(), key = k.x + ',' + k.y, sp = $('danger').children, i;
    for (i = 0; i < sp.length; i++) { sp[i].className = i < lv ? 'on' : ''; }
    if (S.status !== 'playing') { return; }
    if (k.active && key !== lastStepKey) { lastStepKey = key; SFX.step(lv / 5); }
    if (lv >= 4 && t - lastHeart > (lv === 5 ? 0.55 : 0.8)) { lastHeart = t; SFX.heart(); }
  }

  // ---- toasts and scares ----
  var toastTimer = null;
  function toast(msg, who, ms) {
    var el = $('toast'), pv = el.querySelector('canvas');
    el.querySelector('span').innerHTML = msg;
    if (who) { pv.style.display = ''; portrait(pv, who); } else { pv.style.display = 'none'; }
    el.style.display = 'flex';
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.style.display = 'none'; }, ms || 2600);
  }
  function dot(c) { return '<b style="display:inline-block;width:22px;height:22px;border-radius:50%;vertical-align:middle;background:' + COLOR_HEX[c] + '"></b>'; }
  function scare() {
    var el = $('scare'), c = $('scv'), w = el.clientWidth || window.innerWidth, h = el.clientHeight || window.innerHeight, sg, t0 = Date.now();
    el.style.display = 'flex';
    c.width = w; c.height = h;
    sg = c.getContext('2d');
    SFX.stinger();
    (function anim() {
      var f = (Date.now() - t0) / 650;
      sg.fillStyle = '#000'; sg.fillRect(0, 0, w, h);
      var sz = Math.min(w, h) * (0.9 + f * 0.6);
      drawCreature(sg, w / 2, h / 2 + sz * 1.42, sz, { t: f * 3, mode: 'hunt' });
      if (f < 1) { requestAnimationFrame(anim); } else { el.style.display = 'none'; }
    })();
  }
  var SILLY = {
    appear: ['Ding dong! Who came to my party?', 'Is it cake time? I LOVE cake time.', 'Hellooo? I made party hats!'],
    spotted: ['There you are! Come and play musical chairs!', 'Found a guest! Found a guest!', 'Ooh! A party guest!'],
    caught: ['Gotcha! Cage time. It has cushions.', 'Into the party cage! No cake for you.', 'Caught one! Pass the parcel!'],
    gone: ['Where did everybody go...?', 'Hide and seek? I am TERRIBLE at hide and seek.', 'Hmm. Must be in the kitchen.'],
    sniff: ['Sniff sniff... I smell birthday cake.', 'Was that a balloon? I love balloons.', 'Hmm, nobody here. Just my imagination.'],
    shield: ['OW! My mask!', 'Hey! That popped right in my pumpkin!']
  };
  function silly(k) { var a = SILLY[k]; return a[Math.floor(Math.random() * a.length)]; }

  function onEvent(e) {
    var c = e.id ? Rules.charById(S, e.id) : null, nm = c ? CHARS[c.char].name : '', o;
    switch (e.k) {
      case 'appear':
        if (S.spook === 'spooky') { scare(); shake = 14; } else { SFX.boing(); toast(silly('appear'), 'creature', 3200); }
        break;
      case 'spotted':
        if (S.spook === 'spooky') { SFX.stinger(); shake = 10; toast('It has seen ' + nm + '! RUN or HIDE!', 'creature', 2200); }
        else { SFX.boing(); toast(silly('spotted') + '<br><b>Run or hide!</b>', 'creature', 2600); }
        break;
      case 'gone': toast(silly('gone'), 'creature'); break;
      case 'sniff': if (S.spook !== 'spooky') { toast(silly('sniff'), 'creature'); } break;
      case 'caught':
        SFX.clank();
        if (S.spook === 'spooky') { scare(); }
        else { SFX.laugh(); }
        toast(nm + ' was caught! ' + (S.spook === 'spooky' ? 'Free them from the cage!' : silly('caught')), 'creature', 3200);
        break;
      case 'shield': SFX.pop(); shake = 8; toast('POP! ' + nm + '\'s shield saved them! ' + silly('shield'), c.char, 2800); break;
      case 'pop':
        SFX.pop(); o = objOf(e.obj); burst(o.x + 0.5, o.y + 0.4, COLOR_HEX[e.color], 18);
        toast('Balloon ' + (e.idx + 1) + ' was ' + dot(e.color) + ' <b>' + COLOR_WORD[e.color] + '</b>! That was LOUD...', c.char, 3200);
        break;
      case 'boost':
        SFX.sparkle(); o = objOf(e.obj); burst(o.x + 0.5, o.y + 0.4, '#ffd23f', 14);
        toast(e.boost === 'shield' ? nm + ' found a <b>Party Shield</b> 🛡️ - it saves you from one grab!' : nm + ' found <b>Candy Corn</b> 🍬 - run without getting puffed!', c.char, 3200);
        break;
      case 'reveal':
        SFX.chime();
        toast((e.by === 'brainy' ? 'Brainy cracked the invitation!' : 'Glow lit up the secret paint!') + ' The code is ' + dot(S.code[0]) + ' ' + dot(S.code[1]) + ' ' + dot(S.code[2]), c.char, 4200);
        break;
      case 'need':
        SFX.click();
        toast({ brainy: 'Twisty writing... <b>Brainy</b> could read this!', glow: 'Something is painted here, but it is too dark. <b>Glow</b> could light it up!', muscle: 'Too heavy! <b>Muscle</b> could shove it.' }[e.skill], e.skill, 3000);
        break;
      case 'press': SFX.press(e.c); break;
      case 'wrong': SFX.buzz(); shake = 6; toast('Wrong code! And that was LOUD... something is coming.', null, 2600); break;
      case 'open':
        SFX.chime(); burst(8.5, 1, null, 26);
        toast(e.how === 'shove' ? 'Muscle shoved the cabinet - a secret hole! Squeeze through!' : (e.how === 'pick' ? 'Click! Tinker picked the lock!' : 'The big door is open!') + ' Everybody out!', c ? c.char : null, 3200);
        break;
      case 'escape': SFX.cheer(); toast(nm + ' made it out!', c.char, 1800); if (sel === e.id) { autoSelect(); } break;
      case 'rescue': SFX.chime(); toast(nm + ' freed ' + CHARS[Rules.charById(S, e.freed).char].name + '!', c.char, 2400); break;
      case 'puffed': toast(nm + ' is puffed out! Walk for a bit.', c.char, 1800); break;
      case 'tired': toast('Not enough energy for a clue.', c ? c.char : null, 2000); break;
      case 'clue': SFX.sparkle(); toast('💡 ' + e.say, null, 5000); break;
      case 'hide': SFX.click(); break;
      case 'full': toast('No room in there!', c ? c.char : null, 1500); break;
      case 'blocked': toast('Can\'t get there!', c ? c.char : null, 1200); break;
      case 'cleared': SFX.cheer(); burst(8, 5, null, 60); setTimeout(endScreen, 900); break;
      case 'lost': SFX.laugh(); setTimeout(endScreen, 900); break;
    }
  }

  function autoSelect() {
    var i, c;
    c = Rules.charById(S, sel);
    if (c && !c.caged && !c.escaped) { return; }
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      if (!c.caged && !c.escaped) { sel = c.id; return; }
    }
  }

  function onState(st) {
    var i, e;
    S = st;
    for (i = 0; i < S.events.length; i++) {
      e = S.events[i];
      if (e.n > lastEv) { lastEv = e.n; onEvent(e); }
    }
    autoSelect();
    paintBar();
    paintKeypad();
  }

  // ---- keypad ----
  (function () {
    var keys = $('keypad').querySelector('.keys');
    Rules.COLORS.forEach(function (c) {
      var b = document.createElement('button');
      b.className = 'k'; b.style.background = COLOR_HEX[c];
      b.onclick = function () { T.send({ t: 'press', id: sel, c: c }); };
      keys.appendChild(b);
    });
    $('bPick').onclick = function () { T.send({ t: 'pick', id: sel }); };
  })();
  function paintKeypad() {
    var c = Rules.charById(S, sel), el = $('keypad'), on, dots, i;
    on = c && S.status === 'playing' && !S.doorOpen && !c.path.length && Rules.nearDoor(S, c);
    el.style.display = on ? 'block' : 'none';
    if (!on) { return; }
    dots = el.querySelectorAll('.dots i');
    for (i = 0; i < 3; i++) { dots[i].style.background = S.entry[i] ? COLOR_HEX[S.entry[i]] : ''; }
    $('bPick').style.display = c.char === 'tinker' ? 'block' : 'none';
    $('bPick').disabled = !!(c.chan && c.chan.act === 'pick');
    $('bPick').textContent = c.chan && c.chan.act === 'pick' ? '🔧 Picking...' : '🔧 Pick the lock';
  }

  // ---- input: tap to move, double-tap to run ----
  cv.addEventListener('pointerdown', function (ev) {
    if (!S || S.status !== 'playing') { return; }
    try { cv.setPointerCapture(ev.pointerId); } catch (e) { /* older browsers */ }
    var r = cv.getBoundingClientRect(), x = Math.floor((ev.clientX - r.left) / cell), y = Math.floor((ev.clientY - r.top) / cell);
    var now = Date.now(), run = now - lastTap.t < 380 && Math.abs(x - lastTap.x) <= 1 && Math.abs(y - lastTap.y) <= 1;
    lastTap = { t: now, x: x, y: y };
    var o = objAt(x, y), c = Rules.charById(S, sel);
    if (!c) { return; }
    if (o) { T.send({ t: 'go', id: sel, act: o.id, run: run }); }
    else { T.send({ t: 'go', id: sel, x: x, y: y, run: run }); }
    parts.push({ x: x + 0.45, y: y + 0.5, vx: 0, vy: 0, c: run ? '#ff8a1f' : '#7be36b', life: 0.6 });
  });
  function objAt(x, y) {
    var i, o, best = null;
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i];
      if (o.x === x && o.y === y) { best = o; if (o.kind !== 'hole') { return o; } }
    }
    // tall things: wardrobe and curtain also answer to the cell above
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i];
      if (o.kind === 'hide' && (o.look === 'wardrobe' || o.look === 'curtain') && o.x === x && o.y - 1 === y) { return o; }
    }
    if (best && best.kind === 'hole' && !S.holeOpen) { return objOf('cab'); }
    return best;
  }

  $('bClue').onclick = function () { if (S) { T.send({ t: 'clue', id: sel }); } };

  // ---- end of room ----
  function endScreen() {
    var i, c, pts = 0, html = '', over = $('over'), btns = $('overB');
    btns.innerHTML = '';
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      html += CHARS[c.char].badge + ' ' + CHARS[c.char].name + ' <b>+' + (S.points[c.id] || 0) + '</b><br>';
      pts += S.points[c.id] || 0;
    }
    if (S.status === 'cleared' || S.status === 'over') {
      if (!banked) {
        banked = true;
        prog.points += pts; prog.runs += 1;
        if (S.status === 'cleared') { prog.wins += 1; }
        for (i = 0; i < S.chars.length; i++) { c = S.chars[i]; prog.xp[c.char] = (prog.xp[c.char] || 0) + (S.points[c.id] || 0); }
        saveProgress();
      }
      $('overT').textContent = S.status === 'cleared' ? 'You escaped the Front Hall!' : 'The party is over... for now.';
      $('overP').innerHTML = html + '<br>⭐ ' + pts + ' points saved' +
        (S.status === 'cleared' ? '<br><br>More rooms of the party arrive next week...' : '');
      addBtn(btns, 'Play again', function () { show('squad'); buildCards(); gameOn = false; T.stop(); });
      addBtn(btns, 'Home', goHome, true);
    } else {
      $('overT').textContent = 'Everyone is in the cage!';
      $('overP').innerHTML = html + '<br>' + (3 - S.tries - 1) + ' tries left';
      addBtn(btns, 'Try again', function () { over.style.display = 'none'; lastEv = 0; T.send({ t: 'retry' }); rp = {}; kp = null; }, false);
      addBtn(btns, 'Home', goHome, true);
    }
    over.style.display = 'flex';
  }
  function addBtn(box, label, fn, alt) {
    var b = document.createElement('button');
    b.className = 'big' + (alt ? ' alt' : ''); b.textContent = label; b.onclick = fn;
    box.appendChild(b);
  }
  function goHome() {
    gameOn = false; if (T) { T.stop(); }
    $('totPts').textContent = prog.points ? ('⭐ ' + prog.points + ' points saved') : '';
    show('title');
  }

  document.addEventListener('visibilitychange', function () {
    if (!T || !gameOn) { return; }
    if (document.hidden) { T.stop(); } else if (S && S.status === 'playing') { T.start(); }
  });

  // ---- buttons ----
  $('bSolo').onclick = function () { SFX.click(); buildCards(); show('squad'); };
  $('bBack1').onclick = function () { show('title'); };
  $('bStart').onclick = function () {
    var ps = document.querySelectorAll('#story p'), i;
    show('story');
    for (i = 0; i < ps.length; i++) { ps[i].className = ''; }
    for (i = 0; i < ps.length; i++) {
      (function (p, d) { setTimeout(function () { p.className = 'show'; }, d); })(ps[i], 300 + i * 1100);
    }
    SFX.click();
  };
  $('bGo').onclick = function () { SFX.click(); startGame(); };
  $('bHome').onclick = goHome;
  $('bCheck').onclick = function () { show('check'); runCheck(); };
  $('bCkBack').onclick = function () { show('title'); };
  $('bCkAgain').onclick = function () { runCheck(); };

  // ---- Check screen ----
  function runCheck() {
    var rows = [], pending = [], t0;
    function row(name, ok, detail, act) { rows.push({ name: name, ok: ok, detail: detail || '', act: act || '' }); }
    $('ckUrl').textContent = location.href;
    $('ckAct').textContent = 'Checking...';
    $('ckT').innerHTML = '';
    row('Address ends in /', /\/$/.test(location.pathname), location.pathname,
      'Open the address that ends in a slash: ' + location.origin + '/');
    var sw = 'serviceWorker' in navigator;
    row('Offline helper running', sw && !!navigator.serviceWorker.controller,
      sw ? (navigator.serviceWorker.controller ? 'yes' : 'not yet') : 'not supported here',
      'Close the game and open it again once, on wifi.');
    if (window.caches) {
      pending.push(caches.open(SHELL_CACHE).then(function (c) { return c.match('./'); }).then(function (m) {
        row('Game saved for offline', !!m, m ? 'version ' + BUILD : 'not saved yet', 'Close the game and open it again once, on wifi.');
      }, function () { row('Game saved for offline', false, 'cache error', 'Open with ?fresh=1 on the end of the address, then again without it.'); }));
      pending.push(caches.open(ART_CACHE).then(function (c) { return c.keys(); }).then(function (ks) {
        row('Art saved for offline', true, ks.length + ' files (none needed yet)');
      }, function () { row('Art saved for offline', false, 'cache error'); }));
    } else {
      row('Game saved for offline', false, 'no cache storage', 'This browser cannot play offline.');
    }
    if (navigator.storage && navigator.storage.persisted) {
      pending.push(navigator.storage.persisted().then(function (p) {
        row('Storage kept safe', p ? true : null, p ? 'persisted' : 'may be cleared if space runs low',
          'Use the home-screen shortcut made in the adult profile.');
      }));
    } else { row('Storage kept safe', null, 'unknown here'); }
    var lsOk = save('check', Date.now()) && !!load('check', 0);
    row('Saving progress', lsOk, lsOk ? (prog.points + ' points saved') : 'cannot save', 'Progress will not be kept on this device.');
    var A = window.AudioContext || window.webkitAudioContext;
    row('Sound', !!A, A ? (AC ? AC.state : 'ready') : 'no Web Audio', 'Sound will be silent on this device.');
    var sp = 'speechSynthesis' in window;
    row('Spoken phrases', sp ? true : false, sp ? ((window.speechSynthesis.getVoices() || []).length + ' voices') : 'not available',
      'Spoken phrases need another way (later).');
    row('Online play', null, 'not built yet - comes with the spike');
    row('Connection', navigator.onLine ? true : null, navigator.onLine ? 'online' : 'offline');
    row('Screen', true, window.innerWidth + ' x ' + window.innerHeight + ' @' + Math.round((window.devicePixelRatio || 1) * 100) / 100 + 'x');
    t0 = Date.now();
    pending.push(new Promise(function (res) {
      var n = 0;
      (function f() {
        n++;
        if (Date.now() - t0 < 1000) { requestAnimationFrame(f); }
        else { row('Smoothness', n >= 40 ? true : (n >= 25 ? null : false), n + ' frames per second', 'The game may feel jerky on this device.'); res(); }
      })();
    }));
    row('Version', true, BUILD);
    Promise.all(pending.map(function (p) {
      return Promise.race([p, new Promise(function (res) { setTimeout(res, 4000); })]);
    })).then(function () {
      var h = '', i, r, act = '', order = ['Address ends in /', 'Offline helper running', 'Game saved for offline', 'Art saved for offline',
        'Storage kept safe', 'Saving progress', 'Sound', 'Spoken phrases', 'Online play', 'Connection', 'Screen', 'Smoothness', 'Version'];
      rows.sort(function (a, b) { return order.indexOf(a.name) - order.indexOf(b.name); });
      for (i = 0; i < rows.length; i++) {
        r = rows[i];
        h += '<tr><td class="m">' + (r.ok === true ? '✅' : r.ok === false ? '❌' : '➖') + '</td><td><b>' + r.name + '</b><br>' + r.detail + '</td></tr>';
        if (r.ok === false && !act) { act = 'Next: ' + r.act; }
      }
      $('ckT').innerHTML = h;
      $('ckAct').textContent = act || 'Next: nothing - everything that matters works.';
    });
  }

  // ---- offline: service worker + persistent storage ----
  window.addEventListener('load', function () {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('sw.js').catch(function () { /* shown on the Check screen */ });
    }
    if (navigator.storage && navigator.storage.persist) {
      try { navigator.storage.persist(); } catch (e) { /* ignore */ }
    }
  });

  requestAnimationFrame(frame);
})();
