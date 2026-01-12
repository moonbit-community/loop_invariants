# Edmonds' Arborescence (Chu–Liu/Edmonds)

## Overview

A **minimum-cost arborescence** is the directed analogue of a minimum spanning
Tree. Given a root `r`, we want a directed tree where every node (except `r`) has
exactly one incoming edge, and all nodes are reachable from `r`.

This package implements the Chu–Liu/Edmonds algorithm.

- **Time**: O(V × E) (simple implementation)
- **Space**: O(V + E)

## Key Idea

1. For each node `v != r`, choose the cheapest incoming edge.
2. If this forms no directed cycle, we are done.
3. Otherwise, **contract** each cycle into a supernode and adjust edge weights:

```
  w'(u -> v) = w(u -> v) - in_cost[v]   (when v is inside the cycle)
```

This preserves optimality while ensuring that choosing one edge into the cycle
corresponds to selecting exactly one edge to break it.

## Example

```
Edges (root=0):
0->1 (1), 0->2 (5), 1->2 (1), 1->3 (2), 2->3 (1)

Min incoming edges:
1<-0 (1), 2<-1 (1), 3<-2 (1)

No cycle, total cost = 3
```

## Example Usage

```mbt check
///|
test "arborescence example" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1 },
    { from: 0, to: 2, weight: 5 },
    { from: 1, to: 2, weight: 1 },
    { from: 1, to: 3, weight: 2 },
    { from: 2, to: 3, weight: 1 },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges[:], 0).unwrap()
  inspect(res.cost, content="3")
}
```

## When It Returns None

If some vertex cannot be reached from the root, no arborescence exists.
The implementation first performs a reachability check.

## Applications

- Directed network design
- Control-flow graph optimization
- Dependency graphs with costs
- Minimum-cost branching in directed graphs
