/* rules.js - the game's referee. Pure and deterministic: no DOM, no timers,
   no randomness except the seeded generator carried in the state. ES5 only.
   The same file runs in the page (solo) and, later, in the room server. */
var Rules = (function () {
  'use strict';

  var TPS = 10;                       // ticks per second
  var COLORS = ['red', 'blue', 'yellow', 'green'];
  var RUN_COST = 7;                   // stamina per cell run
  var PHRASES = 12;                   // size of the preset phrase list (text lives in the page)
  var ROOMS = {};

  function clone(o) { return JSON.parse(JSON.stringify(o)); }

  // mulberry32, state carried in s.rng
  function rnd(s) {
    s.rng = (s.rng + 0x6D2B79F5) | 0;
    var t = s.rng;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  function addRoom(def) {
    var i;
    if (def.map.length !== def.h) { throw new Error('room ' + def.id + ': map has ' + def.map.length + ' rows'); }
    for (i = 0; i < def.map.length; i++) {
      if (def.map[i].length !== def.w) { throw new Error('room ' + def.id + ': row ' + i + ' is ' + def.map[i].length + ' wide'); }
    }
    ROOMS[def.id] = def;
  }
  function room(s) { return ROOMS[s.room]; }

  function cellAt(r, x, y) {
    if (x < 0 || y < 0 || x >= r.w || y >= r.h) { return '#'; }
    return r.map[y].charAt(x);
  }
  function cheb(ax, ay, bx, by) { return Math.max(Math.abs(ax - bx), Math.abs(ay - by)); }

  function objById(r, id) {
    var i;
    for (i = 0; i < r.objects.length; i++) { if (r.objects[i].id === id) { return r.objects[i]; } }
    return null;
  }
  function objBlocks(s, x, y) {
    var r = room(s), i, o;
    for (i = 0; i < r.objects.length; i++) {
      o = r.objects[i];
      if (o.block && o.x === x && o.y === y && !(s.obj[o.id] && s.obj[o.id].moved)) { return true; }
    }
    return false;
  }
  function walkable(s, x, y) {
    var c = cellAt(room(s), x, y);
    if (c === '#' || c === 'T' || c === 'C') { return false; }
    if (c === 'D') { return s.doorOpen; }
    if (c === 'H') { return s.holeOpen; }
    return !objBlocks(s, x, y);
  }
  function creatureWalkable(s, x, y) {
    var c = cellAt(room(s), x, y);
    if (c === 'D' || c === 'H') { return false; }
    return walkable(s, x, y);
  }

  // Breadth-first search. Returns the cells to step through (excluding the
  // start), [] if the start is already a goal, or null if no route.
  var DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]];
  function bfs(s, sx, sy, isGoal, canWalk) {
    var r = room(s), q = [[sx, sy]], head = 0, seen = {}, prev = {}, c, i, nx, ny, nk, path, k, p;
    seen[sx + ',' + sy] = 1;
    while (head < q.length) {
      c = q[head++];
      if (isGoal(c[0], c[1])) {
        path = [];
        k = c[0] + ',' + c[1];
        while (k !== sx + ',' + sy) {
          p = k.split(',');
          path.unshift([+p[0], +p[1]]);
          k = prev[k];
        }
        return path;
      }
      for (i = 0; i < 4; i++) {
        nx = c[0] + DIRS[i][0]; ny = c[1] + DIRS[i][1];
        nk = nx + ',' + ny;
        if (nx < 0 || ny < 0 || nx >= r.w || ny >= r.h || seen[nk]) { continue; }
        if (!canWalk(nx, ny)) { continue; }
        seen[nk] = 1; prev[nk] = c[0] + ',' + c[1];
        q.push([nx, ny]);
      }
    }
    return null;
  }

  // Line of sight between cells; walls and tables block it.
  function los(s, x0, y0, x1, y1) {
    var r = room(s), dx = Math.abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    var dy = -Math.abs(y1 - y0), sy = y0 < y1 ? 1 : -1, err = dx + dy, x = x0, y = y0, e2, c;
    for (;;) {
      if (x === x1 && y === y1) { return true; }
      if (!(x === x0 && y === y0)) {
        c = cellAt(r, x, y);
        if (c === '#' || c === 'T') { return false; }
      }
      e2 = 2 * err;
      if (e2 >= dy) { err += dy; x += sx; }
      if (e2 <= dx) { err += dx; y += sy; }
    }
  }

  // Can a character standing at (x, y) use object o?
  function reaches(s, o, x, y) {
    if (o.kind === 'hide') { return x === o.x && y === o.y; }
    if (o.kind === 'door' && s.doorOpen) { return x === o.x && y === o.y; }
    if (o.kind === 'hole' && s.holeOpen) { return x === o.x && y === o.y; }
    return cheb(o.x, o.y, x, y) <= 1;
  }

  function event(s, k, data) {
    var e = data || {};
    if (e.n !== undefined || e.k !== undefined) { throw new Error('event data may not use n or k'); }
    s.evn += 1;
    e.n = s.evn; e.k = k;
    s.events.push(e);
    if (s.events.length > 40) { s.events.shift(); }
  }
  function charById(s, id) {
    var i;
    for (i = 0; i < s.chars.length; i++) { if (s.chars[i].id === id) { return s.chars[i]; } }
    return null;
  }
  function isFree(c) { return !c.caged && !c.escaped; }
  // Hidden or sneaking: the creature can neither see nor grab them.
  function unseen(s, c) { return c.hidden || s.tick < c.sneakUntil; }
  function addPoints(s, c, n) { s.points[c.id] = (s.points[c.id] || 0) + n; }

  function init(cfg) {
    var r = ROOMS[cfg.room], i, sq, seed = (cfg.seed >>> 0) || 1;
    if (!r) { throw new Error('unknown room ' + cfg.room); }
    var s = {
      v: 1, room: r.id, seed: seed, rng: seed,
      spook: cfg.spook === 'spooky' ? 'spooky' : 'giggly',
      tick: 0, status: 'playing', tries: cfg.tries || 0,
      squad: clone(cfg.squad), chars: [],
      creature: {
        x: r.spawn[0], y: r.spawn[1], active: false,
        appearAt: cfg.spook === 'spooky' ? 120 : 200,
        mode: 'wait', target: null, goal: null, wp: 0, cd: 0, lost: 0, pause: 0
      },
      obj: {}, code: [], known: [null, null, null], entry: [],
      doorOpen: false, holeOpen: false, uvLit: false,
      cluesLeft: 3, hint: null,
      points: cfg.points ? clone(cfg.points) : {},
      events: [], evn: cfg.evn || 0
    };
    for (i = 0; i < 3; i++) { s.code.push(COLORS[Math.floor(rnd(s) * COLORS.length)]); }
    for (i = 0; i < r.objects.length; i++) { s.obj[r.objects[i].id] = {}; }
    for (i = 0; i < s.squad.length; i++) {
      sq = s.squad[i];
      s.chars.push({
        id: sq.id, char: sq.char, owner: sq.owner,
        x: r.start[i][0], y: r.start[i][1],
        path: [], run: false, running: false, act: null, chan: null, moveCd: 0,
        stamina: 100, tired: false, energy: 100, shield: false, freeRunUntil: 0,
        hidden: false, hideId: null, caged: false, escaped: false,
        sneakUntil: 0, sneakReady: 0
      });
      if (s.points[sq.id] === undefined) { s.points[sq.id] = 0; }
    }
    return s;
  }

  // ---- acting on objects ----
  function startAct(s, c, o) {
    var st = s.obj[o.id], i, n;
    if (o.kind === 'hide') {
      n = 0;
      for (i = 0; i < s.chars.length; i++) {
        if (s.chars[i].hidden && s.chars[i].hideId === o.id && s.chars[i].id !== c.id) { n++; }
      }
      if (n >= (o.cap || 2)) { event(s, 'full', { id: c.id, obj: o.id }); return; }
      c.hidden = true; c.hideId = o.id;
      event(s, 'hide', { id: c.id, obj: o.id });
      return;
    }
    if (o.kind === 'door') {
      if (!s.doorOpen) { event(s, 'keypad', { id: c.id }); }
      return;
    }
    if (o.kind === 'cabinet' || o.kind === 'hole') {
      if (s.holeOpen) { return; }
      if (c.char === 'muscle') { c.chan = { act: 'shove', obj: 'cab', left: 30, total: 30 }; }
      else { event(s, 'need', { id: c.id, skill: 'muscle', obj: o.id }); }
      return;
    }
    if (o.kind === 'balloon') {
      if (!st.popped) { c.chan = { act: 'pop', obj: o.id, left: 8, total: 8 }; }
      return;
    }
    if (o.kind === 'present') {
      if (!st.opened) { c.chan = { act: 'open', obj: o.id, left: 8, total: 8 }; }
      return;
    }
    if (o.kind === 'invite') {
      if (c.char === 'brainy') { c.chan = { act: 'read', obj: o.id, left: 15, total: 15 }; }
      else { event(s, 'need', { id: c.id, skill: 'brainy', obj: o.id }); }
      return;
    }
    if (o.kind === 'uv') {
      if (s.uvLit) { return; }
      if (c.char === 'glow') { c.chan = { act: 'light', obj: o.id, left: 15, total: 15 }; }
      else { event(s, 'need', { id: c.id, skill: 'glow', obj: o.id }); }
      return;
    }
    if (o.kind === 'cage') {
      for (i = 0; i < s.chars.length; i++) {
        if (s.chars[i].caged) {
          n = s.spook === 'spooky' ? 30 : 20;
          c.chan = { act: 'rescue', obj: o.id, left: n, total: n };
          return;
        }
      }
    }
  }

  function alertTo(s, x, y) {
    var k = s.creature;
    if (!k.active || k.mode === 'hunt') { return; }
    k.mode = 'search'; k.goal = [x, y];
    event(s, 'alert', { x: x, y: y });
  }

  function finishAct(s, c, ch) {
    var r = room(s), o = objById(r, ch.obj), st = s.obj[ch.obj], i, j, d, nx, ny;
    if (ch.act === 'pop') {
      st.popped = true;
      s.known[o.n] = s.code[o.n];
      addPoints(s, c, 5);
      event(s, 'pop', { id: c.id, obj: o.id, idx: o.n, color: s.code[o.n] });
      alertTo(s, o.x, o.y);
    } else if (ch.act === 'open') {
      st.opened = true;
      addPoints(s, c, 5);
      if (o.boost === 'shield') { c.shield = true; }
      else { c.freeRunUntil = s.tick + 200; }
      event(s, 'boost', { id: c.id, obj: o.id, boost: o.boost });
    } else if (ch.act === 'read' || ch.act === 'light') {
      if (ch.act === 'read') { st.read = true; } else { s.uvLit = true; }
      for (i = 0; i < 3; i++) { s.known[i] = s.code[i]; }
      addPoints(s, c, 10);
      event(s, 'reveal', { id: c.id, by: c.char });
    } else if (ch.act === 'shove') {
      s.holeOpen = true; s.obj.cab.moved = true;
      addPoints(s, c, 25);
      event(s, 'open', { id: c.id, how: 'shove' });
    } else if (ch.act === 'pick') {
      s.doorOpen = true;
      addPoints(s, c, 25);
      event(s, 'open', { id: c.id, how: 'pick' });
    } else if (ch.act === 'rescue') {
      for (i = 0; i < s.chars.length; i++) {
        if (s.chars[i].caged) {
          s.chars[i].caged = false;
          for (j = 0; j < 4; j++) {
            d = DIRS[(j + 2) % 4]; nx = o.x + d[0]; ny = o.y + d[1];
            if (walkable(s, nx, ny)) { s.chars[i].x = nx; s.chars[i].y = ny; break; }
          }
          addPoints(s, c, 20);
          event(s, 'rescue', { id: c.id, freed: s.chars[i].id });
          break;
        }
      }
    }
  }

  function arrive(s, c) {
    var o;
    if (!c.act) { return; }
    o = objById(room(s), c.act);
    c.act = null;
    if (o) { startAct(s, c, o); }
  }

  function escape(s, c) {
    c.escaped = true; c.path = []; c.act = null; c.chan = null; c.hidden = false;
    addPoints(s, c, 15);
    event(s, 'escape', { id: c.id });
  }

  function stepChar(s, c) {
    var moving, free, canRun, nxt, cc, ch;
    if (!isFree(c)) { return; }
    moving = c.path.length > 0;
    if (c.chan) {
      c.chan.left -= 1;
      if (c.chan.left <= 0) { ch = c.chan; c.chan = null; finishAct(s, c, ch); }
    }
    if (moving) {
      if (c.moveCd > 0) { c.moveCd -= 1; }
      if (c.moveCd <= 0) {
        free = s.tick < c.freeRunUntil;
        canRun = c.run && !c.tired && (free || c.stamina >= RUN_COST);
        nxt = c.path[0];
        if (!walkable(s, nxt[0], nxt[1])) {
          c.path = []; c.act = null;
        } else {
          c.path.shift();
          c.x = nxt[0]; c.y = nxt[1];
          c.running = canRun;
          if (canRun && !free) {
            c.stamina -= RUN_COST;
            if (c.stamina < RUN_COST) { c.tired = true; event(s, 'puffed', { id: c.id }); }
          }
          c.moveCd = canRun ? 2 : (c.energy <= 0 ? 5 : 4);
          cc = cellAt(room(s), c.x, c.y);
          if (cc === 'D' || cc === 'H') { escape(s, c); return; }
          if (c.path.length === 0) { arrive(s, c); }
        }
      }
    } else {
      c.running = false;
    }
    if (!(c.path.length > 0 && c.running)) {
      c.stamina = Math.min(100, c.stamina + (c.hidden ? 3 : 1.5));
      if (c.tired && c.stamina >= 25) { c.tired = false; }
    }
  }

  function creatureTick(s) {
    var r = room(s), k = s.creature, i, c, range, d, best = 99, seen = null, goal, wp, p;
    if (!k.active) {
      if (s.tick >= k.appearAt) {
        k.active = true; k.mode = 'patrol';
        event(s, 'appear', {});
      }
      return;
    }
    if (k.pause > 0) { k.pause -= 1; return; }
    for (i = 0; i < s.chars.length; i++) {
      c = s.chars[i];
      if (!isFree(c) || unseen(s, c)) { continue; }
      range = c.char === 'shadow' ? 2 : (s.spook === 'spooky' ? 5 : 4);
      d = cheb(k.x, k.y, c.x, c.y);
      if (d <= range && d < best && los(s, k.x, k.y, c.x, c.y)) { best = d; seen = c; }
    }
    if (seen) {
      if (k.mode !== 'hunt') { event(s, 'spotted', { id: seen.id }); }
      k.mode = 'hunt'; k.target = seen.id; k.goal = [seen.x, seen.y]; k.lost = 0;
    } else if (k.mode === 'hunt') {
      k.lost += 1;
      if (k.lost > 30) { k.mode = 'patrol'; k.lost = 0; event(s, 'gone', {}); }
    }
    if (k.cd > 0) { k.cd -= 1; return; }
    if (k.mode === 'patrol') {
      wp = r.patrol[k.wp];
      if (k.x === wp[0] && k.y === wp[1]) { k.wp = (k.wp + 1) % r.patrol.length; wp = r.patrol[k.wp]; }
      goal = wp;
    } else {
      goal = k.goal;
    }
    if (!goal) { return; }
    if (k.x === goal[0] && k.y === goal[1]) {
      if (k.mode === 'search') { k.mode = 'patrol'; k.pause = 20; event(s, 'sniff', {}); }
      return;
    }
    p = bfs(s, k.x, k.y, function (x, y) { return x === goal[0] && y === goal[1]; },
      function (x, y) { return creatureWalkable(s, x, y); });
    if (!p) {
      p = bfs(s, k.x, k.y, function (x, y) { return cheb(x, y, goal[0], goal[1]) <= 1; },
        function (x, y) { return creatureWalkable(s, x, y); });
    }
    if (p && p.length) { k.x = p[0][0]; k.y = p[0][1]; }
    else if (k.mode === 'search') { k.mode = 'patrol'; }
    k.cd = k.mode === 'hunt' ? (s.spook === 'spooky' ? 3 : 4) : (k.mode === 'search' ? 5 : 6);
  }

  function catchCheck(s) {
    var r = room(s), k = s.creature, cage = objById(r, 'cage'), i, c;
    if (!k.active || k.pause > 0) { return; }
    for (i = 0; i < s.chars.length; i++) {
      c = s.chars[i];
      if (!isFree(c) || unseen(s, c)) { continue; }
      if (Math.abs(k.x - c.x) + Math.abs(k.y - c.y) <= 1) {
        if (c.shield) {
          c.shield = false; k.pause = 25; k.mode = 'patrol';
          event(s, 'shield', { id: c.id });
        } else {
          c.caged = true; c.path = []; c.chan = null; c.act = null; c.running = false;
          c.x = cage.x; c.y = cage.y;
          k.pause = 20; k.mode = 'patrol';
          event(s, 'caught', { id: c.id });
        }
        return;
      }
    }
  }

  function checkEnd(s) {
    var i, c, free = 0, esc = 0;
    for (i = 0; i < s.chars.length; i++) {
      c = s.chars[i];
      if (isFree(c)) { free++; }
      if (c.escaped) { esc++; }
    }
    if (free > 0) { return; }
    if (esc > 0) {
      s.status = 'cleared';
      for (i = 0; i < s.chars.length; i++) { addPoints(s, s.chars[i], 20); }
      event(s, 'cleared', {});
    } else {
      s.status = s.tries + 1 >= 3 ? 'over' : 'lost';
      event(s, 'lost', {});
    }
  }

  function hintFor(s) {
    var r = room(s), i, anyCaged = false, has = {}, c, known = true;
    for (i = 0; i < s.chars.length; i++) {
      c = s.chars[i];
      if (c.caged) { anyCaged = true; }
      if (isFree(c)) { has[c.char] = true; }
    }
    for (i = 0; i < 3; i++) { if (!s.known[i]) { known = false; } }
    if (anyCaged) { return { obj: 'cage', say: 'Free your friend! Stand by the cage.' }; }
    if (s.doorOpen) { return { obj: 'door', say: 'The big door is open - everybody out!' }; }
    if (s.holeOpen) { return { obj: 'hole', say: 'The secret hole is open - squeeze through!' }; }
    if (known) { return { obj: 'door', say: 'You know the colours! Press them on the keypad by the big door.' }; }
    if (has.tinker) { return { obj: 'door', say: 'Tinker can pick the lock on the big door.' }; }
    if (has.muscle) { return { obj: 'cab', say: 'That cabinet is hiding something. Muscle can shove it!' }; }
    if (has.brainy && !s.obj.invite.read) { return { obj: 'invite', say: 'Brainy can read the twisty party invitation.' }; }
    if (has.glow && !s.uvLit) { return { obj: 'uv', say: 'Glow can light up the painted wall.' }; }
    for (i = 0; i < r.objects.length; i++) {
      if (r.objects[i].kind === 'balloon' && !s.obj[r.objects[i].id].popped) {
        return { obj: r.objects[i].id, say: 'Pop the balloons - each one hides a colour of the door code. Watch the numbers!' };
      }
    }
    return { obj: 'door', say: 'Try the keypad by the big door.' };
  }

  function nearDoor(s, c) {
    var d = objById(room(s), 'door');
    return isFree(c) && cheb(d.x, d.y, c.x, c.y) <= 1;
  }

  function apply(state, move) {
    var s = clone(state), r = room(s), c = charById(s, move.id), o, path = null, act = null, tx, ty, cost, i, ok;
    if (move.t === 'retry') {
      if (s.status !== 'lost') { return s; }
      return init({ room: s.room, squad: s.squad, seed: s.seed + 1, spook: s.spook,
        tries: s.tries + 1, points: s.points, evn: s.evn });
    }
    if (s.status !== 'playing') { return s; }
    if (move.t === 'go') {
      if (!c || !isFree(c)) { return s; }
      if (move.act) {
        o = objById(r, move.act);
        if (o) {
          act = o.id;
          path = bfs(s, c.x, c.y, function (x, y) { return reaches(s, o, x, y); },
            function (x, y) { return walkable(s, x, y); });
        }
      }
      if (!act) {
        tx = move.x | 0; ty = move.y | 0;
        if (walkable(s, tx, ty)) {
          path = bfs(s, c.x, c.y, function (x, y) { return x === tx && y === ty; },
            function (x, y) { return walkable(s, x, y); });
        } else {
          path = bfs(s, c.x, c.y, function (x, y) { return cheb(x, y, tx, ty) <= 1; },
            function (x, y) { return walkable(s, x, y); });
        }
      }
      if (path === null) { event(s, 'blocked', { id: c.id }); return s; }
      c.path = path; c.run = !!move.run; c.act = act; c.chan = null;
      if (path.length > 0 || act !== c.hideId) { c.hidden = false; c.hideId = null; }
      if (path.length === 0) { arrive(s, c); }
    } else if (move.t === 'stop') {
      if (c) { c.path = []; c.act = null; }
    } else if (move.t === 'press') {
      if (!c || !nearDoor(s, c) || s.doorOpen || COLORS.indexOf(move.c) < 0) { return s; }
      s.entry.push(move.c);
      event(s, 'press', { id: c.id, c: move.c });
      if (s.entry.length === 3) {
        ok = true;
        for (i = 0; i < 3; i++) { if (s.entry[i] !== s.code[i]) { ok = false; } }
        s.entry = [];
        if (ok) {
          s.doorOpen = true;
          addPoints(s, c, 25);
          event(s, 'open', { id: c.id, how: 'code' });
        } else {
          event(s, 'wrong', { id: c.id });
          o = objById(r, 'door');
          alertTo(s, o.x, o.y + 1);
        }
      }
    } else if (move.t === 'pick') {
      if (!c || c.char !== 'tinker' || !nearDoor(s, c) || s.doorOpen) { return s; }
      cost = s.spook === 'spooky' ? 50 : 40;
      c.path = []; c.chan = { act: 'pick', obj: 'door', left: cost, total: cost };
    } else if (move.t === 'clue') {
      if (!c || c.escaped || s.cluesLeft <= 0) { return s; }
      cost = c.char === 'brainy' ? 15 : 30;
      if (c.energy < cost) { event(s, 'tired', { id: c.id }); return s; }
      c.energy -= cost; s.cluesLeft -= 1;
      s.hint = hintFor(s); s.hint.until = s.tick + 150;
      event(s, 'clue', { id: c.id, obj: s.hint.obj, say: s.hint.say });
    } else if (move.t === 'sneak') {
      if (!c || c.char !== 'shadow' || !isFree(c)) { return s; }
      if (s.tick < c.sneakReady) { event(s, 'notyet', { id: c.id, wait: c.sneakReady - s.tick }); return s; }
      c.sneakUntil = s.tick + 60; c.sneakReady = s.tick + 200;
      event(s, 'sneak', { id: c.id });
    } else if (move.t === 'say') {
      // preset phrases only (an index into a fixed list); 3 per 10 seconds each
      if (!c || typeof move.p !== 'number' || move.p < 0 || move.p >= PHRASES || move.p % 1) { return s; }
      if (!s.said) { s.said = {}; }
      var recent = (s.said[c.id] || []).filter(function (t) { return s.tick - t < 100; });
      if (recent.length >= 3) { event(s, 'hush', { id: c.id }); return s; }
      recent.push(s.tick); s.said[c.id] = recent;
      event(s, 'say', { id: c.id, p: move.p });
    }
    return s;
  }

  function tick(state) {
    var s = clone(state), i;
    if (s.status !== 'playing') { return s; }
    s.tick += 1;
    for (i = 0; i < s.chars.length; i++) { stepChar(s, s.chars[i]); }
    creatureTick(s);
    catchCheck(s);
    if (s.hint && s.tick > s.hint.until) { s.hint = null; }
    checkEnd(s);
    return s;
  }

  function legalMoves(s, id) {
    var c = charById(s, id), r = room(s), out = [], i;
    if (!c || s.status !== 'playing') { return out; }
    if (isFree(c)) {
      for (i = 0; i < r.objects.length; i++) { out.push({ t: 'go', id: id, act: r.objects[i].id }); }
      if (nearDoor(s, c) && !s.doorOpen) {
        for (i = 0; i < COLORS.length; i++) { out.push({ t: 'press', id: id, c: COLORS[i] }); }
        if (c.char === 'tinker') { out.push({ t: 'pick', id: id }); }
      }
    }
    if (s.cluesLeft > 0) { out.push({ t: 'clue', id: id }); }
    return out;
  }

  function isOver(s) { return s.status === 'cleared' || s.status === 'over'; }

  return {
    TPS: TPS, COLORS: COLORS, PHRASES: PHRASES,
    addRoom: addRoom, getRoom: function (id) { return ROOMS[id]; },
    init: init, apply: apply, tick: tick, legalMoves: legalMoves, isOver: isOver,
    walkable: walkable, nearDoor: nearDoor, charById: charById, objById: objById,
    cellAt: cellAt
  };
})();
if (typeof module !== 'undefined' && module.exports) { module.exports = Rules; }
