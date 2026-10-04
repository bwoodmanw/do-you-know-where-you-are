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
  // unlockable later (v1); drawn now so the reference sheets show them
  CHARS.patch = { name: 'Patch', skill: 'Fast rescues', badge: '\uD83E\uDE79', locked: true,
    look: { body: '#ffb3c7', outfit: '#ffffff', eyes: 'big', hat: 'plaster', hatColor: '#f2d0a0' } };
  CHARS.echo = { name: 'Echo', skill: 'Hears the host', badge: '\uD83C\uDFA7', locked: true,
    look: { body: '#ffd23f', outfit: '#5b3b8a', eyes: 'goggles', hat: 'headphones', hatColor: '#2b2140' } };
  CHARS.bramble = { name: 'Bramble', skill: 'Talks to plants', badge: '\uD83C\uDF3F', locked: true,
    look: { body: '#8fd16a', outfit: '#7a4a1e', eyes: 'sleepy', hat: 'leaves', hatColor: '#3a7d44' } };
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
    if (L.hat === 'plaster') {
      g.save(); g.translate(x + w * 0.18, top + h * 0.18); g.rotate(-0.6);
      g.fillStyle = L.hatColor; rr(g, -s * 0.13, -s * 0.045, s * 0.26, s * 0.09, s * 0.04); g.fill();
      g.fillStyle = 'rgba(0,0,0,.2)'; g.fillRect(-s * 0.03, -s * 0.03, s * 0.06, s * 0.06);
      g.restore();
    } else if (L.hat === 'headphones') {
      g.strokeStyle = L.hatColor; g.lineWidth = Math.max(2, s * 0.06);
      g.beginPath(); g.arc(x, top + h * 0.3, w * 0.5, Math.PI * 1.05, Math.PI * 1.95); g.stroke();
      g.fillStyle = L.hatColor; rr(g, left - s * 0.06, ey - s * 0.12, s * 0.12, s * 0.2, s * 0.05); g.fill();
      rr(g, left + w - s * 0.06, ey - s * 0.12, s * 0.12, s * 0.2, s * 0.05); g.fill();
    } else if (L.hat === 'leaves') {
      var lf;
      for (lf = 0; lf < 5; lf++) {
        g.save(); g.translate(x + (lf - 2) * w * 0.17, top + h * 0.05); g.rotate((lf - 2) * 0.35 + Math.sin(t * 2 + lf) * 0.08);
        g.fillStyle = lf % 2 ? L.hatColor : '#5fb35a'; ell(g, 0, -s * 0.09, s * 0.06, s * 0.12); g.fill();
        g.restore();
      }
    } else if (L.hat === 'cap') {
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

  // ---- the game: a tilted (isometric) world with a camera that follows ----
  var T = null, S = null, room = null, sel = null, lastEv = 0, gameOn = false, banked = false;
  var cv = $('cv'), g = cv.getContext('2d'), dark = document.createElement('canvas');
  var mini = $('mini'), mg = mini.getContext('2d');
  var VW = 0, VH = 0, dpr = 1, TW = 64, TH = 32, ZP = 36;
  var cam = { x: 0, y: 0 }, pan = { x: 0, y: 0 }, rp = {}, kp = null, parts = [], shake = 0;
  var bubbles = {}, pings = [], runMode = false, sprites = [], lastStepKey = '', lastHeart = 0;
  var floorKind = [], furnKind = {}, lastTap = { t: 0, x: -9, y: -9 }, dragging = false;

  var PHRASES = ['👋 Over here!', '🔑 I found something!', '🙈 Hide!', '🏃 Run!',
    '⭐ Use your skill!', '🆘 Help me!', '👍 Nice one!', '🚪 The door is open!',
    '🎈 Pop the balloons!', '🎃 It is coming!', '😂 Ha ha ha!', '🎂 I want cake!'];
  var SKILL_BTN = { tinker: '🔧 Pick lock', shadow: '🌙 Sneak', brainy: '🧠 Read', muscle: '💪 Shove', glow: '💡 Light up' };
  var FLOOR = {
    carpet: ['#7a2741', '#70223b'], boards: ['#4d3526', '#463022'], green: ['#2f5a3e', '#2a5238'],
    tiles: ['#d6cfbf', '#3d3d48'], wood: ['#6b4a32', '#634429'], purple: ['#4b3570', '#43306a'], door: ['#3e2c22', '#3a291f']
  };

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
    var squad = [], i, x, y, f;
    for (i = 0; i < picked.length; i++) { squad.push({ id: 'c' + i, char: picked[i], owner: 'me' }); }
    save('squad', picked); save('spook', spook);
    var st = Rules.init({ room: 'hall', squad: squad, seed: (Date.now() & 0x7fffffff) || 1, spook: spook });
    room = Rules.getRoom('hall');
    // which floor and furniture each tile has
    floorKind = [];
    for (y = 0; y < room.h; y++) {
      floorKind.push([]);
      for (x = 0; x < room.w; x++) {
        floorKind[y].push('door');
        for (i = 0; i < room.floors.length; i++) {
          f = room.floors[i];
          if (x >= f.x0 && x <= f.x1 && y >= f.y0 && y <= f.y1) { floorKind[y][x] = f.kind; }
        }
      }
    }
    furnKind = {};
    for (i = 0; i < room.furniture.length; i++) {
      f = room.furniture[i];
      for (y = f.y0; y <= f.y1; y++) { for (x = f.x0; x <= f.x1; x++) { furnKind[x + ',' + y] = f.kind; } }
    }
    if (T) { T.stop(); }
    T = LocalTransport(st);
    S = st; lastEv = st.evn; sel = 'c0'; rp = {}; kp = null; parts = []; banked = false;
    bubbles = {}; pings = []; runMode = false; pan = { x: 0, y: 0 };
    $('over').style.display = 'none';
    $('say').style.display = 'none';
    buildBar();
    show('game');
    layout();
    var c0 = st.chars[0], w0 = W2(c0.x + 0.5, c0.y + 0.5, 0);
    cam.x = w0[0]; cam.y = w0[1] - TW * 0.3;
    T.onState(onState);
    T.start();
    gameOn = true;
  }

  function buildBar() {
    var box = $('sqs'), i, c;
    box.innerHTML = '';
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      (function (id, key) {
        var b = document.createElement('button'), pv = document.createElement('canvas');
        b.className = 'sq'; b.id = 'sq_' + id; pv.width = 96; pv.height = 96;
        b.appendChild(pv); portrait(pv, key);
        b.insertAdjacentHTML('beforeend', '<div class="info"><div class="nm">' + CHARS[key].name + ' <span class="stt"></span></div>' +
          '<div class="meter st"><i></i></div><div class="meter en"><i></i></div></div>');
        b.onclick = function () { selectChar(id); };
        box.appendChild(b);
      })(c.id, c.char);
    }
  }
  function selectChar(id) {
    var ch = Rules.charById(S, id);
    if (ch && !ch.caged && !ch.escaped) { sel = id; pan.x = 0; pan.y = 0; SFX.click(); paintBar(); }
  }
  function me() { return Rules.charById(S, sel); }
  function paintBar() {
    var i, c, b, m;
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i]; b = $('sq_' + c.id); if (!b) { continue; }
      b.className = 'sq' + (c.id === sel ? ' sel' : '');
      m = b.querySelectorAll('.meter i');
      m[0].style.width = Math.round(c.stamina) + '%';
      m[0].style.background = c.tired ? '#ff4d5e' : '';
      m[1].style.width = Math.round(c.energy) + '%';
      b.querySelector('.stt').textContent = c.escaped ? '✅' : c.caged ? '🔒' : c.hidden ? '🙈' :
        (c.shield ? '🛡️' : '') + (S.tick < c.freeRunUntil ? '🍬' : '') + (S.tick < c.sneakUntil ? '🌙' : '');
    }
    c = me();
    $('bClue').textContent = '💡 Clue (' + S.cluesLeft + ')';
    $('bClue').disabled = S.cluesLeft <= 0;
    $('aRun').className = 'act' + (runMode ? ' on' : '');
    if (c) { $('aSkill').textContent = SKILL_BTN[c.char]; }
    $('aHide').textContent = c && c.hidden ? '👀 Come out' : '🙈 Hide';
    var rn = room ? areaName(c) : '';
    $('rname').textContent = rn ? room.name + ' · ' + rn : (room ? room.name : '');
  }
  function areaName(c) {
    var i, f;
    if (!c) { return ''; }
    for (i = 0; i < room.floors.length; i++) {
      f = room.floors[i];
      if (c.x >= f.x0 && c.x <= f.x1 && c.y >= f.y0 && c.y <= f.y1) { return f.name; }
    }
    return '';
  }

  function layout() {
    var st = $('stage');
    VW = st.clientWidth; VH = st.clientHeight;
    if (!room || !VW || !VH) { return; }
    dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.width = Math.round(VW * dpr); cv.height = Math.round(VH * dpr);
    cv.style.width = VW + 'px'; cv.style.height = VH + 'px';
    dark.width = cv.width; dark.height = cv.height;
    TW = Math.max(48, Math.min(104, Math.round(Math.min(VW, VH * 1.7) / 11)));
    TH = TW / 2; ZP = TW * 0.55;
    mini.width = room.w * 5; mini.height = room.h * 5;
  }
  window.addEventListener('resize', function () { layout(); });

  // world position (px) of a point on the tile grid, z in tile-heights
  function W2(fx, fy, z) { return [(fx - fy) * TW / 2, (fx + fy) * TH / 2 - (z || 0) * ZP]; }
  function poly(pts, fill) {
    var i;
    g.beginPath(); g.moveTo(pts[0][0], pts[0][1]);
    for (i = 1; i < pts.length; i++) { g.lineTo(pts[i][0], pts[i][1]); }
    g.closePath(); g.fillStyle = fill; g.fill();
  }
  function box(x0, y0, w, d, h, top, south, east, z0) {
    var z = z0 || 0;
    poly([W2(x0, y0 + d, z), W2(x0 + w, y0 + d, z), W2(x0 + w, y0 + d, z + h), W2(x0, y0 + d, z + h)], south);
    poly([W2(x0 + w, y0 + d, z), W2(x0 + w, y0, z), W2(x0 + w, y0, z + h), W2(x0 + w, y0 + d, z + h)], east);
    poly([W2(x0, y0, z + h), W2(x0 + w, y0, z + h), W2(x0 + w, y0 + d, z + h), W2(x0, y0 + d, z + h)], top);
  }
  function line(a, b, col, wdt) {
    g.strokeStyle = col; g.lineWidth = wdt || 1;
    g.beginPath(); g.moveTo(a[0], a[1]); g.lineTo(b[0], b[1]); g.stroke();
  }
  function wallH(x, y) {
    if (y === 0 || x === 0) { return 1.5; }
    if (x === room.w - 1 || y === room.h - 1) { return 0.35; }
    return 0.55;
  }
  function objOf(id) { return Rules.objById(room, id); }
  function inView(fx, fy) {
    var p = W2(fx, fy, 0);
    return Math.abs(p[0] - cam.x) < VW / 2 + TW * 1.5 && p[1] - cam.y > -VH / 2 - TW * 1.5 && p[1] - cam.y < VH / 2 + TW * 3;
  }

  function drawFloor() {
    var x, y, c, k, col;
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        c = room.map[y].charAt(x);
        if (c === '#' || c === 'C' || c === 'T') { continue; }
        if (!inView(x + 0.5, y + 0.5)) { continue; }
        k = floorKind[y][x];
        col = FLOOR[k][(x + y) % 2];
        if (c === 'D') { col = S.doorOpen ? '#ffe9a8' : '#3e2c22'; }
        if (c === 'H') { col = '#07040b'; }
        poly([W2(x, y), W2(x + 1, y), W2(x + 1, y + 1), W2(x, y + 1)], col);
        if (k === 'wood' || k === 'boards') { line(W2(x, y + 0.5), W2(x + 1, y + 0.5), 'rgba(0,0,0,.15)', 1); }
      }
    }
  }

  // Everything with height is a sprite, drawn back to front.
  function buildSprites() {
    var list = [], x, y, c, i, o, ch, p;
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        c = room.map[y].charAt(x);
        if (c === '.') { continue; }
        if (!inView(x + 0.5, y + 0.5)) { continue; }
        if (c === 'D' && S.doorOpen) { list.push({ d: x + y, k: 'doorframe', x: x, y: y }); continue; }
        if (c === 'H' && S.holeOpen) { continue; }
        if (c === 'T') { list.push({ d: x + y, k: 'furn', x: x, y: y }); continue; }
        list.push({ d: x + y, k: 'wall', x: x, y: y, c: c });
      }
    }
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i];
      if (o.kind === 'door' || o.kind === 'hole') { continue; }
      list.push({ d: o.x + o.y + (o.y === 0 ? 0.05 : 0.1), k: 'obj', o: o });
    }
    o = objOf('cage');
    list.push({ d: o.x + o.y + 0.6, k: 'bars', o: o });
    list.push({ d: 30.5, k: 'cake' });
    for (i = 0; i < S.chars.length; i++) {
      ch = S.chars[i]; p = rp[ch.id];
      if (!p || ch.hidden || ch.escaped) { continue; }
      list.push({ d: p.x + p.y + 0.3, k: 'char', c: ch, p: p });
    }
    if (S.creature.active && kp) { list.push({ d: kp.x + kp.y + 0.35, k: 'creature' }); }
    list.sort(function (a, b) { return a.d - b.d; });
    return list;
  }

  function drawWall(x, y, c) {
    var h = wallH(x, y), k;
    box(x, y, 1, 1, h, '#5a4278', '#3d2a55', '#30203f');
    if (y === 0) {
      for (k = 0; k < 2; k++) { line(W2(x + 0.3 + k * 0.4, y + 1, 0.05), W2(x + 0.3 + k * 0.4, y + 1, h - 0.05), 'rgba(255,138,31,.12)', Math.max(1, TW * 0.05)); }
    }
    if (x === 0) {
      for (k = 0; k < 2; k++) { line(W2(x + 1, y + 0.3 + k * 0.4, 0.05), W2(x + 1, y + 0.3 + k * 0.4, h - 0.05), 'rgba(255,138,31,.10)', Math.max(1, TW * 0.05)); }
    }
    if (c === 'C') {
      poly([W2(1, y + 0.15, 0), W2(1, y + 0.85, 0), W2(1, y + 0.85, 1.1), W2(1, y + 0.15, 1.1)], '#07040b');
      var e = W2(1, y + 0.45, 0.75);
      circ(g, e[0] - TW * 0.05, e[1], TW * 0.03, 'rgba(255,60,60,.8)'); circ(g, e[0] + TW * 0.05, e[1] + TW * 0.02, TW * 0.03, 'rgba(255,60,60,.8)');
    }
    if (c === 'D') {
      poly([W2(x + 0.12, 1, 0), W2(x + 0.88, 1, 0), W2(x + 0.88, 1, 1.25), W2(x + 0.12, 1, 1.25)], '#7a4a1e');
      poly([W2(x + 0.2, 1, 0.75), W2(x + 0.8, 1, 0.75), W2(x + 0.8, 1, 1.15), W2(x + 0.2, 1, 1.15)], '#5c3614');
      var kc = ['red', 'blue', 'yellow', 'green'], q, kpp;
      poly([W2(x + 0.3, 1, 0.3), W2(x + 0.7, 1, 0.3), W2(x + 0.7, 1, 0.65), W2(x + 0.3, 1, 0.65)], '#222');
      for (q = 0; q < 4; q++) {
        kpp = W2(x + 0.4 + (q % 2) * 0.2, 1, 0.55 - Math.floor(q / 2) * 0.17);
        circ(g, kpp[0], kpp[1], TW * 0.035, COLOR_HEX[kc[q]]);
      }
      kpp = W2(x + 0.8, 1, 0.5); circ(g, kpp[0], kpp[1], TW * 0.03, '#ffd23f');
    }
  }

  function drawFurn(x, y) {
    var k = furnKind[x + ',' + y] || 'table', i, a;
    if (k === 'table') { box(x, y, 1, 1, 0.45, '#f2e9f7', '#ff8a1f', '#e07818'); }
    else if (k === 'counter') { box(x, y, 1, 1, 0.6, '#cfc8bb', '#8b6a4f', '#735540'); }
    else if (k === 'shelf') {
      box(x, y + 0.2, 1, 0.6, 0.95, '#5c3a22', '#6b4226', '#4e2f1a');
      var cols = ['#e8505b', '#3d8bff', '#ffd23f', '#46d160', '#8a6bd1'];
      for (i = 0; i < 4; i++) {
        a = x + 0.1 + i * 0.22;
        poly([W2(a, y + 0.8, 0.5), W2(a + 0.16, y + 0.8, 0.5), W2(a + 0.16, y + 0.8, 0.8), W2(a, y + 0.8, 0.8)], cols[(x + i) % 5]);
        poly([W2(a, y + 0.8, 0.1), W2(a + 0.16, y + 0.8, 0.1), W2(a + 0.16, y + 0.8, 0.4), W2(a, y + 0.8, 0.4)], cols[(x + i + 2) % 5]);
      }
    }
  }

  function drawObj(o, t) {
    var st = S.obj[o.id] || {}, gp = W2(o.x + 0.5, o.y + 0.5, 0), s = TW, h = 0.5, k;
    if (o.kind === 'balloon') {
      h = 1.5;
      var by = gp[1] - s * 0.95 + Math.sin(t * 2 + o.n) * s * 0.05;
      if (!st.popped) {
        line([gp[0], gp[1]], [gp[0], by + s * 0.28], '#ddd', 1);
        g.fillStyle = '#efe9f5'; ell(g, gp[0], by, s * 0.22, s * 0.27); g.fill();
        g.fillStyle = 'rgba(255,255,255,.7)'; ell(g, gp[0] - s * 0.07, by - s * 0.1, s * 0.05, s * 0.08); g.fill();
        g.fillStyle = '#3a2a4f'; g.font = 'bold ' + Math.round(s * 0.28) + 'px sans-serif';
        g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(String(o.n + 1), gp[0], by + s * 0.02);
      } else {
        g.fillStyle = COLOR_HEX[S.code[o.n]];
        for (k = 0; k < 8; k++) { g.fillRect(gp[0] + s * (((k * 37) % 60) / 100 - 0.3), gp[1] + s * (((k * 23) % 24) / 100 - 0.12), s * 0.08, s * 0.05); }
        g.beginPath(); g.arc(gp[0], gp[1] - s * 0.3, s * 0.17, 0, Math.PI * 2); g.fill();
        g.fillStyle = '#fff'; g.font = 'bold ' + Math.round(s * 0.22) + 'px sans-serif';
        g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(String(o.n + 1), gp[0], gp[1] - s * 0.29);
      }
    } else if (o.kind === 'present') {
      h = 0.4;
      var blue = o.boost === 'shield';
      box(o.x + 0.27, o.y + 0.27, 0.46, 0.46, 0.32, blue ? '#5aa0ff' : '#ff6b75', blue ? '#3d8bff' : '#e8505b', blue ? '#2c6bd1' : '#c43a45');
      if (!st.opened) {
        line(W2(o.x + 0.5, o.y + 0.27, 0.32), W2(o.x + 0.5, o.y + 0.73, 0.32), '#ffd23f', Math.max(2, s * 0.04));
        line(W2(o.x + 0.27, o.y + 0.5, 0.32), W2(o.x + 0.73, o.y + 0.5, 0.32), '#ffd23f', Math.max(2, s * 0.04));
        var bw = W2(o.x + 0.5, o.y + 0.5, 0.36);
        g.fillStyle = '#ffd23f'; ell(g, bw[0] - s * 0.06, bw[1], s * 0.06, s * 0.04); g.fill(); ell(g, bw[0] + s * 0.06, bw[1], s * 0.06, s * 0.04); g.fill();
      }
    } else if (o.kind === 'cabinet') {
      h = 1.2;
      var off = st.moved ? 0.9 : 0;
      box(o.x + 0.1, o.y + 0.1 + off, 0.8, 0.8, 1.2, '#7d5233', '#5c3a22', '#4a2e1b');
      line(W2(o.x + 0.1, o.y + 0.9 + off, 0.6), W2(o.x + 0.9, o.y + 0.9 + off, 0.6), 'rgba(0,0,0,.4)', 2);
      var kb = W2(o.x + 0.5, o.y + 0.9 + off, 0.9); circ(g, kb[0], kb[1], s * 0.03, '#d9b26f');
      kb = W2(o.x + 0.5, o.y + 0.9 + off, 0.35); circ(g, kb[0], kb[1], s * 0.03, '#d9b26f');
    } else if (o.kind === 'cage') {
      h = 1.2;
      box(o.x, o.y, 1, 1, 0.06, '#3a3a44', '#2b2b33', '#222229');
    } else if (o.kind === 'invite') {
      h = 1.2;
      poly([W2(o.x + 0.2, 1, 0.5), W2(o.x + 0.8, 1, 0.55), W2(o.x + 0.8, 1, 1.2), W2(o.x + 0.2, 1, 1.15)], '#f7e7c4');
      poly([W2(o.x + 0.2, 1, 1.03), W2(o.x + 0.8, 1, 1.08), W2(o.x + 0.8, 1, 1.2), W2(o.x + 0.2, 1, 1.15)], '#ff8a1f');
      for (k = 0; k < 3; k++) { line(W2(o.x + 0.3, 1, 0.92 - k * 0.13), W2(o.x + 0.7, 1, 0.95 - k * 0.13), '#8a3fd1', Math.max(1, s * 0.025)); }
    } else if (o.kind === 'uv') {
      h = 1.2;
      if (S.uvLit) {
        poly([W2(o.x - 0.3, 1, 0.4), W2(o.x + 1.3, 1, 0.4), W2(o.x + 1.3, 1, 1.3), W2(o.x - 0.3, 1, 1.3)], 'rgba(170,90,255,.35)');
        for (k = 0; k < 3; k++) { var dp = W2(o.x + k * 0.5, 1, 0.85); circ(g, dp[0], dp[1], s * 0.13, COLOR_HEX[S.code[k]]); }
      } else {
        line(W2(o.x - 0.2, 1, 0.7), W2(o.x + 0.4, 1, 1.0), 'rgba(200,170,255,.25)', Math.max(1, s * 0.04));
        line(W2(o.x + 0.4, 1, 1.0), W2(o.x + 1.1, 1, 0.75), 'rgba(200,170,255,.25)', Math.max(1, s * 0.04));
      }
    } else if (o.kind === 'hide') {
      h = drawHide(o);
    }
    return h;
  }

  function drawHide(o) {
    var x = o.x, y = o.y, k;
    if (o.look === 'wardrobe') {
      box(x + 0.08, y + 0.15, 0.84, 0.7, 1.7, '#5c3a22', '#6b4226', '#4e2f1a');
      line(W2(x + 0.5, y + 0.85, 0.1), W2(x + 0.5, y + 0.85, 1.6), 'rgba(0,0,0,.45)', 2);
      var kb = W2(x + 0.45, y + 0.85, 0.9); circ(g, kb[0], kb[1], TW * 0.03, '#d9b26f');
      kb = W2(x + 0.55, y + 0.85, 0.9); circ(g, kb[0], kb[1], TW * 0.03, '#d9b26f');
      return 1.7;
    }
    if (o.look === 'curtain') {
      box(x + 0.05, y + 0.1, 0.9, 0.3, 1.7, '#a02a50', '#7a1f3d', '#5e1730');
      for (k = 0; k < 4; k++) { line(W2(x + 0.15 + k * 0.22, y + 0.4, 0.05), W2(x + 0.15 + k * 0.22, y + 0.4, 1.65), 'rgba(0,0,0,.25)', Math.max(1, TW * 0.04)); }
      box(x, y + 0.05, 1, 0.4, 0.05, '#ffd23f', '#d9a800', '#c49500', 1.7);
      return 1.7;
    }
    if (o.look === 'cloth') {
      box(x, y, 1, 0.35, 0.45, '#f2e9f7', '#e9dff0', '#d8cde2');
      for (k = 0; k < 3; k++) { var sc = W2(x + 0.17 + k * 0.33, y + 0.35, 0.02); circ(g, sc[0], sc[1], TW * 0.08, '#ff8a1f'); }
      return 0.5;
    }
    if (o.look === 'sofa') {
      box(x + 0.05, y + 0.05, 0.9, 0.3, 0.7, '#8a66c4', '#5b3b8a', '#4a2f73');
      box(x + 0.05, y + 0.35, 0.9, 0.6, 0.3, '#7a55b3', '#5b3b8a', '#4a2f73');
      return 0.7;
    }
    box(x + 0.12, y + 0.12, 0.76, 0.76, 0.7, '#d9ab6b', '#c99a5b', '#a87a40');
    var q = W2(x + 0.5, y + 0.88, 0.35);
    g.fillStyle = '#3a2a4f'; g.font = 'bold ' + Math.round(TW * 0.25) + 'px sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
    g.fillText('?', q[0], q[1]);
    return 0.7;
  }

  function drawBars(o) {
    var t, x = o.x, y = o.y;
    for (t = 0; t <= 1.001; t += 0.25) {
      line(W2(x + t, y + 1, 0), W2(x + t, y + 1, 1.15), '#9a9aa8', Math.max(2, TW * 0.04));
      line(W2(x + 1, y + t, 0), W2(x + 1, y + t, 1.15), '#9a9aa8', Math.max(2, TW * 0.04));
    }
    poly([W2(x, y, 1.15), W2(x + 1, y, 1.15), W2(x + 1, y + 1, 1.15), W2(x, y + 1, 1.15)], 'rgba(60,60,72,.85)');
    var l = W2(x + 0.5, y + 1, 0.6);
    g.fillStyle = '#ffd23f'; rr(g, l[0] - TW * 0.08, l[1] - TW * 0.06, TW * 0.16, TW * 0.13, TW * 0.03); g.fill();
  }

  function drawCake() {
    box(14.6, 13.6, 0.8, 0.8, 0.3, '#f7c6d9', '#e8a9c1', '#d98fab', 0.45);
    box(14.6, 13.6, 0.8, 0.8, 0.06, '#8a3fd1', '#7a32bd', '#6b28a8', 0.6);
    var cd = W2(15, 14, 0.75);
    g.fillStyle = '#fff'; g.fillRect(cd[0] - TW * 0.02, cd[1] - TW * 0.12, TW * 0.04, TW * 0.12);
    circ(g, cd[0], cd[1] - TW * 0.15, TW * 0.04, '#ffd23f');
  }

  function peek(o, n, t, h) {
    var p = W2(o.x + 0.5, o.y + 0.5, h * 0.75), i, X, blink;
    for (i = 0; i < n; i++) {
      X = p[0] + (n > 1 ? (i - 0.5) * TW * 0.3 : 0);
      blink = Math.sin(t * 1.7 + i * 3) > 0.96 ? 0.2 : 1;
      g.fillStyle = '#fff';
      ell(g, X - TW * 0.06, p[1], TW * 0.045, TW * 0.055 * blink); g.fill();
      ell(g, X + TW * 0.06, p[1], TW * 0.045, TW * 0.055 * blink); g.fill();
      circ(g, X - TW * 0.05, p[1], TW * 0.022, '#111'); circ(g, X + TW * 0.07, p[1], TW * 0.022, '#111');
    }
  }

  function frame() {
    requestAnimationFrame(frame);
    if ($('title').className.indexOf('on') >= 0) { drawTitle(); return; }
    if (!gameOn || !S || !room || !VW) { return; }
    var t = Date.now() / 1000, dt = Math.min(0.1, t - (frame.last || t)), i, c, p, hid = {}, list, sp, k = S.creature, hh = {};
    frame.last = t;
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i];
      p = rp[c.id] || (rp[c.id] = { x: c.x, y: c.y });
      glide(p, c.x, c.y, c.running ? 5.5 : 2.8, dt);
      if (c.hidden) { hid[c.hideId] = (hid[c.hideId] || 0) + 1; }
    }
    if (!kp) { kp = { x: k.x, y: k.y }; }
    glide(kp, k.x, k.y, k.mode === 'hunt' ? 3.6 : 2.0, dt);
    // camera follows the selected character, plus any drag
    c = me(); p = c && rp[c.id];
    var tg = p ? W2(p.x + 0.5, p.y + 0.5, 0) : W2(room.w / 2, room.h / 2, 0);
    var tx = tg[0] + pan.x, ty = tg[1] - TW * 0.3 + pan.y, f = dragging ? 1 : Math.min(1, dt * 5);
    cam.x += (tx - cam.x) * f; cam.y += (ty - cam.y) * f;
    var minX = -room.h * TW / 2, maxX = room.w * TW / 2, minY = -1.6 * ZP, maxY = (room.w + room.h) * TH / 2;
    cam.x = maxX - minX < VW ? (minX + maxX) / 2 : Math.max(minX + VW / 2 - TW, Math.min(maxX - VW / 2 + TW, cam.x));
    cam.y = maxY - minY < VH ? (minY + maxY) / 2 : Math.max(minY + VH / 2 - TW, Math.min(maxY - VH / 2 + TW, cam.y));

    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.fillStyle = '#0e0816'; g.fillRect(0, 0, VW, VH);
    g.save();
    var sx = 0, sy = 0;
    if (shake > 0.2) { sx = (Math.random() - 0.5) * shake; sy = (Math.random() - 0.5) * shake; shake *= 0.88; } else { shake = 0; }
    g.translate(Math.round(VW / 2 - cam.x + sx), Math.round(VH / 2 - cam.y + sy));
    drawFloor();
    drawPings(t);
    list = buildSprites();
    sprites = [];
    for (i = 0; i < list.length; i++) {
      sp = list[i];
      if (sp.k === 'wall') { drawWall(sp.x, sp.y, sp.c); }
      else if (sp.k === 'doorframe') {
        box(sp.x, sp.y, 0.1, 1, 1.5, '#7a4a1e', '#5c3614', '#4a2b10');
        box(sp.x + 0.9, sp.y, 0.1, 1, 1.5, '#7a4a1e', '#5c3614', '#4a2b10');
      }
      else if (sp.k === 'furn') { drawFurn(sp.x, sp.y); }
      else if (sp.k === 'cake') { drawCake(); }
      else if (sp.k === 'obj') {
        var oh = drawObj(sp.o, t), gp = W2(sp.o.x + 0.5, sp.o.y + (sp.o.y === 0 ? 1 : 0.5), sp.o.y === 0 ? 0.6 : 0);
        hh[sp.o.id] = oh;
        sprites.push({ kind: 'obj', o: sp.o, x0: gp[0] - TW * 0.45, x1: gp[0] + TW * 0.45, y0: gp[1] - oh * ZP - TW * 0.35, y1: gp[1] + TH * 0.5 });
        if (sp.o.kind === 'hide' && hid[sp.o.id]) { peek(sp.o, hid[sp.o.id], t, oh); }
      }
      else if (sp.k === 'bars') { drawBars(sp.o); }
      else if (sp.k === 'char') {
        c = sp.c; p = sp.p;
        var cp = W2(p.x + 0.5, p.y + 0.5, 0);
        drawChar(g, cp[0], cp[1], TW * 0.9, c.char, {
          t: t + i, moving: Math.abs(p.x - c.x) + Math.abs(p.y - c.y) > 0.05, selected: c.id === sel && !c.caged,
          scared: c.caged || (k.mode === 'hunt' && k.target === c.id), look: k.active ? (kp.x - kp.y < p.x - p.y ? -1 : 1) : 0,
          alpha: S.tick < c.sneakUntil ? 0.45 : undefined
        });
        if (c.chan) { drawChan(cp, c.chan); }
        drawBubble(c.id, cp, t);
        if (!c.caged) { sprites.push({ kind: 'char', id: c.id, x0: cp[0] - TW * 0.35, x1: cp[0] + TW * 0.35, y0: cp[1] - TW * 0.85, y1: cp[1] + TH * 0.3 }); }
      }
      else if (sp.k === 'creature') {
        var kpp = W2(kp.x + 0.5, kp.y + 0.5, 0);
        drawCreature(g, kpp[0], kpp[1], TW, { t: t, mode: k.mode, moving: Math.abs(kp.x - k.x) + Math.abs(kp.y - k.y) > 0.05, stunned: k.pause > 0 });
      }
    }
    drawParts(dt);
    drawHint(t, hh);
    g.restore();
    drawDark(t, sx, sy);
    drawMini();
    sounds(t);
  }
  function glide(p, x, y, speed, dt) {
    var dx = x - p.x, dy = y - p.y, d = Math.sqrt(dx * dx + dy * dy), m = speed * dt * 1.15;
    if (d > 2.5 || d <= m) { p.x = x; p.y = y; return; }
    p.x += dx / d * m; p.y += dy / d * m;
  }
  function drawChan(cp, ch) {
    var x = cp[0], y = cp[1] - TW * 1.05, f = 1 - ch.left / ch.total;
    g.lineWidth = Math.max(3, TW * 0.08);
    g.strokeStyle = 'rgba(0,0,0,.5)'; g.beginPath(); g.arc(x, y, TW * 0.16, 0, Math.PI * 2); g.stroke();
    g.strokeStyle = '#7be36b'; g.beginPath(); g.arc(x, y, TW * 0.16, -Math.PI / 2, -Math.PI / 2 + f * Math.PI * 2); g.stroke();
  }
  function drawBubble(id, cp, t) {
    var b = bubbles[id], w, x, y, fs;
    if (!b || b.until < Date.now()) { return; }
    fs = Math.max(13, Math.round(TW * 0.22));
    g.font = 'bold ' + fs + 'px sans-serif';
    w = g.measureText(b.text).width + fs;
    x = cp[0] - w / 2; y = cp[1] - TW * 1.45 - fs * 1.6;
    g.fillStyle = '#fff'; rr(g, x, y, w, fs * 1.6, fs * 0.5); g.fill();
    g.beginPath(); g.moveTo(cp[0] - fs * 0.3, y + fs * 1.6); g.lineTo(cp[0] + fs * 0.3, y + fs * 1.6); g.lineTo(cp[0], y + fs * 2.2); g.closePath(); g.fill();
    g.fillStyle = '#1a1026'; g.textAlign = 'center'; g.textBaseline = 'middle';
    g.fillText(b.text, cp[0], y + fs * 0.82);
  }
  function drawPings(t) {
    var i, q, p, a;
    for (i = pings.length - 1; i >= 0; i--) {
      q = pings[i];
      if (q.until < Date.now()) { pings.splice(i, 1); continue; }
      a = 0.5 + 0.5 * Math.sin(t * 10);
      g.strokeStyle = 'rgba(255,210,63,' + a + ')'; g.lineWidth = Math.max(3, TW * 0.06);
      g.beginPath();
      p = [W2(q.x, q.y), W2(q.x + 1, q.y), W2(q.x + 1, q.y + 1), W2(q.x, q.y + 1)];
      g.moveTo(p[0][0], p[0][1]); g.lineTo(p[1][0], p[1][1]); g.lineTo(p[2][0], p[2][1]); g.lineTo(p[3][0], p[3][1]); g.closePath(); g.stroke();
      p = W2(q.x + 0.5, q.y + 0.5, 1.2 + 0.15 * Math.sin(t * 6));
      g.fillStyle = '#ffd23f'; g.font = 'bold ' + Math.round(TW * 0.5) + 'px sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
      g.fillText('!', p[0], p[1]);
    }
  }
  function drawDark(t, sx, sy) {
    var i, c, p, r, d, grd, k = S.creature, ox = VW / 2 - cam.x + sx, oy = VH / 2 - cam.y + sy, q;
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    if (S.spook !== 'spooky') {
      g.fillStyle = 'rgba(20,8,40,.14)'; g.fillRect(0, 0, VW, VH);
      return;
    }
    d = dark.getContext('2d');
    d.setTransform(dpr, 0, 0, dpr, 0, 0);
    d.globalCompositeOperation = 'source-over';
    d.clearRect(0, 0, VW, VH);
    d.fillStyle = 'rgba(4,2,10,.9)'; d.fillRect(0, 0, VW, VH);
    d.globalCompositeOperation = 'destination-out';
    function hole(wp, rad) {
      var x = wp[0] + ox, y = wp[1] + oy;
      grd = d.createRadialGradient(x, y, rad * 0.25, x, y, rad);
      grd.addColorStop(0, 'rgba(0,0,0,1)'); grd.addColorStop(1, 'rgba(0,0,0,0)');
      d.fillStyle = grd; d.beginPath(); d.arc(x, y, rad, 0, Math.PI * 2); d.fill();
    }
    for (i = 0; i < S.chars.length; i++) {
      c = S.chars[i]; p = rp[c.id]; if (!p || c.escaped) { continue; }
      r = c.caged ? 1.2 : (c.char === 'glow' ? 5 : 3);
      hole(W2(p.x + 0.5, p.y + 0.5, 0.4), r * TW * 0.62 * (1 + Math.sin(t * 3 + i) * 0.03));
    }
    if (S.doorOpen) { q = objOf('door'); hole(W2(q.x + 0.5, q.y + 1, 0.5), 2.2 * TW); }
    if (S.uvLit) { q = objOf('uv'); hole(W2(q.x + 0.5, q.y + 1, 0.8), 1.8 * TW); }
    g.drawImage(dark, 0, 0, VW, VH);
    if (k.active && kp) {
      var e = W2(kp.x + 0.5, kp.y + 0.5, 0), col = k.mode === 'hunt' ? '#ff3b30' : '#ffe14d';
      var ex = e[0] + ox, ey = e[1] + oy - TW * 1.45;
      g.shadowColor = col; g.shadowBlur = TW * 0.3;
      circ(g, ex - TW * 0.13, ey, TW * 0.045, col); circ(g, ex + TW * 0.13, ey, TW * 0.045, col);
      g.shadowBlur = 0;
    }
  }
  function drawHint(t, hh) {
    if (!S.hint) { return; }
    var o = objOf(S.hint.obj); if (!o) { return; }
    var wall = o.y === 0, gp = W2(o.x + 0.5, wall ? 1 : o.y + 0.5, 0), top = W2(o.x + 0.5, wall ? 1 : o.y + 0.5, (hh[o.id] || 0.6) + (wall ? 1.4 : 0.5));
    var b = Math.abs(Math.sin(t * 4)) * TW * 0.25;
    g.strokeStyle = 'rgba(123,227,107,' + (0.5 + 0.5 * Math.sin(t * 6)) + ')'; g.lineWidth = Math.max(3, TW * 0.06);
    g.beginPath(); ell(g, gp[0], gp[1], TW * 0.6, TH * 0.6); g.stroke();
    g.fillStyle = '#7be36b';
    g.beginPath(); g.moveTo(top[0] - TW * 0.2, top[1] - b - TW * 0.25); g.lineTo(top[0] + TW * 0.2, top[1] - b - TW * 0.25); g.lineTo(top[0], top[1] - b + TW * 0.05); g.closePath(); g.fill();
  }
  function burst(fx, fy, col, n) {
    var i, p = W2(fx, fy, 0.6);
    for (i = 0; i < n; i++) {
      parts.push({ x: p[0], y: p[1], vx: (Math.random() - 0.5) * TW * 5, vy: -Math.random() * TW * 5, c: col || ['#ff4d5e', '#3d8bff', '#ffd23f', '#46d160'][i % 4], life: 1 });
    }
  }
  function drawParts(dt) {
    var i, q;
    for (i = parts.length - 1; i >= 0; i--) {
      q = parts[i];
      q.x += q.vx * dt; q.y += q.vy * dt; q.vy += TW * 9 * dt; q.life -= dt * 0.8;
      if (q.life <= 0) { parts.splice(i, 1); continue; }
      g.globalAlpha = Math.max(0, q.life);
      g.fillStyle = q.c; g.fillRect(q.x, q.y, TW * 0.1, TW * 0.07);
    }
    g.globalAlpha = 1;
  }
  function drawMini() {
    var x, y, c, i, ch, s = 5, k = S.creature;
    mg.clearRect(0, 0, mini.width, mini.height);
    for (y = 0; y < room.h; y++) {
      for (x = 0; x < room.w; x++) {
        c = room.map[y].charAt(x);
        mg.fillStyle = c === '#' || c === 'C' ? '#2a1d3d' : c === 'T' ? '#5a4a3a' : c === 'D' ? (S.doorOpen ? '#ffe9a8' : '#ff8a1f') : c === 'H' ? (S.holeOpen ? '#ffe9a8' : '#2a1d3d') : FLOOR[floorKind[y][x]][0];
        mg.fillRect(x * s, y * s, s, s);
      }
    }
    for (i = 0; i < S.chars.length; i++) {
      ch = S.chars[i]; if (ch.escaped) { continue; }
      mg.fillStyle = ch.id === sel ? '#7be36b' : '#ffffff';
      mg.fillRect(ch.x * s - 1, ch.y * s - 1, s + 2, s + 2);
    }
    if (k.active && dangerLevel() >= 3) { mg.fillStyle = '#ff3b30'; mg.fillRect(k.x * s - 1, k.y * s - 1, s + 2, s + 2); }
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
        SFX.chime(); o = e.how === 'shove' ? objOf('hole') : objOf('door'); burst(o.x + 0.5, o.y + 0.5, null, 26);
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
      case 'cleared': SFX.cheer(); setTimeout(endScreen, 900); break;
      case 'lost': SFX.laugh(); setTimeout(endScreen, 900); break;
      case 'sneak': SFX.sparkle(); toast('Shadow is sneaking - the host cannot see or grab Shadow for 6 seconds!', 'shadow', 2200); break;
      case 'notyet': toast('Sneak is recharging... ' + Math.ceil(e.wait / 10) + ' seconds', 'shadow', 1500); break;
      case 'say': bubbles[e.id] = { text: PHRASES[e.p], until: Date.now() + 2800 }; speak(PHRASES[e.p]); break;
      case 'hush': toast('Too many messages - wait a moment.', c ? c.char : null, 1500); break;
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

  // ---- input: tap to move, double-tap to run, hold to point, drag to look ----
  var pd = null;
  function toWorld(cx, cy) {
    var r = cv.getBoundingClientRect();
    return [cx - r.left - VW / 2 + cam.x, cy - r.top - VH / 2 + cam.y];
  }
  function toTile(w) {
    return [Math.floor(w[1] / TH + w[0] / TW), Math.floor(w[1] / TH - w[0] / TW)];
  }
  cv.addEventListener('pointerdown', function (ev) {
    if (!S || S.status !== 'playing') { return; }
    try { cv.setPointerCapture(ev.pointerId); } catch (e) { /* older browsers */ }
    pd = { id: ev.pointerId, x: ev.clientX, y: ev.clientY, drag: false, pinged: false, px: pan.x, py: pan.y };
    var start = pd;
    pd.timer = setTimeout(function () {
      if (pd === start && !pd.drag) { pd.pinged = true; pointAt(start.x, start.y); }
    }, 480);
  });
  cv.addEventListener('pointermove', function (ev) {
    if (!pd || ev.pointerId !== pd.id) { return; }
    var dx = ev.clientX - pd.x, dy = ev.clientY - pd.y;
    if (!pd.drag && Math.abs(dx) + Math.abs(dy) > 14) { pd.drag = true; dragging = true; clearTimeout(pd.timer); }
    if (pd.drag) { pan.x = pd.px - dx; pan.y = pd.py - dy; }
  });
  function endPointer(ev, cancelled) {
    if (!pd || ev.pointerId !== pd.id) { return; }
    var p = pd;
    clearTimeout(p.timer); pd = null; dragging = false;
    if (!cancelled && !p.drag && !p.pinged) { tapAt(ev.clientX, ev.clientY); }
  }
  cv.addEventListener('pointerup', function (ev) { endPointer(ev, false); });
  cv.addEventListener('pointercancel', function (ev) { endPointer(ev, true); });

  function pointAt(cx, cy) {
    var tl = toTile(toWorld(cx, cy));
    pings.push({ x: tl[0], y: tl[1], until: Date.now() + 3000 });
    tone(880, 0.12, 'triangle', 0.2); tone(1320, 0.15, 'triangle', 0.15, 0, 0.1);
  }
  function tapAt(cx, cy) {
    var w = toWorld(cx, cy), i, s, hit = null, tl, now = Date.now(), run, o;
    for (i = sprites.length - 1; i >= 0; i--) {
      s = sprites[i];
      if (w[0] >= s.x0 && w[0] <= s.x1 && w[1] >= s.y0 && w[1] <= s.y1) { hit = s; break; }
    }
    if (hit && hit.kind === 'char' && hit.id !== sel) { selectChar(hit.id); return; }
    tl = toTile(w);
    run = runMode || (now - lastTap.t < 380 && Math.abs(tl[0] - lastTap.x) <= 1 && Math.abs(tl[1] - lastTap.y) <= 1);
    lastTap = { t: now, x: tl[0], y: tl[1] };
    pan.x = 0; pan.y = 0;
    o = hit && hit.kind === 'obj' ? hit.o : objAt(tl[0], tl[1]);
    if (o) { T.send({ t: 'go', id: sel, act: o.id, run: run }); }
    else { T.send({ t: 'go', id: sel, x: tl[0], y: tl[1], run: run }); }
    var gp = W2(tl[0] + 0.5, tl[1] + 0.5, 0);
    parts.push({ x: gp[0], y: gp[1], vx: 0, vy: 0, c: run ? '#ff8a1f' : '#7be36b', life: 0.6 });
  }
  function objAt(x, y) {
    var i, o;
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i];
      if (o.x === x && o.y === y) {
        if (o.kind === 'hole' && !S.holeOpen) { return objOf('cab'); }
        return o;
      }
    }
    return null;
  }

  // ---- action bar ----
  function nearest(pred, maxD) {
    var c = me(), i, o, d, best = null, bd = 1e9;
    if (!c) { return null; }
    for (i = 0; i < room.objects.length; i++) {
      o = room.objects[i];
      if (!pred(o)) { continue; }
      d = Math.abs(o.x - c.x) + Math.abs(o.y - c.y);
      if (d < bd && d <= maxD) { bd = d; best = o; }
    }
    return best;
  }
  function anyCaged() {
    var i; for (i = 0; i < S.chars.length; i++) { if (S.chars[i].caged) { return true; } }
    return false;
  }
  function go(o) { if (o) { pan.x = 0; pan.y = 0; T.send({ t: 'go', id: sel, act: o.id, run: runMode }); } }
  function actRun() { runMode = !runMode; SFX.click(); paintBar(); toast(runMode ? '🏃 Running is ON - taps make you run (uses stamina).' : 'Walking. Double-tap still runs.', null, 1600); }
  function actHide() {
    var c = me(); if (!c) { return; }
    if (c.hidden) { T.send({ t: 'go', id: sel, x: c.x, y: c.y + 1 }); return; }
    var o = nearest(function (q) { return q.kind === 'hide'; }, 99);
    if (o) { go(o); }
  }
  function actUse() {
    var o = nearest(function (q) {
      var st = S.obj[q.id] || {};
      if (q.kind === 'balloon') { return !st.popped; }
      if (q.kind === 'present') { return !st.opened; }
      if (q.kind === 'cage') { return anyCaged(); }
      if (q.kind === 'door') { return true; }
      if (q.kind === 'hole') { return S.holeOpen; }
      return false;
    }, 4);
    if (o) { go(o); } else { toast('Nothing to use here - walk up to something!', me() ? me().char : null, 1800); }
  }
  function actSkill() {
    var c = me(); if (!c) { return; }
    if (c.char === 'shadow') { T.send({ t: 'sneak', id: sel }); return; }
    if (c.char === 'tinker') {
      if (S.doorOpen) { toast('The door is already open!', 'tinker', 1500); }
      else if (Rules.nearDoor(S, c)) { T.send({ t: 'pick', id: sel }); }
      else { go(objOf('door')); }
      return;
    }
    if (c.char === 'brainy') { if (S.obj.invite.read) { toast('Brainy already read it!', 'brainy', 1500); } else { go(objOf('invite')); } return; }
    if (c.char === 'muscle') { if (S.holeOpen) { toast('Already shoved!', 'muscle', 1500); } else { go(objOf('cab')); } return; }
    if (c.char === 'glow') { if (S.uvLit) { toast('Already lit up!', 'glow', 1500); } else { go(objOf('uv')); } }
  }
  function actSay() {
    var el = $('say');
    el.style.display = el.style.display === 'grid' ? 'none' : 'grid';
    SFX.click();
  }
  (function () {
    var box = $('say'), i;
    for (i = 0; i < PHRASES.length; i++) {
      (function (n) {
        var b = document.createElement('button');
        b.className = 'ph'; b.textContent = PHRASES[n];
        b.onclick = function () { T.send({ t: 'say', id: sel, p: n }); box.style.display = 'none'; };
        box.appendChild(b);
      })(i);
    }
  })();
  function speak(text) {
    try {
      if (!window.speechSynthesis || !window.SpeechSynthesisUtterance) { return; }
      var u = new SpeechSynthesisUtterance(text.replace(/^[^A-Za-z]+/, ''));
      u.rate = 1.05; u.pitch = 1.35;
      window.speechSynthesis.cancel();
      window.speechSynthesis.speak(u);
    } catch (e) { /* no voice on this device */ }
  }
  $('aRun').onclick = actRun;
  $('aHide').onclick = actHide;
  $('aUse').onclick = actUse;
  $('aSkill').onclick = actSkill;
  $('aSay').onclick = actSay;

  // PC keyboard: arrows/WASD move, 1-3 pick, R run, H hide, E use, Q skill, T talk, C clue
  document.addEventListener('keydown', function (ev) {
    if (!gameOn || !S || S.status !== 'playing') { return; }
    var k = ev.key, c = me(), d = null, done = true;
    if (k === '1' || k === '2' || k === '3') { if (S.chars[+k - 1]) { selectChar(S.chars[+k - 1].id); } }
    else if (k === 'r' || k === 'R') { actRun(); }
    else if (k === 'h' || k === 'H') { actHide(); }
    else if (k === 'e' || k === 'E' || k === ' ') { actUse(); }
    else if (k === 'q' || k === 'Q') { actSkill(); }
    else if (k === 't' || k === 'T') { actSay(); }
    else if (k === 'c' || k === 'C') { T.send({ t: 'clue', id: sel }); }
    else if (k === 'ArrowUp' || k === 'w' || k === 'W') { d = [-1, -1]; }
    else if (k === 'ArrowDown' || k === 's' || k === 'S') { d = [1, 1]; }
    else if (k === 'ArrowLeft' || k === 'a' || k === 'A') { d = [-1, 1]; }
    else if (k === 'ArrowRight' || k === 'd' || k === 'D') { d = [1, -1]; }
    else { done = false; }
    if (d && c) { pan.x = 0; pan.y = 0; T.send({ t: 'go', id: sel, x: c.x + d[0], y: c.y + d[1], run: runMode || ev.shiftKey }); }
    if (done) { ev.preventDefault(); }
  });

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
      $('overT').textContent = S.status === 'cleared' ? 'You escaped the Party House!' : 'The party is over... for now.';
      $('overP').innerHTML = html + '<br>⭐ ' + pts + ' points saved' +
        (S.status === 'cleared' ? '<br><br>More of the party arrives next week...' : '');
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

  // read-only look inside, for diagnosing from a browser console
  window.dykwya = { state: function () { return S; }, bubbles: function () { return bubbles; }, sel: function () { return sel; },
    draw: { chars: CHARS, order: ORDER, char: drawChar, host: drawCreature } };
  requestAnimationFrame(frame);
})();
