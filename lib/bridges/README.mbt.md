# Bridges and Articulation Points

## Overview

**Bridges** are edges whose removal disconnects the graph.
**Articulation Points** are vertices whose removal disconnects the graph.
Both are found in O(V + E) using Tarjan's algorithm.

- **Time**: O(V + E)
- **Space**: O(V)

## Visual Examples

```
Bridges:
    0 ─── 1 ─── 2
    │     │
    └─────┘

Edge (1,2) is a bridge - removing it disconnects vertex 2.
Edges (0,1) and (0,1) form a cycle - neither is a bridge.

Articulation Points:
    0 ─── 1 ─── 3
    │     │
    └─────┤
          2

Vertex 1 is an articulation point - removing it disconnects {0,2} from {3}.
```

## The Key Insight: Low Values

```
DFS creates a tree. For each vertex u:
  disc[u] = discovery time (when first visited)
  low[u] = earliest discovery time reachable via back edges

          disc  low
    0 ─── 1 ─── 3     0: 0, 0
    │     │           1: 1, 0  (can reach 0 via back edge)
    └─────┤           2: 2, 0  (can reach 0 via back edge)
          2           3: 3, 3  (no back edges)

Edge (u,v) is bridge if: low[v] > disc[u]
  - v's subtree cannot reach u or above
  - Removing (u,v) disconnects v's subtree
```

## Algorithm Walkthrough

```
Graph:
    0 ─── 1 ─── 2 ─── 3
    │     │           │
    └─────┘           │
                      4

DFS from 0:
  Visit 0: disc[0]=0, low[0]=0
  Visit 1: disc[1]=1, low[1]=1
    Back edge 1→0: low[1] = min(1, 0) = 0
  Visit 2: disc[2]=2, low[2]=2
  Visit 3: disc[3]=3, low[3]=3
  Visit 4: disc[4]=4, low[4]=4
    Back edge 4→3: low[4] = min(4, 3) = 3
  Back to 3: low[3] = min(3, 3) = 3
  Back to 2: low[2] = min(2, 3) = 2
    Check bridge: low[3]=3 > disc[2]=2? Yes! (2,3) is bridge

Bridges: [(1,2), (2,3)]
  - (1,2): low[2]=2 > disc[1]=1
  - (2,3): low[3]=3 > disc[2]=2
```

## Articulation Point Rules

```
Rule 1: Root is articulation point if it has ≥ 2 DFS children

Rule 2: Non-root u is articulation point if it has child v with:
        low[v] >= disc[u]
        (v's subtree cannot reach above u)

Example:
          0 (root, 2 children → AP)
         / \
        1   3 (has child 4 with low[4]=3 >= disc[3]=2 → AP)
        |   |
        2   4

Root 0 has 2 DFS tree children → articulation point
Node 3 has child 4 with low[4] >= disc[3] → articulation point
```

## Example Usage

```mbt check
///|
test "bridges example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let bridges = @bridges.find_bridges(4, edges[:])
  inspect(bridges, content="[(1, 3)]")
  let cuts = @bridges.articulation_points(4, edges[:])
  inspect(cuts, content="[1]")
}
```

## Common Applications

### 1. Network Reliability
```
Find critical connections in computer networks.
Bridges = single points of failure
Add redundant connections to eliminate bridges.
```

### 2. Social Network Analysis
```
Articulation points = influential connectors
Removing them fragments the network.
```

### 3. Transportation Planning
```
Bridges in road networks = critical routes
Plan alternative routes for these roads.
```

### 4. Circuit Analysis
```
Find critical paths in electrical circuits.
```

## Relationship Between Bridges and Articulation Points

```
Bridge (u,v) implies at least one of u,v is articulation point
(unless it's the only edge)

    0 ─── 1    Bridge (0,1), both are APs

    0 ─── 1 ─── 2    Bridge (1,2), vertex 1 is AP
    │     │
    └─────┘

Not every AP is adjacent to a bridge:
    0 ─── 1 ─── 2
    │     │     │
    └─────┼─────┘
          │
          3

1 is AP (removing it disconnects 3), but no bridges exist!
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Find all bridges | O(V + E) |
| Find all articulation points | O(V + E) |
| Check if edge is bridge | O(1)* |

*After O(V + E) preprocessing

## Bridge Detection vs Cut Detection

| Concept | Bridges | Articulation Points |
|---------|---------|---------------------|
| Type | Edges | Vertices |
| Condition | low[v] > disc[u] | low[v] >= disc[u] |
| Count | ≤ V - 1 | ≤ V |

Note the subtle difference: `>` for bridges, `>=` for articulation points!

## 2-Edge-Connected Components

```
After removing all bridges, remaining components are
2-edge-connected (no single edge removal disconnects them).

    0 ─── 1 ═══ 2 ─── 3
    │     │           │
    └─────┘           │
                      4

Bridge: (1,2)
2-edge-connected components: {0,1}, {2,3,4}
```

## Implementation Notes

- Track parent to avoid counting parent edge as back edge
- For articulation points, count DFS tree children for root separately
- Handle multi-edges carefully (parallel edges are not bridges)
- Initialize low[u] = disc[u], update with back edges and children
- Use adjacency list with edge indices to identify specific bridges

