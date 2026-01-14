# Suurballe's Algorithm (Edge-Disjoint Shortest Paths)

## Overview

**Suurballe's algorithm** finds **two edge-disjoint shortest paths** from a
source to a target in a weighted directed graph. The combined length of the
two paths is minimized.

- **Time**: O(E log V)
- **Space**: O(V + E)
- **Key Feature**: Optimal pair of non-overlapping paths

## The Key Insight

```
Problem: Find two paths s → t that share no edges, minimizing total length

Naive approach: Find shortest path, remove its edges, find second shortest
  → NOT optimal! Removing edges might block better solutions

Suurballe's insight:
  1. Find shortest path P1
  2. Reverse edges of P1 and use potentials to reweight
  3. Find shortest path P2 in modified graph
  4. Cancel overlapping edges (they appear in both directions)
  5. Extract two disjoint paths from remaining edges

The reversal trick allows "undoing" parts of P1 to find globally optimal pair!
```

## Visual: Why Reversal Works

```
Original graph:           After finding P1 = s→a→b→t
    a───2───►b               and reversing P1's edges:
   ↗         ↘
  1           1           s───1───►a←──2──b───1───►t
 ↗             ↘                   │       ↑
s───────3───────►t                 │       │
                                   └───3───┘

If we find P2 = s→t directly (cost 3), we'd have:
  P1: s→a→b→t (cost 4)
  P2: s→t (cost 3)
  Total: 7

But with reversal, P2 might use reversed edge b→a:
  P2 in modified graph: s→a→b→a→t? No, that revisits a.

Actually, the reversal allows P2 to "cancel" edge a→b:
  - P1 used a→b
  - P2 uses b→a (reversed)
  - They cancel out!

Final paths after cancellation might be:
  Path 1: s→a→t (via some route)
  Path 2: s→b→t (via some route)
```

## Algorithm

```
suurballe(graph, s, t):
  // Step 1: First Dijkstra from s
  dist = dijkstra(graph, s)
  if dist[t] == ∞: return None

  // Step 2: Compute potentials (Johnson's trick)
  potential[v] = dist[v]

  // Step 3: Create modified graph
  modified = empty graph
  for each edge (u, v, w) in graph:
    reduced_cost = w + potential[u] - potential[v]
    modified.add_edge(u, v, reduced_cost)

  // Step 4: Reverse edges on shortest path s→t
  path1 = reconstruct_path(s, t)
  for each edge (u, v) in path1:
    modified.remove_edge(u, v)
    modified.add_edge(v, u, 0)  // Cost 0 due to potentials

  // Step 5: Second Dijkstra from s in modified graph
  dist2 = dijkstra(modified, s)
  if dist2[t] == ∞: return None

  // Step 6: Extract two disjoint paths
  path2 = reconstruct_path_in_modified(s, t)
  return extract_disjoint_paths(path1, path2)
```

## Example Usage

```mbt check
///|
test "suurballe example" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 4, 1L),
    (0, 2, 1L),
    (2, 4, 1L),
    (0, 3, 2L),
    (3, 4, 0L),
  ]
  let result = @suurballe_disjoint_paths.suurballe_disjoint_paths(
    5,
    edges[:],
    0,
    4,
  )
  match result {
    None => fail("expected two disjoint paths")
    Some((p1, p2)) => {
      assert_eq(p1[0], 0)
      assert_eq(p1[p1.length() - 1], 4)
      assert_eq(p2[0], 0)
      assert_eq(p2[p2.length() - 1], 4)
      assert_true(p1.length() == 3)
      assert_true(p2.length() == 3)
    }
  }
}
```

## Algorithm Walkthrough

```
Graph:
  0 ──1──► 1 ──1──► 4
  │
  1
  │
  ▼
  2 ──1──────────► 4

  0 ──2──► 3 ──0──► 4

Step 1: Dijkstra from 0
  dist = [0, 1, 1, 2, 2]
  Shortest path: 0→1→4 (cost 2) or 0→2→4 (cost 2)
  Take P1 = 0→1→4

Step 2: Potentials = dist = [0, 1, 1, 2, 2]

Step 3: Reweight edges
  Edge 0→1: reduced = 1 + 0 - 1 = 0
  Edge 1→4: reduced = 1 + 1 - 2 = 0
  Edge 0→2: reduced = 1 + 0 - 1 = 0
  Edge 2→4: reduced = 1 + 1 - 2 = 0
  Edge 0→3: reduced = 2 + 0 - 2 = 0
  Edge 3→4: reduced = 0 + 2 - 2 = 0

Step 4: Reverse P1 edges (0→1, 1→4)
  Remove: 0→1, 1→4
  Add: 1→0 (cost 0), 4→1 (cost 0)

Step 5: Second Dijkstra finds P2 = 0→2→4 (cost 0 in reduced)

Step 6: Extract paths
  P1 edges: {0→1, 1→4}
  P2 edges: {0→2, 2→4}
  No overlap → paths are already disjoint!

Result:
  Path 1: 0 → 1 → 4 (length 2)
  Path 2: 0 → 2 → 4 (length 2)
  Total: 4
```

## Why Johnson's Potentials?

```
Problem: After reversing edges, some might have negative weight!

Original edge u→v has weight w.
Reversed edge v→u would have weight -w.

Solution: Use potentials to make all reduced costs non-negative.

reduced_cost(u, v) = w + potential[u] - potential[v]

If potential = shortest path distances:
  - reduced_cost ≥ 0 for all edges (triangle inequality)
  - Shortest paths are preserved
  - Can use Dijkstra instead of Bellman-Ford!

For reversed edges on P1:
  reduced_cost(v, u) = -w + potential[v] - potential[u]
                     = -(w + potential[u] - potential[v])
                     = -reduced_cost(u, v)
                     = 0 (since edge is on shortest path!)
```

## Common Applications

### 1. Network Reliability
```
Find two independent routes for fault tolerance.
If one path fails, the other still works.
```

### 2. Telecommunications
```
Route backup connections that don't share any links.
Ensures redundancy in network infrastructure.
```

### 3. Transportation
```
Evacuation routes that don't share roads.
Prevents congestion during emergencies.
```

### 4. VLSI Routing
```
Route multiple signals without crossing.
Each path represents a wire trace.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| First Dijkstra | O(E log V) | Standard shortest path |
| Potential computation | O(V) | Just copy distances |
| Graph modification | O(E) | Reweight + reverse |
| Second Dijkstra | O(E log V) | In modified graph |
| Path extraction | O(V) | Trace back paths |
| **Total** | **O(E log V)** | Two Dijkstra passes |

## Suurballe vs Other Approaches

| Method | Finds | Time |
|--------|-------|------|
| Suurballe | 2 edge-disjoint | O(E log V) |
| k-shortest paths | k paths (may overlap) | O(kE log V) |
| Max-flow | k edge-disjoint | O(kE log V) |
| Min-cost max-flow | k min-cost edge-disjoint | O(kE log V) |

**Choose Suurballe when**: You need exactly 2 edge-disjoint shortest paths.

## Generalizations

```
For k edge-disjoint paths:
  - Use min-cost max-flow with capacity 1 per edge
  - Cost = edge weight, find flow of value k
  - Decompose flow into k paths

For vertex-disjoint paths:
  - Split each vertex v into v_in and v_out
  - Connect v_in → v_out with capacity 1
  - Apply edge-disjoint algorithm on transformed graph
```

## Implementation Notes

- Handle unreachable target (return None)
- Store parent pointers for path reconstruction
- Be careful with edge reversal in adjacency list
- Potentials make all reduced costs non-negative
- Reversed edges on P1 have reduced cost 0

