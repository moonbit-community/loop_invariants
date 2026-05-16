# A* Shortest Path

## Overview

**A\*** (Hart, Nilsson, Raphael 1968) generalises Dijkstra's algorithm
to exploit a heuristic estimate of remaining cost to the goal. With a
good heuristic, A\* expands only a fraction of the vertices Dijkstra
would, while still guaranteeing the optimal path.

The priority queue is ordered by `f(v) = g(v) + h(v)`:

- `g(v)` — best known cost from `source` to `v`.
- `h(v)` — heuristic estimate of remaining cost from `v` to `target`.

When `h ≡ 0`, A\* **reduces to Dijkstra**. The more accurately `h`
estimates the true remaining cost, the closer A\* gets to expanding only
the optimal path.

| Operation | Time | Space |
|---|---|---|
| `a_star(n, adj, s, t, h)` | `O((V + E) log V)` | `O(V)` |

---

## Heuristic conditions

- **Admissible**: `h(v) ≤ d*(v, target)` for every `v`. Required for
  optimality.
- **Consistent**: `h(u) ≤ w(u, v) + h(v)` for every edge `u → v`.
  Stronger than admissibility; implies optimality *and* optimal
  efficiency (no admissible algorithm expands fewer vertices using the
  same heuristic).

Common consistent heuristics for grid pathfinding:

- **Manhattan distance** — when only 4-directional moves are allowed.
- **Chebyshev distance** — when 8-directional moves cost 1.
- **Euclidean distance** — when diagonal moves cost `√2`.

---

## The invariant

The same as Dijkstra's:

> When a vertex `u` is popped (and accepted) from the open-set with
> `g(u) = d`, `d` equals the true shortest-path cost from `source`
> to `u`.

For a consistent heuristic, the popped `f` values are monotonically
non-decreasing, which is enough for this invariant — the same proof as
Dijkstra's, with `h` cancelling on both sides.

---

## API

```
pub(all) struct Edge       { to : Int; w : Int64 }
pub(all) struct AStarResult {
  dist : Int64?      // None if target unreachable
  path : Array[Int]  // source ... target, or [] when None
  expanded : Int     // settled-vertex count (handy for heuristic tuning)
}

pub fn a_star(
  n : Int,
  adj : Array[Array[Edge]],
  source : Int,
  target : Int,
  heuristic : (Int) -> Int64,
) -> AStarResult
```

Edge costs must be non-negative. The graph is directed; for undirected
graphs add both `u → v` and `v → u`.

---

## Tests and examples

```mbt check
///|
test "a_star reaches target" {
  let adj : Array[Array[@a_star.Edge]] = [
    [{ to: 1, w: 1L }, { to: 2, w: 4L }],
    [{ to: 2, w: 2L }],
    [],
  ]
  debug_inspect(@a_star.a_star(3, adj, 0, 2, _ => 0L).dist, content="Some(3)")
}
```

```mbt check
///|
test "a_star unreachable" {
  let adj : Array[Array[@a_star.Edge]] = [[{ to: 1, w: 1L }], [], []]
  debug_inspect(@a_star.a_star(3, adj, 0, 2, _ => 0L).dist, content="None")
}
```

---

## Use cases

- **Game pathfinding** on grids with terrain costs.
- **Robot motion planning** with admissible heuristics.
- **Puzzle solving** (8-puzzle, sliding tile, Rubik's cube with
  pattern-database heuristics).
- **Route planning** on road networks (with ALT / landmark heuristics).

---

## Pitfalls

- **Inadmissible heuristic.** A\* will still finish but may return a
  *suboptimal* path. Useful for "anytime" / greedy variants but
  disables the optimality guarantee.
- **Negative edges.** Not supported; use Bellman-Ford or SPFA.
- **Stale heap entries.** When a vertex's `g` is improved, the old
  entry is left in the heap and skipped on pop (`e.g != g[e.v]` check).
- **Tied f values.** Implementation is deterministic given the input;
  if you need a specific tiebreaker (preferring higher `g`, etc.), wrap
  the heuristic accordingly.

---

## Related concepts

```
Dijkstra                same algorithm with h ≡ 0
Bidirectional A*        searches from both ends, halving the typical wavefront
IDA* (Iterative-deepening) memory-light variant; useful for huge state spaces
ALT / landmark          consistent heuristic from precomputed landmark distances
```
