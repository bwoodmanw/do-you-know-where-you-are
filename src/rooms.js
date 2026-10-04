/* rooms.js - room data. A room is data plus art; the rules read it.
   Map key: # wall, . floor, T table (blocks walking and sight),
   D the big door (opens with the code or Tinker), H a hole behind the
   cabinet (opens when Muscle shoves it), C the creature's door. */
(function (R) {
  'use strict';
  R.addRoom({
    id: 'hall', theme: 'party', name: 'The Front Hall', w: 16, h: 10,
    map: [
      '########D#######',
      '#..............#',
      'C..............#',
      '#....TTTT......#',
      '#....TTTT......#',
      '#..............#',
      '#..............H',
      '#..............#',
      '#..............#',
      '################'
    ],
    start: [[7, 8], [8, 8], [6, 8], [9, 8], [5, 7], [10, 7]],
    spawn: [1, 2],
    patrol: [[1, 2], [7, 2], [13, 2], [13, 6], [9, 6], [4, 6], [2, 4]],
    objects: [
      { id: 'door', kind: 'door', x: 8, y: 0 },
      { id: 'hole', kind: 'hole', x: 15, y: 6 },
      { id: 'cab', kind: 'cabinet', x: 14, y: 6, block: true },
      { id: 'cage', kind: 'cage', x: 1, y: 7, block: true },
      { id: 'b0', kind: 'balloon', n: 0, x: 2, y: 4 },
      { id: 'b1', kind: 'balloon', n: 1, x: 12, y: 3 },
      { id: 'b2', kind: 'balloon', n: 2, x: 11, y: 8 },
      { id: 'invite', kind: 'invite', x: 4, y: 0 },
      { id: 'uv', kind: 'uv', x: 11, y: 0 },
      { id: 'p0', kind: 'present', boost: 'candy', x: 13, y: 8 },
      { id: 'p1', kind: 'present', boost: 'shield', x: 1, y: 1 },
      { id: 'wardrobe', kind: 'hide', look: 'wardrobe', x: 14, y: 1, cap: 2 },
      { id: 'curtain', kind: 'hide', look: 'curtain', x: 1, y: 5, cap: 2 },
      { id: 'cloth', kind: 'hide', look: 'cloth', x: 6, y: 5, cap: 2 },
      { id: 'sofa', kind: 'hide', look: 'sofa', x: 9, y: 2, cap: 2 },
      { id: 'box', kind: 'hide', look: 'box', x: 4, y: 8, cap: 2 }
    ]
  });
})(typeof Rules !== 'undefined' ? Rules : require('./rules.js'));
