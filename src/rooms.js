/* rooms.js - room data. A room is data plus art; the rules read it.
   Map key: # wall, . floor, T furniture that blocks walking and sight
   (tables, counters, shelves), D the big door (opens with the code or
   Tinker), H a hole behind the cabinet (opens when Muscle shoves it),
   C the creature's door. */
(function (R) {
  'use strict';
  // The ground floor of the party house: six rooms joined by doorways.
  //   Parlour      | Corridor (big door) | Library
  //   Kitchen      | Front Hall (start)  | Game Room (secret hole)
  R.addRoom({
    id: 'hall', theme: 'party', name: 'The Party House', w: 30, h: 22,
    map: [
      '###############D##############',
      '#.........#........#.........#',
      '#.........#........#.........#',
      '#.........#........#.TTTTTTT.#',
      '#.........#........#.........#',
      '#............................#',
      '#.........#........#.TTTTTTT.#',
      '#.........#........#.........#',
      '#.........#........#.........#',
      '#####.#########.########.#####',
      '#.........#........#.........#',
      '#.TTTT....#........#.........#',
      '#.........#........#.........#',
      'C.........#..TTTT..#.........#',
      '#.........#..TTTT..#.........#',
      '#............................#',
      '#.........#........#.........#',
      '#.........#........#.........H',
      '#.........#........#.........#',
      '#.........#........#.........#',
      '#.........#........#.........#',
      '##############################'
    ],
    floors: [
      { x0: 1, y0: 1, x1: 9, y1: 8, kind: 'carpet', name: 'Parlour' },
      { x0: 11, y0: 1, x1: 18, y1: 8, kind: 'boards', name: 'Corridor' },
      { x0: 20, y0: 1, x1: 28, y1: 8, kind: 'green', name: 'Library' },
      { x0: 1, y0: 10, x1: 9, y1: 20, kind: 'tiles', name: 'Kitchen' },
      { x0: 11, y0: 10, x1: 18, y1: 20, kind: 'wood', name: 'Front Hall' },
      { x0: 20, y0: 10, x1: 28, y1: 20, kind: 'purple', name: 'Game Room' }
    ],
    furniture: [
      { x0: 2, y0: 11, x1: 5, y1: 11, kind: 'counter' },
      { x0: 13, y0: 13, x1: 16, y1: 14, kind: 'table' },
      { x0: 21, y0: 3, x1: 27, y1: 3, kind: 'shelf' },
      { x0: 21, y0: 6, x1: 27, y1: 6, kind: 'shelf' }
    ],
    start: [[14, 19], [15, 19], [13, 19], [16, 19], [12, 18], [17, 18]],
    spawn: [1, 13],
    patrol: [[4, 15], [14, 17], [24, 15], [24, 5], [15, 5], [5, 4], [5, 13]],
    objects: [
      { id: 'door', kind: 'door', x: 15, y: 0 },
      { id: 'hole', kind: 'hole', x: 29, y: 17 },
      { id: 'cab', kind: 'cabinet', x: 28, y: 17, block: true },
      { id: 'cage', kind: 'cage', x: 11, y: 11, block: true },
      { id: 'b0', kind: 'balloon', n: 0, x: 7, y: 18 },
      { id: 'b1', kind: 'balloon', n: 1, x: 3, y: 2 },
      { id: 'b2', kind: 'balloon', n: 2, x: 25, y: 12 },
      { id: 'invite', kind: 'invite', x: 6, y: 0 },
      { id: 'uv', kind: 'uv', x: 25, y: 0 },
      { id: 'p0', kind: 'present', boost: 'candy', x: 2, y: 20 },
      { id: 'p1', kind: 'present', boost: 'shield', x: 12, y: 2 },
      { id: 'wardrobe', kind: 'hide', look: 'wardrobe', x: 8, y: 1, cap: 2 },
      { id: 'sofa', kind: 'hide', look: 'sofa', x: 3, y: 7, cap: 2 },
      { id: 'cloth', kind: 'hide', look: 'cloth', x: 14, y: 15, cap: 2 },
      { id: 'curtain', kind: 'hide', look: 'curtain', x: 18, y: 11, cap: 2 },
      { id: 'pantry', kind: 'hide', look: 'wardrobe', x: 9, y: 20, cap: 2 },
      { id: 'box', kind: 'hide', look: 'box', x: 27, y: 20, cap: 2 },
      { id: 'nook', kind: 'hide', look: 'curtain', x: 28, y: 1, cap: 2 }
    ]
  });
})(typeof Rules !== 'undefined' ? Rules : require('./rules.js'));
