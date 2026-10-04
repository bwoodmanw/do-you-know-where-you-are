/* Rules tests. Run: node test/rules.test.js */
var assert = require('assert');
var Rules = require('../src/rules.js');
require('../src/rooms.js');

var passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('ok   ' + name); }
  catch (e) { console.log('FAIL ' + name + '\n     ' + (e && e.stack || e)); process.exitCode = 1; }
}

function squad(chars) {
  return chars.map(function (ch, i) { return { id: 'c' + i, char: ch, owner: 'p1' }; });
}
function game(chars, opts) {
  opts = opts || {};
  return Rules.init({ room: 'hall', squad: squad(chars), seed: opts.seed || 42, spook: opts.spook || 'giggly' });
}
function run(s, n) { for (var i = 0; i < n; i++) { s = Rules.tick(s); } return s; }
function calm(s) { s.creature.appearAt = 1e9; return s; } // no creature
function evs(s, k) { return s.events.filter(function (e) { return e.k === k; }); }
function goAct(s, id, act) { return Rules.apply(s, { t: 'go', id: id, act: act }); }
function untilIdle(s, id, max) {
  for (var i = 0; i < (max || 1500); i++) {
    var c = Rules.charById(s, id);
    if (!c.path.length && !c.chan) { return s; }
    s = Rules.tick(s);
  }
  throw new Error('did not settle');
}

test('same seed gives the same code; state is plain JSON', function () {
  var a = game(['tinker'], { seed: 7 }), b = game(['tinker'], { seed: 7 });
  assert.deepStrictEqual(a.code, b.code);
  assert.strictEqual(JSON.stringify(a), JSON.stringify(JSON.parse(JSON.stringify(a))));
});

test('apply and tick never mutate the input state', function () {
  var s = game(['tinker']), before = JSON.stringify(s);
  Rules.apply(s, { t: 'go', id: 'c0', x: 3, y: 3 });
  Rules.tick(s);
  assert.strictEqual(JSON.stringify(s), before);
});

test('walking reaches the tapped cell; running is twice as fast and costs stamina', function () {
  var s = calm(game(['tinker', 'shadow']));
  s = Rules.apply(s, { t: 'go', id: 'c0', x: 14, y: 16 });          // 3 cells up
  s = Rules.apply(s, { t: 'go', id: 'c1', x: 18, y: 19, run: true }); // 3 cells right
  s = run(s, 9);
  var walker = Rules.charById(s, 'c0'), runner = Rules.charById(s, 'c1');
  assert.deepStrictEqual([walker.x, walker.y], [14, 16]);
  assert.deepStrictEqual([runner.x, runner.y], [18, 19]);
  assert.ok(runner.stamina < 100, 'running spent stamina');
});

test('running until empty leaves you puffed, then stamina recharges', function () {
  var s = calm(game(['muscle']));
  s = Rules.apply(s, { t: 'go', id: 'c0', x: 1, y: 1, run: true });
  s = Rules.apply(s, { t: 'go', id: 'c0', x: 14, y: 8, run: true });
  s = untilIdle(s, 'c0');
  s = Rules.apply(s, { t: 'go', id: 'c0', x: 1, y: 1, run: true });
  s = untilIdle(s, 'c0');
  assert.ok(evs(s, 'puffed').length >= 1, 'got puffed');
  s = run(s, 80);
  assert.strictEqual(Rules.charById(s, 'c0').stamina, 100);
  assert.strictEqual(Rules.charById(s, 'c0').tired, false);
});

test('popping all three balloons reveals the code in order, and the keypad opens the door', function () {
  var s = calm(game(['shadow'])), i;
  ['b0', 'b1', 'b2'].forEach(function (b) { s = goAct(s, 'c0', b); s = untilIdle(s, 'c0'); });
  assert.deepStrictEqual(s.known, s.code);
  s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0');
  assert.ok(Rules.nearDoor(s, Rules.charById(s, 'c0')));
  for (i = 0; i < 3; i++) { s = Rules.apply(s, { t: 'press', id: 'c0', c: s.code[i] }); }
  assert.strictEqual(s.doorOpen, true);
  s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0');
  assert.strictEqual(s.status, 'cleared');
  assert.ok(s.points.c0 > 0);
});

test('a wrong code buzzes and sends the creature to the door', function () {
  var s = game(['shadow']);
  s = run(s, 205); // creature is out
  s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0');
  var wrong = s.code[0] === 'red' ? 'blue' : 'red';
  s = Rules.apply(s, { t: 'press', id: 'c0', c: wrong });
  s = Rules.apply(s, { t: 'press', id: 'c0', c: wrong });
  s = Rules.apply(s, { t: 'press', id: 'c0', c: wrong });
  assert.strictEqual(s.doorOpen, false);
  assert.strictEqual(evs(s, 'wrong').length, 1);
  assert.ok(s.creature.mode === 'search' || s.creature.mode === 'hunt');
});

test('two ways through: Tinker picks the lock; Muscle shoves the cabinet', function () {
  var s = calm(game(['tinker']));
  s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0');
  s = Rules.apply(s, { t: 'pick', id: 'c0' }); s = untilIdle(s, 'c0');
  assert.strictEqual(s.doorOpen, true);

  s = calm(game(['muscle']));
  s = goAct(s, 'c0', 'cab'); s = untilIdle(s, 'c0');
  assert.strictEqual(s.holeOpen, true);
  s = goAct(s, 'c0', 'hole'); s = untilIdle(s, 'c0');
  assert.strictEqual(s.status, 'cleared');
});

test('Brainy reads the invitation and Glow lights the wall; others are told who can', function () {
  var s = calm(game(['brainy']));
  s = goAct(s, 'c0', 'invite'); s = untilIdle(s, 'c0');
  assert.deepStrictEqual(s.known, s.code);
  s = calm(game(['glow']));
  s = goAct(s, 'c0', 'uv'); s = untilIdle(s, 'c0');
  assert.deepStrictEqual(s.known, s.code);
  s = calm(game(['tinker']));
  s = goAct(s, 'c0', 'invite'); s = untilIdle(s, 'c0');
  assert.strictEqual(evs(s, 'need')[0].skill, 'brainy');
  assert.deepStrictEqual(s.known, [null, null, null]);
});

test('the creature catches a visible player, who goes to the cage; a teammate frees them', function () {
  var s = game(['shadow', 'tinker']);
  s.creature.appearAt = 0;
  var k = s.creature, t = Rules.charById(s, 'c1');
  t.x = 3; t.y = 13; // right next to the creature's door
  s = run(s, 30);
  t = Rules.charById(s, 'c1');
  assert.strictEqual(t.caged, true);
  assert.strictEqual(evs(s, 'caught').length, 1);
  s.creature.appearAt = 1e9; s.creature.active = false; // creature leaves
  s = goAct(s, 'c0', 'cage'); s = untilIdle(s, 'c0');
  assert.strictEqual(Rules.charById(s, 'c1').caged, false);
  assert.strictEqual(evs(s, 'rescue').length, 1);
});

test('a hidden player is not caught; a shield saves one capture', function () {
  var s = game(['shadow']);
  var c = Rules.charById(s, 'c0');
  c.x = 3; c.y = 7; c.hidden = true; c.hideId = 'sofa';
  s.creature.appearAt = 0;
  s.creature.x = 3; s.creature.y = 6;
  s = run(s, 20);
  assert.strictEqual(Rules.charById(s, 'c0').caged, false);

  s = game(['tinker']);
  c = Rules.charById(s, 'c0');
  c.shield = true; c.x = 2; c.y = 13;
  s.creature.appearAt = 0;
  s = run(s, 5);
  assert.strictEqual(evs(s, 'shield').length, 1);
  assert.strictEqual(Rules.charById(s, 'c0').caged, false);
  assert.strictEqual(Rules.charById(s, 'c0').shield, false);
});

test('everyone caged loses the room; retry starts it again; three losses end the run', function () {
  var s = game(['tinker']);
  var c = Rules.charById(s, 'c0');
  c.x = 2; c.y = 13; s.creature.appearAt = 0;
  s = run(s, 5);
  assert.strictEqual(s.status, 'lost');
  s = Rules.apply(s, { t: 'retry' });
  assert.strictEqual(s.status, 'playing');
  assert.strictEqual(s.tries, 1);
  c = Rules.charById(s, 'c0'); c.x = 2; c.y = 13; s.creature.appearAt = 0;
  s = run(s, 5); s = Rules.apply(s, { t: 'retry' });
  c = Rules.charById(s, 'c0'); c.x = 2; c.y = 13; s.creature.appearAt = 0;
  s = run(s, 5);
  assert.strictEqual(s.status, 'over');
  assert.ok(Rules.isOver(s));
});

test('a clue costs the asker energy (Brainy half) and points at the next step', function () {
  var s = calm(game(['tinker', 'brainy']));
  s = Rules.apply(s, { t: 'clue', id: 'c0' });
  assert.strictEqual(Rules.charById(s, 'c0').energy, 70);
  assert.strictEqual(s.hint.obj, 'door');
  s = Rules.apply(s, { t: 'clue', id: 'c1' });
  assert.strictEqual(Rules.charById(s, 'c1').energy, 85);
  assert.strictEqual(s.cluesLeft, 1);
});

test('presents give boosts: candy corn runs free, the other gives a shield', function () {
  var s = calm(game(['muscle']));
  s = goAct(s, 'c0', 'p0'); s = untilIdle(s, 'c0');
  assert.ok(Rules.charById(s, 'c0').freeRunUntil > s.tick);
  s = goAct(s, 'c0', 'p1'); s = untilIdle(s, 'c0');
  assert.strictEqual(Rules.charById(s, 'c0').shield, true);
});

test('every squad of one can clear the room on its own', function () {
  ['tinker', 'shadow', 'brainy', 'muscle', 'glow'].forEach(function (ch) {
    var s = calm(game([ch])), i;
    if (ch === 'muscle') { s = goAct(s, 'c0', 'cab'); s = untilIdle(s, 'c0'); s = goAct(s, 'c0', 'hole'); }
    else if (ch === 'tinker') { s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0'); s = Rules.apply(s, { t: 'pick', id: 'c0' }); s = untilIdle(s, 'c0'); s = goAct(s, 'c0', 'door'); }
    else {
      if (ch === 'brainy') { s = goAct(s, 'c0', 'invite'); s = untilIdle(s, 'c0'); }
      else if (ch === 'glow') { s = goAct(s, 'c0', 'uv'); s = untilIdle(s, 'c0'); }
      else { ['b0', 'b1', 'b2'].forEach(function (b) { s = goAct(s, 'c0', b); s = untilIdle(s, 'c0'); }); }
      s = goAct(s, 'c0', 'door'); s = untilIdle(s, 'c0');
      for (i = 0; i < 3; i++) { s = Rules.apply(s, { t: 'press', id: 'c0', c: s.code[i] }); }
      s = goAct(s, 'c0', 'door');
    }
    s = untilIdle(s, 'c0');
    assert.strictEqual(s.status, 'cleared', ch + ' cleared');
  });
});

test('Shadow sneaks: unseen and ungrabbable for 6 seconds, then must wait', function () {
  var s = game(['shadow']);
  var c = Rules.charById(s, 'c0');
  c.x = 3; c.y = 13; s.creature.appearAt = 0;
  s = Rules.apply(s, { t: 'sneak', id: 'c0' });
  s = run(s, 30);
  assert.strictEqual(Rules.charById(s, 'c0').caged, false);
  s = Rules.apply(s, { t: 'sneak', id: 'c0' });
  assert.strictEqual(evs(s, 'notyet').length, 1);
  s = calm(game(['tinker']));
  s = Rules.apply(s, { t: 'sneak', id: 'c0' });
  assert.strictEqual(evs(s, 'sneak').length, 0, 'only Shadow sneaks');
});

test('preset phrases: index only, three per ten seconds', function () {
  var s = calm(game(['glow']));
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 3 });
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 4 });
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 5 });
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 6 });
  assert.strictEqual(evs(s, 'say').length, 3);
  assert.strictEqual(evs(s, 'hush').length, 1);
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 'hello' });
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 99 });
  assert.strictEqual(evs(s, 'say').length, 3, 'free text and bad indexes refused');
  s = run(s, 101);
  s = Rules.apply(s, { t: 'say', id: 'c0', p: 0 });
  assert.strictEqual(evs(s, 'say').length, 4);
});

console.log('\n' + passed + ' passed' + (process.exitCode ? ', some FAILED' : ''));
