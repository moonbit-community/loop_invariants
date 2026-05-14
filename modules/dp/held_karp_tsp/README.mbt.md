# Held-Karp TSP

## Overview

Exact Traveling Salesman in `O(2^n · n²)` via bitmask DP. Solves
both symmetric and asymmetric TSP for `n ≤ 20` in seconds. The best
known exact algorithm for general TSP — better polynomial approaches
remain an open problem (a millennium-class question is whether TSP
admits a substantially better algorithm than `O(c^n)` for some
constant `c < 2`).

- **Time**: O(2^n · n²)
- **Space**: O(2^n · n)
- **Signature**: `shortest_tour(n, cost) -> Int64?`

Held & Karp (1962) and independently Bellman (1962) introduced the
DP. The bitmask state `(mask, i)` is the canonical example of
"exponential DP" in algorithms textbooks.

---

## The state

```
dp[mask][i]  =  minimum cost of a path that
                  - starts at city 0,
                  - visits exactly the cities in `mask`,
                  - ends at city i.
```

`mask` is a bitmask: bit `j` is set iff city `j` has been visited.
Bit 0 is always set (every state corresponds to a path beginning at
city 0).

---

## The recurrence

```
base: dp[{0}][0] = 0                  -- sitting at city 0, no other city visited
recurrence: dp[mask][i] = min over j ∈ mask, j ≠ i of
              dp[mask \ {i}][j] + cost[j][i]
final answer: min over i ∈ [1, n) of dp[{all}][i] + cost[i][0]
```

We process masks in numeric (= popcount) order so the subproblems
`dp[mask \ {i}]` are always available when we need them.

---

## Why O(2^n · n²)?

| Factor | Explanation |
|---|---|
| `2^n` | masks |
| `· n` | the "ending city" dimension |
| `· n` | inner loop over the "previous city" candidates |

Total `O(2^n · n²)`. For `n = 20`, that's about `4·10^8` operations
— a few seconds on commodity hardware.

---

## Worked example

A 3-city symmetric TSP with cost matrix:

```
    0   1   3
    1   0   2
    3   2   0
```

The tour `0 → 1 → 2 → 0` has cost `1 + 2 + 3 = 6`, and the tour
`0 → 2 → 1 → 0` has cost `3 + 2 + 1 = 6`. Both are optimal.

DP trace:

```
mask = 001        (only city 0)
  dp[001][0] = 0

mask = 011        (cities {0, 1})
  dp[011][1] = dp[001][0] + cost[0][1] = 0 + 1 = 1

mask = 101        (cities {0, 2})
  dp[101][2] = dp[001][0] + cost[0][2] = 0 + 3 = 3

mask = 111        (cities {0, 1, 2})
  dp[111][1] = min(dp[101][2] + cost[2][1], ...) = 3 + 2 = 5
  dp[111][2] = min(dp[011][1] + cost[1][2], ...) = 1 + 2 = 3

answer = min(dp[111][1] + cost[1][0], dp[111][2] + cost[2][0])
       = min(5 + 1, 3 + 3) = min(6, 6) = 6
```

---

## Tests and examples

```mbt check
///|
test "held-karp triangle" {
  let cost : Array[Array[Int64]] = [[0L, 1L, 3L], [1L, 0L, 2L], [3L, 2L, 0L]]
  debug_inspect(@held_karp_tsp.shortest_tour(3, cost[:]), content="Some(6)")
}
```

```mbt check
///|
test "held-karp four cities asymmetric" {
  let cost : Array[Array[Int64]] = [
    [0L, 10L, 15L, 20L],
    [5L, 0L, 9L, 10L],
    [6L, 13L, 0L, 12L],
    [8L, 8L, 9L, 0L],
  ]
  // Optimal tour 0 -> 1 -> 3 -> 2 -> 0 = 10 + 10 + 9 + 6 = 35.
  debug_inspect(@held_karp_tsp.shortest_tour(4, cost[:]), content="Some(35)")
}
```

```mbt check
///|
test "held-karp single city" {
  let cost : Array[Array[Int64]] = [[0L]]
  debug_inspect(@held_karp_tsp.shortest_tour(1, cost[:]), content="Some(0)")
}
```

```mbt check
///|
test "held-karp degenerate" {
  let cost : Array[Array[Int64]] = []
  debug_inspect(@held_karp_tsp.shortest_tour(0, cost[:]), content="None")
}
```

---

## Complexity

| Operation       | Time          | Space        |
|-----------------|---------------|--------------|
| `shortest_tour` | O(2^n · n²)   | O(2^n · n)   |

For `n = 20` the DP table has `2^20 · 20 ≈ 2.1 · 10^7` Int64 entries
(~160 MB). Beyond `n ≈ 22-25` you need either streaming
implementations or heuristics (Lin-Kernighan, Christofides, etc.).

---

## When to reach for it

- **Exact small-TSP** (`n ≤ 20`): vehicle routing for short driver
  shifts, PCB drill paths, DNA fragment ordering on small instances.
- **As a baseline for heuristics**: validate that the heuristic
  output is close to optimal on small benchmarks.
- **As a teaching example for bitmask DP**: tests are usually written
  comparing against the exact algorithm on small instances.

For `n > 20`, prefer:
- **Christofides** (1.5-approximation, metric TSP)
- **Lin-Kernighan** (near-optimal in practice)
- **Concorde** (exact but with sophisticated branch-and-cut)

---

## Common pitfalls

- **The `n ≤ 20` bound is hard**. Beyond `n = 20`, the DP table
  overflows the largest practical machine memories; this package
  defensively returns `None`.
- **Asymmetric vs symmetric**. The algorithm handles both; just
  pass a non-symmetric cost matrix if needed.
- **Sparse graphs / missing edges**. Encode "no edge" as the
  sentinel `hk_inf = 10^18`. The DP will skip such transitions and
  return `None` if no tour exists.
- **Bit-0-must-be-set convention**. The recurrence assumes the
  tour starts at city 0. Renumber if you want a different starting
  city (or just observe that the optimal tour's cost is the same
  regardless of starting city).

---

## Related concepts

```
Held-Karp (this)           exact, O(2^n · n^2)
Christofides              1.5-approximation, metric TSP, polynomial
Lin-Kernighan             local search heuristic, ~1% from optimum
Branch-and-bound          general framework; Concorde is the gold standard
2-opt / 3-opt             simple local-search improvements
Approximation: PTAS for Euclidean TSP (Arora 1996)
```
