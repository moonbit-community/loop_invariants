# Mo's Algorithm (Reference, Extended)

Extended Mo's algorithm variants, including tree queries and additional
window-maintenance patterns.

## What it demonstrates

- Query ordering by blocks
- Tree flattening for Mo on trees
- Maintaining a rolling window state

## Core Idea

Mo's algorithm answers offline range queries by sorting them so adjacent
queries have similar [l, r] windows. We maintain a window and update a data
structure with `add` and `remove` operations as the window moves.

## Pseudocode Sketch

```mbt nocheck
block = floor(sqrt(n))
sort queries by (l / block, r) with alternating r-order

cur_l = 0, cur_r = -1
for q in sorted:
  while cur_l > q.l: add(--cur_l)
  while cur_r < q.r: add(++cur_r)
  while cur_l < q.l: remove(cur_l++)
  while cur_r > q.r: remove(cur_r--)
  answer[q] = current_state()
```

## Notes

- Complexity is roughly O((n + q) * sqrt(n)) for O(1) add/remove.
- This package is a reference implementation with invariants (not a public API).
